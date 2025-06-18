//
//  WidgetView.swift
//  Speedometer
//
//  Created by John Durcan on 18/06/2025.
//
import SwiftUI

// Widget view (handles content and context menu)
struct WidgetView: View {
  let widget: WidgetComponent
  @ObservedObject var viewModel: WidgetOrganizerViewModel
  let isDragging: Bool

  var body: some View {
    ZStack {
      switch widget.style {
      case .leather: Color.brown.opacity(0.8)
      case .carbonFiber: Color.gray.opacity(0.9)
      case .metallic: Color.gray.opacity(0.7)
      }

      switch widget.type {
      case .speedDial:
        SpeedDialView(speed: 65)
      case .gMeter:
        GMeterView(gForce: 0.8)
      }
    }
    .frame(
      width: CGFloat(widget.size.gridSize.width) * viewModel.gridConfig.cellSize,
      height: CGFloat(widget.size.gridSize.height) * viewModel.gridConfig.cellSize
    )
    .cornerRadius(16)
    .shadow(radius: isDragging ? 10 : 5)
    .overlay(
      RoundedRectangle(cornerRadius: 16)
        .stroke(viewModel.isMounted ? Color.clear : Color.red, lineWidth: 2)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 16)
        .stroke(isDragging && viewModel.isPositionAvailable(for: widget.size, at: widget.position, excluding: widget.id) ? Color.green : Color.clear, lineWidth: 2)
    )
    .scaleEffect(isDragging ? 1.1 : 1.0)
    .animation(.spring(), value: isDragging)
    .contextMenu {
      ForEach(widget.type.supportedSizes, id: \.self) { size in
        Button(size.rawValue.capitalized) {
          viewModel.updateWidgetSize(id: widget.id, size: size)
        }
      }
      Divider()
      Button("Remove", role: .destructive) {
        viewModel.removeWidget(id: widget.id)
      }
    }
    .disabled(isDragging)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(widget.type.rawValue) widget, \(widget.size.rawValue) size")
    .accessibilityAddTraits(isDragging ? .isButton : [])
    .accessibilityHint("Long-press and drag to reposition, or long-press for options")
  }
}
