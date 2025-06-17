//
//  UnitDisplayToggle.swift
//  Speedometer
//
//  Created by John Durcan on 17/06/2025.
//

import SwiftUI

struct UnitDisplayToggle: View {
 @Binding var type: SpeedType

  var body: some View {
    Picker("Unit", selection: $type) {
      Text("MPH").tag(SpeedType.mph)
      Text("KPH").tag(SpeedType.kph)
    }
    .pickerStyle(.segmented)
    .padding(.horizontal)
  }
}
