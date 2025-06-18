//
//  UnitDisplayToggle.swift
//  Speedometer
//
//  Created by John Durcan on 17/06/2025.
//

import SwiftUI

struct UnitDisplayToggle: View {
  @Binding var type: SpeedType
  @Environment(\.theme) private var theme

  var body: some View {
    Picker("Unit", selection: $type) {
      Text("MPH").tag(SpeedType.mph)
      Text("KPH").tag(SpeedType.kph)
    }
    .pickerStyle(.segmented)
    .padding(.horizontal)
    .tint(theme.accentColor)
    .foregroundColor(theme.primaryColor)
    .applyStyle(.button(.primary))
    .accessibilityLabel("Unit toggle, current unit \(type == .mph ? "MPH" : "KPH")")
  }
}
