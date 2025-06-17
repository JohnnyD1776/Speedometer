//
//  TelemetryDataPoint.swift
//  Speedometer
//
//  Created by John Durcan on 17/06/2025.
//

import Foundation

struct TelemetryDataPoint: Codable {
  let timestamp: Date
  let speed: Double
  let gforceX: Double
  let gforceY: Double
  let gforceZ: Double
}
