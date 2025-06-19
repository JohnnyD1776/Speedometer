//
//  ThemeManager.swift
//  Speedometer
//
//  Created by John Durcan on 18/06/2025.
//

import SwiftUI

// Theme struct with widget support
struct Theme {
  let primaryColor: Color
  let secondaryColor: Color
  let tertiaryColor: Color
  let backgroundColor: Color
  let accentColor: Color
  let primaryFont: Font
  let primaryBackground: WidgetBackgroundType
  let widgetBackground: WidgetBackgroundType
  let widgetCornerRadius: CGFloat
  let containerCornerRadius: CGFloat
  let meterGradient: Gradient
  private let gForceMeterDotColorOverride: Color?
  private let gForceMeterTailColorOverride: Color?
  private let gForceMeterSeismographLineColorOverride: Color?
  private let gForceMeterSeismographBackgroundColorOverride: Color?

  var gForceMeterStyle: some GForceMeterStyle {
    struct Style: GForceMeterStyle {
      let dotColor: Color
      let tailColor: Color
      let seismographLineColor: Color
      let seismographBackgroundColor: Color
    }
    return Style(
      dotColor: gForceMeterDotColorOverride ?? primaryColor,
      tailColor: gForceMeterTailColorOverride ?? primaryColor.opacity(0.5),
      seismographLineColor: gForceMeterSeismographLineColorOverride ?? secondaryColor,
      seismographBackgroundColor: gForceMeterSeismographBackgroundColorOverride ?? backgroundColor
    )
  }

  func style(for viewStyle: ViewStyle) -> ViewStyleConfiguration {
    switch viewStyle {
    case .text(let textStyle):
      return textStyleConfiguration(for: textStyle)
    case .button(let buttonStyle):
      return buttonStyleConfiguration(for: buttonStyle)
    case .container(let containerStyle):
      return containerStyleConfiguration(for: containerStyle)
    case .gForceMeter:
      return ViewStyleConfiguration(
        foregroundColor: gForceMeterStyle.dotColor,
        backgroundColor: gForceMeterStyle.seismographBackgroundColor,
        accentColor: accentColor,
        font: primaryFont,
        padding: 8,
        cornerRadius: widgetCornerRadius
      )
    }
  }

  private func textStyleConfiguration(for textStyle: ViewStyle.TextStyle) -> ViewStyleConfiguration {
    switch textStyle {
    case .title:
      return ViewStyleConfiguration(
        foregroundColor: primaryColor,
        backgroundColor: .clear,
        accentColor: accentColor,
        font: primaryFont,
        padding: 8,
        cornerRadius: 0
      )
    case .subtitle:
      return ViewStyleConfiguration(
        foregroundColor: secondaryColor,
        backgroundColor: .clear,
        accentColor: accentColor,
        font: primaryFont,
        padding: 6,
        cornerRadius: 0
      )
    case .body:
      return ViewStyleConfiguration(
        foregroundColor: primaryColor,
        backgroundColor: .clear,
        accentColor: accentColor,
        font: primaryFont,
        padding: 4,
        cornerRadius: 0
      )
    case .caption:
      return ViewStyleConfiguration(
        foregroundColor: secondaryColor,
        backgroundColor: .clear,
        accentColor: accentColor,
        font: primaryFont,
        padding: 2,
        cornerRadius: 0
      )
    case .boldBody:
      return ViewStyleConfiguration(
        foregroundColor: primaryColor,
        backgroundColor: .clear,
        accentColor: accentColor,
        font: primaryFont.weight(.bold),
        padding: 4,
        cornerRadius: 0
      )
    }
  }

  private func buttonStyleConfiguration(for buttonStyle: ViewStyle.ButtonStyle) -> ViewStyleConfiguration {
    switch buttonStyle {
    case .primary:
      return ViewStyleConfiguration(
        foregroundColor: .white,
        backgroundColor: primaryColor,
        accentColor: accentColor,
        font: primaryFont,
        padding: 12,
        cornerRadius: containerCornerRadius
      )
    case .secondary:
      return ViewStyleConfiguration(
        foregroundColor: primaryColor,
        backgroundColor: backgroundColor,
        accentColor: accentColor,
        font: primaryFont,
        padding: 12,
        cornerRadius: containerCornerRadius
      )
    case .destructive:
      return ViewStyleConfiguration(
        foregroundColor: .white,
        backgroundColor: .red,
        accentColor: accentColor,
        font: primaryFont,
        padding: 12,
        cornerRadius: containerCornerRadius
      )
    }
  }

  private func containerStyleConfiguration(for containerStyle: ViewStyle.ContainerStyle) -> ViewStyleConfiguration {
    switch containerStyle {
    case .card:
      return ViewStyleConfiguration(
        foregroundColor: primaryColor,
        backgroundColor: backgroundColor.opacity(0.8),
        accentColor: accentColor,
        font: primaryFont,
        padding: 16,
        cornerRadius: containerCornerRadius
      )
    case .background:
      return ViewStyleConfiguration(
        foregroundColor: primaryColor,
        backgroundColor: backgroundColor,
        accentColor: accentColor,
        font: primaryFont,
        padding: 0,
        cornerRadius: 0,
        backgroundType: primaryBackground
      )
    case .meter:
      return ViewStyleConfiguration(
        foregroundColor: primaryColor,
        backgroundColor: backgroundColor,
        accentColor: accentColor,
        font: primaryFont,
        padding: 8,
        cornerRadius: widgetCornerRadius,
        gradient: meterGradient
      )
    case .widget:
      return ViewStyleConfiguration(
        foregroundColor: primaryColor,
        backgroundColor: backgroundColor,
        accentColor: accentColor,
        font: primaryFont,
        padding: 8,
        cornerRadius: widgetCornerRadius,
        backgroundType: widgetBackground
      )
    }
  }

  init(
    primaryColor: Color = Color("PrimaryColor"),
    secondaryColor: Color = Color("SecondaryColor"),
    tertiaryColor: Color = Color("TertiaryColor"),
    backgroundColor: Color = Color("BackgroundColor"),
    accentColor: Color = Color("AccentColor"),
    primaryFont: Font = .body,
    primaryBackground: WidgetBackgroundType = .solid,
    widgetBackground: WidgetBackgroundType = .solid,
    widgetCornerRadius: CGFloat = 8,
    containerCornerRadius: CGFloat = 12,
    meterGradient: Gradient = Gradient(colors: [
      Color("MeterColor1"),
      Color("MeterColor2"),
      Color("MeterColor3"),
      Color("MeterColor4")
    ]),
    gForceMeterDotColor: Color? = nil,
    gForceMeterTailColor: Color? = nil,
    gForceMeterSeismographLineColor: Color? = nil,
    gForceMeterSeismographBackgroundColor: Color? = nil
  ) {
    self.primaryColor = primaryColor
    self.secondaryColor = secondaryColor
    self.tertiaryColor = tertiaryColor
    self.backgroundColor = backgroundColor
    self.accentColor = accentColor
    self.primaryFont = primaryFont
    self.primaryBackground = primaryBackground
    self.widgetBackground = widgetBackground
    self.widgetCornerRadius = widgetCornerRadius
    self.containerCornerRadius = containerCornerRadius
    self.meterGradient = meterGradient
    self.gForceMeterDotColorOverride = gForceMeterDotColor
    self.gForceMeterTailColorOverride = gForceMeterTailColor
    self.gForceMeterSeismographLineColorOverride = gForceMeterSeismographLineColor
    self.gForceMeterSeismographBackgroundColorOverride = gForceMeterSeismographBackgroundColor
  }
}
