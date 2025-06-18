//
//  GridBackgroundView.swift
//  Speedometer
//
//  Created by John Durcan on 18/06/2025.
//
import SwiftUI

// Grid background
struct GridBackgroundView: View {
  let config: GridConfig

  var body: some View {
    GeometryReader { geometry in
      Path { path in
        for col in 0...config.columns {
          let x = CGFloat(col) * config.cellSize
          path.move(to: CGPoint(x: x, y: 0))
          path.addLine(to: CGPoint(x: x, y: geometry.size.height))
        }
        for row in 0...config.rows {
          let y = CGFloat(row) * config.cellSize
          path.move(to: CGPoint(x: 0, y: y))
          path.addLine(to: CGPoint(x: geometry.size.width, y: y))
        }
      }
      .stroke(Color.gray.opacity(0.2), lineWidth: 1)
    }
  }
}
