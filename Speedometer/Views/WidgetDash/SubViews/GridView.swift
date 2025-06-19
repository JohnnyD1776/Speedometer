//
//  GridView.swift
//  Speedometer
//
//  Created by John Durcan on 18/06/2025.
//
import SwiftUI

struct GridView: View {
  @Environment(\.theme) private var theme
  @Environment(\.safeAreaInsets) private var safeAreaInsets

  @EnvironmentObject private var widgetManager: WidgetOrganizer
  @EnvironmentObject private var dataManager: DataManager
  @EnvironmentObject private var locationManager: LocationManager
  @State private var draggedWidget: WidgetComponent?
  @Binding var selectedPage: Int
  let page: Int

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        GridBackgroundView(config: widgetManager.gridConfig)
          .environment(\.theme, theme)
        if let dragged = draggedWidget, dragged.position.page == page,
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

        ForEach(widgetManager.widgets.filter { $0.position.page == page }) { widget in
          WidgetContainerView(
            draggedWidget: $draggedWidget,
            selectedPage: $selectedPage,
            widget: widget,
            geometry: geometry
          )
          .position(
            x: CGFloat(widget.position.column) * widgetManager.gridConfig.cellSize + Double(widget.size.gridSize.width) * widgetManager.gridConfig.cellSize / 2 ,
            y: CGFloat(widget.position.row) * widgetManager.gridConfig.cellSize + Double(widget.size.gridSize.height) * widgetManager.gridConfig.cellSize / 2
          )
          .zIndex(draggedWidget?.id == widget.id ? 1 : 0)
          .environment(\.theme, widget.theme?.theme ?? theme)
          .environmentObject(widgetManager)
          .environmentObject(dataManager)
          .environmentObject(locationManager)
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .padding(.top, safeAreaInsets.top)
      .applyStyle(.container(.background))
    }
  }
}
