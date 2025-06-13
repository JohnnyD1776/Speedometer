//
//  LocationManager.swift
//  Speedometer
//
//  Created by John Durcan on 03/06/2025.
//

import CoreLocation
import CoreMotion
import Combine

struct TelemetryDataPoint: Codable {
  let timestamp: Date
  let speed: Double
  let gforceX: Double
  let gforceY: Double
  let gforceZ: Double
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
  private let locationManager = CLLocationManager()
  private var motionManager: CMMotionManager?
  @Published var speed: Double = 0.0 // Speed in meters per second
  @Published var gforce: CMAcceleration = .init() // G-force
  @Published var telemetryHistory: [TelemetryDataPoint] = []
  @Published var isPlayingBack: Bool = false
  private var isSimulating: Bool
  private var simulationTimer: Timer?
  private var recordingTimer: Timer?
  private var previousSpeed: Double?
  private var previousTimestamp: Date?

  // Variables for simulating lateral forces (cornering)
  private var inTurn: Bool = false
  private var turnLateralAcceleration: Double = 0.0
  private var turnDurationLeft: Int = 0
  let motionActivityManager = CMMotionActivityManager()

  /// Initialize with an option to simulate data
  init(isSimulating: Bool = false) {
    self.isSimulating = isSimulating
    super.init()
    startMotionUpdates()

    if isSimulating {
      startSimulation()
    } else {
      // Set up CoreMotion for accelerometer data
      motionManager = CMMotionManager()
      motionManager?.deviceMotionUpdateInterval = 0.1 // 10 Hz updates
      motionManager?.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
        guard let self = self, let motion = motion else { return }
        if !self.isPlayingBack {
          self.gforce = motion.userAcceleration
        }
      }
      // Set up CoreLocation for speed data
      locationManager.delegate = self
      locationManager.desiredAccuracy = kCLLocationAccuracyBest
//      locationManager.distanceFilter = 10 // Update every 10 meters
      locationManager.allowsBackgroundLocationUpdates = true

      locationManager.requestWhenInUseAuthorization()
      locationManager.startUpdatingLocation()
    }
  }

  /// Simulate speed and G-force when in simulation mode
  private var phase: Double = 0.0


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


  private func startSimulation() {
    speed = 0.0 // Initialize speed
    simulationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
      guard let self = self else { return }
      if self.isPlayingBack { return }

      // Increment phase for sinusoidal variation
      self.phase += 0.1

      // Define amplitudes for G-forces
      let A = 0.5 // Longitudinal G-force amplitude
      let B = 0.3 // Lateral G-force amplitude

      // Calculate sinusoidal G-forces
      let gforceY = A * sin(self.phase) // Longitudinal (acceleration/braking)
      let gforceX = B * cos(self.phase) // Lateral (cornering)

      // Update speed based on longitudinal acceleration (in m/s^2)
      let deltaT = 0.1
      self.speed += (gforceY * 9.8) * deltaT

      // Clamp speed to realistic range: 0 to 30 m/s (108 km/h)
      if self.speed < 0 {
        self.speed = 0
      } else if self.speed > 30 {
        self.speed = 30
      }

      // Set the G-force values
      self.gforce = CMAcceleration(x: gforceX, y: gforceY, z: 0.0)
    }
  }

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
      self.telemetryHistory.append(dataPoint)
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
      let data = try encoder.encode(telemetryHistory)
      let fileURL = getDocumentsDirectory().appendingPathComponent(fileName)
      try data.write(to: fileURL)
      telemetryHistory.removeAll() // Clear memory after saving
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
    self.telemetryHistory.removeAll()
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
        self.telemetryHistory.append(point)
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

  /// Clean up resources
  deinit {
    simulationTimer?.invalidate()
    recordingTimer?.invalidate()
    motionManager?.stopDeviceMotionUpdates()
  }
}
