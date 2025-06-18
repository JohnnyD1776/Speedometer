//
//  WidgetDropDelegate.swift
//  Speedometer
//
//  Created by John Durcan on 18/06/2025.
//
import SwiftUI

// Drag-and-drop delegate
struct WidgetDropDelegate: DropDelegate {
  let widget: WidgetComponent
  let widgetManager: WidgetOrganizer
  let geometry: GeometryProxy
  @Binding var draggedWidget: WidgetComponent?

  func performDrop(info: DropInfo) -> Bool {
    guard let item = info.itemProviders(for: [.text]).first,
          item.canLoadObject(ofClass: NSString.self) else { return false }

    item.loadObject(ofClass: NSString.self) { (string, _) in
      if let draggedID = UUID(uuidString: String(describing: string)),
         let draggedWidget = widgetManager.widgets.first(where: { $0.id == draggedID }) {
        let dropLocation = info.location
        let cellSize = widgetManager.gridConfig.cellSize
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
          self.widgetManager.moveWidget(id: draggedID, to: newPosition)
          self.draggedWidget = nil
        }
      }
    }
    return true
  }

  func dropUpdated(info: DropInfo) -> DropProposal? {
    if let dragged = draggedWidget {
      let dropLocation = info.location
      let cellSize = widgetManager.gridConfig.cellSize
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
        row: max(0, min(newRow, widgetManager.gridConfig.rows - dragged.size.gridSize.height)),
        column: max(0, min(newColumn, widgetManager.gridConfig.columns - dragged.size.gridSize.width)),
        page: dragged.position.page
      )
      self.draggedWidget = WidgetComponent(
        id: dragged.id,
        type: dragged.type,
        size: dragged.size,
        position: adjustedPosition,
        theme: dragged.theme
      )
    }
    return DropProposal(operation: .move)
  }
}
