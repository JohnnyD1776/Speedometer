//
//  WidgetComponent.swift
//  Speedometer
//
//  Created by John Durcan on 18/06/2025.
//
import Foundation

// Model for a widget component
struct WidgetComponent: Identifiable, Codable {
  let id: UUID
  var type: WidgetType
  var size: WidgetSize
  var position: GridPosition
  var theme: WidgetTheme? // Optional theme override
}

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

enum WidgetStyle: String, Codable, CaseIterable {
  case leather
  case carbonFiber
  case metallic
}

enum WidgetType: String, Codable, CaseIterable {
  case gForceDot
  case speedometer
  case speedGauge
  case seismograph
  case unitToggle

  var supportedSizes: [WidgetSize] {
    switch self {
    case .gForceDot:
      return [.mediumHorizontal, .large]
    case .speedometer:
      return [.large, .extraLarge]
    case .speedGauge:
      return [.small, .mediumHorizontal]
    case .seismograph:
      return [.mediumVertical, .large, .extraLarge]
    case .unitToggle:
      return [.mediumHorizontal]
    }
  }
}
