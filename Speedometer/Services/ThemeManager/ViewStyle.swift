//
//  ViewStyle.swift
//  Speedometer
//
//  Created by John Durcan on 18/06/2025.
//


import SwiftUI

// Enum for view styles
enum ViewStyle {
  case text(TextStyle)
  case button(ButtonStyle)
  case container(ContainerStyle)
  case gForceMeter

  enum TextStyle {
    case title
    case subtitle
    case body
    case caption
    case boldBody
  }

  enum ButtonStyle {
    case primary
    case secondary
    case destructive
  }

  enum ContainerStyle {
    case card
    case background
    case meter
    case widget
  }
}

