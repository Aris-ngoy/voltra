import Foundation

// MARK: - Options Structures (Plain Swift, no Expo dependency)

/// Shared options for both startLiveActivity and updateLiveActivity
public struct SharedVoltraOptions {
  /// Unix timestamp in milliseconds
  public var staleDate: Double?

  /// Double value between 0.0 and 1.0, defaults to 0.0
  public var relevanceScore: Double?

  public init(from dict: [String: Any]?) {
    self.staleDate = dict?["staleDate"] as? Double
    self.relevanceScore = dict?["relevanceScore"] as? Double
  }
}

/// Options for starting a Live Activity
public struct StartVoltraOptions {
  /// The name of the Live Activity.
  /// Allows you to rebind to the same activity on app restart.
  public var activityName: String?

  /// URL to open when the Live Activity is tapped.
  public var deepLinkUrl: String?

  /// Unix timestamp in milliseconds
  public var staleDate: Double?

  /// Double value between 0.0 and 1.0, defaults to 0.0
  public var relevanceScore: Double?

  public init(from dict: [String: Any]?) {
    self.activityName = dict?["activityId"] as? String
    self.deepLinkUrl = dict?["deepLinkUrl"] as? String
    self.staleDate = dict?["staleDate"] as? Double
    self.relevanceScore = dict?["relevanceScore"] as? Double
  }
}

/// Options for updating a Live Activity
public typealias UpdateVoltraOptions = SharedVoltraOptions

/// Options for ending a Live Activity
public struct EndVoltraOptions {
  public var dismissalPolicy: DismissalPolicyOptions?

  public init(from dict: [String: Any]?) {
    if let policyDict = dict?["dismissalPolicy"] as? [String: Any] {
      self.dismissalPolicy = DismissalPolicyOptions(from: policyDict)
    }
  }
}

/// Dismissal policy options
public struct DismissalPolicyOptions {
  public var type: String  // "immediate" or "after"
  public var date: Double?  // timestamp for after

  public init(from dict: [String: Any]) {
    self.type = dict["type"] as? String ?? "immediate"
    self.date = dict["date"] as? Double
  }
}

/// Options for updating a home screen widget
public struct UpdateWidgetOptions {
  /// URL to open when the widget is tapped
  public var deepLinkUrl: String?

  public init(from dict: [String: Any]?) {
    self.deepLinkUrl = dict?["deepLinkUrl"] as? String
  }
}

/// Options for preloading a single image
public struct PreloadImageOptions {
  /// The URL to download the image from
  public var url: String

  /// The key to use when referencing this image (used as assetName)
  public var key: String

  /// HTTP method to use (GET, POST, PUT). Defaults to GET.
  public var method: String?

  /// Optional HTTP headers to include in the request
  public var headers: [String: String]?

  public init?(from dict: [String: Any]) {
    guard let url = dict["url"] as? String,
      let key = dict["key"] as? String
    else {
      return nil
    }
    self.url = url
    self.key = key
    self.method = dict["method"] as? String
    self.headers = dict["headers"] as? [String: String]
  }
}

/// Result of a failed image preload
public struct PreloadImageFailure {
  public var key: String
  public var error: String

  public init(key: String, error: String) {
    self.key = key
    self.error = error
  }

  public func toDictionary() -> [String: String] {
    return ["key": key, "error": error]
  }
}

/// Result of preloading images
public struct PreloadImagesResult {
  public var succeeded: [String]
  public var failed: [PreloadImageFailure]

  public init(succeeded: [String] = [], failed: [PreloadImageFailure] = []) {
    self.succeeded = succeeded
    self.failed = failed
  }

  public func toDictionary() -> [String: Any] {
    return [
      "succeeded": succeeded,
      "failed": failed.map { $0.toDictionary() },
    ]
  }
}
