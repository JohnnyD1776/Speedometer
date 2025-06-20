//
//  WidgetOrganizerView.swift
//  Speedometer
//
//  Created by John Durcan on 18/06/2025.
//
import SwiftUI

struct WidgetOrganizerView: View {
  @Environment(\.theme) var theme
  @EnvironmentObject var widgetManager: WidgetOrganizer
  @EnvironmentObject var dataManager: DataManager
  @EnvironmentObject var locationManager: LocationManager
  @Environment(\.safeAreaInsets) var safeAreaInsets

  @State var isAddingWidget = false
  @State var selectedPage: Int = 0
  @State var draggedWidget: WidgetComponent?
  @State var dragLocation: CGPoint?

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        tabsView
        draggedWidgetView
        toastView
        navigationView
      }
      .sheet(isPresented: $isAddingWidget) {
        AddWidgetView(isPresented: $isAddingWidget, currentPage: selectedPage)
          .environmentObject(widgetManager)
      }
      .ignoresSafeArea()
      .onChange(of: geometry.size) { newSize in
        Log.debug("Geometry size changed: \(newSize)")
        widgetManager.updateGridConfig(for: newSize)
      }
      .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
        Log.debug("Device orientation changed")
        widgetManager.updateGridConfig(for: geometry.size)
      }
    }
    .onAppear {
      UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
  }
}

struct WidgetOrganizerView_Previews: PreviewProvider {
  static var dependency: SpeedometerDependency = .init()

  static var previews: some View {
    Group {
      WidgetOrganizerView()
        .environment(\.theme, .bmwLeather)
        .environmentObject(dependency.widgetManager)
        .environmentObject(dependency.dataManager)
        .environmentObject(dependency.locationManager)
        .previewDevice("iPhone 14")
        .previewDisplayName("iPhone 14")
      WidgetOrganizerView()
        .environment(\.theme, .racingFlat)
        .environmentObject(dependency.widgetManager)
        .environmentObject(dependency.dataManager)
        .environmentObject(dependency.locationManager)
        .previewDevice("iPad Pro (12.9-inch) (6th generation)")
        .previewDisplayName("iPad Pro")
    }
  }
}
