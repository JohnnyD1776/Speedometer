//
//  SpeedDialView.swift
//  Speedometer
//
//  Created by John Durcan on 18/06/2025.
//
import SwiftUI

// Speed dial component
struct SpeedDialView: View {
  let speed: Double

  var body: some View {
    VStack {
      Text("\(Int(speed)) mph")
        .font(.system(size: 24, weight: .bold))
        .foregroundColor(.white)
      Text("Speed")
        .font(.caption)
        .foregroundColor(.white.opacity(0.8))
    }
  }
}
