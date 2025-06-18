//
//  GMeter.swift
//  Speedometer
//
//  Created by John Durcan on 13/06/2025.
//

import SwiftUI

struct SeismographView: View {
  @Binding var history: [Double]
  let accelerationRange: ClosedRange<Double>
  let timeInterval: Double
  let maxTime: Double
  let stepSize: Double
  @Environment(\.theme) private var theme
  @State private var dataPoints: [DataPoint] = []
  @State private var timeOffset: Double = 0.0
  @State private var animatedLatestValue: Double = 0.0

  init(history: Binding<[Double]>, accelerationRange: ClosedRange<Double> = -1.0...1.0, timeInterval: Double = 0.1, maxTime: Double = 10, stepSize: Double = 0.5) {
    self._history = history
    self.accelerationRange = accelerationRange
    self.timeInterval = timeInterval
    self.maxTime = maxTime
    self.stepSize = stepSize
  }

  var body: some View {
    VStack {
      GeometryReader { geometry in
        let width = geometry.size.width
        let height = geometry.size.height
        let minValue = accelerationRange.lowerBound
        let maxValue = accelerationRange.upperBound

        ZStack {
          Rectangle().fill(theme.gForceMeterStyle.seismographBackgroundColor)

          gridLines(width: width, height: height, minValue: minValue, maxValue: maxValue)

          xAxisLabels(width: width, minValue: minValue, maxValue: maxValue)

          yAxisLabels(height: height)

          normalRangeLines(width: width, height: height, minValue: minValue, maxValue: maxValue)

          HistoryPath(
            dataPoints: dataPoints,
            minValue: minValue,
            maxValue: maxValue,
            maxTime: maxTime,
            timeOffset: timeOffset,
            animatedLatestValue: animatedLatestValue
          )
          .stroke(theme.gForceMeterStyle.seismographLineColor, lineWidth: 2)

          if let latest = dataPoints.last {
            let x = (animatedLatestValue - minValue) / (maxValue - minValue) * width
            let y: CGFloat = 0
            Circle()
              .fill(theme.gForceMeterStyle.seismographLineColor)
              .frame(width: 10, height: 10)
              .position(x: x, y: y)
          }
        }
      }
      Text("G-Force Acceleration")
        .font(theme.primaryFont)
        .foregroundColor(theme.primaryColor)
        .applyStyle(.text(.caption))
    }
    .applyStyle(.gForceMeter)
    .onChange(of: history) { newHistory in
      updateDataPoints(with: newHistory)
    }
    .onAppear {
      updateDataPoints(with: history, animate: false)
    }
    .accessibilityLabel("Seismograph, latest G-Force \(animatedLatestValue, specifier: "%.1f")")
  }

  private func updateDataPoints(with history: [Double], animate: Bool = true) {
    var newDataPoints = history.enumerated().map { index, value in
      DataPoint(value: value, time: -Double(history.count - 1 - index) * timeInterval)
    }
    newDataPoints = newDataPoints.filter { $0.time >= -maxTime }

    if animate && !dataPoints.isEmpty {
      let previousValue = dataPoints.last?.value ?? newDataPoints[newDataPoints.count - 2].value
      animatedLatestValue = previousValue
      timeOffset = 0.0
      dataPoints = newDataPoints

      withAnimation(.easeInOut) {
        animatedLatestValue = newDataPoints.last!.value
        timeOffset = timeInterval
      }
    } else {
      dataPoints = newDataPoints
      animatedLatestValue = newDataPoints.last?.value ?? 0.0
      timeOffset = 0.0
    }
  }

  private func gridLines(width: CGFloat, height: CGFloat, minValue: Double, maxValue: Double) -> some View {
    ZStack {
      let range = maxValue - minValue
      let steps = Int((maxValue - minValue) / stepSize)
      ForEach(0...steps, id: \.self) { i in
        let value = minValue + Double(i) * stepSize
        if accelerationRange.contains(value) {
          let x = (value - minValue) / (maxValue - minValue) * width
          Path { path in
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: height))
          }
          .stroke(theme.tertiaryColor.opacity(0.5), lineWidth: 1)
        }
      }
      ForEach(0...Int(maxTime), id: \.self) { k in
        let time_ago = Double(k)
        let y = (time_ago / maxTime) * height
        Path { path in
          path.move(to: CGPoint(x: 0, y: y))
          path.addLine(to: CGPoint(x: width, y: y))
        }
        .stroke(theme.tertiaryColor.opacity(0.5), lineWidth: 1)
      }
    }
  }

  private func xAxisLabels(width: CGFloat, minValue: Double, maxValue: Double) -> some View {
    let range = maxValue - minValue
    let steps = Int((maxValue - minValue) / stepSize) - 1
    return Group {
      ForEach(1...steps, id: \.self) { i in
        let value = minValue + Double(i) * stepSize
        if accelerationRange.contains(value) {
          let x = (value - minValue) / (maxValue - minValue) * width
          Text("\(value, specifier: "%.1f")")
            .font(theme.primaryFont)
            .foregroundColor(theme.secondaryColor)
            .applyStyle(.text(.caption))
            .position(x: x, y: 10)
        }
      }
    }
  }

  private func yAxisLabels(height: CGFloat) -> some View {
    ForEach(1...Int(maxTime), id: \.self) { k in
      let time_ago = Double(k)
      let y = (time_ago / maxTime) * height
      Text("\(time_ago, specifier: "%.0f")s")
        .font(theme.primaryFont)
        .foregroundColor(theme.secondaryColor)
        .applyStyle(.text(.caption))
        .position(x: 10, y: y)
    }
  }

  private func normalRangeLines(width: CGFloat, height: CGFloat, minValue: Double, maxValue: Double) -> some View {
    let x1 = (-stepSize - minValue) / (maxValue - minValue) * width
    let x2 = (stepSize - minValue) / (maxValue - minValue) * width
    return Path { path in
      path.move(to: CGPoint(x: x1, y: 0))
      path.addLine(to: CGPoint(x: x1, y: height))
      path.move(to: CGPoint(x: x2, y: 0))
      path.addLine(to: CGPoint(x: x2, y: height))
    }
    .stroke(theme.gForceMeterStyle.seismographLineColor, lineWidth: 1)
  }
}
