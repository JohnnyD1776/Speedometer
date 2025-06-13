//
//  GMeter.swift
//  Speedometer
//
//  Created by John Durcan on 13/06/2025.
//

import SwiftUI

// Style protocol for theming
protocol GForceMeterStyle {
  var dotColor: Color { get }
  var tailColor: Color { get }
  var seismographLineColor: Color { get }
  var seismographBackgroundColor: Color { get }
}

// Default theme
struct DefaultGForceMeterStyle: GForceMeterStyle {
  var dotColor: Color = .blue
  var tailColor: Color = .blue.opacity(0.5)
  var seismographLineColor: Color = .green
  var seismographBackgroundColor: Color = .clear
}

// Dark theme
struct DarkGForceMeterStyle: GForceMeterStyle {
  var dotColor: Color = .white
  var tailColor: Color = .white.opacity(0.5)
  var seismographLineColor: Color = .yellow
  var seismographBackgroundColor: Color = .black
}

// G-Force Dot Display
struct GForceDotView: View {
  let style: GForceMeterStyle
  let currentAcceleration: (x: Double, y: Double)
  let history: [(x: Double, y: Double)]
  let xAccelerationRange: ClosedRange<Double>
  let yAccelerationRange: ClosedRange<Double>

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
        (1 - (accY - yMin) / (yMax - yMin)) * height // y increases upwards
      }

      let currentPoint = CGPoint(x: mapX(currentAcceleration.x), y: mapY(currentAcceleration.y))
      let historyPoints = history.map { CGPoint(x: mapX($0.x), y: mapY($0.y)) }

      ZStack {
        if !historyPoints.isEmpty {
          let points = historyPoints + [currentPoint]
          let N = points.count - 1
          ForEach(0..<N, id: \.self) { i in
            let start = points[i]
            let end = points[i + 1]
            let opacity = Double(i + 1) / Double(N)
            Path { path in
              path.move(to: start)
              path.addLine(to: end)
            }
            .stroke(style.tailColor.opacity(opacity), lineWidth: 2)
          }
        }
        Circle()
          .fill(style.dotColor)
          .frame(width: 10, height: 10)
          .position(currentPoint)
      }
    }
  }
}

// Seismograph-Style Display
// Struct to hold value and time for each data point
struct DataPoint {
  var value: Double // G-force value
  var time: Double  // Time ago (negative, 0 is most recent)
}

struct HistoryPath: Shape {
  var dataPoints: [DataPoint]
  let minValue: Double
  let maxValue: Double
  let maxTime: Double
  var timeOffset: Double // Animation offset for smooth scrolling
  var animatedLatestValue: Double // Animated value for the latest point

  func path(in rect: CGRect) -> Path {
    Path { path in
      if dataPoints.count >= 1 {
        var points = dataPoints
        if !points.isEmpty {
          // Update the latest point's value with the animated value
          points[points.count - 1].value = animatedLatestValue
        }

        for (index, point) in points.enumerated() {
          let animatedTime = point.time - timeOffset
          let x = (point.value - minValue) / (maxValue - minValue) * rect.width
          let y = (-animatedTime / maxTime) * rect.height
          if index == 0 {
            path.move(to: CGPoint(x: x, y: y))
          } else {
            path.addLine(to: CGPoint(x: x, y: y))
          }
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

struct SeismographView: View {
  let style: GForceMeterStyle
  let history: [Double] // X acceleration values, most recent last
  let accelerationRange: ClosedRange<Double>
  let timeInterval: Double // Time interval between data points in seconds
  let maxTime: Double // Total time span in seconds for the y-axis

  @State private var dataPoints: [DataPoint] = []
  @State private var timeOffset: Double = 0.0
  @State private var animatedLatestValue: Double = 0.0

  var body: some View {
    VStack {
      GeometryReader { geometry in
        let width = geometry.size.width
        let height = geometry.size.height
        let minValue = accelerationRange.lowerBound
        let maxValue = accelerationRange.upperBound

        ZStack {
          // Background
          Rectangle().fill(style.seismographBackgroundColor)

          // Grid lines
          gridLines(width: width, height: height, minValue: minValue, maxValue: maxValue)

          // X-axis labels at the top
          xAxisLabels(width: width, minValue: minValue, maxValue: maxValue)

          // Y-axis labels on the left (time)
          yAxisLabels(height: height)

          // Vertical lines for normal G-force range (-0.5 and +0.5)
          normalRangeLines(width: width, height: height, minValue: minValue, maxValue: maxValue)

          // History path with smooth scrolling
          HistoryPath(
            dataPoints: dataPoints,
            minValue: minValue,
            maxValue: maxValue,
            maxTime: maxTime,
            timeOffset: timeOffset,
            animatedLatestValue: animatedLatestValue
          )
          .stroke(style.seismographLineColor, lineWidth: 2)

          // Current G-force dot at the top
          if let latest = dataPoints.last {
            let x = (animatedLatestValue - minValue) / (maxValue - minValue) * width
            let y: CGFloat = 0 // Always at the top
            Circle()
              .fill(style.seismographLineColor)
              .frame(width: 10, height: 10)
              .position(x: x, y: y)
          }
        }
      }
      Text("GForce Acceleration")
        .font(.caption)
        .foregroundColor(.black)
    }
    .onChange(of: history) { newHistory in
      updateDataPoints(with: newHistory)
    }
    .onAppear {
      updateDataPoints(with: history, animate: false)
    }
  }

  private func updateDataPoints(with history: [Double], animate: Bool = true) {
    // Convert history to DataPoints with time values
    var newDataPoints = history.enumerated().map { index, value in
      DataPoint(value: value, time: -Double(history.count - 1 - index) * timeInterval)
    }

    // Cap at maxTime
    newDataPoints = newDataPoints.filter { $0.time >= -maxTime }

    if animate && !dataPoints.isEmpty && history.count > dataPoints.count {
      // Determine the previous value for animation
      let previousValue = dataPoints.last?.value ?? newDataPoints[newDataPoints.count - 2].value
      animatedLatestValue = previousValue
      timeOffset = 0.0
      dataPoints = newDataPoints

      withAnimation(.linear(duration: timeInterval)) {
        animatedLatestValue = newDataPoints.last!.value
        timeOffset = timeInterval
      }
    } else {
      // Initial setup or no animation
      dataPoints = newDataPoints
      animatedLatestValue = newDataPoints.last?.value ?? 0.0
      timeOffset = 0.0
    }
  }

  private func gridLines(width: CGFloat, height: CGFloat, minValue: Double, maxValue: Double) -> some View {
    ZStack {
      // Vertical grid lines (G-force)
      ForEach(-3...3, id: \.self) { i in
        let value = Double(i) * 0.5
        if accelerationRange.contains(value) {
          let x = (value - minValue) / (maxValue - minValue) * width
          Path { path in
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: height))
          }
          .stroke(Color.gray.opacity(0.5), lineWidth: 1)
        }
      }

      // Horizontal grid lines (Time)
      ForEach(0...Int(maxTime), id: \.self) { k in
        let time_ago = Double(k)
        let y = (time_ago / maxTime) * height
        Path { path in
          path.move(to: CGPoint(x: 0, y: y))
          path.addLine(to: CGPoint(x: width, y: y))
        }
        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
      }
    }
  }

  private func xAxisLabels(width: CGFloat, minValue: Double, maxValue: Double) -> some View {
    ForEach(-3...3, id: \.self) { i in
      let value = Double(i) * 0.5
      if accelerationRange.contains(value) {
        let x = (value - minValue) / (maxValue - minValue) * width
        Text("\(value, specifier: "%.1f")")
          .font(.caption)
          .position(x: x, y: 10) // Positioned at the top
      }
    }
  }

  private func yAxisLabels(height: CGFloat) -> some View {
    ForEach(1...Int(maxTime), id: \.self) { k in // Start from 1 to avoid overlap with y=0
      let time_ago = Double(k)
      let y = (time_ago / maxTime) * height
      Text("\(time_ago, specifier: "%.0f")s")
        .font(.caption)
        .position(x: 10, y: y) // Positioned on the left
    }
  }

  private func normalRangeLines(width: CGFloat, height: CGFloat, minValue: Double, maxValue: Double) -> some View {
    let x1 = (-0.5 - minValue) / (maxValue - minValue) * width
    let x2 = (0.5 - minValue) / (maxValue - minValue) * width
    return Path { path in
      path.move(to: CGPoint(x: x1, y: 0))
      path.addLine(to: CGPoint(x: x1, y: height))
      path.move(to: CGPoint(x: x2, y: 0))
      path.addLine(to: CGPoint(x: x2, y: height))
    }
    .stroke(style.seismographLineColor, lineWidth: 1)
  }
}

struct DemoView: View {
  @State private var history: [(x: Double, y: Double)] = []
  @State private var phase: Double = 0.0
  let timer = Timer.publish(every: 0.2, on: .main, in: .common).autoconnect()
  let style = DefaultGForceMeterStyle()
  let xRange: ClosedRange<Double> = -3...3
  let yRange: ClosedRange<Double> = -5...5
  let timeInterval: Double = 0.2 // Matches timer interval
  let maxTime: Double = 5    // 10 seconds of history

  var body: some View {
    VStack {
      GForceDotView(
        style: style,
        currentAcceleration: history.last ?? (0, 0),
        history: history.dropLast().suffix(10),
        xAccelerationRange: xRange,
        yAccelerationRange: yRange
      )
      .frame(height: 200)

      SeismographView(
        style: style,
        history: history.map { $0.x }.suffix(Int(maxTime / timeInterval)),
        accelerationRange: xRange,
        timeInterval: timeInterval,
        maxTime: maxTime
      )
      .frame(width: 320, height: 200)
    }
    .onReceive(timer) { _ in
      self.updateData()
    }
  }

  func updateData() {
    let newX = 3 * sin(phase)
    let newY = 3 * cos(phase)
    history.append((newX, newY))
    if history.count > Int(maxTime / timeInterval) {
      history.removeFirst()
    }
    phase += 0.1
  }
}

struct DemoView_Previews: PreviewProvider {
  static var previews: some View {
    DemoView()
  }
}
