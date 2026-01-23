import ActivityKit
import Compression
import Foundation
import React
import WidgetKit

@objc(VoltraModule)
public class VoltraModule: RCTEventEmitter {
  private let MAX_PAYLOAD_SIZE_IN_BYTES = 4096
  private let WIDGET_JSON_WARNING_SIZE = 50000 // 50KB per widget
  private let TIMELINE_WARNING_SIZE = 100_000 // 100KB per timeline
  private let liveActivityService = VoltraLiveActivityService()
  private var wasLaunchedInBackground: Bool = false
  private var monitoredActivityIds: Set<String> = []
  private var hasListeners = false

  enum VoltraErrors: Error {
    case unsupportedOS
    case notFound
    case liveActivitiesNotEnabled
    case unexpectedError(Error)
  }

  // MARK: - Initialization

  public override init() {
    super.init()
    // Track if app was launched in background (headless)
    DispatchQueue.main.async { [weak self] in
      self?.wasLaunchedInBackground = UIApplication.shared.applicationState == .background
    }
    // Clean up data for widgets that are no longer installed
    cleanupOrphanedWidgetData()
  }

  // MARK: - RCTEventEmitter

  @objc
  public override static func requiresMainQueueSetup() -> Bool {
    return true
  }

  @objc
  public override func supportedEvents() -> [String] {
    return ["interaction", "activityTokenReceived", "activityPushToStartTokenReceived", "stateChange"]
  }

  @objc
  public override func startObserving() {
    hasListeners = true
    VoltraEventBus.shared.subscribe { [weak self] eventType, eventData in
      self?.sendEvent(withName: eventType, body: eventData)
    }

    if pushNotificationsEnabled {
      observePushToStartToken()
    }

    observeLiveActivityUpdates()
  }

  @objc
  public override func stopObserving() {
    hasListeners = false
    VoltraEventBus.shared.unsubscribe()
    monitoredActivityIds.removeAll()
  }

  // MARK: - Validation

  private func validatePayloadSize(_ compressedPayload: String, operation: String) throws {
    let dataSize = compressedPayload.utf8.count
    let safeBudget = 3345
    print("Compressed payload size: \(dataSize)B (safe budget \(safeBudget)B, hard cap \(MAX_PAYLOAD_SIZE_IN_BYTES)B)")

    if dataSize > safeBudget {
      throw VoltraErrors.unexpectedError(
        NSError(
          domain: "VoltraModule",
          code: operation == "start" ? -10 : -11,
          userInfo: [NSLocalizedDescriptionKey: "Compressed payload too large: \(dataSize)B (safe budget \(safeBudget)B, hard cap \(MAX_PAYLOAD_SIZE_IN_BYTES)B). Reduce the UI before \(operation == "start" ? "starting" : "updating") the Live Activity."]
        )
      )
    }
  }

  // MARK: - Live Activity Methods

  @objc(startLiveActivity:options:resolve:reject:)
  func startLiveActivity(
    _ jsonString: String,
    options: NSDictionary?,
    resolve: @escaping RCTPromiseResolveBlock,
    reject: @escaping RCTPromiseRejectBlock
  ) {
    guard #available(iOS 16.2, *) else {
      reject("UNSUPPORTED_OS", "Live Activities require iOS 16.2 or later", nil)
      return
    }
    guard VoltraLiveActivityService.areActivitiesEnabled() else {
      reject("LIVE_ACTIVITIES_NOT_ENABLED", "Live Activities are not enabled", nil)
      return
    }

    Task {
      do {
        let compressedJson = try BrotliCompression.compress(jsonString: jsonString)
        try validatePayloadSize(compressedJson, operation: "start")

        let activityName = (options?["activityId"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let deepLinkUrl = options?["deepLinkUrl"] as? String

        let staleDate: Date? = {
          if let staleDateMs = options?["staleDate"] as? Double {
            return Date(timeIntervalSince1970: staleDateMs / 1000.0)
          }
          return nil
        }()
        let relevanceScore: Double = options?["relevanceScore"] as? Double ?? 0.0

        let createRequest = CreateActivityRequest(
          activityId: activityName,
          deepLinkUrl: deepLinkUrl,
          jsonString: compressedJson,
          staleDate: staleDate,
          relevanceScore: relevanceScore,
          pushType: self.pushNotificationsEnabled ? .token : nil,
          endExistingWithSameName: true
        )

        let finalActivityId = try await self.liveActivityService.createActivity(createRequest)
        resolve(finalActivityId)
      } catch {
        print("Error starting Voltra instance: \(error)")
        reject("START_FAILED", error.localizedDescription, error)
      }
    }
  }

  @objc(updateLiveActivity:jsonString:options:resolve:reject:)
  func updateLiveActivity(
    _ activityId: String,
    jsonString: String,
    options: NSDictionary?,
    resolve: @escaping RCTPromiseResolveBlock,
    reject: @escaping RCTPromiseRejectBlock
  ) {
    guard #available(iOS 16.2, *) else {
      reject("UNSUPPORTED_OS", "Live Activities require iOS 16.2 or later", nil)
      return
    }

    Task {
      do {
        let compressedJson = try BrotliCompression.compress(jsonString: jsonString)
        try validatePayloadSize(compressedJson, operation: "update")

        let staleDate: Date? = {
          if let staleDateMs = options?["staleDate"] as? Double {
            return Date(timeIntervalSince1970: staleDateMs / 1000.0)
          }
          return nil
        }()
        let relevanceScore: Double = options?["relevanceScore"] as? Double ?? 0.0

        let updateRequest = UpdateActivityRequest(
          jsonString: compressedJson,
          staleDate: staleDate,
          relevanceScore: relevanceScore
        )

        try await self.liveActivityService.updateActivity(byName: activityId, request: updateRequest)
        resolve(nil)
      } catch {
        if let serviceError = error as? VoltraLiveActivityError {
          switch serviceError {
          case .unsupportedOS:
            reject("UNSUPPORTED_OS", "Live Activities require iOS 16.2 or later", nil)
          case .notFound:
            reject("NOT_FOUND", "Activity not found", nil)
          case .liveActivitiesNotEnabled:
            reject("LIVE_ACTIVITIES_NOT_ENABLED", "Live Activities are not enabled", nil)
          }
        } else {
          reject("UPDATE_FAILED", error.localizedDescription, error)
        }
      }
    }
  }

  @objc(endLiveActivity:options:resolve:reject:)
  func endLiveActivity(
    _ activityId: String,
    options: NSDictionary?,
    resolve: @escaping RCTPromiseResolveBlock,
    reject: @escaping RCTPromiseRejectBlock
  ) {
    guard #available(iOS 16.2, *) else {
      reject("UNSUPPORTED_OS", "Live Activities require iOS 16.2 or later", nil)
      return
    }

    Task {
      do {
        let dismissalPolicy = self.convertToActivityKitDismissalPolicy(options?["dismissalPolicy"] as? NSDictionary)
        try await self.liveActivityService.endActivity(byName: activityId, dismissalPolicy: dismissalPolicy)
        resolve(nil)
      } catch {
        if let serviceError = error as? VoltraLiveActivityError {
          switch serviceError {
          case .unsupportedOS:
            reject("UNSUPPORTED_OS", "Live Activities require iOS 16.2 or later", nil)
          case .notFound:
            reject("NOT_FOUND", "Activity not found", nil)
          case .liveActivitiesNotEnabled:
            reject("LIVE_ACTIVITIES_NOT_ENABLED", "Live Activities are not enabled", nil)
          }
        } else {
          reject("END_FAILED", error.localizedDescription, error)
        }
      }
    }
  }

  @objc(endAllLiveActivities:reject:)
  func endAllLiveActivities(
    _ resolve: @escaping RCTPromiseResolveBlock,
    reject: @escaping RCTPromiseRejectBlock
  ) {
    guard #available(iOS 16.2, *) else {
      reject("UNSUPPORTED_OS", "Live Activities require iOS 16.2 or later", nil)
      return
    }

    Task {
      await self.liveActivityService.endAllActivities()
      resolve(nil)
    }
  }

  @objc(getLatestVoltraActivityId:reject:)
  func getLatestVoltraActivityId(
    _ resolve: @escaping RCTPromiseResolveBlock,
    reject: @escaping RCTPromiseRejectBlock
  ) {
    guard #available(iOS 16.2, *) else {
      resolve(nil)
      return
    }
    resolve(liveActivityService.getLatestActivity()?.id)
  }

  @objc(listVoltraActivityIds:reject:)
  func listVoltraActivityIds(
    _ resolve: @escaping RCTPromiseResolveBlock,
    reject: @escaping RCTPromiseRejectBlock
  ) {
    guard #available(iOS 16.2, *) else {
      resolve([])
      return
    }
    resolve(liveActivityService.getAllActivities().map(\.id))
  }

  @objc(isLiveActivityActive:)
  func isLiveActivityActive(_ activityName: String) -> NSNumber {
    guard #available(iOS 16.2, *) else { return false }
    return NSNumber(value: liveActivityService.isActivityActive(name: activityName))
  }

  @objc(isHeadless)
  func isHeadless() -> NSNumber {
    return NSNumber(value: wasLaunchedInBackground)
  }

  // MARK: - Image Preloading Methods

  @objc(preloadImages:resolve:reject:)
  func preloadImages(
    _ images: NSArray,
    resolve: @escaping RCTPromiseResolveBlock,
    reject: @escaping RCTPromiseRejectBlock
  ) {
    Task {
      var succeeded: [String] = []
      var failed: [[String: String]] = []

      for case let imageDict as NSDictionary in images {
        guard let url = imageDict["url"] as? String,
              let key = imageDict["key"] as? String else {
          continue
        }

        let method = imageDict["method"] as? String
        let headers = imageDict["headers"] as? [String: String]

        do {
          try await self.downloadAndSaveImage(
            url: url,
            key: key,
            method: method,
            headers: headers
          )
          succeeded.append(key)
        } catch {
          failed.append(["key": key, "error": error.localizedDescription])
        }
      }

      resolve(["succeeded": succeeded, "failed": failed])
    }
  }

  @objc(reloadLiveActivities:resolve:reject:)
  func reloadLiveActivities(
    _ activityNames: NSArray?,
    resolve: @escaping RCTPromiseResolveBlock,
    reject: @escaping RCTPromiseRejectBlock
  ) {
    guard #available(iOS 16.2, *) else {
      reject("UNSUPPORTED_OS", "Live Activities require iOS 16.2 or later", nil)
      return
    }

    Task {
      let activities = self.liveActivityService.getAllActivities()
      let namesArray = activityNames as? [String]

      for activity in activities {
        if let names = namesArray, !names.isEmpty {
          guard names.contains(activity.attributes.name) else { continue }
        }

        do {
          let newState = try VoltraAttributes.ContentState(
            uiJsonData: activity.content.state.uiJsonData
          )

          await activity.update(
            ActivityContent(
              state: newState,
              staleDate: activity.content.staleDate,
              relevanceScore: activity.content.relevanceScore
            )
          )
          print("[Voltra] Reloaded Live Activity '\(activity.attributes.name)'")
        } catch {
          print("[Voltra] Failed to reload Live Activity '\(activity.attributes.name)': \(error)")
        }
      }
      resolve(nil)
    }
  }

  @objc(clearPreloadedImages:resolve:reject:)
  func clearPreloadedImages(
    _ keys: NSArray?,
    resolve: @escaping RCTPromiseResolveBlock,
    reject: @escaping RCTPromiseRejectBlock
  ) {
    Task {
      if let keysArray = keys as? [String], !keysArray.isEmpty {
        VoltraImageStore.removeImages(keys: keysArray)
        print("[Voltra] Cleared preloaded images: \(keysArray.joined(separator: ", "))")
      } else {
        VoltraImageStore.clearAll()
        print("[Voltra] Cleared all preloaded images")
      }
      resolve(nil)
    }
  }

  // MARK: - Widget Methods

  @objc(updateWidget:jsonString:options:resolve:reject:)
  func updateWidget(
    _ widgetId: String,
    jsonString: String,
    options: NSDictionary?,
    resolve: @escaping RCTPromiseResolveBlock,
    reject: @escaping RCTPromiseRejectBlock
  ) {
    do {
      let deepLinkUrl = options?["deepLinkUrl"] as? String
      try writeWidgetData(widgetId: widgetId, jsonString: jsonString, deepLinkUrl: deepLinkUrl)
      clearWidgetTimeline(widgetId: widgetId)
      WidgetCenter.shared.reloadTimelines(ofKind: "Voltra_Widget_\(widgetId)")
      print("[Voltra] Updated widget '\(widgetId)'")
      resolve(nil)
    } catch {
      reject("WIDGET_UPDATE_FAILED", error.localizedDescription, error)
    }
  }

  @objc(scheduleWidget:timelineJson:resolve:reject:)
  func scheduleWidget(
    _ widgetId: String,
    timelineJson: String,
    resolve: @escaping RCTPromiseResolveBlock,
    reject: @escaping RCTPromiseRejectBlock
  ) {
    do {
      try writeWidgetTimeline(widgetId: widgetId, timelineJson: timelineJson)
      WidgetCenter.shared.reloadTimelines(ofKind: "Voltra_Widget_\(widgetId)")
      resolve(nil)
    } catch {
      reject("WIDGET_SCHEDULE_FAILED", error.localizedDescription, error)
    }
  }

  @objc(reloadWidgets:resolve:reject:)
  func reloadWidgets(
    _ widgetIds: NSArray?,
    resolve: @escaping RCTPromiseResolveBlock,
    reject: @escaping RCTPromiseRejectBlock
  ) {
    if let idsArray = widgetIds as? [String], !idsArray.isEmpty {
      for widgetId in idsArray {
        WidgetCenter.shared.reloadTimelines(ofKind: "Voltra_Widget_\(widgetId)")
      }
      print("[Voltra] Reloaded widgets: \(idsArray.joined(separator: ", "))")
    } else {
      WidgetCenter.shared.reloadAllTimelines()
      print("[Voltra] Reloaded all widgets")
    }
    resolve(nil)
  }

  @objc(clearWidget:resolve:reject:)
  func clearWidget(
    _ widgetId: String,
    resolve: @escaping RCTPromiseResolveBlock,
    reject: @escaping RCTPromiseRejectBlock
  ) {
    clearWidgetData(widgetId: widgetId)
    WidgetCenter.shared.reloadTimelines(ofKind: "Voltra_Widget_\(widgetId)")
    print("[Voltra] Cleared widget '\(widgetId)'")
    resolve(nil)
  }

  @objc(clearAllWidgets:reject:)
  func clearAllWidgets(
    _ resolve: @escaping RCTPromiseResolveBlock,
    reject: @escaping RCTPromiseRejectBlock
  ) {
    clearAllWidgetData()
    WidgetCenter.shared.reloadAllTimelines()
    print("[Voltra] Cleared all widgets")
    resolve(nil)
  }

  // MARK: - Helper Methods

  private func convertToActivityKitDismissalPolicy(_ options: NSDictionary?) -> ActivityUIDismissalPolicy {
    guard let options = options else {
      return .immediate
    }

    switch options["type"] as? String {
    case "immediate":
      return .immediate
    case "after":
      if let timestamp = options["date"] as? Double {
        let date = Date(timeIntervalSince1970: timestamp / 1000.0)
        return .after(date)
      }
      return .immediate
    default:
      return .immediate
    }
  }
}

// MARK: - Image Preloading

private extension VoltraModule {
  func downloadAndSaveImage(url urlString: String, key: String, method: String?, headers: [String: String]?) async throws {
    guard let url = URL(string: urlString) else {
      throw PreloadError.invalidURL(urlString)
    }

    var request = URLRequest(url: url)
    request.httpMethod = method ?? "GET"

    if let headers = headers {
      for (headerKey, value) in headers {
        request.setValue(value, forHTTPHeaderField: headerKey)
      }
    }

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw PreloadError.invalidResponse
    }

    guard (200 ... 299).contains(httpResponse.statusCode) else {
      throw PreloadError.httpError(statusCode: httpResponse.statusCode)
    }

    if let contentLengthString = httpResponse.value(forHTTPHeaderField: "Content-Length"),
       let contentLength = Int(contentLengthString)
    {
      if contentLength >= MAX_PAYLOAD_SIZE_IN_BYTES {
        throw PreloadError.imageTooLarge(key: key, size: contentLength)
      }
    }

    if data.count >= MAX_PAYLOAD_SIZE_IN_BYTES {
      throw PreloadError.imageTooLarge(key: key, size: data.count)
    }

    guard UIImage(data: data) != nil else {
      throw PreloadError.invalidImageData(key: key)
    }

    try VoltraImageStore.saveImage(data, key: key)
    print("[Voltra] Preloaded image '\(key)' (\(data.count) bytes)")
  }
}

/// Errors that can occur during image preloading
enum PreloadError: Error, LocalizedError {
  case invalidURL(String)
  case invalidResponse
  case httpError(statusCode: Int)
  case imageTooLarge(key: String, size: Int)
  case invalidImageData(key: String)
  case appGroupNotConfigured

  var errorDescription: String? {
    switch self {
    case let .invalidURL(url):
      return "Invalid URL: \(url)"
    case .invalidResponse:
      return "Invalid response from server"
    case let .httpError(statusCode):
      return "HTTP error: \(statusCode)"
    case let .imageTooLarge(key, size):
      return "Image '\(key)' is too large: \(size) bytes (max 4096 bytes for Live Activities)"
    case let .invalidImageData(key):
      return "Invalid image data for '\(key)'"
    case .appGroupNotConfigured:
      return "App Group not configured. Set 'groupIdentifier' in the Voltra config plugin."
    }
  }
}

// MARK: - Widget Data Management

private extension VoltraModule {
  func writeWidgetData(widgetId: String, jsonString: String, deepLinkUrl: String?) throws {
    guard let groupId = VoltraConfig.groupIdentifier() else {
      throw WidgetError.appGroupNotConfigured
    }
    guard let defaults = UserDefaults(suiteName: groupId) else {
      throw WidgetError.userDefaultsUnavailable
    }

    let dataSize = jsonString.utf8.count
    if dataSize > WIDGET_JSON_WARNING_SIZE {
      print("[Voltra] ⚠️ Large widget payload for '\(widgetId)': \(dataSize) bytes (warning threshold: \(WIDGET_JSON_WARNING_SIZE) bytes)")
    }

    defaults.set(jsonString, forKey: "Voltra_Widget_JSON_\(widgetId)")

    if let url = deepLinkUrl, !url.isEmpty {
      defaults.set(url, forKey: "Voltra_Widget_DeepLinkURL_\(widgetId)")
    } else {
      defaults.removeObject(forKey: "Voltra_Widget_DeepLinkURL_\(widgetId)")
    }

    defaults.synchronize()
  }

  func writeWidgetTimeline(widgetId: String, timelineJson: String) throws {
    guard let groupId = VoltraConfig.groupIdentifier() else {
      throw WidgetError.appGroupNotConfigured
    }
    guard let defaults = UserDefaults(suiteName: groupId) else {
      throw WidgetError.userDefaultsUnavailable
    }

    let dataSize = timelineJson.utf8.count
    if dataSize > TIMELINE_WARNING_SIZE {
      print("[Voltra] ⚠️ Large timeline for '\(widgetId)': \(dataSize) bytes (warning threshold: \(TIMELINE_WARNING_SIZE) bytes)")
    }

    defaults.set(timelineJson, forKey: "Voltra_Widget_Timeline_\(widgetId)")
    defaults.synchronize()
    print("[Voltra] writeWidgetTimeline: Timeline stored successfully")
  }

  func clearWidgetData(widgetId: String) {
    guard let groupId = VoltraConfig.groupIdentifier(),
          let defaults = UserDefaults(suiteName: groupId) else { return }

    defaults.removeObject(forKey: "Voltra_Widget_JSON_\(widgetId)")
    defaults.removeObject(forKey: "Voltra_Widget_DeepLinkURL_\(widgetId)")
    defaults.removeObject(forKey: "Voltra_Widget_Timeline_\(widgetId)")
    defaults.synchronize()
  }

  func clearAllWidgetData() {
    guard let groupId = VoltraConfig.groupIdentifier(),
          let defaults = UserDefaults(suiteName: groupId) else { return }

    let widgetIds = Bundle.main.object(forInfoDictionaryKey: "Voltra_WidgetIds") as? [String] ?? []

    for widgetId in widgetIds {
      defaults.removeObject(forKey: "Voltra_Widget_JSON_\(widgetId)")
      defaults.removeObject(forKey: "Voltra_Widget_DeepLinkURL_\(widgetId)")
      defaults.removeObject(forKey: "Voltra_Widget_Timeline_\(widgetId)")
    }
    defaults.synchronize()
  }

  func clearWidgetTimeline(widgetId: String) {
    guard let groupId = VoltraConfig.groupIdentifier(),
          let defaults = UserDefaults(suiteName: groupId) else { return }

    defaults.removeObject(forKey: "Voltra_Widget_Timeline_\(widgetId)")
    defaults.synchronize()
  }

  func cleanupOrphanedWidgetData() {
    guard let groupId = VoltraConfig.groupIdentifier(),
          let defaults = UserDefaults(suiteName: groupId) else { return }

    let knownWidgetIds = Bundle.main.object(forInfoDictionaryKey: "Voltra_WidgetIds") as? [String] ?? []
    guard !knownWidgetIds.isEmpty else { return }

    WidgetCenter.shared.getCurrentConfigurations { result in
      guard case let .success(configs) = result else { return }

      let installedIds = Set(configs.compactMap { config -> String? in
        let prefix = "Voltra_Widget_"
        guard config.kind.hasPrefix(prefix) else { return nil }
        return String(config.kind.dropFirst(prefix.count))
      })

      for widgetId in knownWidgetIds where !installedIds.contains(widgetId) {
        defaults.removeObject(forKey: "Voltra_Widget_JSON_\(widgetId)")
        defaults.removeObject(forKey: "Voltra_Widget_DeepLinkURL_\(widgetId)")
        defaults.removeObject(forKey: "Voltra_Widget_Timeline_\(widgetId)")
        print("[Voltra] Cleaned up orphaned widget data for '\(widgetId)'")
      }
    }
  }
}

/// Errors that can occur during widget operations
enum WidgetError: Error, LocalizedError {
  case appGroupNotConfigured
  case userDefaultsUnavailable

  var errorDescription: String? {
    switch self {
    case .appGroupNotConfigured:
      return "App Group not configured. Set 'groupIdentifier' in the Voltra config plugin to use widgets."
    case .userDefaultsUnavailable:
      return "Unable to access UserDefaults for the app group."
    }
  }
}

// MARK: - Push Tokens and Activity State Streams

private extension VoltraModule {
  var pushNotificationsEnabled: Bool {
    let main = Bundle.main
    return main.object(forInfoDictionaryKey: "Voltra_EnablePushNotifications") as? Bool ?? false
  }

  func observePushToStartToken() {
    guard #available(iOS 17.2, *), ActivityAuthorizationInfo().areActivitiesEnabled else { return }

    if let initialTokenData = Activity<VoltraAttributes>.pushToStartToken {
      let token = initialTokenData.hexString
      VoltraEventBus.shared.send(.pushToStartTokenReceived(token: token))
    }

    Task {
      for await tokenData in Activity<VoltraAttributes>.pushToStartTokenUpdates {
        let token = tokenData.hexString
        VoltraEventBus.shared.send(.pushToStartTokenReceived(token: token))
      }
    }
  }

  func observeLiveActivityUpdates() {
    guard #available(iOS 16.2, *) else { return }

    for activity in Activity<VoltraAttributes>.activities {
      monitorActivity(activity)
    }

    Task {
      for await newActivity in Activity<VoltraAttributes>.activityUpdates {
        monitorActivity(newActivity)
      }
    }
  }

  private func monitorActivity(_ activity: Activity<VoltraAttributes>) {
    let activityId = activity.id

    guard !monitoredActivityIds.contains(activityId) else { return }
    monitoredActivityIds.insert(activityId)

    Task {
      for await state in activity.activityStateUpdates {
        VoltraEventBus.shared.send(
          .stateChange(
            activityName: activity.attributes.name,
            state: String(describing: state)
          )
        )
      }
    }

    if pushNotificationsEnabled {
      Task {
        for await pushTokenData in activity.pushTokenUpdates {
          let pushTokenString = pushTokenData.hexString
          VoltraEventBus.shared.send(
            .tokenReceived(
              activityName: activity.attributes.name,
              pushToken: pushTokenString
            )
          )
        }
      }
    }
  }
}
