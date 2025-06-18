//
//  GridView.swift
//  Speedometer
//
//  Created by John Durcan on 18/06/2025.
//
import SwiftUI

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
