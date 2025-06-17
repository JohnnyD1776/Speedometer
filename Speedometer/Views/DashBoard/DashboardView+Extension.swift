//
//  DashboardView+Extension.swift
//  Speedometer
//
//  Created by John Durcan on 04/06/2025.
//
import SwiftUI


extension DashboardView {

  var gMeter: some View {
    return VStack(alignment: .center) {
      SeismographView(
        style: style,
        history: $vm.history,
        maxTime: vm.maxTime
      )
    }
  }

  var speedometer: some View {
    Speedometer(speedAngle: vm.speedAngle, displayedSpeed: $vm.displayedSpeed, type: $vm.type, targetSpeed: $vm.targetSpeed, topSpeed: $vm.topSpeed)
      .animation(.easeInOut, value: vm.displayedSpeed)
      .animation(.easeInOut, value: vm.speedAngle)
  }

  var header: some View {
    HStack {
      Text("Speedometer")
        .foregroundStyle(.red)
        .font(.title)
      Spacer()
      SpeedGauge(current: $vm.displayedSpeed, topValue: $vm.topSpeed, maxValue: $vm.maxSpeed)
        .frame(width: 60)
    }
  }
}
