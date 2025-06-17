//
//  TestWidgetViews.swift
//  Speedometer
//
//  Created by John Durcan on 17/06/2025.
//
import SwiftUI
import CoreMotion
import UIKit

// Model for a widget component
struct WidgetComponent: Identifiable, Codable {
  let id: UUID
  var type: WidgetType
  var size: WidgetSize
  var style: WidgetStyle
  var position: GridPosition
}

struct GridPosition: Codable, Equatable {
  var row: Int
  var column: Int
  var page: Int

  static func == (lhs: GridPosition, rhs: GridPosition) -> Bool {
    lhs.row == rhs.row && lhs.column == rhs.column && lhs.page == rhs.page
  }
}

enum WidgetType: String, Codable, CaseIterable {
  case speedDial
  case gMeter

  var supportedSizes: [WidgetSize] {
    switch self {
    case .speedDial: return [.small, .mediumHorizontal, .large]
    case .gMeter: return [.small, .mediumVertical, .large, .extraLarge]
    }
  }
}

enum WidgetSize: String, Codable, CaseIterable {
  case small
  case mediumHorizontal
  case mediumVertical
  case large
  case extraLarge

  var gridSize: (width: Int, height: Int) {
    switch self {
    case .small: return (1, 1)
    case .mediumHorizontal: return (2, 1)
    case .mediumVertical: return (1, 2)
    case .large: return (2, 2)
    case .extraLarge: return (3, 2)
    }
  }
}

enum WidgetStyle: String, Codable, CaseIterable {
  case leather
  case carbonFiber
  case metallic
}

// Device-specific grid configuration
struct GridConfig {
  let columns: Int
  let rows: Int
  let cellSize: CGFloat

  static func forDevice() -> GridConfig {
    let screenSize = UIScreen.main.bounds.size
    let isIPad = UIDevice.current.userInterfaceIdiom == .pad
    let columns = isIPad ? 6 : 4
    let rows = isIPad ? 12 : 8
    let padding: CGFloat = 16
    let cellSize = (screenSize.width - padding * CGFloat(columns + 1)) / CGFloat(columns)
    return GridConfig(columns: columns, rows: rows, cellSize: cellSize)
  }
}

// Toast model for user feedback
struct Toast: Identifiable {
  let id = UUID()
  let message: String
  let duration: Double = 2.0
}

// View model to manage widget components
class WidgetOrganizerViewModel: ObservableObject {
  @Published var widgets: [WidgetComponent] = []
  @Published var isMounted: Bool = true
  @Published var toast: Toast?
  let gridConfig: GridConfig
  let maxPages = 6 // 1 initial + 5 extra pages

  init() {
    gridConfig = GridConfig.forDevice()
    loadWidgets()
    startMountDetection()
  }

  var pageCount: Int {
    let highestPage = widgets.map { $0.position.page }.max() ?? 0
    // Add one empty page if the last page has widgets
    return widgets.contains(where: { $0.position.page == highestPage }) ? highestPage + 2 : highestPage + 1
  }

  func addWidget(type: WidgetType, style: WidgetStyle = .leather, size: WidgetSize? = nil) {
    let targetSize = size ?? type.supportedSizes.first ?? .small
    guard type.supportedSizes.contains(targetSize) else { return }

    if let position = findAvailablePosition(for: targetSize) {
      let newWidget = WidgetComponent(
        id: UUID(),
        type: type,
        size: targetSize,
        style: style,
        position: position
      )
      widgets.append(newWidget)
      saveWidgets()
      UINotificationFeedbackGenerator().notificationOccurred(.success)
    } else {
      toast = Toast(message: "No space available for this widget")
    }
  }

  func removeWidget(id: UUID) {
    widgets.removeAll { $0.id == id }
    saveWidgets()
    UINotificationFeedbackGenerator().notificationOccurred(.success)
  }

  func updateWidgetSize(id: UUID, size: WidgetSize) {
    guard let index = widgets.firstIndex(where: { $0.id == id }),
          widgets[index].type.supportedSizes.contains(size) else { return }

    let currentPosition = widgets[index].position
    if isPositionAvailable(for: size, at: currentPosition, excluding: id) {
      widgets[index].size = size
      saveWidgets()
      UINotificationFeedbackGenerator().notificationOccurred(.success)
    } else if let newPosition = findAvailablePosition(for: size, preferringPage: currentPosition.page) {
      widgets[index].size = size
      widgets[index].position = newPosition
      saveWidgets()
      UINotificationFeedbackGenerator().notificationOccurred(.success)
    } else {
      toast = Toast(message: "No space for \(size.rawValue) size")
    }
  }

  func moveWidget(id: UUID, to position: GridPosition) {
    guard let index = widgets.firstIndex(where: { $0.id == id }) else { return }
    let size = widgets[index].size
    let adjustedPosition = GridPosition(
      row: max(0, min(position.row, gridConfig.rows - size.gridSize.height)),
      column: max(0, min(position.column, gridConfig.columns - size.gridSize.width)),
      page: max(0, min(position.page, maxPages - 1))
    )

    if isPositionAvailable(for: size, at: adjustedPosition, excluding: id) {
      widgets[index].position = adjustedPosition
      saveWidgets()
      UINotificationFeedbackGenerator().notificationOccurred(.success)
    } else if let newPosition = findNearestValidPosition(for: size, near: adjustedPosition, excluding: id) {
      widgets[index].position = newPosition
      saveWidgets()
      UINotificationFeedbackGenerator().notificationOccurred(.success)
    } else {
      toast = Toast(message: "No space at this position")
    }
  }

  private func findAvailablePosition(for size: WidgetSize, preferringPage: Int? = nil) -> GridPosition? {
    let (width, height) = size.gridSize
    let pages = preferringPage != nil ? [min(preferringPage!, maxPages - 1)] + Array(0..<maxPages).filter { $0 != preferringPage } : Array(0..<maxPages)

    for page in pages {
      for row in 0...(gridConfig.rows - height) {
        for column in 0...(gridConfig.columns - width) {
          let position = GridPosition(row: row, column: column, page: page)
          if isPositionAvailable(for: size, at: position) {
            return position
          }
        }
      }
    }
    return nil
  }

  private func findNearestValidPosition(for size: WidgetSize, near position: GridPosition, excluding excludeID: UUID?) -> GridPosition? {
    let (width, height) = size.gridSize
    let page = min(max(0, position.page), maxPages - 1)
    let centerRow = position.row
    let centerColumn = position.column
    let maxDistance = max(gridConfig.rows, gridConfig.columns) / 2

    for distance in 0...maxDistance {
      for row in max(0, centerRow - distance)...min(gridConfig.rows - height, centerRow + distance) {
        for column in max(0, centerColumn - distance)...min(gridConfig.columns - width, centerColumn + distance) {
          let testPosition = GridPosition(row: row, column: column, page: page)
          if isPositionAvailable(for: size, at: testPosition, excluding: excludeID) {
            return testPosition
          }
        }
      }
    }
    return findAvailablePosition(for: size, preferringPage: page)
  }

  func isPositionAvailable(for size: WidgetSize, at position: GridPosition, excluding excludeID: UUID? = nil) -> Bool {
    let (width, height) = size.gridSize
    guard position.row + height <= gridConfig.rows,
          position.column + width <= gridConfig.columns,
          position.page < maxPages else { return false }

    for widget in widgets where widget.id != excludeID {
      let wPos = widget.position
      let wSize = widget.size.gridSize
      if wPos.page == position.page {
        let widgetRect = CGRect(
          x: CGFloat(wPos.column),
          y: CGFloat(wPos.row),
          width: CGFloat(wSize.width),
          height: CGFloat(wSize.height)
        )
        let newRect = CGRect(
          x: CGFloat(position.column),
          y: CGFloat(position.row),
          width: CGFloat(width),
          height: CGFloat(height)
        )
        if widgetRect.intersects(newRect) {
          return false
        }
      }
    }
    return true
  }

  private func saveWidgets() {
    if let encoded = try? JSONEncoder().encode(widgets) {
      UserDefaults(suiteName: "group.com.yourapp.speedometer")?.set(encoded, forKey: "widgets")
    }
  }

  private func loadWidgets() {
    if let data = UserDefaults(suiteName: "group.com.yourapp.speedometer")?.data(forKey: "widgets"),
       let decoded = try? JSONDecoder().decode([WidgetComponent].self, from: data) {
      widgets = decoded
    }
  }

  private func startMountDetection() {
    let motionManager = CMMotionManager()
    if motionManager.isDeviceMotionAvailable {
      motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
        guard let motion = motion, error == nil else { return }
        self?.isMounted = abs(motion.attitude.pitch) < 0.2
      }
    }
  }
}

// Main organizer view
struct WidgetOrganizerView: View {
  @StateObject private var viewModel = WidgetOrganizerViewModel()
  @State private var isAddingWidget = false
  @State private var selectedWidgetType: WidgetType = .speedDial
  @State private var selectedStyle: WidgetStyle = .leather
  @State private var draggedWidget: WidgetComponent?
  @State private var selectedPage: Int = 0

  var body: some View {
    NavigationView {
      ZStack {
        Color(.systemBackground).ignoresSafeArea()

        TabView(selection: $selectedPage) {
          ForEach(0..<viewModel.pageCount, id: \.self) { page in
            GridView(page: page, viewModel: viewModel, draggedWidget: $draggedWidget, selectedPage: $selectedPage)
              .frame(maxWidth: .infinity, maxHeight: .infinity)
              .tag(page)
          }
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .animation(.easeInOut, value: selectedPage)

        if !viewModel.isMounted {
          Text("Please mount your device for safety")
            .foregroundColor(.white)
            .padding()
            .background(Color.red.opacity(0.8))
            .cornerRadius(10)
            .shadow(radius: 5)
            .accessibilityLabel("Safety warning: Please mount your device")
        }

        if let toast = viewModel.toast {
          ToastView(message: toast.message)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .onAppear {
              DispatchQueue.main.asyncAfter(deadline: .now() + toast.duration) {
                viewModel.toast = nil
              }
            }
        }
      }
      .navigationTitle("Speedometer Dashboard")
      .toolbar {
        Button(action: { isAddingWidget = true }) {
          Image(systemName: "plus")
        }
        .accessibilityLabel("Add Widget")
      }
      .sheet(isPresented: $isAddingWidget) {
        AddWidgetView(viewModel: viewModel, isPresented: $isAddingWidget)
      }
    }
    .onAppear {
      UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
  }
}

// Toast view
struct ToastView: View {
  let message: String

  var body: some View {
    Text(message)
      .foregroundColor(.white)
      .padding()
      .background(Color.black.opacity(0.8))
      .cornerRadius(10)
      .shadow(radius: 5)
      .padding(.bottom, 50)
      .accessibilityLabel("Notification: \(message)")
  }
}

// Grid view for a single page
struct GridView: View {
  let page: Int
  @ObservedObject var viewModel: WidgetOrganizerViewModel
  @Binding var draggedWidget: WidgetComponent?
  @Binding var selectedPage: Int

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        GridBackgroundView(config: viewModel.gridConfig)

        // Highlight valid drop zone
        if let dragged = draggedWidget, dragged.position.page == page,
           viewModel.isPositionAvailable(for: dragged.size, at: dragged.position, excluding: dragged.id) {
          WidgetView(widget: dragged, viewModel: viewModel, isDragging: true)
            .frame(
              width: CGFloat(dragged.size.gridSize.width) * viewModel.gridConfig.cellSize,
              height: CGFloat(dragged.size.gridSize.height) * viewModel.gridConfig.cellSize
            )
            .opacity(0.5)
            .cornerRadius(16)
            .position(
              x: CGFloat(dragged.position.column) * viewModel.gridConfig.cellSize + Double(dragged.size.gridSize.width) * viewModel.gridConfig.cellSize / 2 + 16,
              y: CGFloat(dragged.position.row) * viewModel.gridConfig.cellSize + Double(dragged.size.gridSize.height) * viewModel.gridConfig.cellSize / 2 + 16
            )
        }

        ForEach(viewModel.widgets.filter { $0.position.page == page }) { widget in
          WidgetContainerView(widget: widget, viewModel: viewModel, geometry: geometry, draggedWidget: $draggedWidget, selectedPage: $selectedPage)
            .position(
              x: CGFloat(widget.position.column) * viewModel.gridConfig.cellSize + Double(widget.size.gridSize.width) * viewModel.gridConfig.cellSize / 2 + 16,
              y: CGFloat(widget.position.row) * viewModel.gridConfig.cellSize + Double(widget.size.gridSize.height) * viewModel.gridConfig.cellSize / 2 + 16
            )
            .zIndex(draggedWidget?.id == widget.id ? 1 : 0)
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .padding(16)
    }
  }
}

// Widget container view (handles dragging)
struct WidgetContainerView: View {
  let widget: WidgetComponent
  @ObservedObject var viewModel: WidgetOrganizerViewModel
  let geometry: GeometryProxy
  @Binding var draggedWidget: WidgetComponent?
  @Binding var selectedPage: Int
  @State private var isDragging = false
  @State private var previewOffset: CGSize = .zero
  @State private var lastSnappedPosition: GridPosition?
  @State private var lastPageSwitched: Int?

  var body: some View {
    WidgetView(widget: widget, viewModel: viewModel, isDragging: isDragging)
      .draggable(widget.id.uuidString) {
        WidgetView(widget: widget, viewModel: viewModel, isDragging: true)
          .frame(
            width: CGFloat(widget.size.gridSize.width) * viewModel.gridConfig.cellSize,
            height: CGFloat(widget.size.gridSize.height) * viewModel.gridConfig.cellSize
          )
          .opacity(0.5)
      }
      .onDrop(of: [.text], delegate: WidgetDropDelegate(
        widget: widget,
        viewModel: viewModel,
        geometry: geometry,
        draggedWidget: $draggedWidget
      ))
      .gesture(
        DragGesture(minimumDistance: 10, coordinateSpace: .global)
          .onChanged { value in
            if !isDragging {
              isDragging = true
              draggedWidget = widget
              UINotificationFeedbackGenerator().notificationOccurred(.warning)
            }
            // Follow finger for visual preview
            previewOffset = CGSize(
              width: value.translation.width,
              height: value.translation.height
            )
            // Calculate widget's center for grid snapping
            let cellSize = viewModel.gridConfig.cellSize
            let padding: CGFloat = 16
            let originalCenterX = (CGFloat(widget.position.column) + CGFloat(widget.size.gridSize.width) / 2) * cellSize + padding
            let originalCenterY = (CGFloat(widget.position.row) + CGFloat(widget.size.gridSize.height) / 2) * cellSize + padding
            let newCenterX = originalCenterX + value.translation.width
            let newCenterY = originalCenterY + value.translation.height
            let newColumn = Int((newCenterX - padding - cellSize / 2) / cellSize)
            let newRow = Int((newCenterY - padding - cellSize / 2) / cellSize)

            // Detect edge for page swipe
            let edgeThreshold: CGFloat = 50
            let screenWidth = UIScreen.main.bounds.width
            var newPage = selectedPage
            if value.location.x < edgeThreshold && selectedPage > 0 {
              if lastPageSwitched != selectedPage - 1 {
                newPage = selectedPage - 1
                selectedPage = newPage
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                lastPageSwitched = newPage
              }
            } else if value.location.x > screenWidth - edgeThreshold && selectedPage < viewModel.pageCount - 1 {
              if lastPageSwitched != selectedPage + 1 {
                newPage = selectedPage + 1
                selectedPage = newPage
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                lastPageSwitched = newPage
              }
            } else {
              lastPageSwitched = nil
            }

            let adjustedPosition = GridPosition(
              row: max(0, min(newRow, viewModel.gridConfig.rows - widget.size.gridSize.height)),
              column: max(0, min(newColumn, viewModel.gridConfig.columns - widget.size.gridSize.width)),
              page: newPage
            )
            draggedWidget = WidgetComponent(
              id: widget.id,
              type: widget.type,
              size: widget.size,
              style: widget.style,
              position: adjustedPosition
            )
            // Haptic feedback for grid snapping
            if viewModel.isPositionAvailable(for: widget.size, at: adjustedPosition, excluding: widget.id),
               adjustedPosition != lastSnappedPosition {
              UIImpactFeedbackGenerator(style: .light).impactOccurred()
              lastSnappedPosition = adjustedPosition
            }
          }
          .onEnded { _ in
            isDragging = false
            if let dragged = draggedWidget {
              viewModel.moveWidget(id: widget.id, to: dragged.position)
            }
            draggedWidget = nil
            previewOffset = .zero
            lastSnappedPosition = nil
            lastPageSwitched = nil
          }
      )
      .offset(isDragging ? previewOffset : .zero)
      .animation(.spring(), value: previewOffset)
  }
}

// Widget view (handles content and context menu)
struct WidgetView: View {
  let widget: WidgetComponent
  @ObservedObject var viewModel: WidgetOrganizerViewModel
  let isDragging: Bool

  var body: some View {
    ZStack {
      switch widget.style {
      case .leather: Color.brown.opacity(0.8)
      case .carbonFiber: Color.gray.opacity(0.9)
      case .metallic: Color.gray.opacity(0.7)
      }

      switch widget.type {
      case .speedDial:
        SpeedDialView(speed: 65)
      case .gMeter:
        GMeterView(gForce: 0.8)
      }
    }
    .frame(
      width: CGFloat(widget.size.gridSize.width) * viewModel.gridConfig.cellSize,
      height: CGFloat(widget.size.gridSize.height) * viewModel.gridConfig.cellSize
    )
    .cornerRadius(16)
    .shadow(radius: isDragging ? 10 : 5)
    .overlay(
      RoundedRectangle(cornerRadius: 16)
        .stroke(viewModel.isMounted ? Color.clear : Color.red, lineWidth: 2)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 16)
        .stroke(isDragging && viewModel.isPositionAvailable(for: widget.size, at: widget.position, excluding: widget.id) ? Color.green : Color.clear, lineWidth: 2)
    )
    .scaleEffect(isDragging ? 1.1 : 1.0)
    .animation(.spring(), value: isDragging)
    .contextMenu {
      ForEach(widget.type.supportedSizes, id: \.self) { size in
        Button(size.rawValue.capitalized) {
          viewModel.updateWidgetSize(id: widget.id, size: size)
        }
      }
      Divider()
      Button("Remove", role: .destructive) {
        viewModel.removeWidget(id: widget.id)
      }
    }
    .disabled(isDragging)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(widget.type.rawValue) widget, \(widget.size.rawValue) size")
    .accessibilityAddTraits(isDragging ? .isButton : [])
    .accessibilityHint("Long-press and drag to reposition, or long-press for options")
  }
}

// Grid background
struct GridBackgroundView: View {
  let config: GridConfig

  var body: some View {
    GeometryReader { geometry in
      Path { path in
        for col in 0...config.columns {
          let x = CGFloat(col) * config.cellSize
          path.move(to: CGPoint(x: x, y: 0))
          path.addLine(to: CGPoint(x: x, y: geometry.size.height))
        }
        for row in 0...config.rows {
          let y = CGFloat(row) * config.cellSize
          path.move(to: CGPoint(x: 0, y: y))
          path.addLine(to: CGPoint(x: geometry.size.width, y: y))
        }
      }
      .stroke(Color.gray.opacity(0.2), lineWidth: 1)
    }
  }
}

// Speed dial component
struct SpeedDialView: View {
  let speed: Double

  var body: some View {
    VStack {
      Text("\(Int(speed)) mph")
        .font(.system(size: 24, weight: .bold))
        .foregroundColor(.white)
      Text("Speed")
        .font(.caption)
        .foregroundColor(.white.opacity(0.8))
    }
  }
}

// G-meter component
struct GMeterView: View {
  let gForce: Double

  var body: some View {
    VStack {
      Gauge(value: gForce, in: 0...2) {
        Text("G-Force")
      } currentValueLabel: {
        Text("\(gForce, specifier: "%.1f") G")
      }
      .gaugeStyle(.accessoryCircular)
      .tint(.white)
    }
    .padding()
  }
}

// Add widget sheet
struct AddWidgetView: View {
  @ObservedObject var viewModel: WidgetOrganizerViewModel
  @Binding var isPresented: Bool
  @State private var selectedType: WidgetType = .speedDial
  @State private var selectedStyle: WidgetStyle = .leather
  @State private var selectedSize: WidgetSize = .small

  var body: some View {
    NavigationView {
      Form {
        Picker("Widget Type", selection: $selectedType) {
          ForEach(WidgetType.allCases, id: \.self) { type in
            Text(type.rawValue.capitalized).tag(type)
          }
        }
        Picker("Style", selection: $selectedStyle) {
          ForEach(WidgetStyle.allCases, id: \.self) { style in
            Text(style.rawValue.capitalized).tag(style)
          }
        }
        Picker("Size", selection: $selectedSize) {
          ForEach(selectedType.supportedSizes, id: \.self) { size in
            Text(size.rawValue.capitalized).tag(size)
          }
        }
      }
      .navigationTitle("Add Widget")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { isPresented = false }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Add") {
            viewModel.addWidget(type: selectedType, style: selectedStyle, size: selectedSize)
            isPresented = false
          }
        }
      }
    }
  }
}

// Drag-and-drop delegate
struct WidgetDropDelegate: DropDelegate {
  let widget: WidgetComponent
  let viewModel: WidgetOrganizerViewModel
  let geometry: GeometryProxy
  @Binding var draggedWidget: WidgetComponent?

  func performDrop(info: DropInfo) -> Bool {
    guard let item = info.itemProviders(for: [.text]).first,
          item.canLoadObject(ofClass: NSString.self) else { return false }

    item.loadObject(ofClass: NSString.self) { (string, _) in
      if let draggedID = UUID(uuidString: String(describing: string)),
         let draggedWidget = viewModel.widgets.first(where: { $0.id == draggedID }) {
        let dropLocation = info.location
        let cellSize = viewModel.gridConfig.cellSize
        let padding: CGFloat = 16
        let originalCenterX = (CGFloat(draggedWidget.position.column) + CGFloat(draggedWidget.size.gridSize.width) / 2) * cellSize + padding
        let originalCenterY = (CGFloat(draggedWidget.position.row) + CGFloat(draggedWidget.size.gridSize.height) / 2) * cellSize + padding
        let translationX = dropLocation.x - geometry.frame(in: .global).minX - originalCenterX
        let translationY = dropLocation.y - geometry.frame(in: .global).minY - originalCenterY
        let newCenterX = originalCenterX + translationX
        let newCenterY = originalCenterY + translationY
        let newColumn = Int((newCenterX - padding - cellSize / 2) / cellSize)
        let newRow = Int((newCenterY - padding - cellSize / 2) / cellSize)

        let newPosition = GridPosition(
          row: newRow,
          column: newColumn,
          page: draggedWidget.position.page // Use draggedWidget's page, set during drag
        )

        DispatchQueue.main.async {
          self.viewModel.moveWidget(id: draggedID, to: newPosition)
          self.draggedWidget = nil
        }
      }
    }
    return true
  }

  func dropUpdated(info: DropInfo) -> DropProposal? {
    if let dragged = draggedWidget {
      let dropLocation = info.location
      let cellSize = viewModel.gridConfig.cellSize
      let padding: CGFloat = 16
      let originalCenterX = (CGFloat(dragged.position.column) + CGFloat(dragged.size.gridSize.width) / 2) * cellSize + padding
      let originalCenterY = (CGFloat(dragged.position.row) + CGFloat(dragged.size.gridSize.height) / 2) * cellSize + padding
      let translationX = dropLocation.x - geometry.frame(in: .global).minX - originalCenterX
      let translationY = dropLocation.y - geometry.frame(in: .global).minY - originalCenterY
      let newCenterX = originalCenterX + translationX
      let newCenterY = originalCenterY + translationY
      let newColumn = Int((newCenterX - padding - cellSize / 2) / cellSize)
      let newRow = Int((newCenterY - padding - cellSize / 2) / cellSize)
      let adjustedPosition = GridPosition(
        row: max(0, min(newRow, viewModel.gridConfig.rows - dragged.size.gridSize.height)),
        column: max(0, min(newColumn, viewModel.gridConfig.columns - dragged.size.gridSize.width)),
        page: dragged.position.page
      )
      self.draggedWidget = WidgetComponent(
        id: dragged.id,
        type: dragged.type,
        size: dragged.size,
        style: dragged.style,
        position: adjustedPosition
      )
    }
    return DropProposal(operation: .move)
  }
}

struct WidgetOrganizerView_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      WidgetOrganizerView()
        .previewDevice("iPhone 14")
        .previewDisplayName("iPhone 14")
      WidgetOrganizerView()
        .previewDevice("iPad Pro (12.9-inch) (6th generation)")
        .previewDisplayName("iPad Pro")
    }
  }
}
