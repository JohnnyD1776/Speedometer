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
  var style: WidgetStyle
  var position: GridPosition
}
