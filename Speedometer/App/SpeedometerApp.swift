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

    let locationManager = {

#if targetEnvironment(simulator)
      return LocationManager(isSimulating: true)
#else
      if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
        return LocationManager(isSimulating: true)
      } else {
        return LocationManager(isSimulating: false)
      }
#endif
    }()
    self.locationManager = locationManager
    self.dataManager =  DataManager(locationManager: locationManager)
    Log.debug("Loaded SpeedometerDependency")
  }


  var body: some Scene {
    WindowGroup {
      WidgetOrganizerView()
        .environment(\.theme, .bmwLeather)
        .environmentObject(widgetManager)
        .environmentObject(dataManager)
        .environmentObject(locationManager)
    }
  }
}
