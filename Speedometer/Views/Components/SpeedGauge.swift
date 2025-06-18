//
//  SpeedGauge.swift
//  Speedometer
//
//  Created by John Durcan on 03/06/2025.
//
import SwiftUI

struct SpeedGauge: View {
  @Binding var current: Double
  @Binding var topValue: Double
  @Binding var maxValue: Double
  @Environment(\.theme) private var theme

  init(current: Binding<Double>, topValue: Binding<Double>, maxValue: Binding<Double>) {
    self._current = current
    self._topValue = topValue
    self._maxValue = maxValue
  }

  var body: some View {
    Gauge(value: current, in: 0...topValue) {
      Text("Speed")
        .font(theme.primaryFont)
        .foregroundColor(theme.secondaryColor)
        .applyStyle(.text(.caption))
    } currentValueLabel: {
      Text("\(Int(current))")
        .font(theme.primaryFont)
        .foregroundColor(theme.primaryColor)
        .applyStyle(.text(.body))
    } minimumValueLabel: {
      Text("\(Int(0))")
        .font(theme.primaryFont)
        .foregroundColor(theme.secondaryColor)
        .applyStyle(.text(.caption))
    } maximumValueLabel: {
      Text("\(Int(topValue))")
        .font(theme.primaryFont)
        .foregroundColor(theme.secondaryColor)
        .applyStyle(.text(.caption))
    }
    .gaugeStyle(.accessoryCircular)
    .tint(LinearGradient(gradient: theme.meterGradient, startPoint: .leading, endPoint: .trailing))
    .accessibilityLabel("Speed Gauge, current speed \(current, specifier: "%.0f"), top speed \(topValue, specifier: "%.0f")")
  }
}


#Preview {
  SpeedGauge(current: .constant(35), topValue: .constant(150), maxValue: .constant(200))
}
