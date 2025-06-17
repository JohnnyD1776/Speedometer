//
//  GForceMeterStyle.swift
//  Speedometer
//
//  Created by John Durcan on 13/06/2025.
//


import SwiftUI

// Style protocol for theming
protocol GForceMeterStyle {
  var dotColor: Color { get }
  var tailColor: Color { get }
  var seismographLineColor: Color { get }
  var seismographBackgroundColor: Color { get }
}

// Default theme
struct DefaultGForceMeterStyle: GForceMeterStyle {
  var dotColor: Color = .blue
  var tailColor: Color = .blue.opacity(0.5)
  var seismographLineColor: Color = .green
  var seismographBackgroundColor: Color = .clear
}

// Dark theme
struct DarkGForceMeterStyle: GForceMeterStyle {
  var dotColor: Color = .white
  var tailColor: Color = .white.opacity(0.5)
  var seismographLineColor: Color = .yellow
  var seismographBackgroundColor: Color = .black
}
