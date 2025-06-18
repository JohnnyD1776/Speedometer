//
//  SpeedometerDependency.swift
//  Speedometer
//
//  Created by John Durcan on 18/06/2025.
//
import Foundation
import SwiftUI
import CoreLocation

class SpeedometerDependency: ObservableObject {
  @ObservedObject var widgetManager: WidgetOrganizer
  @ObservedObject var dataManager: DataManager
  @ObservedObject var locationManager: LocationManager

  init(
    widgetManager: WidgetOrganizer = .init(),
    locationManager: LocationManager = {
#if DEBUG
      return LocationManager(isSimulating: true)
#else
      return LocationManager(isSimulating: false)
#endif
    }(),
    dataManager: DataManager? = nil
  ) {
    self.widgetManager = widgetManager
    self.locationManager = locationManager
    self.dataManager = dataManager ?? DataManager(locationManager: locationManager)
    Log.debug("Loaded SpeedometerDependency")

    // Initialize other services here (e.g., OBD, CarPlay) as needed
  }

  // Convenience initializer for testing with mocks
  convenience init(
    widgetManager: WidgetOrganizer,
    dataManager: DataManager,
    locationManager: LocationManager
  ) {
    self.init(
      widgetManager: widgetManager,
      locationManager: locationManager,
      dataManager: dataManager
    )
  }
}
