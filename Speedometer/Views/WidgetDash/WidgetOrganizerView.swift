//
//  WidgetOrganizerView.swift
//  Speedometer
//
//  Created by John Durcan on 18/06/2025.
//
import SwiftUI

// Main organizer view
struct WidgetOrganizerView: View {
  @StateObject private var viewModel = WidgetOrganizerViewModel()
  @State private var isAddingWidget = false
  @State private var selectedWidgetType: WidgetType = .speedDial
  @State private var selectedStyle: WidgetStyle = .leather
  @State private var draggedWidget: WidgetComponent?
  @State private var selectedPage: Int = 0

  var body: some View {
    NavigationView {
      ZStack {
        Color(.systemBackground).ignoresSafeArea()

        TabView(selection: $selectedPage) {
          ForEach(0..<viewModel.pageCount, id: \.self) { page in
            GridView(page: page, viewModel: viewModel, draggedWidget: $draggedWidget, selectedPage: $selectedPage)
              .frame(maxWidth: .infinity, maxHeight: .infinity)
              .tag(page)
          }
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .animation(.easeInOut, value: selectedPage)

        if !viewModel.isMounted {
          Text("WidgetOrganizer.MountDeviceWarning")
            .foregroundColor(.white)
            .padding()
            .background(Color.red.opacity(0.8))
            .cornerRadius(10)
            .shadow(radius: 5)
            .accessibilityLabel("WidgetOrganizer.MountDeviceWarning.Accessibility")
        }

        if let toast = viewModel.toast {
          ToastView(message: toast.message)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .onAppear {
              DispatchQueue.main.asyncAfter(deadline: .now() + toast.duration) {
                viewModel.toast = nil
              }
            }
        }
      }
      .navigationTitle("WidgetOrganizer.Title")
      .toolbar {
        Button(action: { isAddingWidget = true }) {
          Image(systemName: "plus")
        }
        .accessibilityLabel("WidgetOrganizer.Toolbar.Accessibility")
      }
      .sheet(isPresented: $isAddingWidget) {
        AddWidgetView(viewModel: viewModel, isPresented: $isAddingWidget)
      }
    }
    .onAppear {
      UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
  }
}

struct WidgetOrganizerView_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      WidgetOrganizerView()
        .previewDevice("iPhone 14")
        .previewDisplayName("iPhone 14")
      WidgetOrganizerView()
        .previewDevice("iPad Pro (12.9-inch) (6th generation)")
        .previewDisplayName("iPad Pro")
    }
  }
}
