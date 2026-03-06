import { NativeEventEmitter, NativeModules, Platform } from 'react-native'

import NativeVoltraModule from './NativeVoltraModule.js'
import type { EventSubscription, PreloadImageOptions, PreloadImagesResult, UpdateWidgetOptions } from './types.js'

/**
 * Options for starting a Live Activity
 */
export type StartVoltraOptions = {
  /**
   * Target type for the activity (used internally)
   */
  target?: string
  /**
   * URL to open when the Live Activity is tapped.
   */
  deepLinkUrl?: string
  /**
   * The ID/name of the Live Activity.
   * Allows you to rebind to the same activity on app restart.
   */
  activityId?: string
  /**
   * Unix timestamp in milliseconds
   */
  staleDate?: number
  /**
   * Double value between 0.0 and 1.0, defaults to 0.0
   */
  relevanceScore?: number
}

/**
 * Options for updating a Live Activity
 */
export type UpdateVoltraOptions = {
  /**
   * Unix timestamp in milliseconds
   */
  staleDate?: number
  /**
   * Double value between 0.0 and 1.0, defaults to 0.0
   */
  relevanceScore?: number
}

/**
 * Options for ending a Live Activity
 */
export type EndVoltraOptions = {
  dismissalPolicy?: {
    type: 'immediate' | 'after'
    date?: number
  }
}

/**
 * VoltraModule native module interface
 */
export interface VoltraModuleSpec {
  /**
   * Start a new Live Activity
   */
  startLiveActivity(jsonString: string, options?: StartVoltraOptions): Promise<string>

  /**
   * Update an existing Live Activity
   */
  updateLiveActivity(activityId: string, jsonString: string, options?: UpdateVoltraOptions): Promise<void>

  /**
   * End a Live Activity
   */
  endLiveActivity(activityId: string, options?: EndVoltraOptions): Promise<void>

  /**
   * End all active Live Activities
   */
  endAllLiveActivities(): Promise<void>

  /**
   * Get the latest (most recently created) Voltra Live Activity ID, if any
   */
  getLatestVoltraActivityId(): Promise<string | null>

  /**
   * List all running Voltra Live Activity IDs
   */
  listVoltraActivityIds(): Promise<string[]>

  /**
   * Check if a Live Activity with the given name is currently active
   */
  isLiveActivityActive(activityName: string): boolean

  /**
   * Check if the app was launched in the background (headless)
   */
  isHeadless(): boolean

  /**
   * Android Live Update: Start a new live update notification
   */
  startAndroidLiveUpdate(payload: string, options: { updateName?: string; channelId?: string }): Promise<string>

  /**
   * Android Live Update: Update an existing live update notification
   */
  updateAndroidLiveUpdate(notificationId: string, payload: string): Promise<void>

  /**
   * Android Live Update: Stop a live update notification
   */
  stopAndroidLiveUpdate(notificationId: string): Promise<void>

  /**
   * Android Live Update: Check if a live update is active
   */
  isAndroidLiveUpdateActive(updateName: string): boolean

  /**
   * Android Live Update: End all active live updates
   */
  endAllAndroidLiveUpdates(): Promise<void>

  /**
   * Android Widget: Update a widget with new content
   */
  updateAndroidWidget(widgetId: string, jsonString: string, options?: { deepLinkUrl?: string }): Promise<void>

  /**
   * Android Widget: Reload widget timelines to refresh their content
   */
  reloadAndroidWidgets(widgetIds?: string[] | null): Promise<void>

  /**
   * Android Widget: Clear a widget's stored data
   */
  clearAndroidWidget(widgetId: string): Promise<void>

  /**
   * Android Widget: Clear all widgets' stored data
   */
  clearAllAndroidWidgets(): Promise<void>

  /**
   * Android Widget: Request to pin a widget to the home screen
   *
   * See: https://developer.android.com/develop/ui/compose/glance/pin-in-app
   *
   * @param widgetId - The widget identifier to pin
   * @param options - Optional settings for the pin request
   * @param options.previewWidth - Optional preview width in dp (default: 245)
   * @param options.previewHeight - Optional preview height in dp (default: 115)
   * @returns Promise that resolves to true if the pin request was successful
   */
  requestPinGlanceAppWidget(
    widgetId: string,
    options?: { previewWidth?: number; previewHeight?: number }
  ): Promise<boolean>

  /**
   * Preload images to App Group storage for use in Live Activities
   */
  preloadImages(images: PreloadImageOptions[]): Promise<PreloadImagesResult>

  /**
   * Reload Live Activities to pick up preloaded images
   */
  reloadLiveActivities(activityNames?: string[] | null): Promise<void>

  /**
   * Clear preloaded images from App Group storage
   */
  clearPreloadedImages(keys?: string[] | null): Promise<void>

  /**
   * Update a home screen widget with new content
   */
  updateWidget(widgetId: string, jsonString: string, options?: UpdateWidgetOptions): Promise<void>

  /**
   * Schedule a widget timeline with multiple entries to be displayed at future times
   */
  scheduleWidget(widgetId: string, timelineJson: string): Promise<void>

  /**
   * Reload widget timelines to refresh their content
   */
  reloadWidgets(widgetIds?: string[] | null): Promise<void>

  /**
   * Clear a widget's stored data
   */
  clearWidget(widgetId: string): Promise<void>

  /**
   * Clear all widgets' stored data
   */
  clearAllWidgets(): Promise<void>

  /**
   * Add an event listener
   */
  addListener(event: string, listener: (event: any) => void): EventSubscription
}

const turboModule = NativeVoltraModule
const legacyModule = (NativeModules as { VoltraModule?: VoltraModuleSpec }).VoltraModule ?? null

const nativeModule = (turboModule ?? legacyModule) as VoltraModuleSpec | null

const isTurboModuleEnabled = Boolean((global as any)?.__turboModuleProxy)
const unavailableError = new Error(
  `[Voltra] Native module 'VoltraModule' is not available on ${Platform.OS}. Ensure the native module is properly installed and the app was rebuilt.` +
    (Platform.OS === 'android' && !isTurboModuleEnabled
      ? ' TurboModules require the New Architecture to be enabled on Android.'
      : '') +
    ' If using Expo, install and run a custom dev client (Expo Go is not supported).'
)

let hasWarnedUnavailable = false
const warnUnavailable = (): void => {
  if (hasWarnedUnavailable) return
  hasWarnedUnavailable = true
  console.warn(unavailableError.message)
}

const unavailableModule = new Proxy(
  {},
  {
    get: () => {
      return (..._args: any[]) => {
        warnUnavailable()
        throw unavailableError
      }
    },
  }
) as VoltraModuleSpec

const eventEmitter = nativeModule ? new NativeEventEmitter(nativeModule as any) : null

const createModuleWrapper = (module: VoltraModuleSpec): VoltraModuleSpec => {
  const nativeAddListener = (module as any).addListener
  if (typeof nativeAddListener === 'function' && nativeAddListener.length >= 2) {
    return module
  }

  return new Proxy(module as any, {
    get: (target, prop) => {
      if (prop === 'addListener') {
        return (event: string, listener: (event: any) => void): EventSubscription => {
          const subscription = eventEmitter?.addListener(event, listener)
          return {
            remove: () => subscription?.remove(),
          }
        }
      }

      return (target as any)[prop]
    },
  }) as VoltraModuleSpec
}

const VoltraModule: VoltraModuleSpec = nativeModule ? createModuleWrapper(nativeModule) : unavailableModule

export default VoltraModule
