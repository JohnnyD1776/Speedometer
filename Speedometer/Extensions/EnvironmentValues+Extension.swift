//
//  EnvironmentValues+Extension.swift
//  Speedometer
//
//  Created by John Durcan on 18/06/2025.
//

import SwiftUI


extension EnvironmentValues {
  var theme: Theme {
    get { self[ThemeKey.self] }
    set { self[ThemeKey.self] = newValue }
  }
}
