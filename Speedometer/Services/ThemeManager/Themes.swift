//
//  Themes.swift
//  Speedometer
//
//  Created by John Durcan on 18/06/2025.
//

import SwiftUI

// Predefined themes
extension Theme {
  static let bmwLeather = Theme(
    primaryColor: .black,
    secondaryColor: .gray,
    tertiaryColor: .white,
    backgroundColor: Color("BMWLeatherBackground"),
    accentColor: .blue,
    primaryFont: .custom("HelveticaNeue-Bold", size: 16),
    primaryBackground: .leather,
    widgetBackground: .solid,
    widgetCornerRadius: 10,
    containerCornerRadius: 15,
    meterGradient: Gradient(colors: [.green, .yellow, .orange, .red])
  )

  static let racingFlat = Theme(
    primaryColor: .white,
    secondaryColor: .black,
    tertiaryColor: .gray,
    backgroundColor: Color("RacingFlatBackground"),
    accentColor: .red,
    primaryFont: .system(.body, design: .monospaced),
    primaryBackground: .solid,
    widgetBackground: .carbonFiber,
    widgetCornerRadius: 5,
    containerCornerRadius: 8,
    meterGradient: Gradient(colors: [.blue, .cyan, .white])
  )

  static let highContrast = Theme(
    primaryColor: .black,
    secondaryColor: .white,
    tertiaryColor: .gray,
    backgroundColor: .white,
    accentColor: .black,
    primaryFont: .system(.body, design: .default, weight: .bold),
    primaryBackground: .solid,
    widgetBackground: .solid,
    widgetCornerRadius: 8,
    containerCornerRadius: 12,
    meterGradient: Gradient(colors: [.black, .gray, .white]),
    gForceMeterDotColor: .black,
    gForceMeterTailColor: .black.opacity(0.5),
    gForceMeterSeismographLineColor: .white,
    gForceMeterSeismographBackgroundColor: .gray
  )
}


