//
//  Toast.swift
//  Speedometer
//
//  Created by John Durcan on 18/06/2025.
//
import Foundation

// Toast model for user feedback
struct Toast: Identifiable {
  let id = UUID()
  let message: String
  let duration: Double = 2.0
}
