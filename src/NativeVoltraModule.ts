import type { TurboModule } from 'react-native'
import { TurboModuleRegistry } from 'react-native'

export type StartVoltraOptions = {
  target?: string
  deepLinkUrl?: string
  activityId?: string
  staleDate?: number
  relevanceScore?: number
}

export type UpdateVoltraOptions = {
  staleDate?: number
  relevanceScore?: number
}

export type EndVoltraOptions = {
  dismissalPolicy?: {
    type: 'immediate' | 'after'
    date?: number
  }
}

export type PreloadImageOptions = {
  url: string
  key: string
  method?: 'GET' | 'POST' | 'PUT'
  headers?: Record<string, string>
}

export type PreloadImageFailure = {
  key: string
  error: string
}

export type PreloadImagesResult = {
  succeeded: string[]
  failed: PreloadImageFailure[]
}

export type UpdateWidgetOptions = {
  deepLinkUrl?: string
}

export interface Spec extends TurboModule {
  startLiveActivity(jsonString: string, options?: StartVoltraOptions): Promise<string>
  updateLiveActivity(activityId: string, jsonString: string, options?: UpdateVoltraOptions): Promise<void>
  endLiveActivity(activityId: string, options?: EndVoltraOptions): Promise<void>
  endAllLiveActivities(): Promise<void>
  getLatestVoltraActivityId(): Promise<string | null>
  listVoltraActivityIds(): Promise<string[]>
  isLiveActivityActive(activityName: string): boolean
  isHeadless(): boolean

  startAndroidLiveUpdate(payload: string, options: { updateName?: string; channelId?: string }): Promise<string>
  updateAndroidLiveUpdate(notificationId: string, payload: string): Promise<void>
  stopAndroidLiveUpdate(notificationId: string): Promise<void>
  isAndroidLiveUpdateActive(updateName: string): boolean
  endAllAndroidLiveUpdates(): Promise<void>

  updateAndroidWidget(widgetId: string, jsonString: string, options?: { deepLinkUrl?: string }): Promise<void>
  reloadAndroidWidgets(widgetIds?: string[] | null): Promise<void>
  clearAndroidWidget(widgetId: string): Promise<void>
  clearAllAndroidWidgets(): Promise<void>
  requestPinGlanceAppWidget(
    widgetId: string,
    options?: { previewWidth?: number; previewHeight?: number }
  ): Promise<boolean>

  preloadImages(images: PreloadImageOptions[]): Promise<PreloadImagesResult>
  reloadLiveActivities(activityNames?: string[] | null): Promise<void>
  clearPreloadedImages(keys?: string[] | null): Promise<void>

  updateWidget(widgetId: string, jsonString: string, options?: UpdateWidgetOptions): Promise<void>
  scheduleWidget(widgetId: string, timelineJson: string): Promise<void>
  reloadWidgets(widgetIds?: string[] | null): Promise<void>
  clearWidget(widgetId: string): Promise<void>
  clearAllWidgets(): Promise<void>

  addListener(eventName: string): void
  removeListeners(count: number): void
}

export default TurboModuleRegistry.get<Spec>('VoltraModule')
