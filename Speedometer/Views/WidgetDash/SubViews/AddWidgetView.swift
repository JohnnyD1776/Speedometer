//
//  AddWidgetView.swift
//  Speedometer
//
//  Created by John Durcan on 18/06/2025.
//
import SwiftUI

// Add widget sheet
import SwiftUI

struct AddWidgetView: View {
  @EnvironmentObject private var dependency: SpeedometerDependency
  @Binding var isPresented: Bool
  @State private var selectedType: WidgetType = .speedGauge
  @State private var selectedSize: WidgetSize = .small
  @State private var selectedTheme: WidgetTheme? = nil

  var body: some View {
    NavigationView {
      Form {
        Picker("Widget Type", selection: $selectedType) {
          ForEach(WidgetType.allCases, id: \.self) { type in
            Text(type.rawValue.capitalized).tag(type)
          }
        }
        .accessibilityLabel("Select widget type")

        Picker("Size", selection: $selectedSize) {
          ForEach(selectedType.supportedSizes, id: \.self) { size in
            Text(size.rawValue.capitalized).tag(size)
          }
        }
        .accessibilityLabel("Select widget size")

        Picker("Theme", selection: $selectedTheme) {
          Text("App Default").tag(WidgetTheme?.none)
          ForEach(WidgetTheme.allCases, id: \.self) { theme in
            Text(theme.rawValue.capitalized).tag(WidgetTheme?.some(theme))
          }
        }
        .accessibilityLabel("Select widget theme")
      }
      .navigationTitle("Add Widget")
      .onChange(of: selectedType) { newType in
        if !newType.supportedSizes.contains(selectedSize) {
          selectedSize = newType.supportedSizes.first ?? .small // Fallback to .small if no sizes available
        }
      }
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { isPresented = false }
            .accessibilityLabel("Cancel adding widget")
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Add") {
            dependency.widgetManager.addWidget(
              type: selectedType,
              size: selectedSize,
              theme: selectedTheme
            )
            isPresented = false
          }
          .accessibilityLabel("Add widget")
        }
      }
    }
  }
}
