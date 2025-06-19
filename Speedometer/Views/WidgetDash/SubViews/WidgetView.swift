//
//  WidgetView.swift
//  Speedometer
//
//  Created by John Durcan on 18/06/2025.
//
import SwiftUI

struct WidgetView: View {
  let widget: WidgetComponent
  let isDragging: Bool
  @Environment(\.theme) private var globalTheme
  @EnvironmentObject private var widgetManager: WidgetOrganizer
  @EnvironmentObject private var dataManager: DataManager
  @EnvironmentObject private var locationManager: LocationManager

  private var theme: Theme {
    widget.theme?.theme ?? globalTheme
  }

  private var widgetTheme: ViewStyleConfiguration {
    theme.style(for: .container(.widget))
  }

  private var history: [CGPoint] {
    locationManager.telemetryHistory.compactMap { CGPoint(x: $0.gforceX, y: $0.gforceY) }
  }

  var body: some View {
    ZStack {
      Color.clear
        .environment(\.theme, theme)

      switch widget.type {
      case .gForceDot:
        GForceDotView(currentAcceleration: history.last ?? .zero, history: history)
          .environment(\.theme, theme)
      case .speedometer:
        Speedometer(
          speedAngle: dataManager.speedAngle,
          displayedSpeed: $dataManager.displayedSpeed,
          type: $dataManager.type,
          targetSpeed: $dataManager.targetSpeed,
          topSpeed: $dataManager.topSpeed
        )
        .environment(\.theme, theme)
      case .speedGauge:
        SpeedGauge(
          current: $dataManager.displayedSpeed,
          topValue: $dataManager.topSpeed,
          maxValue: $dataManager.maxSpeed
        )
        .environment(\.theme, theme)
      case .seismograph:
        SeismographView(
          history: $dataManager.history,
          accelerationRange: -2.0...2.0,
          timeInterval: 0.1,
          maxTime: 10,
          stepSize: 0.5
        )
        .environment(\.theme, theme)
      case .unitToggle:
        UnitDisplayToggle(type: $dataManager.type)
          .environment(\.theme, theme)
      }
    }
    .padding(widgetTheme.padding)
    .frame(
      width: CGFloat(widget.size.gridSize.width) * widgetManager.gridConfig.cellSize,
      height: CGFloat(widget.size.gridSize.height) * widgetManager.gridConfig.cellSize
    )
    .cornerRadius(widgetTheme.cornerRadius)
    .shadow(radius: isDragging ? widgetTheme.cornerRadius * 2 : widgetTheme.cornerRadius)
    .overlay(
      RoundedRectangle(cornerRadius: widgetTheme.cornerRadius)
        .stroke(widgetManager.isMounted ? Color.clear : widgetTheme.accentColor, lineWidth: 2)
    )
    .overlay(
      RoundedRectangle(cornerRadius: widgetTheme.cornerRadius)
        .stroke(isDragging && widgetManager.isPositionAvailable(for: widget.size, at: widget.position, excluding: widget.id) ? widgetTheme.backgroundColor : Color.clear, lineWidth: 2)
    )
    .scaleEffect(isDragging ? 1.1 : 1.0)
    .animation(.spring(), value: isDragging)
    .contextMenu {
      ForEach(widget.type.supportedSizes, id: \.self) { size in
        Button(size.rawValue.capitalized) {
          widgetManager.updateWidgetSize(id: widget.id, size: size)
        }
      }
      Divider()
      Button("Remove", role: .destructive) {
        widgetManager.removeWidget(id: widget.id)
      }
    }
    .disabled(isDragging)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(widget.type.rawValue.capitalized) widget, \(widget.size.rawValue) size")
    .accessibilityAddTraits(isDragging ? .isButton : [])
    .accessibilityHint("Long-press and drag to reposition, or long-press for options")
    .id(widget.id) // Ensure unique view identity
  }
}
