//
//  WidgetOrganizerView.swift
//  Speedometer
//
//  Created by John Durcan on 18/06/2025.
//
import SwiftUI

struct WidgetOrganizerView: View {
  @EnvironmentObject private var widgetManager: WidgetOrganizer
  @EnvironmentObject private var dataManager: DataManager
  @EnvironmentObject private var locationManager: LocationManager

  @State private var isAddingWidget = false
  @State private var selectedPage: Int = 0

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        tabsView
        if !widgetManager.isMounted {
          Text("WidgetOrganizer.MountDeviceWarning")
            .foregroundColor(.white)
            .padding()
            .background(Color.red.opacity(0.8))
            .cornerRadius(10)
            .shadow(radius: 5)
            .accessibilityLabel("WidgetOrganizer.MountDeviceWarning.Accessibility")
        }

        if let toast = widgetManager.toast {
          ToastView(message: toast.message)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .onAppear {
              DispatchQueue.main.asyncAfter(deadline: .now() + toast.duration) {
                widgetManager.toast = nil
              }
            }
        }
        headerView
      }
      .sheet(isPresented: $isAddingWidget) {
        AddWidgetView(isPresented: $isAddingWidget)
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

  var headerView: some View {
      Button(action: { isAddingWidget = true }) {
        Image(systemName: "plus")
      }
      .accessibilityLabel("WidgetOrganizer.Toolbar.Accessibility")
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
      .padding(24)
    }

  var tabsView: some View {
    TabView(selection: $selectedPage) {
      ForEach(0..<widgetManager.pageCount, id: \.self) { page in
        GridView(
          selectedPage: $selectedPage,
          page: page
        )
        .ignoresSafeArea()
        .environmentObject(widgetManager)
        .environmentObject(dataManager)
        .environmentObject(locationManager)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .tag(page)
      }
    }
    .tabViewStyle(.page)
    .indexViewStyle(.page(backgroundDisplayMode: .always))
    .animation(.easeInOut, value: selectedPage)
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
