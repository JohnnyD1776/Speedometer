//
//  for.swift
//  Speedometer
//
//  Created by John Durcan on 18/06/2025.
//
import SwiftUI

// Configuration struct for view styles
struct ViewStyleConfiguration {
  let foregroundColor: Color
  let backgroundColor: Color
  let accentColor: Color
  let font: Font
  let padding: CGFloat
  let cornerRadius: CGFloat
  let gradient: Gradient?
  let backgroundType: WidgetBackgroundType?

  init(
    foregroundColor: Color,
    backgroundColor: Color,
    accentColor: Color,
    font: Font,
    padding: CGFloat,
    cornerRadius: CGFloat,
    gradient: Gradient? = nil,
    backgroundType: WidgetBackgroundType? = nil
  ) {
    self.foregroundColor = foregroundColor
    self.backgroundColor = backgroundColor
    self.accentColor = accentColor
    self.font = font
    self.padding = padding
    self.cornerRadius = cornerRadius
    self.gradient = gradient
    self.backgroundType = backgroundType
  }
}
