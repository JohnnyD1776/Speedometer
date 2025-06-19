//
//  GridBackgroundView.swift
//  Speedometer
//
//  Created by John Durcan on 18/06/2025.
//
import SwiftUI

struct GridBackgroundView: View {
  let config: GridConfig
  @Environment(\.theme) private var theme

  var body: some View {
    GeometryReader { geometry in
      Path { path in
        let width = min(geometry.size.width, CGFloat(config.columns) * config.cellSize)
        let height = min(geometry.size.height, CGFloat(config.rows) * config.cellSize)

        // Draw vertical lines
        for col in 0...config.columns {
          let x = CGFloat(col) * config.cellSize
          if x <= width {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: height))
          }
        }
        // Draw horizontal lines
        for row in 0...config.rows {
          let y = CGFloat(row) * config.cellSize
          if y <= height {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: width, y: y))
          }
        }
      }
      .stroke(theme.tertiaryColor.opacity(0.2), lineWidth: 1)
      .clipped() // Ensure lines don't extend beyond view
    }
  }
}
