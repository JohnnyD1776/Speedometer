//
//  GForceDotView.swift
//  Speedometer
//
//  Created by John Durcan on 18/06/2025.
//

import SwiftUI

// G-Force Dot Display
struct GForceDotView: View {
  let currentAcceleration: CGPoint
  let history: [CGPoint]
  let xAccelerationRange: ClosedRange<Double>
  let yAccelerationRange: ClosedRange<Double>
  @Environment(\.theme) private var theme
  @State private var animatedPoint: CGPoint = .zero

  private var widgetTheme: ViewStyleConfiguration {
    theme.style(for: .container(.widget))
  }



  init(currentAcceleration: CGPoint, history: [CGPoint] = [], xAccelerationRange: ClosedRange<Double> = -3.0...3.0, yAccelerationRange: ClosedRange<Double> = -5.0...5.0) {
    self.currentAcceleration = currentAcceleration
    self.history = history
    self.xAccelerationRange = xAccelerationRange
    self.yAccelerationRange = yAccelerationRange
  }

  var body: some View {
    GeometryReader { geometry in
      let width = geometry.size.width
      let height = geometry.size.height
      let xMin = xAccelerationRange.lowerBound
      let xMax = xAccelerationRange.upperBound
      let yMin = yAccelerationRange.lowerBound
      let yMax = yAccelerationRange.upperBound

      let mapX: (Double) -> Double = { accX in
        (accX - xMin) / (xMax - xMin) * width
      }
      let mapY: (Double) -> Double = { accY in
        (1 - (accY - yMin) / (yMax - yMin)) * height
      }

      let targetPoint = CGPoint(x: mapX(currentAcceleration.x), y: mapY(currentAcceleration.y))
      let historyPoints = history.map { CGPoint(x: mapX($0.x), y: mapY($0.y)) }

      ZStack {
        if !historyPoints.isEmpty {
          let points = historyPoints + [animatedPoint]
          let N = points.count - 1
          ForEach(0..<N, id: \.self) { i in
            let start = points[i]
            let end = points[i + 1]
            let opacity = Double(i + 1) / Double(N)
            Path { path in
              path.move(to: start)
              path.addLine(to: end)
            }
            .stroke(theme.gForceMeterStyle.tailColor.opacity(opacity), lineWidth: 2)
          }
        }
        Circle()
          .fill(theme.gForceMeterStyle.dotColor)
          .frame(width: 10, height: 10)
          .position(animatedPoint)
      }
      .applyStyle(.gForceMeter)
      .onChange(of: currentAcceleration) { newValue in
        withAnimation(.easeInOut(duration: 0.2)) {
          animatedPoint = CGPoint(x: mapX(newValue.x), y: mapY(newValue.y))
        }
      }
      .onAppear {
        animatedPoint = targetPoint
      }
      .accessibilityLabel("G-Force Dot, current acceleration \(currentAcceleration.x, specifier: "%.1f") X, \(currentAcceleration.y, specifier: "%.1f") Y")
    }
  }
}
