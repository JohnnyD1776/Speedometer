//
//  AddWidgetView.swift
//  Speedometer
//
//  Created by John Durcan on 18/06/2025.
//
import SwiftUI

// Add widget sheet
struct AddWidgetView: View {
  @ObservedObject var viewModel: WidgetOrganizerViewModel
  @Binding var isPresented: Bool
  @State private var selectedType: WidgetType = .speedDial
  @State private var selectedStyle: WidgetStyle = .leather
  @State private var selectedSize: WidgetSize = .small

  var body: some View {
    NavigationView {
      Form {
        Picker("Widget Type", selection: $selectedType) {
          ForEach(WidgetType.allCases, id: \.self) { type in
            Text(type.rawValue.capitalized).tag(type)
          }
        }
        Picker("Style", selection: $selectedStyle) {
          ForEach(WidgetStyle.allCases, id: \.self) { style in
            Text(style.rawValue.capitalized).tag(style)
          }
        }
        Picker("Size", selection: $selectedSize) {
          ForEach(selectedType.supportedSizes, id: \.self) { size in
            Text(size.rawValue.capitalized).tag(size)
          }
        }
      }
      .navigationTitle("Add Widget")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { isPresented = false }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Add") {
            viewModel.addWidget(type: selectedType, style: selectedStyle, size: selectedSize)
            isPresented = false
          }
        }
      }
    }
  }
}
