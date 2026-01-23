import type { TurboModule } from 'react-native'
import { TurboModuleRegistry } from 'react-native'

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
 * Dismissal policy for ending a Live Activity
 */
export type DismissalPolicy = {
  type: 'immediate' | 'after'
  date?: number
}

/**
 * Options for ending a Live Activity
 */
export type EndVoltraOptions = {
  dismissalPolicy?: DismissalPolicy
}

/**
 * Options for preloading an image
 */
export type PreloadImageOptions = {
  url: string
  key: string
  method?: string
  headers?: { [key: string]: string }
}

/**
 * Result of a failed image preload
 */
export type PreloadImageFailure = {
  key: string
  error: string
}

/**
 * Result of preloading images
 */
export type PreloadImagesResult = {
  succeeded: string[]
  failed: PreloadImageFailure[]
}

/**
 * Options for updating a home screen widget
 */
export type UpdateWidgetOptions = {
  deepLinkUrl?: string
}

/**
 * Voltra TurboModule Spec
 */
export interface Spec extends TurboModule {
  // Live Activity Functions
  startLiveActivity(jsonString: string, options?: StartVoltraOptions): Promise<string>
  updateLiveActivity(activityId: string, jsonString: string, options?: UpdateVoltraOptions): Promise<void>
  endLiveActivity(activityId: string, options?: EndVoltraOptions): Promise<void>
  endAllLiveActivities(): Promise<void>
  getLatestVoltraActivityId(): Promise<string | null>
  listVoltraActivityIds(): Promise<string[]>
  isLiveActivityActive(activityName: string): boolean
  isHeadless(): boolean

  // Image Preloading Functions
  preloadImages(images: PreloadImageOptions[]): Promise<PreloadImagesResult>
  reloadLiveActivities(activityNames?: string[] | null): Promise<void>
  clearPreloadedImages(keys?: string[] | null): Promise<void>

  // Widget Functions
  updateWidget(widgetId: string, jsonString: string, options?: UpdateWidgetOptions): Promise<void>
  scheduleWidget(widgetId: string, timelineJson: string): Promise<void>
  reloadWidgets(widgetIds?: string[] | null): Promise<void>
  clearWidget(widgetId: string): Promise<void>
  clearAllWidgets(): Promise<void>

  // Event emitter methods
  addListener(eventName: string): void
  removeListeners(count: number): void
}

export default TurboModuleRegistry.get<Spec>('VoltraModule')
