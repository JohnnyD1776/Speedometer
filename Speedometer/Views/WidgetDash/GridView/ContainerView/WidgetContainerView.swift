//
//  WidgetContainerView.swift
//  Speedometer
//
//  Created by John Durcan on 18/06/2025.
//
import SwiftUI

/// A view that wraps a draggable widget in the Speedometer app's dashboard, handling drag gestures, page switching, and grid snapping.
/// Displays a widget that can be dragged to new grid positions across pages, with visual and haptic feedback for snapping and page changes.
/// Supports theming and environment objects for data, location, and widget management, optimized for iPhone with iPad scalability.
struct WidgetContainerView: View {
  // MARK: - Environment
  @Environment(\.theme) private var theme
  @Environment(\.safeAreaInsets) private var safeAreaInsets
  @EnvironmentObject private var widgetManager: WidgetOrganizer
  @EnvironmentObject private var dataManager: DataManager
  @EnvironmentObject private var locationManager: LocationManager
  // MARK: - Bindings
  @Binding var draggedWidget: WidgetComponent?
  @Binding var selectedPage: Int
  @Binding var dragLocation: CGPoint?

  // MARK: - State
  @State private var previewOffset: CGSize = .zero
  @State private var isDragging = false
  @State private var lastSnappedPosition: GridPosition?
  @State private var lastPageSwitched: Int?
  @State private var pageSwitchTimer: DispatchWorkItem?
  @State private var lastSwitchTime: Date?


  // MARK: - Properties
  let widget: WidgetComponent
  let geometry: GeometryProxy
  let minimumInterval: TimeInterval = 1.0 // Minimum time between page switches
  let animationDelay: TimeInterval = 0.3 // Delay for animation start


  // MARK: - Body
  var body: some View {
    contentView
      .offset(isDragging ? previewOffset : .zero)
      .animation(.spring(), value: dragLocation)
      .animation(.spring(), value: previewOffset)
      .environment(\.theme, widget.theme?.theme ?? theme)
      .environmentObject(widgetManager)
      .environmentObject(dataManager)
      .environmentObject(locationManager)
  }

  // MARK: - Subviews

  /// The main content view of the widget, including drag-and-drop and gesture handling.
  ///
  /// - Returns: A `View` with the widget, configured for dragging and dropping with opacity and gesture support.
  private var contentView: some View {
    WidgetView(widget: widget, isDragging: isDragging)
      .opacity(isDragging ? 0 : 1)
      .draggable(widget.id.uuidString) {
        draggablePreview
      }
      .onDrop(
        of: [.text],
        delegate: WidgetDropDelegate(
          widget: widget,
          widgetManager: widgetManager,
          geometry: geometry,
          draggedWidget: $draggedWidget
        )
      )
      .gesture(dragGesture)
  }

  /// The preview view shown during dragging, styled with partial opacity and widget-specific sizing.
  ///
  /// - Returns: A `View` representing the dragged widget, scaled to its grid size and themed appropriately.
  private var draggablePreview: some View {
    WidgetView(widget: widget, isDragging: true)
      .frame(
        width: cellWidth,
        height: cellHeight
      )
      .opacity(0.5)
      .environment(\.theme, widget.theme?.theme ?? theme)
      .environmentObject(widgetManager)
      .environmentObject(dataManager)
      .environmentObject(locationManager)
  }

  // MARK: - Computed Properties
  /// The width of the widget based on its grid size and cell configuration.
  /// - Returns: A `CGFloat` representing the widget's width in points.
  private var cellWidth: CGFloat {
    CGFloat(widget.size.gridSize.width) * widgetManager.gridConfig.cellSize
  }

  /// The height of the widget based on its grid size and cell configuration.
  /// - Returns: A `CGFloat` representing the widget's height in points.
  private var cellHeight: CGFloat {
    CGFloat(widget.size.gridSize.height) * widgetManager.gridConfig.cellSize
  }

  // MARK: - Gestures

  /// The drag gesture for moving the widget, with minimum distance and global coordinate space.
  /// - Returns: A `DragGesture` configured for widget dragging with change and end handlers.
  private var dragGesture: some Gesture {
    DragGesture(minimumDistance: 10, coordinateSpace: .global)
      .onChanged { value in
        handleDragChanged(value)
      }
      .onEnded { _ in
        handleDragEnded()
      }
  }

  // MARK: - Drag Handling

  /// Handles changes during a drag gesture, updating state, page switching, and grid snapping.
  /// - Parameter value: The `DragGesture.Value` containing location and translation data.
  private func handleDragChanged(_ value: DragGesture.Value) {
    if !isDragging {
      startDragging()
    }

    updateDragState(location: value.location, translation: value.translation)
    handlePageSwitching(location: value.location)
    snapToGrid(location: value.location)
  }

  /// Initiates the dragging state, setting the dragged widget and triggering haptic feedback.
  private func startDragging() {
    isDragging = true
    draggedWidget = widget
    UINotificationFeedbackGenerator().notificationOccurred(.warning)
  }

  /// Updates the drag location and preview offset during dragging.
  /// - Parameter location: The `CGPoint` of the current drag location.
  /// - Parameter translation: The `CGSize` of the drag translation.
  private func updateDragState(location: CGPoint, translation: CGSize) {
    dragLocation = location
    previewOffset = translation
  }

  /// Manages page switching when dragging near screen edges, with a minimum interval between switches.
  /// - Parameter location: The `CGPoint` of the current drag location.
  /// Checks if the drag is near the left or right edge and schedules a page switch if the minimum interval has passed.
  /// Continuous holding near the edge triggers subsequent switches after the interval.
  private func handlePageSwitching(location: CGPoint) {
    let screenWidth = UIScreen.main.bounds.width
    let edgeThreshold = screenWidth * 0.1
    let isNearLeftEdge = location.x < edgeThreshold && selectedPage > 0
    let isNearRightEdge = location.x > screenWidth - edgeThreshold && selectedPage < widgetManager.pageCount - 1

    guard isNearLeftEdge || isNearRightEdge else {
      cancelPageSwitch()
      return
    }

    let targetPage = isNearLeftEdge ? selectedPage - 1 : selectedPage + 1
    schedulePageSwitch(to: targetPage)
  }

  /// Schedules a page switch with a delay and animation, enforcing a minimum interval between switches.
  /// - Parameter targetPage: The `Int` index of the target page.
  /// If a switch occurred recently, delays the next switch until the interval (1 second) is met.
  /// Subsequent switches are scheduled if the user continues holding near the edge.
  private func schedulePageSwitch(to targetPage: Int) {
    guard pageSwitchTimer == nil else { return }

    let now = Date()
    // Calculate additional delay if last switch was recent
    let lastSwitchInterval = lastSwitchTime != nil ? now.timeIntervalSince(lastSwitchTime!) : minimumInterval
    let additionalDelay = max(0, minimumInterval - lastSwitchInterval)

    let timer = DispatchWorkItem {
      selectedPage = targetPage
      lastPageSwitched = targetPage
      lastSwitchTime = Date()
      pageSwitchTimer = nil
    }
    pageSwitchTimer = timer
    DispatchQueue.main.asyncAfter(deadline: .now() + animationDelay + additionalDelay, execute: timer)
  }

  /// Cancels any pending page switch operation.
  private func cancelPageSwitch() {
    pageSwitchTimer?.cancel()
    pageSwitchTimer = nil
  }

  /// Snaps the widget to the nearest valid grid position based on drag location.
  /// - Parameter location: The `CGPoint` of the current drag location.
  private func snapToGrid(location: CGPoint) {
    let newPage = selectedPage
    let localX = location.x
    let localY = location.y - safeAreaInsets.top
    let cellSize = widgetManager.gridConfig.cellSize

    let newColumn = Int(localX / cellSize)
    let newRow = Int(localY / cellSize)

    let adjustedColumn = max(0, min(newColumn, widgetManager.gridConfig.columns - widget.size.gridSize.width))
    let adjustedRow = max(0, min(newRow, widgetManager.gridConfig.rows - widget.size.gridSize.height))
    let adjustedPosition = GridPosition(row: adjustedRow, column: adjustedColumn, page: newPage)

    updateDraggedWidget(position: adjustedPosition)
    provideSnapFeedback(for: adjustedPosition)
  }

  /// Updates the dragged widget's position during dragging.
  /// - Parameter position: The `GridPosition` to assign to the dragged widget.
  private func updateDraggedWidget(position: GridPosition) {
    draggedWidget = WidgetComponent(
      id: widget.id,
      type: widget.type,
      size: widget.size,
      position: position,
      theme: widget.theme
    )
  }

  /// Provides haptic feedback when snapping to a valid grid position.
  /// - Parameter position: The `GridPosition` to check for snapping.
  private func provideSnapFeedback(for position: GridPosition) {
    guard widgetManager.isPositionAvailable(for: widget.size, at: position, excluding: widget.id),
          position != lastSnappedPosition else { return }

    UIImpactFeedbackGenerator(style: .light).impactOccurred()
    lastSnappedPosition = position
  }

  /// Finalizes the drag operation, updating the widget's position and resetting state.
  private func handleDragEnded() {
    withAnimation(.spring()) {
      isDragging = false
      if let dragged = draggedWidget {
        widgetManager.moveWidget(id: widget.id, to: dragged.position)
      }
      resetDragState()
    }
  }

  /// Resets all drag-related state properties to their initial values.
  private func resetDragState() {
    draggedWidget = nil
    dragLocation = nil
    previewOffset = .zero
    lastSnappedPosition = nil
    lastPageSwitched = nil
    cancelPageSwitch()
  }
}
