//
//  LocationManager.swift
//  Speedometer
//
//  Created by John Durcan on 03/06/2025.
//

import SwiftUI
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
  private let locationManager = CLLocationManager()
  @Published var speed: Double = 0.0 // Speed in meters per second
  private var isSimulating: Bool
  private var simulationTimer: Timer?

  init(isSimulating: Bool = false) {
    self.isSimulating = isSimulating
    super.init()
    if isSimulating {
      startSimulation()
    } else {
      locationManager.delegate = self
      locationManager.requestWhenInUseAuthorization()
      locationManager.startUpdatingLocation()
    }
  }

  private func startSimulation() {
    simulationTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
      guard let self = self else { return }
      let minValue = max(0, self.speed - 15)
      let maxValue = min(75, self.speed + 15)
      self.speed = Double.random(in: minValue...maxValue)
    }
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    if !isSimulating, let speed = locations.last?.speed, speed >= 0 {
      self.speed = speed
    }
  }

  deinit {
    simulationTimer?.invalidate()
  }
}
