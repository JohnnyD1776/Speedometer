//
//  GridConfig.swift
//  Speedometer
//
//  Created by John Durcan on 18/06/2025.
//
import SwiftUI

// Device-specific grid configuration
struct GridConfig: Equatable {
  let columns: Int
  let rows: Int
  let cellSize: CGFloat

  static func forDevice(size: CGSize) -> GridConfig {
    let isIPad = UIDevice.current.userInterfaceIdiom == .pad
    let isLandscape = size.width > size.height
    let columns: Int
    let rows: Int
    let padding: CGFloat = 0

    if isIPad {
      columns = isLandscape ? 12 : 6
      rows = isLandscape ? 6 : 12
    } else {
      columns = isLandscape ? 8 : 4
      rows = isLandscape ? 4 : 8
    }

    // Use minimum dimension to ensure square cells
    let availableWidth = size.width - padding * CGFloat(columns + 1)
    let availableHeight = size.height - padding * CGFloat(rows + 1)
    let cellSize = min(availableWidth / CGFloat(columns), availableHeight / CGFloat(rows))

    return GridConfig(columns: columns, rows: rows, cellSize: cellSize)
  }

  static func == (lhs: GridConfig, rhs: GridConfig) -> Bool {
    lhs.columns == rhs.columns && lhs.rows == rhs.rows && abs(lhs.cellSize - rhs.cellSize) < 0.01
  }
}

struct GridPosition: Codable, Equatable {
  var row: Int
  var column: Int
  var page: Int

  static func == (lhs: GridPosition, rhs: GridPosition) -> Bool {
    lhs.row == rhs.row && lhs.column == rhs.column && lhs.page == rhs.page
  }
}
