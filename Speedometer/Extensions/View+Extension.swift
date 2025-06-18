//
//  View+Extension.swift
//  Speedometer
//
//  Created by John Durcan on 18/06/2025.
//
import SwiftUI

// View extensions
extension View {
  func applyStyle(_ style: ViewStyle) -> some View {
    self.modifier(StyleModifier(style: style))
  }

  func titleStyle() -> some View {
    applyStyle(.text(.title))
  }

  func bodyStyle() -> some View {
    applyStyle(.text(.body))
  }

  func primaryButtonStyle() -> some View {
    applyStyle(.button(.primary))
  }

  func cardStyle() -> some View {
    applyStyle(.container(.card))
  }

  func widgetStyle() -> some View {
    applyStyle(.container(.widget))
  }
}
