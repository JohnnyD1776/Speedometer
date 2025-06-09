//
//  DashboardViewModel.swift
//  Speedometer
//
//  Created by John Durcan on 04/06/2025.
//

import SwiftUI
import Combine

class DashbordViewModel: ObservableObject {
  @Published var displayedSpeed: Double = 0.0
  @Published var targetSpeed: Double = 0.0
  @Published var startSpeed: Double = 0.0
  @Published var startTime: Date = Date()
  @Published var maxSpeed: Double = 155.0
  @Published var topSpeed: Double = 175.0
  @Published var type: SpeedType = .mph
  @Published var animationDuration: Double = 0.0
  let maxRateOfChange: Double = 10.0
  let baseTopSpeed: Double = 175.0 // Base value in MPH

  init() {

  }
  
}
