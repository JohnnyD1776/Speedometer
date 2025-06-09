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

  let gradient = Gradient(colors: [.green, .yellow, .orange, .red])

  init(current: Binding<Double>, topValue: Binding<Double>, maxValue: Binding<Double>) {
    self._current = current
    self._topValue = topValue
    self._maxValue = maxValue
  }

  var body: some View {
    Gauge(value: current, in: 0...topValue) {
      Text("Speed")
    } currentValueLabel: {
      Text("\(Int(current))")
    } minimumValueLabel: {
      Text("\(Int(0))")
    } maximumValueLabel: {
      Text("\(Int(topValue))")
    }
    .gaugeStyle(.accessoryCircular)
    .tint(gradient)
  }
}



#Preview {
  SpeedGauge(current: .constant(35), topValue: .constant(150), maxValue: .constant(200))
}
