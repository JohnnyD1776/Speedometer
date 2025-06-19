//
//  EnvironmentValues+Extension.swift
//  Speedometer
//
//  Created by John Durcan on 18/06/2025.
//

import SwiftUI


extension EnvironmentValues {
  var theme: Theme {
    get { self[ThemeKey.self] }
    set { self[ThemeKey.self] = newValue }
  }
}

/// Extension to UIApplication to provide access to the key window.
extension UIApplication {
  /// The current key window of the application.
  var keyWindow: UIWindow? {
    connectedScenes
      .compactMap {
        $0 as? UIWindowScene
      }
      .flatMap {
        $0.windows
      }
      .first {
        $0.isKeyWindow
      }
  }
}

/// Environment key to store safe area insets for SwiftUI views.
private struct SafeAreaInsetsKey: EnvironmentKey {
  /// Default value for safe area insets, derived from the key window or empty insets.
  static var defaultValue: EdgeInsets {
    UIApplication.shared.keyWindow?.safeAreaInsets.swiftUiInsets ?? EdgeInsets()
  }
}

/// Extension to EnvironmentValues to provide access to safe area insets.
extension EnvironmentValues {
  /// The safe area insets of the current key window, accessible in SwiftUI.
  ///
  /// Usage:
  /// ```swift
  /// struct MyView: View {
  ///     @Environment(\.safeAreaInsets) private var safeAreaInsets
  ///
  ///     var body: some View {
  ///         Text("Ciao")
  ///             .padding(safeAreaInsets)
  ///     }
  /// }
  /// ```
  var safeAreaInsets: EdgeInsets {
    self[SafeAreaInsetsKey.self]
  }
}

/// Extension to convert UIEdgeInsets to SwiftUI EdgeInsets.
private extension UIEdgeInsets {
  /// Converts UIKit UIEdgeInsets to SwiftUI EdgeInsets.
  var swiftUiInsets: EdgeInsets {
    EdgeInsets(top: top, leading: left, bottom: bottom, trailing: right)
  }
}
