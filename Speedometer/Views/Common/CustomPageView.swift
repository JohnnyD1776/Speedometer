//
//  CustomPageView.swift
//  Speedometer
//
//  Created by John Durcan on 21/06/2025.
//
import SwiftUI

struct CustomPageView: View {
  @Environment(\.theme) var theme
  @Binding var selectedPage: Int
  @State private var animatedPage: Double = 0
  @State private var dragOffset: CGFloat = 0
  @EnvironmentObject var widgetManager: WidgetOrganizer
  @EnvironmentObject var dataManager: DataManager
  @EnvironmentObject var locationManager: LocationManager
  @Binding var draggedWidget: WidgetComponent?
  @Binding var dragLocation: CGPoint?
  var animationDuration = 0.3

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        theme.backgroundColor
          .ignoresSafeArea()
        ForEach(0..<widgetManager.pageCount, id: \.self) { page in
          GridView(
            draggedWidget: $draggedWidget,
            dragLocation: $dragLocation,
            selectedPage: $selectedPage,
            page: page
          )
          .ignoresSafeArea()
          .environmentObject(widgetManager)
          .environmentObject(dataManager)
          .environmentObject(locationManager)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .offset(x: (CGFloat(page) - animatedPage) * geometry.size.width + dragOffset)
        }
        PageIndicatorView(pageCount: widgetManager.pageCount, selectedPage: $selectedPage)
          .environment(\.theme, theme)
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
      }
      .gesture(
        DragGesture()
          .onChanged { value in
            dragOffset = value.translation.width
          }
          .onEnded { value in
            let pageWidth = geometry.size.width
            let currentPageOffset = animatedPage - dragOffset / pageWidth
            let predictedPage = animatedPage - value.predictedEndTranslation.width / pageWidth
            let targetPage = max(0, min(widgetManager.pageCount - 1, Int(round(predictedPage))))

            let velocity = abs(value.velocity.width)
            let adjustedDuration = max(0.1, min(animationDuration, 3000 / velocity))

            withAnimation(.spring(response: adjustedDuration, dampingFraction: 0.8)) {
              animatedPage = Double(targetPage)
              selectedPage = targetPage
              dragOffset = 0
            }
          }
      )
    }
    .background(theme.backgroundColor)
    .onChange(of: selectedPage) { newPage in
      withAnimation(.easeInOut(duration: animationDuration)) {
        animatedPage = Double(newPage)
      }
    }
  }
}
