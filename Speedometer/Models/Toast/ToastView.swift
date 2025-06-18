//
//  ToastView.swift
//  Speedometer
//
//  Created by John Durcan on 18/06/2025.
//
import SwiftUI

// Toast view
struct ToastView: View {
  let message: String

  var body: some View {
    Text(message)
      .foregroundColor(.white)
      .padding()
      .background(Color.black.opacity(0.8))
      .cornerRadius(10)
      .shadow(radius: 5)
      .padding(.bottom, 50)
      .accessibilityLabel("Notification: \(message)")
  }
}
