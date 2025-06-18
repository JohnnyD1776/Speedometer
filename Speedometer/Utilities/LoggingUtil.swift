//
//  LoggingUtil.swift
//  Speedometer
//
//  Created by John Durcan on 17/06/2025.
//

import Foundation
import OSLog

/// Logging Detail Levels:
///   - Log messages can individually include a `detail` parameter to indicate the level of verbosity.
///     The `currentDetailLevel` property sets the minimum detail level to log. Messages with a lower detail level will not be shown.
///   - To interactively Adjust Debug Level, set app breakpoint on currentDetailLevel and in debugger window: `expr LogConfig.currentDetailLevel = 2`
enum LogConfig {
  private static let config: [String: Any] = {
    guard let path = Bundle.main.path(forResource: "LocalConfig", ofType: "plist"),
          let config = NSDictionary(contentsOfFile: path) as? [String: Any] else {
      assertionFailure("Failed to load LocalConfig.plist")
      return [:]
    }
    return config
  }()

  static var currentDetailLevel: LogLevel = {
    if let detailLevel = config["LOG_DETAIL_LEVEL"] as? Int, let logLevel = LogLevel(rawValue: detailLevel) {
      return logLevel
    } else if config["LOG_DETAIL_LEVEL"] != nil {
      assertionFailure("Invalid LOG_DETAIL_LEVEL: \(String(describing: config["LOG_DETAIL_LEVEL"]))")
    }
    return .debug
  }()

  static var disablePrefix: Bool = {
    if let value = config["LOG_DISABLE_PREFIX"] as? Bool {
      return value
    } else if config["LOG_DISABLE_PREFIX"] != nil {
      assertionFailure("Invalid LOG_DISABLE_PREFIX: \(String(describing: config["LOG_DISABLE_PREFIX"]))")
    }
    return false
  }()

  static var showContextByDefault: Bool = {
    if let value = config["LOG_SHOW_CONTEXT"] as? Bool {
      return value
    } else if config["LOG_SHOW_CONTEXT"] != nil {
      assertionFailure("Invalid LOG_SHOW_CONTEXT: \(String(describing: config["LOG_SHOW_CONTEXT"]))")
    }
    return true
  }()

  static var categoryDetailLevels: [String: Int] = {
    var levels: [String: Int] = [
      "mainView": LogLevel.error.rawValue,
      "otherView": LogLevel.error.rawValue,
      "networkmonitor": LogLevel.error.rawValue
    ]
    if let loggingCategories = config["FILE_LOG_LEVEL"] as? [String: Any] {
      for (category, level) in loggingCategories {
        if let intLevel = level as? Int, LogLevel(rawValue: intLevel) != nil {
          levels[category.lowercased()] = intLevel
        } else {
          assertionFailure("Invalid log level for category '\(category)': \(level)")
        }
      }
    }
    return levels
  }()
}

/// Enumerations:
///   - `LogLevel`: Defines log levels with custom emoji prefixes, providing a way to categorize logs.
///     - `.debug` (DEBUG 🛠️): For detailed debug information.
///     - `.info` (INFO 🧠): For informational messages.
///     - `.warning` (WARN ⚠️): For warning messages.
///     - `.error` (ERROR ❌): For error messages.

enum LogLevel: Int, CaseIterable {
  case debug = 0
  case info = 1
  case warning = 2
  case error = 3

  var prefix: String {
    switch self {
    case .debug: return "DEBUG 🛠️"
    case .info: return "INFO 🧠"
    case .warning: return "WARN ⚠️"
    case .error: return "ERROR ❌"
    }
  }
}


/// `Log` - A comprehensive and flexible logging utility in Swift.

/// Example Usages:
///   - `Log.info("User logged in")`: Logs an informational message.
///   - `Log.warning("Low memory warning", detail: 2)`: Logs a warning with a specific detail level.
///   - `Log.error("Failed to load resource", detail: 3)`: Logs an error with the highest detail level.
///   - `Log.debug("Detailed debug info", detail: 0)`: Logs a detailed debug message, depending on the current detail threshold.
///   - `Log.info("Details", shouldLogContext: false)`: Logs an informational message without including the file, function, or line context.
enum Log {

  struct Context {
    let file: String
    let function: String
    let line: Int

    var description: String {
      return "\((file as NSString).lastPathComponent):\(line) \(function)"
    }

    func fileNameAndClassName() -> (fileName: String, className: String) {
      let filename = (file as NSString).lastPathComponent.replacingOccurrences(of: ".swift", with: "")
      let components = filename.split(separator: "+")
      let className = components[0].trimmingCharacters(in: .whitespaces)
      return (filename, className)
    }
  }

  private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "", category: "Logger")

  private static let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "dd-MM-yyyy HH:mm:ss"
    return formatter
  }()

  // Check if running in SwiftUI Preview context
  private static let isPreview: Bool = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"

  // Log a debug message with a detail level
  static func debug(_ str: StaticString, detail: Int = 0, shouldLogContext: Bool = LogConfig.showContextByDefault, file: String = #file, function: String = #function, line: Int = #line) {
    let context = Context(file: file, function: function, line: line)
    if shouldLog(context: context, detail: detail) {
      Log.handleLog(level: .debug, str: str.description, shouldLogContext: shouldLogContext, context: context)
    }
  }

  // Log a debug message with a detail level
  static func debug(_ str: String, detail: Int = 0, shouldLogContext: Bool = LogConfig.showContextByDefault, file: String = #file, function: String = #function, line: Int = #line) {
    let context = Context(file: file, function: function, line: line)
    if shouldLog(context: context, detail: detail) {
      Log.handleLog(level: .debug, str: str.description, shouldLogContext: shouldLogContext, context: context)
    }
  }

  // Log an info message with a detail level
  static func info(_ str: String, detail: Int = 1, shouldLogContext: Bool = LogConfig.showContextByDefault, file: String = #file, function: String = #function, line: Int = #line) {
    let context = Context(file: file, function: function, line: line)
    if shouldLog(context: context, detail: detail) {
      Log.handleLog(level: .info, str: str.description, shouldLogContext: shouldLogContext, context: context)
    }
  }

  static func info(_ str: StaticString, detail: Int = 1, shouldLogContext: Bool = LogConfig.showContextByDefault, file: String = #file, function: String = #function, line: Int = #line) {
    let context = Context(file: file, function: function, line: line)
    if shouldLog(context: context, detail: detail) {
      Log.handleLog(level: .info, str: str.description, shouldLogContext: shouldLogContext, context: context)
    }
  }

  // Log a warning message with a detail level
  static func warning(_ str: StaticString, detail: Int = 2, shouldLogContext: Bool = LogConfig.showContextByDefault, file: String = #file, function: String = #function, line: Int = #line) {
    let context = Context(file: file, function: function, line: line)
    if shouldLog(context: context, detail: detail) {
      Log.handleLog(level: .warning, str: str.description, shouldLogContext: shouldLogContext, context: context)
    }
  }

  // Log a warning message with a detail level
  static func warning(_ str: String, detail: Int = 2, shouldLogContext: Bool = LogConfig.showContextByDefault, file: String = #file, function: String = #function, line: Int = #line) {
    let context = Context(file: file, function: function, line: line)
    if shouldLog(context: context, detail: detail) {
      Log.handleLog(level: .warning, str: str.description, shouldLogContext: shouldLogContext, context: context)
    }
  }

  // Log an error message with a detail level
  static func error(_ str: StaticString, detail: Int = 3, shouldLogContext: Bool = LogConfig.showContextByDefault, file: String = #file, function: String = #function, line: Int = #line) {
    let context = Context(file: file, function: function, line: line)
    if shouldLog(context: context, detail: detail) {
      Log.handleLog(level: .error, str: str.description, shouldLogContext: shouldLogContext, context: context)
    }
  }

  // Log an error message with a detail level
  static func error(_ str: String, detail: Int = 3, shouldLogContext: Bool = LogConfig.showContextByDefault, file: String = #file, function: String = #function, line: Int = #line) {
    let context = Context(file: file, function: function, line: line)
    if shouldLog(context: context, detail: detail) {
      Log.handleLog(level: .error, str: str.description, shouldLogContext: shouldLogContext, context: context)
    }
  }


  // This is a helper method to check if the log message should be printed based on the detail level.
  private static func shouldLog(context: Context, detail: Int) -> Bool {
#if DEBUG
    let (category, className) = context.fileNameAndClassName()
    let minDetail = LogConfig.categoryDetailLevels[category.lowercased()] ?? LogConfig.categoryDetailLevels[className.lowercased()] ?? LogConfig.currentDetailLevel.rawValue
    return detail >= minDetail
#else
    return false
#endif
  }

  // Internal function to handle the actual log printing
  private static func handleLog(level: LogLevel, str: String, shouldLogContext: Bool, context: Context) {
    let currentDateTime = dateFormatter.string(from: Date())
    let logComponents = ["[\(currentDateTime)]", "[\(level.prefix)]", str]
    var fullString = LogConfig.disablePrefix ? str : logComponents.joined(separator: " ")
    if shouldLogContext {
      fullString += " ➜ \(context.description)"
    }
    if isPreview {
      print("\(fullString)")
    } else {
      switch level {
      case .debug: logger.debug("\(fullString)")
      case .info: logger.info("\(fullString)")
      case .warning: logger.warning("\(fullString)")
      case .error: logger.error("\(fullString)")
      }
    }
  }
}
