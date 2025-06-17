//
//  Speedometer.swift
//  Speedometer
//
//  Created by John Durcan on 17/06/2025.
//

import SwiftUI

struct Speedometer: View {
  let gradient = Gradient(colors: [.green, .yellow, .orange, .red])
  var speedAngle: Angle
  @Binding var displayedSpeed: Double
  @Binding var type: SpeedType
  @Binding var targetSpeed: Double
  @Binding var topSpeed: Double

  var body: some View {
    GeometryReader { geometry in
      let size = min(geometry.size.width, geometry.size.height)
      let center = size / 2
      let radius = 0.8 * center
      let outerCircleRatio = 0.93
      let innerCircleRatio = 0.86
      ZStack {
        Circle()
          .foregroundStyle(gradient)
          .frame(width: size * outerCircleRatio)

        Circle()
          .foregroundStyle(.red)
          .frame(width: size * innerCircleRatio)

        ZStack {
          RoundedRectangle(cornerRadius: 2)
            .foregroundStyle(.white)
            .frame(width: size / 3.3, height: 5)
            .offset(x: size / 4.5)
        }
        .rotationEffect(speedAngle)

        Text("\(String(format: "%.1f", displayedSpeed)) \(type == .mph ? "MPH" : "KPH")")
          .fontDesign(.rounded)
          .foregroundStyle(.white)
          .fontWeight(.light)
          .font(.system(size: size / 9))
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
          .padding(size / 5)
        Circle()
          .foregroundStyle(gradient)
          .frame(width: size * 0.2)
        Text("\(String(format: "%.1f", targetSpeed))")

        ForEach(Array(stride(from: 0, through: topSpeed, by: 20)), id: \.self) { speed in
          let angle = Angle(degrees: 360 * (speed / topSpeed) - 90).radians
          let x =  radius * cos(angle)
          let y =  radius * sin(angle)

          Text("\(Int(speed))")
            .offset(x: x, y: y)
            .foregroundColor(.white)
            .font(.system(size: size / 25))
        }
      }
    }
  }
}
