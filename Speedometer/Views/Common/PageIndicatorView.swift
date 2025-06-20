//
//  PageIndicatorView.swift
//  Speedometer
//
//  Created by John Durcan on 21/06/2025.
//



import SwiftUI

/// A view that displays page indicators at the bottom, reflecting the current page with themed colors and accessibility support.
struct PageIndicatorView: View {
  let pageCount: Int
  @Binding var selectedPage: Int
  @Environment(\.theme) private var theme
  @Environment(\.safeAreaInsets) private var safeAreaInsets


  var body: some View {
    HStack(spacing: 8) {
      ForEach(0..<pageCount, id: \.self) { page in
        Circle()
          .fill(page == selectedPage ? theme.primaryColor : theme.secondaryColor)
          .frame(width: 8, height: 8)
          .onTapGesture {
            selectedPage = page
          }
          .accessibilityLabel("Page \(page + 1) of \(pageCount)")
          .accessibilityAddTraits(page == selectedPage ? .isSelected : [])
          .accessibilityAction {
            selectedPage = page
          }
      }
    }
    .padding(8)
    .padding(.bottom, safeAreaInsets.bottom)
    .background(theme.backgroundColor.opacity(0.5))
    .cornerRadius(8)
    .accessibilityElement(children: .contain)
    .accessibilityLabel("Page indicator")
  }
}
