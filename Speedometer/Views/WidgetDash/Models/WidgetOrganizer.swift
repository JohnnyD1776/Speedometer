//
//  WidgetOrganizerViewModel.swift
//  Speedometer
//
//  Created by John Durcan on 18/06/2025.
//
import SwiftUI

// View model to manage widget components
class WidgetOrganizer: ObservableObject {
  @Published var widgets: [WidgetComponent] = []
  @Published var isMounted: Bool = true
  @Published var toast: Toast?
  @Published var gridConfig: GridConfig
  let maxPages = 5

  init() {
    gridConfig = GridConfig.forDevice(size: UIScreen.main.bounds.size)
    loadWidgets()
  }

  var pageCount: Int {
    let highestPage = widgets.map { $0.position.page }.max() ?? 0
    return widgets.contains(where: { $0.position.page == highestPage }) ? highestPage + 2 : highestPage + 1
  }

  func addWidget(type: WidgetType, size: WidgetSize? = nil, theme: WidgetTheme? = nil, currentPage: Int? = nil) {
    let targetSize = size ?? type.supportedSizes.first ?? .small
    guard type.supportedSizes.contains(targetSize) else { return }

    if let position = findAvailablePosition(for: targetSize, currentPage: currentPage) {
      let newWidget = WidgetComponent(
        id: UUID(),
        type: type,
        size: targetSize,
        position: position,
        theme: theme
      )
      widgets.append(newWidget)
      saveWidgets()
      UINotificationFeedbackGenerator().notificationOccurred(.success)
    } else {
      toast = Toast(message: "WidgetOrganizer.AddWidget.Warning.NoSpace")
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
    } else if let newPosition = findAvailablePosition(for: size, currentPage: currentPosition.page) {
      widgets[index].size = size
      widgets[index].position = newPosition
      saveWidgets()
      UINotificationFeedbackGenerator().notificationOccurred(.success)
    } else {
      toast = Toast(message: String(format: NSLocalizedString("WidgetOrganizer.AddWidget.Warning.NoDropSpaceForSize", comment: ""), size.rawValue))
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
      toast = Toast(message: "WidgetOrganizer.AddWidget.Warning.NoDropSpace")
    }
  }

  func updateGridConfig(for size: CGSize) {
    Log.debug("Updating grid config for size: \(size)")
    let newConfig = GridConfig.forDevice(size: size)
    if newConfig != gridConfig {
      Log.debug("Grid config changed from \(gridConfig.columns)x\(gridConfig.rows) to \(newConfig.columns)x\(newConfig.rows)")
      let oldConfig = gridConfig
      gridConfig = newConfig
      rearrangeWidgets(oldConfig: oldConfig, newConfig: newConfig)
    } else {
      Log.debug("No grid config change needed")
    }
  }

  private func rearrangeWidgets(oldConfig: GridConfig, newConfig: GridConfig) {
    Log.debug("Rearranging widgets for new grid: \(newConfig.columns)x\(newConfig.rows)")
    var placedWidgets: [WidgetComponent] = []
    let sortedWidgets = widgets.sorted {
      $0.position.page < $1.position.page ||
      ($0.position.page == $1.position.page && $0.position.row < $1.position.row) ||
      ($0.position.page == $1.position.page && $0.position.row == $1.position.row && $0.position.column < $1.position.column)
    }

    for widget in sortedWidgets {
      let relCol = (Double(widget.position.column) + Double(widget.size.gridSize.width) / 2) / Double(oldConfig.columns)
      let relRow = (Double(widget.position.row) + Double(widget.size.gridSize.height) / 2) / Double(oldConfig.rows)

      let desiredCol = Int((relCol * Double(newConfig.columns) - Double(widget.size.gridSize.width) / 2).rounded())
      let desiredRow = Int((relRow * Double(newConfig.rows) - Double(widget.size.gridSize.height) / 2).rounded())

      let clampedCol = max(0, min(desiredCol, newConfig.columns - widget.size.gridSize.width))
      let clampedRow = max(0, min(desiredRow, newConfig.rows - widget.size.gridSize.height))
      let desiredPosition = GridPosition(row: clampedRow, column: clampedCol, page: widget.position.page)

      Log.debug("Widget \(widget.id): Old pos (\(widget.position.column),\(widget.position.row)), Desired pos (\(clampedCol),\(clampedRow))")

      if isPositionAvailable(for: widget.size, at: desiredPosition, excluding: widget.id, in: placedWidgets) {
        placedWidgets.append(widget.withPosition(desiredPosition))
        Log.debug("Placed at desired position: (\(clampedCol),\(clampedRow))")
      } else if let newPosition = findNearestValidPosition(for: widget.size, near: desiredPosition, excluding: widget.id, in: placedWidgets) {
        placedWidgets.append(widget.withPosition(newPosition))
        Log.debug("Placed at nearest position: (\(newPosition.column),\(newPosition.row))")
      } else {
        Log.debug("No position available for widget \(widget.id)")
        if let fallbackPosition = findAvailablePosition(for: widget.size, currentPage: widget.position.page, in: placedWidgets) {
          placedWidgets.append(widget.withPosition(fallbackPosition))
          Log.debug("Placed at fallback position: (\(fallbackPosition.column),\(fallbackPosition.row))")
        }
      }
    }
    widgets = placedWidgets
    saveWidgets()
  }

  private func findAvailablePosition(for size: WidgetSize, currentPage: Int? = nil, in widgets: [WidgetComponent] = []) -> GridPosition? {
    let (width, height) = size.gridSize
    // Prioritize currentPage if provided, otherwise scan all pages
    let pages = currentPage != nil ? [min(currentPage!, maxPages - 1)] + Array(0..<maxPages).filter { $0 != currentPage } : Array(0..<maxPages)

    for page in pages {
      for row in 0...(gridConfig.rows - height) {
        for column in 0...(gridConfig.columns - width) {
          let position = GridPosition(row: row, column: column, page: page)
          if isPositionAvailable(for: size, at: position, in: widgets) {
            return position
          }
        }
      }
    }
    return nil
  }

  private func findNearestValidPosition(for size: WidgetSize, near position: GridPosition, excluding excludeID: UUID?, in widgets: [WidgetComponent] = []) -> GridPosition? {
    let (width, height) = size.gridSize
    let page = min(max(0, position.page), maxPages - 1)
    let centerRow = position.row
    let centerColumn = position.column
    let maxDistance = max(gridConfig.rows, gridConfig.columns) / 2

    for distance in 0...maxDistance {
      for row in max(0, centerRow - distance)...min(gridConfig.rows - height, centerRow + distance) {
        for column in max(0, centerColumn - distance)...min(gridConfig.columns - width, centerColumn + distance) {
          let testPosition = GridPosition(row: row, column: column, page: page)
          if isPositionAvailable(for: size, at: testPosition, excluding: excludeID, in: widgets) {
            return testPosition
          }
        }
      }
    }
    return findAvailablePosition(for: size, currentPage: page, in: widgets)
  }

  func isPositionAvailable(for size: WidgetSize, at position: GridPosition, excluding excludeID: UUID? = nil, in widgets: [WidgetComponent] = []) -> Bool {
    let (width, height) = size.gridSize
    guard position.row + height <= gridConfig.rows,
          position.column + width <= gridConfig.columns,
          position.page < maxPages else { return false }

    for widget in (self.widgets + widgets).filter({ $0.id != excludeID }) {
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
      UserDefaults(suiteName: "studio.itch.speedometer")?.set(encoded, forKey: "widgets")
    }
  }

  private func loadWidgets() {
    if let data = UserDefaults(suiteName: "studio.itch.speedometer")?.data(forKey: "widgets"),
       let decoded = try? JSONDecoder().decode([WidgetComponent].self, from: data) {
      widgets = decoded
    }
  }
}

extension WidgetComponent {
  func withPosition(_ position: GridPosition) -> WidgetComponent {
    return WidgetComponent(id: self.id, type: self.type, size: self.size, position: position, theme: self.theme)
  }
}
