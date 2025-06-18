//
//  LocationManager.swift
//  Speedometer
//
//  Created by John Durcan on 03/06/2025.
//

import CoreLocation
import CoreMotion
import Combine

class LocationManager: NSObject, ObservableObject {
  @Published var speed: Double = 0.0 // Speed in meters per second
  @Published var gforce: CMAcceleration = .init() // G-force
  @Published var telemetryHistory: [TelemetryDataPoint] = []
  @Published var telemetryRecording: [TelemetryDataPoint] = []
  @Published var isPlayingBack: Bool = false

  private var isSimulating: Bool
  private var simulationTimer: Timer?
  private var recordingTimer: Timer?
  private var animationTimer: Timer?

  // Variables for simulating lateral forces (cornering)
  private var phase: Double = 0.0

  private var motionManager: CMMotionManager?
  private let motionActivityManager = CMMotionActivityManager()
  private let locationManager = CLLocationManager()

  /// Initialize with an option to simulate data
  init(isSimulating: Bool = false) {
    self.isSimulating = isSimulating
    super.init()

    if isSimulating {
      startSimulation()
    } else {
      startMotionUpdates()
      startMotionManager()
      startLocationManager()
    }
    startSmoothUpdateTimer()
  }

  /// Clean up resources
  deinit {
    simulationTimer?.invalidate()
    recordingTimer?.invalidate()
    animationTimer?.invalidate()
    motionManager?.stopDeviceMotionUpdates()
  }

  func startSmoothUpdateTimer() {
    animationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
      guard let self = self else { return }
      if self.isPlayingBack { return }
      let dataPoint = TelemetryDataPoint(
        timestamp: Date(),
        speed: self.speed,
        gforceX: self.gforce.x,
        gforceY: self.gforce.y,
        gforceZ: self.gforce.z
      )
      self.telemetryHistory.append(dataPoint)
    }
  }
  /// Set up CoreLocation for speed data
  func startLocationManager() {
    locationManager.delegate = self
    locationManager.requestWhenInUseAuthorization()
    locationManager.desiredAccuracy = kCLLocationAccuracyBest
    //      locationManager.distanceFilter = 10 // Update every 10 meters
    locationManager.allowsBackgroundLocationUpdates = true
    locationManager.startUpdatingLocation()
  }

  func startMotionManager() {
    motionManager = CMMotionManager()
    motionManager?.deviceMotionUpdateInterval = 0.1 // 10 Hz updates
    motionManager?.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
      guard let self = self, let motion = motion else { return }
      if !self.isPlayingBack {
        self.gforce = motion.userAcceleration
      }
    }
  }

  func startMotionUpdates() {
    if CMMotionActivityManager.isActivityAvailable() {
      motionActivityManager.startActivityUpdates(to: .main) { activity in
        if let activity = activity {
          print("Motion activity: \(activity)")
        }
      }
    } else {
      print("Motion activity not available")
    }
  }
}

/// Simulation Functions
extension LocationManager {

  private func startSimulation() {
    speed = 0.0
    simulationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
      guard let self = self else { return }
      if self.isPlayingBack { return }

      self.phase += 0.1
      let A = 0.5
      let B = 0.3
      let gforceY = A * sin(self.phase)
      let gforceX = B * cos(self.phase)
      let deltaT = 0.1
      self.speed += (gforceY * 9.8) * deltaT

      if self.speed < 0 {
        self.speed = 0
      } else if self.speed > 30 {
        self.speed = 30
      }

      self.gforce = CMAcceleration(x: gforceX, y: gforceY, z: 0.0)
      Log.debug("LocationManager: Simulated speed: \(self.speed), gforce: (\(gforceX), \(gforceY))")
    }
  }
}

extension LocationManager: CLLocationManagerDelegate {

  /// Handle location updates from GPS
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    if !isSimulating && !isPlayingBack, let location = locations.last, location.speed >= 0 {
      self.speed = location.speed
    }
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    print("Location error: \(error)")
  }

  func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    if status == .authorizedWhenInUse {
      locationManager.startUpdatingLocation()
    }
  }

}

/// Functions related to Recording
extension LocationManager {

  /// Start recording telemetry data at 0.1-second intervals
  func startRecording() {
    recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
      guard let self = self else { return }
      if self.isPlayingBack { return }
      let dataPoint = TelemetryDataPoint(
        timestamp: Date(),
        speed: self.speed,
        gforceX: self.gforce.x,
        gforceY: self.gforce.y,
        gforceZ: self.gforce.z
      )
      self.telemetryRecording.append(dataPoint)
    }
  }

  /// Stop recording telemetry data
  func stopRecording() {
    recordingTimer?.invalidate()
    recordingTimer = nil
  }

  /// Save the telemetry history to a JSON file
  func saveRun(to fileName: String) {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    do {
      let data = try encoder.encode(telemetryRecording)
      let fileURL = getDocumentsDirectory().appendingPathComponent(fileName)
      try data.write(to: fileURL)
      telemetryRecording.removeAll() // Clear memory after saving
    } catch {
      print("Failed to save run: \(error)")
    }
  }

  /// Load telemetry data from a JSON file
  func loadRun(from fileName: String) -> [TelemetryDataPoint]? {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    do {
      let fileURL = getDocumentsDirectory().appendingPathComponent(fileName)
      let data = try Data(contentsOf: fileURL)
      return try decoder.decode([TelemetryDataPoint].self, from: data)
    } catch {
      print("Failed to load run: \(error)")
      return nil
    }
  }

  /// Playback the loaded telemetry data
  func playbackRun(data: [TelemetryDataPoint]) {
    guard !data.isEmpty else { return }
    self.isPlayingBack = true
    self.telemetryRecording.removeAll()
    var index = 0
    let startTime = Date()
    let runStartTime = data[0].timestamp
    Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
      guard let self = self else {
        timer.invalidate()
        return
      }
      let elapsedTime = Date().timeIntervalSince(startTime)
      let runTime = runStartTime.addingTimeInterval(elapsedTime)
      while index < data.count && data[index].timestamp <= runTime {
        let point = data[index]
        self.speed = point.speed
        self.gforce = CMAcceleration(x: point.gforceX, y: point.gforceY, z: point.gforceZ)
        self.telemetryRecording.append(point)
        index += 1
      }
      if index >= data.count {
        self.isPlayingBack = false
        timer.invalidate()
      }
    }
  }

  /// Get the documents directory URL
  private func getDocumentsDirectory() -> URL {
    FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
  }

}
