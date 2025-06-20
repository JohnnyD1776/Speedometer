//
//  DataPoint.swift
//  Speedometer
//
//  Created by John Durcan on 18/06/2025.
//
import Foundation

// Seismograph-Style Display
// Struct to hold value and time for each data point
struct DataPoint {
  var value: Double // G-force value
  var time: Double  // Time ago (negative, 0 is most recent)
}
