//
//  GridPosition.swift
//  Speedometer
//
//  Created by John Durcan on 18/06/2025.
//
import Foundation

struct GridPosition: Codable, Equatable {
  var row: Int
  var column: Int
  var page: Int

  static func == (lhs: GridPosition, rhs: GridPosition) -> Bool {
    lhs.row == rhs.row && lhs.column == rhs.column && lhs.page == rhs.page
  }
}
