//
//  StyleModifier.swift
//  Speedometer
//
//  Created by John Durcan on 18/06/2025.
//
import SwiftUI

// View modifier for styles
struct StyleModifier: ViewModifier {
  let style: ViewStyle
  @Environment(\.theme) private var theme

  func body(content: Content) -> some View {
    let config = theme.style(for: style)
    content
      .foregroundColor(config.foregroundColor)
      .font(config.font)
      .padding(config.padding)
      .background(
        Group {
          if let gradient = config.gradient {
            LinearGradient(
              gradient: gradient,
              startPoint: .leading,
              endPoint: .trailing
            )
          } else if let bgType = config.backgroundType, bgType != .solid {
            config.backgroundColor.overlay(
              Image(bgType.rawValue)
                .resizable()
                .scaledToFill()
                .opacity(0.3)
            )
          } else {
            config.backgroundColor
          }
        }
      )
      .clipShape(RoundedRectangle(cornerRadius: config.cornerRadius))
      .dynamicTypeSize(.large)
  }
}
