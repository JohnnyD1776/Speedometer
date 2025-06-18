//
//  GridConfig.swift
//  Speedometer
//
//  Created by John Durcan on 18/06/2025.
//
import SwiftUI

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
