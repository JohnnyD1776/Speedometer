//
//  WidgetSize.swift
//  Speedometer
//
//  Created by John Durcan on 18/06/2025.
//
import Foundation

enum WidgetSize: String, Codable, CaseIterable {
  case small
  case mediumHorizontal
  case mediumVertical
  case large
  case extraLarge

  var gridSize: (width: Int, height: Int) {
    switch self {
    case .small: return (1, 1)
    case .mediumHorizontal: return (2, 1)
    case .mediumVertical: return (1, 2)
    case .large: return (2, 2)
    case .extraLarge: return (3, 2)
    }
  }
}
