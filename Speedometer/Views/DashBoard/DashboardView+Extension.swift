//
//  DashboardView+Extension.swift
//  Speedometer
//
//  Created by John Durcan on 04/06/2025.
//
import SwiftUI


extension DashboardView {

  var gMeter: some View {
    let currentTime = Date()
    let startTime = currentTime.addingTimeInterval(-maxTime)
    let history = locationManager.telemetryHistory
      .filter { $0.timestamp > startTime } // Keep only recent data
      .map { $0.gforceX } // Extract X-axis acceleration

    return VStack {
      SeismographView(
        style: style, // Replace with your actual GForceMeterStyle
        history: history,
        accelerationRange: accelerationRange,
        timeInterval: timeInterval,
        maxTime: maxTime
      )
      .onAppear {
        locationManager.startRecording() // Start collecting data when the view appears
      }
      .onDisappear {
        locationManager.stopRecording() // Stop when the view disappears
      }
    }
  }

  var speedometer: some View {
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

        Text("\(String(format: "%.1f", vm.displayedSpeed)) \(vm.type == .mph ? "MPH" : "KPH")")
          .fontDesign(.rounded)
          .foregroundStyle(.white)
          .fontWeight(.light)
          .font(.system(size: size / 9))
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
          .padding(size / 5)
        Circle()
          .foregroundStyle(gradient)
          .frame(width: size * 0.2)
        Text("\(String(format: "%.1f", vm.targetSpeed))")

        ForEach(Array(stride(from: 0, through: vm.topSpeed, by: 20)), id: \.self) { speed in
          let angle = Angle(degrees: 360 * (speed / vm.topSpeed) - 90).radians
          let x = center + radius * cos(angle)
          let y = center + radius * sin(angle)

          Text("\(Int(speed))")
            .position(x: x, y: y)
            .foregroundColor(.white)
            .font(.system(size: size / 25))
        }
      }
      .frame(width: size, height: size)
    }
  }
}
