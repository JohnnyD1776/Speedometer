//
//  HistoryPath.swift
//  Speedometer
//
//  Created by John Durcan on 18/06/2025.
//
import SwiftUI

struct HistoryPath: Shape {
  var dataPoints: [DataPoint]
  let minValue: Double
  let maxValue: Double
  let maxTime: Double
  var timeOffset: Double // Animation offset for smooth scrolling
  var animatedLatestValue: Double // Animated value for the latest point

  func path(in rect: CGRect) -> Path {
    Path { path in
      if dataPoints.count >= 2 {
        var points = dataPoints
        if !points.isEmpty {
          // Update the latest point's value with the animated value
          points[points.count - 1].value = animatedLatestValue
        }

        let N = points.count - 1
        for i in 0..<N {
          let startPoint = points[i]
          let endPoint = points[i + 1]

          let startX = (startPoint.value - minValue) / (maxValue - minValue) * rect.width
          let startY = (-(startPoint.time - timeOffset) / maxTime) * rect.height
          let endX = (endPoint.value - minValue) / (maxValue - minValue) * rect.width
          let endY = (-(endPoint.time - timeOffset) / maxTime) * rect.height

          let opacity = Double(i + 1) / Double(N)

          // Create a subpath for each segment to allow individual styling
          path.addPath(Path { subPath in
            subPath.move(to: CGPoint(x: startX, y: startY))
            subPath.addLine(to: CGPoint(x: endX, y: endY))
          })
        }
      }
    }
  }

  var animatableData: AnimatablePair<Double, Double> {
    get {
      AnimatablePair(timeOffset, animatedLatestValue)
    }
    set {
      timeOffset = newValue.first
      animatedLatestValue = newValue.second
    }
  }
}
