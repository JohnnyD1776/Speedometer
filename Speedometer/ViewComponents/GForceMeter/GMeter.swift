//
//  GMeter.swift
//  Speedometer
//
//  Created by John Durcan on 13/06/2025.
//

import SwiftUI

// G-Force Dot Display
struct GForceDotView: View {
  let style: GForceMeterStyle
  let currentAcceleration: CGPoint
  let history: [CGPoint]
  let xAccelerationRange: ClosedRange<Double>
  let yAccelerationRange: ClosedRange<Double>

  // State for animatable current point
  @State private var animatedPoint: CGPoint = .zero

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
            .stroke(style.tailColor.opacity(opacity), lineWidth: 2)
          }
        }
        Circle()
          .fill(style.dotColor)
          .frame(width: 10, height: 10)
          .position(animatedPoint)
      }
      .onChange(of: currentAcceleration) {  newValue in
        // Animate to the new target point
        withAnimation(.easeInOut(duration: 0.2)) {
          animatedPoint = CGPoint(x: mapX(newValue.x), y: mapY(newValue.y))
        }
      }
      .onAppear {
        // Initialize animatedPoint on first render
        animatedPoint = targetPoint
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

struct SeismographView: View {
  let style: GForceMeterStyle
  @Binding var history: [Double] // X acceleration values, most recent last
  let accelerationRange: ClosedRange<Double>
  let timeInterval: Double // Time interval between data points in seconds
  let maxTime: Double  // Total time span in seconds for the y-axis
  let stepSize: Double
  @State private var dataPoints: [DataPoint] = []
  @State private var timeOffset: Double = 0.0
  @State private var animatedLatestValue: Double = 0.0

  init(style: GForceMeterStyle, history: Binding<[Double]>, accelerationRange: ClosedRange<Double> = -1.0...1.0, timeInterval: Double = 0.1, maxTime: Double = 10, stepSize: Double = 0.5) {
    self.style = style
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

    if animate && !dataPoints.isEmpty {
      // Determine the previous value for animation
      let previousValue = dataPoints.last?.value ?? newDataPoints[newDataPoints.count - 2].value
      animatedLatestValue = previousValue
      timeOffset = 0.0
      dataPoints = newDataPoints

      withAnimation(.easeInOut) {
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
          .stroke(Color.gray.opacity(0.5), lineWidth: 1)
        }
      }

      // Horizontal grid lines (Time) - unchanged
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
    let range = maxValue - minValue
    let steps = Int((maxValue - minValue) / stepSize) - 1
    return Group {
      ForEach(1...steps, id: \.self) { i in
        let value = minValue + Double(i) * stepSize
        if accelerationRange.contains(value) {
          let x = (value - minValue) / (maxValue - minValue) * width
          Text("\(value, specifier: "%.1f")")
            .font(.caption)
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
        .font(.caption)
        .position(x: 10, y: y) // Positioned on the left
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
    .stroke(style.seismographLineColor, lineWidth: 1)
  }
}

struct DemoView: View {
  @State private var history: [CGPoint] = []
  @State private var xHistory: [Double] = [] // New state for x values
  @State private var phase: Double = 0.0
  let timer = Timer.publish(every: 0.2, on: .main, in: .common).autoconnect()
  let style = DefaultGForceMeterStyle()
  let xRange: ClosedRange<Double> = -3...3
  let yRange: ClosedRange<Double> = -5...5
  let timeInterval: Double = 0.2 // Matches timer interval
  let maxTime: Double = 5    // 10 seconds of history

  var body: some View {
    VStack {
//      GForceDotView(
//        style: style,
//        currentAcceleration: history.last ?? CGPoint.zero,
//        history: history.dropLast().suffix(10),
//        xAccelerationRange: xRange,
//        yAccelerationRange: yRange
//      )
//      .frame(height: 200)

      SeismographView(
        style: style,
        history: $xHistory,
        accelerationRange: xRange,
        timeInterval: timeInterval,
        maxTime: maxTime
      )
      .frame(width: 320, height: 300)
    }
    .onReceive(timer) { _ in
      self.updateData()
    }
  }

  func updateData() {
    let newX = 3 * sin(phase) // Double value
    let newY = 3 * cos(phase) // Double value
    history.append(CGPoint(x: newX, y: newY)) // CGPoint converts Double to CGFloat
    xHistory.append(newX) // Store as Double

    let maxPoints = Int(maxTime / timeInterval) // e.g., 25 points
    if history.count > maxPoints {
      history.removeFirst()
    }
    if xHistory.count > maxPoints {
      xHistory.removeFirst()
    }
    phase += 0.1
  }
}

struct DemoView_Previews: PreviewProvider {
  static var previews: some View {
    DemoView()
  }
}
