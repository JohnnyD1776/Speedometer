//
//  Speedometer.swift
//  Speedometer
//
//  Created by John Durcan on 17/06/2025.
//

import SwiftUI

import SwiftUI

struct Speedometer: View {
  var speedAngle: Angle
  @Binding var displayedSpeed: Double
  @Binding var type: SpeedType
  @Binding var targetSpeed: Double
  @Binding var topSpeed: Double
  @Environment(\.theme) private var theme

  var body: some View {
    GeometryReader { geometry in
      let size = min(geometry.size.width, geometry.size.height)
      let center = size / 2
      let radius = 0.8 * center
      let outerCircleRatio = 0.93
      let innerCircleRatio = 0.86
      ZStack {
        Circle()
          .fill(LinearGradient(gradient: theme.meterGradient, startPoint: .leading, endPoint: .trailing))
          .frame(width: size * outerCircleRatio)

        Circle()
          .fill(theme.accentColor)
          .frame(width: size * innerCircleRatio)

        ZStack {
          RoundedRectangle(cornerRadius: 2)
            .fill(theme.primaryColor)
            .frame(width: size / 3.3, height: 5)
            .offset(x: size / 4.5)
        }
        .rotationEffect(speedAngle)

        Text("\(String(format: "%.1f", displayedSpeed)) \(type == .mph ? "MPH" : "KPH")")
          .font(theme.primaryFont)
          .foregroundColor(theme.primaryColor)
          .applyStyle(.text(.body))
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
          .padding(size / 5)

        Circle()
          .fill(LinearGradient(gradient: theme.meterGradient, startPoint: .leading, endPoint: .trailing))
          .frame(width: size * 0.2)

        Text("\(String(format: "%.1f", targetSpeed))")
          .font(theme.primaryFont)
          .foregroundColor(theme.secondaryColor)
          .applyStyle(.text(.caption))

        ForEach(Array(stride(from: 0, through: topSpeed, by: 20)), id: \.self) { speed in
          let angle = Angle(degrees: 360 * (speed / topSpeed) - 90).radians
          let x = radius * cos(angle)
          let y = radius * sin(angle)

          Text("\(Int(speed))")
            .offset(x: x, y: y)
            .font(theme.primaryFont)
            .foregroundColor(theme.primaryColor)
            .applyStyle(.text(.caption))
        }
      }
      .animation(.default, value: speedAngle)
      .accessibilityLabel("Speedometer, current speed \(displayedSpeed, specifier: "%.1f") \(type == .mph ? "MPH" : "KPH"), target speed \(targetSpeed, specifier: "%.1f")")
      .id(displayedSpeed) // Force redraw when displayedSpeed changes
    }
  }
}

#Preview {
  struct SpeedometerPreview: View {
    @StateObject var dataManager = DataManager(locationManager: LocationManager(isSimulating: true))

    var body: some View {
      Speedometer(
        speedAngle: dataManager.speedAngle,
        displayedSpeed: $dataManager.displayedSpeed,
        type: $dataManager.type,
        targetSpeed: $dataManager.targetSpeed,
        topSpeed: $dataManager.topSpeed
      )
      .environment(\.theme, .bmwLeather)

    }
  }
  return SpeedometerPreview()
}
