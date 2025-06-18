//
//  WidgetType.swift
//  Speedometer
//
//  Created by John Durcan on 18/06/2025.
//
import Foundation

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
