//
//  Double+Extension.swift
//  Speedometer
//
//  Created by John Durcan on 03/06/2025.
//
import Foundation

extension Double {
  /// Rounds the double to decimal places value
  func rounded(toPlaces places:Int) -> Double {
    let divisor = pow(10.0, Double(places))
    return (self * divisor).rounded() / divisor
  }
}
