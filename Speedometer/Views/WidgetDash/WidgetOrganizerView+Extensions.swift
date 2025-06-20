//
//  WidgetOrganizerView.swift
//  Speedometer
//
//  Created by John Durcan on 18/06/2025.
//
import SwiftUI

extension WidgetOrganizerView {
  var toastView: some View {
    Group{
      if let toast = widgetManager.toast {
        ToastView(message: toast.message)
          .transition(.move(edge: .bottom).combined(with: .opacity))
          .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + toast.duration) {
              widgetManager.toast = nil
            }
          }
      }
    }
  }

  /// Displays the currently Dragged Widget on the screen at the users cursor position.
  var draggedWidgetView: some View {
    Group{
      if let dragged = draggedWidget, let location = dragLocation {
        WidgetView(widget: dragged, isDragging: true)
          .frame(
            width: CGFloat(dragged.size.gridSize.width) * widgetManager.gridConfig.cellSize,
            height: CGFloat(dragged.size.gridSize.height) * widgetManager.gridConfig.cellSize
          )
          .position(location)
          .cornerRadius(theme.widgetCornerRadius)
          .environment(\.theme, dragged.theme?.theme ?? theme)
          .environmentObject(widgetManager)
          .environmentObject(dataManager)
          .environmentObject(locationManager)
      }
      if !widgetManager.isMounted {
        Text("WidgetOrganizer.MountDeviceWarning")
          .foregroundColor(.white)
          .padding()
          .background(Color.red.opacity(0.8))
          .cornerRadius(10)
          .shadow(radius: 5)
          .accessibilityLabel("WidgetOrganizer.MountDeviceWarning.Accessibility")
      }
    }
  }

  /// Main Buttons Overlay
  var navigationView: some View {
    Button(action: { isAddingWidget = true }) {
      Image(systemName: "plus")
    }
    .buttonStyle(.bordered)
    .accessibilityLabel("WidgetOrganizer.Toolbar.Accessibility")
    .padding(.bottom, safeAreaInsets.bottom)
    .padding(.trailing, safeAreaInsets.trailing + 12)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
  }

  /// Present each GridView page as a Tab
  /// Receives a binding for the dragLocaiton, the widget being dragged and the currently selected page
  var tabsView: some View {
    CustomPageView(
      selectedPage: $selectedPage,
      draggedWidget: $draggedWidget,
      dragLocation: $dragLocation
    )
    .environment(\.theme, theme)
  }
}
