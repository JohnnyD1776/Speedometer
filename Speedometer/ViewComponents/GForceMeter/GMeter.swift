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
struct SeismographView: View {
  let style: GForceMeterStyle
  let history: [Double] // X acceleration values, most recent last
  let accelerationRange: ClosedRange<Double>
  let timeInterval: Double = 0.3
  let maxTime: Double = 5.0

  @State private var animatedHistory: [Double] = []

  var body: some View {
    VStack {
      GeometryReader { geometry in
        let width = geometry.size.width
        let height = geometry.size.height
        let minValue = accelerationRange.lowerBound
        let maxValue = accelerationRange.upperBound
        let M = animatedHistory.count

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

          // History path (excluding the most recent point)
          historyPath(width: width, height: height, minValue: minValue, maxValue: maxValue, M: M)

          // Current G-force dot at the top
          if M >= 1 {
            let currentValue = animatedHistory.last!
            let x = (currentValue - minValue) / (maxValue - minValue) * width
            let y: CGFloat = 0
            Circle()
              .fill(style.seismographLineColor)
              .frame(width: 10, height: 10)
              .position(x: x, y: y)
          }
        }
      }
      Text("Cornering G")
        .font(.caption)
        .foregroundColor(.black)
    }
    .onChange(of: history) { newHistory in
      withAnimation(.linear(duration: timeInterval)) {
        animatedHistory = newHistory
      }
    }
    .onAppear {
      animatedHistory = history
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
    .stroke(Color.gray, lineWidth: 1)
  }
  private func historyPath(width: CGFloat, height: CGFloat, minValue: Double, maxValue: Double, M: Int) -> some View {
    Path { path in
      if M >= 2 {
        for (index, value) in animatedHistory.dropLast(1).enumerated() { // Exclude the most recent point
          let time_ago = Double(M - 1 - index) * timeInterval
          let y = min((time_ago / maxTime) * height, height)
          let x = (value - minValue) / (maxValue - minValue) * width
          if index == 0 {
            path.move(to: CGPoint(x: x, y: y))
          } else {
            path.addLine(to: CGPoint(x: x, y: y))
          }
        }
      }
    }
    .stroke(style.seismographLineColor, lineWidth: 2)
  }
}

//struct SeismographView: View {
//  let style: GForceMeterStyle
//  let history: [Double] // X acceleration values, most recent last
//  let accelerationRange: ClosedRange<Double>
//  let timeInterval: Double = 0.3
//  let maxTime: Double = 5
//
//  @State private var animatedHistory: [Double] = []
//
//  var body: some View {
//    VStack {
//      GeometryReader { geometry in
//        let width = geometry.size.width
//        let height = geometry.size.height
//        let minValue = accelerationRange.lowerBound
//        let maxValue = accelerationRange.upperBound
//        let M = animatedHistory.count
//
//        ZStack {
//          // Background
//          Rectangle().fill(style.seismographBackgroundColor)
//
//          // Grid lines and labels
//          gridLines(width: width, height: height, minValue: minValue, maxValue: maxValue)
//
//          // Vertical lines for normal G-force range (-0.5 and +0.5)
//          let x1 = (-0.5 - minValue) / (maxValue - minValue) * width
//          let x2 = (0.5 - minValue) / (maxValue - minValue) * width
//          Path { path in
//            path.move(to: CGPoint(x: x1, y: 0))
//            path.addLine(to: CGPoint(x: x1, y: height))
//            path.move(to: CGPoint(x: x2, y: 0))
//            path.addLine(to: CGPoint(x: x2, y: height))
//          }
//          .stroke(style.seismographLineColor, lineWidth: 1)
//
//          // History path (trailing G-force history)
//          if M >= 2 {
//            Path { path in
//              for (index, value) in animatedHistory.enumerated() {
//                let x = (value - minValue) / (maxValue - minValue) * width
//                let y = (1 - Double(index) / Double(M - 1)) * height
//                if index == 0 {
//                  path.move(to: CGPoint(x: x, y: y))
//                } else {
//                  path.addLine(to: CGPoint(x: x, y: y))
//                }
//              }
//            }
//            .stroke(style.seismographLineColor, lineWidth: 2)
//          }
//
//          // Current G-force dot (at the top)
//          if M >= 1 {
//            let currentValue = animatedHistory.last!
//            let x = (currentValue - minValue) / (maxValue - minValue) * width
//            let y: CGFloat = 0
//            Circle()
//              .fill(style.seismographLineColor)
//              .frame(width: 10, height: 10)
//              .position(x: x, y: y)
//          }
//        }
//      }
//      // Title at the bottom
//      Text("Cornering G")
//        .font(.caption)
//        .foregroundColor(.black)
//    }
//    .onChange(of: history) { newHistory in
//      withAnimation(.linear(duration: timeInterval)) {
//        animatedHistory = newHistory
//      }
//    }
//    .onAppear {
//      animatedHistory = history
//    }
//  }
//
//  private func gridLines(width: CGFloat, height: CGFloat, minValue: Double, maxValue: Double) -> some View {
//    let gForceStep = 0.5 // G-force interval for vertical lines
//    let timeStep = 1.0  // Time interval for horizontal lines (1 second)
//
//    return ZStack {
//      // Vertical grid lines (G-force)
//      ForEach(-3...3, id: \.self) { i in
//        let value = Double(i) * gForceStep
//        if accelerationRange.contains(value) {
//          let x = (value - minValue) / (maxValue - minValue) * width
//          Path { path in
//            path.move(to: CGPoint(x: x, y: 0))
//            path.addLine(to: CGPoint(x: x, y: height))
//          }
//          .stroke(Color.gray.opacity(0.5), lineWidth: 1)
//          Text("\(value, specifier: "%.1f")")
//            .font(.caption)
//            .position(x: x, y: height + 10)
//        }
//      }
//
//      // Horizontal grid lines (Time)
//      ForEach(0..<Int(maxTime / timeStep), id: \.self) { i in
//        let time = Double(i) * timeStep
//        let y = (1 - time / maxTime) * height
//        Path { path in
//          path.move(to: CGPoint(x: 0, y: y))
//          path.addLine(to: CGPoint(x: width, y: y))
//        }
//        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
//        Text("\(time, specifier: "%.0f")s")
//          .font(.caption)
//          .position(x: -10, y: y)
//      }
//    }
//  }
//}


struct DemoView: View {
  @State private var history: [(x: Double, y: Double)] = []
  @State private var phase: Double = 0.0
  let timer = Timer.publish(every: 0.2, on: .main, in: .common).autoconnect()
  let style = DefaultGForceMeterStyle()
  let xRange: ClosedRange<Double> = -5...5
  let yRange: ClosedRange<Double> = -5...5

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
        history: history.map { $0.x }.suffix(50),
        accelerationRange: xRange
      )
      .frame(height: 100)
    }
    .onReceive(timer) { _ in
      self.updateData()
    }
  }

  func updateData() {
    let newX = 3 * sin(phase)
    let newY = 3 * cos(phase)
    history.append((newX, newY))
    if history.count > 50 {
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
