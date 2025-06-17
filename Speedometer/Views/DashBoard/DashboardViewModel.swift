//
//  DashboardViewModel.swift
//  Speedometer
//
//  Created by John Durcan on 04/06/2025.
//

import SwiftUI
import Combine

class DashbordViewModel: ObservableObject {
  @ObservedObject var locationManager: LocationManager
  var cancellables = Set<AnyCancellable>()

  @Published var displayedSpeed: Double = 0.0
  @Published var targetSpeed: Double = 0.0
  @Published var startSpeed: Double = 0.0
  @Published var startTime: Date = Date()
  @Published var maxSpeed: Double = 155.0
  @Published var topSpeed: Double = 175.0
  @Published var type: SpeedType = .mph
  @Published var history: [Double] = []
  @Published var animationDuration: Double = 0.0
  let maxTime: Double = 10.0
  var speedAngle: Angle {
    Angle(degrees: 360 * (displayedSpeed / topSpeed) - 90)
  }
  let maxRateOfChange: Double = 10.0
  let baseTopSpeed: Double = 175.0 // Base value in MPH

  private var timer: Timer?

  init(locationManager: LocationManager) {
    self.locationManager = locationManager
    subscriptions()
  }

  deinit {
    stopRecordingData()
  }

  func startRecordingData() {
    locationManager.startRecording()
  }

  func stopRecordingData() {
    locationManager.stopRecording()
  }

  func subscriptions() {
    $type
      .sink { [weak self] newType in
        guard let self = self else { return }
        let speedInMps = locationManager.speed
        let newTarget = newType == .mph ? speedInMps * 2.23694 : speedInMps * 3.6
        let speedDifference = abs(newTarget - displayedSpeed)
        animationDuration = speedDifference / maxRateOfChange
        startSpeed = displayedSpeed
        targetSpeed = newTarget
        startTime = Date()
        topSpeed = newType == .mph ? baseTopSpeed : baseTopSpeed * 1.60934
      }
      .store(in: &cancellables)

    locationManager.$telemetryHistory
      .sink {  [weak self] telemetry in
        guard let self = self else { return }
        let currentTime = Date()
        let startTime = currentTime.addingTimeInterval(-maxTime)
        self.history = telemetry
          .filter { $0.timestamp > startTime } // Keep only recent data
          .map { $0.gforceX }
        Log.debug("History Updated:\n\(self.history)")
      }
      .store(in: &cancellables)

    locationManager.$speed
      .sink
    { [weak self] gpsSpeed in
      guard let self = self else { return }
      self.displayedSpeed = gpsSpeed
      let newSpeed = self.type == .mph ? gpsSpeed * 2.23694 : gpsSpeed * 3.6
      // Calculate animation duration based on difference and max rate
      let speedDifference = abs(newSpeed - self.displayedSpeed)
      let duration = speedDifference / self.maxRateOfChange
      // Animate to the new speed with a minimum duration of 0.1s
      self.targetSpeed = newSpeed
      self.animationDuration =  duration
      self.startSpeed = self.displayedSpeed
      self.startTime = Date()
    }
    .store(in: &cancellables)
  }

}
