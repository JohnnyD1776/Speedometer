//
//  GridView.swift
//  Speedometer
//
//  Created by John Durcan on 18/06/2025.
//
import SwiftUI

/// Present a page of Widgets
struct GridView: View {
  @Environment(\.theme) private var theme
  @Environment(\.safeAreaInsets) private var safeAreaInsets
  @EnvironmentObject private var widgetManager: WidgetOrganizer
  @EnvironmentObject private var dataManager: DataManager
  @EnvironmentObject private var locationManager: LocationManager
  @Binding var draggedWidget: WidgetComponent?
  @Binding var dragLocation: CGPoint?
  @Binding var selectedPage: Int
  let page: Int

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        gridBackgroundView
        draggedWidgetView
        widgetsDisplayView(geometry: geometry)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .padding(.top, safeAreaInsets.top)
      .applyStyle(.container(.background))
    }
  }

  /// Display the interactable widgets for the current GridViewPage
  /// Hides the widget being dragged
  /// Has the Drag interaction and the context menu
  func widgetsDisplayView(geometry: GeometryProxy) -> some View {
    ForEach(widgetManager.widgets.filter { $0.position.page == page }) { widget in
      WidgetContainerView(
        draggedWidget: $draggedWidget,
        selectedPage: $selectedPage,
        dragLocation: $dragLocation,
        widget: widget,
        geometry: geometry
      )
      .position(
        x: CGFloat(widget.position.column) * widgetManager.gridConfig.cellSize + Double(widget.size.gridSize.width) * widgetManager.gridConfig.cellSize / 2,
        y: CGFloat(widget.position.row) * widgetManager.gridConfig.cellSize + Double(widget.size.gridSize.height) * widgetManager.gridConfig.cellSize / 2
      )
      .zIndex(draggedWidget?.id == widget.id ? 1 : 0)
      .environment(\.theme, widget.theme?.theme ?? theme)
      .environmentObject(widgetManager)
      .environmentObject(dataManager)
      .environmentObject(locationManager)
    }
  }

  /// Display the themed GridBackground
  var gridBackgroundView: some View {
    GridBackgroundView(config: widgetManager.gridConfig)
      .environment(\.theme, theme)
  }

  /// Display the widget in the position that is possible to place the widget
  /// Check isPositionAvailable
  var draggedWidgetView: some View {
    Group {
      if let dragged = draggedWidget, let _ = dragLocation, // Only show if actively dragging
         dragged.position.page == page,
         widgetManager.isPositionAvailable(for: dragged.size, at: dragged.position, excluding: dragged.id) {
        WidgetView(widget: dragged, isDragging: true)
          .frame(
            width: CGFloat(dragged.size.gridSize.width) * widgetManager.gridConfig.cellSize,
            height: CGFloat(dragged.size.gridSize.height) * widgetManager.gridConfig.cellSize
          )
          .opacity(0.5)
          .cornerRadius(theme.widgetCornerRadius)
          .position(
            x: CGFloat(dragged.position.column) * widgetManager.gridConfig.cellSize + Double(dragged.size.gridSize.width) * widgetManager.gridConfig.cellSize / 2,
            y: CGFloat(dragged.position.row) * widgetManager.gridConfig.cellSize + Double(dragged.size.gridSize.height) * widgetManager.gridConfig.cellSize / 2
          )
          .environment(\.theme, dragged.theme?.theme ?? theme)
          .environmentObject(widgetManager)
          .environmentObject(dataManager)
          .environmentObject(locationManager)
      }
    }
  }
}
