//
//  WidgetContainerView.swift
//  Speedometer
//
//  Created by John Durcan on 18/06/2025.
//
import SwiftUI

struct WidgetContainerView: View {
  @Environment(\.theme) private var theme
  @EnvironmentObject private var widgetManager: WidgetOrganizer
  @EnvironmentObject private var dataManager: DataManager
  @EnvironmentObject private var locationManager: LocationManager
  @Binding var draggedWidget: WidgetComponent?
  @Binding var selectedPage: Int
  @State private var isDragging = false
  @State private var previewOffset: CGSize = .zero
  @State private var lastSnappedPosition: GridPosition?
  @State private var lastPageSwitched: Int?
  let widget: WidgetComponent
  let geometry: GeometryProxy

  var body: some View {
    WidgetView(widget: widget, isDragging: isDragging)
      .draggable(widget.id.uuidString) {
        WidgetView(widget: widget, isDragging: true)
          .frame(
            width: CGFloat(widget.size.gridSize.width) * widgetManager.gridConfig.cellSize,
            height: CGFloat(widget.size.gridSize.height) * widgetManager.gridConfig.cellSize
          )
          .opacity(0.5)
          .environment(\.theme, widget.theme?.theme ?? theme)
      }
      .onDrop(of: [.text], delegate: WidgetDropDelegate(
        widget: widget,
        widgetManager: widgetManager,
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
            previewOffset = CGSize(
              width: value.translation.width,
              height: value.translation.height
            )
            let cellSize = widgetManager.gridConfig.cellSize
            let padding: CGFloat = 16
            let originalCenterX = (CGFloat(widget.position.column) + CGFloat(widget.size.gridSize.width) / 2) * cellSize + padding
            let originalCenterY = (CGFloat(widget.position.row) + CGFloat(widget.size.gridSize.height) / 2) * cellSize + padding
            let newCenterX = originalCenterX + value.translation.width
            let newCenterY = originalCenterY + value.translation.height
            let newColumn = Int((newCenterX - padding - cellSize / 2) / cellSize)
            let newRow = Int((newCenterY - padding - cellSize / 2) / cellSize)

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
            } else if value.location.x > screenWidth - edgeThreshold && selectedPage < widgetManager.pageCount - 1 {
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
              row: max(0, min(newRow, widgetManager.gridConfig.rows - widget.size.gridSize.height)),
              column: max(0, min(newColumn, widgetManager.gridConfig.columns - widget.size.gridSize.width)),
              page: newPage
            )
            draggedWidget = WidgetComponent(
              id: widget.id,
              type: widget.type,
              size: widget.size,
              position: adjustedPosition,
              theme: widget.theme
            )
            if widgetManager.isPositionAvailable(for: widget.size, at: adjustedPosition, excluding: widget.id),
               adjustedPosition != lastSnappedPosition {
              UIImpactFeedbackGenerator(style: .light).impactOccurred()
              lastSnappedPosition = adjustedPosition
            }
          }
          .onEnded { _ in
            isDragging = false
            if let dragged = draggedWidget {
              widgetManager.moveWidget(id: widget.id, to: dragged.position)
            }
            draggedWidget = nil
            previewOffset = .zero
            lastSnappedPosition = nil
            lastPageSwitched = nil
          }
      )
      .offset(isDragging ? previewOffset : .zero)
      .animation(.spring(), value: previewOffset)
      .environment(\.theme, widget.theme?.theme ?? theme)
      .environmentObject(widgetManager)
      .environmentObject(dataManager)
      .environmentObject(locationManager)
  }
}
