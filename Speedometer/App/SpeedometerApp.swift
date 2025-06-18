//
//  SpeedometerApp.swift
//  Speedometer
//
//  Created by John Durcan on 03/06/2025.
//

import SwiftUI

@main
struct SpeedometerApp: App {
  @ObservedObject var widgetManager: WidgetOrganizer
  @ObservedObject var dataManager: DataManager
  @ObservedObject var locationManager: LocationManager

  init() {
    self.widgetManager = .init()

#if DEBUG
    let locationManager = LocationManager(isSimulating: true)
#else
    let locationManager = LocationManager(isSimulating: false)
#endif
    self.locationManager = locationManager
    self.dataManager =  DataManager(locationManager: locationManager)
    Log.debug("Loaded SpeedometerDependency")
  }


  var body: some Scene {
    WindowGroup {
      WidgetOrganizerView()
        .environmentObject(widgetManager)
        .environmentObject(dataManager)
        .environmentObject(locationManager)
    }
  }
}
