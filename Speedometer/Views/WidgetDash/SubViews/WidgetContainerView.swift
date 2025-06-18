//
//  WidgetContainerView.swift
//  Speedometer
//
//  Created by John Durcan on 18/06/2025.
//
import SwiftUI

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
