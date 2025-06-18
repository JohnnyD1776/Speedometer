//
//  WidgetType.swift
//  Speedometer
//
//  Created by John Durcan on 18/06/2025.
//
import Foundation

enum WidgetType: String, Codable, CaseIterable {
  case speedDial
  case gMeter

  var supportedSizes: [WidgetSize] {
    switch self {
    case .speedDial: return [.small, .mediumHorizontal, .large]
    case .gMeter: return [.small, .mediumVertical, .large, .extraLarge]
    }
  }
}
