//
//  GMeterView.swift
//  Speedometer
//
//  Created by John Durcan on 18/06/2025.
//
import SwiftUI

// G-meter component
struct GMeterView: View {
  let gForce: Double

  var body: some View {
    VStack {
      Gauge(value: gForce, in: 0...2) {
        Text("G-Force")
      } currentValueLabel: {
        Text("\(gForce, specifier: "%.1f") G")
      }
      .gaugeStyle(.accessoryCircular)
      .tint(.white)
    }
    .padding()
  }
}
