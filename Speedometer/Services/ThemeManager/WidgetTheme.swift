//
//  WidgetTheme.swift
//  Speedometer
//
//  Created by John Durcan on 18/06/2025.
//

import SwiftUI

enum WidgetTheme: String, Codable, CaseIterable {
  case bmwLeather
  case racingFlat
  case highContrast

  var theme: Theme {
    switch self {
    case .bmwLeather:
      return .bmwLeather
    case .racingFlat:
      return .racingFlat
    case .highContrast:
      return .highContrast
    }
  }
}
