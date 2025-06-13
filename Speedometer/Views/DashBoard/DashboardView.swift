//
//  ContentView.swift
//  Speedometer
//
//  Created by John Durcan on 03/06/2025.
//

import SwiftUI
import CoreLocation

struct DashboardView: View {
  @ObservedObject var locationManager: LocationManager
  @ObservedObject var vm: DashbordViewModel
  let style: GForceMeterStyle
  let maxTime: Double = 10.0 // Total time span for the y-axis (e.g., 10 seconds)
  let timeInterval: Double = 0.1 // Time interval between data points (e.g., 0.1 seconds)
  let accelerationRange: ClosedRange<Double> = -1.0...1.0 // Example range for acceleration
  
  init(locationManager: LocationManager, viewModel: DashbordViewModel, style: GForceMeterStyle = DefaultGForceMeterStyle()) {
    self.locationManager = locationManager
    self.vm = viewModel
    self.style = style
  }

  let gradient = Gradient(colors: [.green, .yellow, .orange, .red])

  var speedAngle: Angle {
    Angle(degrees: 360 * (vm.displayedSpeed / vm.topSpeed) - 90)
  }

  var body: some View {
    VStack(alignment: .center) {
      HStack {
        Text("Speedometer")
          .foregroundStyle(.red)
          .font(.title)
        Spacer()
        SpeedGauge(current: $vm.displayedSpeed, topValue: $vm.topSpeed, maxValue: $vm.maxSpeed)
          .frame(width: 60)
      }
      .padding(12)

      // Unit Toggle
      Picker("Unit", selection: $vm.type) {
        Text("MPH").tag(SpeedType.mph)
        Text("KPH").tag(SpeedType.kph)
      }
      .pickerStyle(.segmented)
      .padding(.horizontal)
      Spacer()
      speedometer
      Spacer()
      gMeter
    }
    .animation(.easeInOut, value: vm.displayedSpeed)
    .animation(.easeInOut, value: speedAngle)
    .padding()
    .onReceive(locationManager.$speed) { gpsSpeed in
      let newSpeed = vm.type == .mph ? gpsSpeed * 2.23694 : gpsSpeed * 3.6
      // Calculate animation duration based on difference and max rate
      let speedDifference = abs(newSpeed - vm.displayedSpeed)
      let duration = speedDifference / vm.maxRateOfChange
      // Animate to the new speed with a minimum duration of 0.1s
      vm.targetSpeed = newSpeed
      vm.animationDuration =  duration
      vm.startSpeed = vm.displayedSpeed
      vm.startTime = Date()
    }
    .onChange(of: vm.type) { old, newType in
      let speedInMps = locationManager.speed
      let newTarget = newType == .mph ? speedInMps * 2.23694 : speedInMps * 3.6
      let speedDifference = abs(newTarget - vm.displayedSpeed)
      vm.animationDuration = speedDifference / vm.maxRateOfChange
      vm.startSpeed = vm.displayedSpeed
      vm.targetSpeed = newTarget
      vm.startTime = Date()
      vm.topSpeed = newType == .mph ? vm.baseTopSpeed : vm.baseTopSpeed * 1.60934
    }
    .onReceive(Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()) { _ in
      let elapsed = Date().timeIntervalSince(vm.startTime)
      let progress = min(elapsed / vm.animationDuration, 1.0)
      vm.displayedSpeed = vm.startSpeed + (vm.targetSpeed - vm.startSpeed) * progress
      if progress >= 1.0 {
        vm.startSpeed = vm.targetSpeed
      }
    }
  }

}


#Preview {
  DashboardView(locationManager: LocationManager(isSimulating: true), viewModel: DashbordViewModel())
}
