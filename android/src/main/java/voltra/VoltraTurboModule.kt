package voltra

import android.util.Log
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import androidx.glance.appwidget.GlanceAppWidgetManager
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.modules.core.DeviceEventManagerModule
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.launch
import voltra.events.VoltraEventBus
import voltra.images.VoltraImageManager
import voltra.widget.VoltraGlanceWidget
import voltra.widget.VoltraWidgetManager

@ReactModule(name = VoltraTurboModule.NAME)
class VoltraTurboModule(reactContext: ReactApplicationContext) : NativeVoltraModuleSpec(reactContext) {
    companion object {
        const val NAME = "VoltraModule"
        private const val TAG = "VoltraTurboModule"
    }

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)

    private val notificationManager by lazy {
        VoltraNotificationManager(reactApplicationContext)
    }

    private val widgetManager by lazy {
        VoltraWidgetManager(reactApplicationContext)
    }

    private val imageManager by lazy {
        VoltraImageManager(reactApplicationContext)
    }

    private val eventBus by lazy {
        VoltraEventBus.getInstance(reactApplicationContext)
    }

    private var eventBusUnsubscribe: (() -> Unit)? = null

    override fun getName(): String = NAME

    private fun emitEvent(eventName: String, payload: ReadableMap) {
        reactApplicationContext
            .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
            .emit(eventName, payload)
    }

    // iOS-only Live Activity APIs (no-op / unsupported on Android)

    override fun startLiveActivity(
        jsonString: String,
        options: ReadableMap?,
        promise: Promise,
    ) {
        promise.reject("E_UNSUPPORTED", "Live Activities are iOS-only on Android.")
    }

    override fun updateLiveActivity(
        activityId: String,
        jsonString: String,
        options: ReadableMap?,
        promise: Promise,
    ) {
        promise.reject("E_UNSUPPORTED", "Live Activities are iOS-only on Android.")
    }

    override fun endLiveActivity(activityId: String, options: ReadableMap?, promise: Promise) {
        promise.reject("E_UNSUPPORTED", "Live Activities are iOS-only on Android.")
    }

    override fun endAllLiveActivities(promise: Promise) {
        promise.reject("E_UNSUPPORTED", "Live Activities are iOS-only on Android.")
    }

    override fun getLatestVoltraActivityId(promise: Promise) {
        promise.resolve(null)
    }

    override fun listVoltraActivityIds(promise: Promise) {
        promise.resolve(Arguments.createArray())
    }

    override fun isLiveActivityActive(activityName: String): Boolean = false

    override fun isHeadless(): Boolean = false

    // Android Live Update APIs

    override fun startAndroidLiveUpdate(payload: String, options: ReadableMap?, promise: Promise) {
        scope.launch {
            try {
                val updateName = options?.getString("updateName")
                val channelId = options?.getString("channelId") ?: "voltra_live_updates"
                val result = notificationManager.startLiveUpdate(payload, updateName, channelId)
                promise.resolve(result)
            } catch (e: Exception) {
                promise.reject("E_START_LIVE_UPDATE", e)
            }
        }
    }

    override fun updateAndroidLiveUpdate(notificationId: String, payload: String, promise: Promise) {
        scope.launch {
            try {
                notificationManager.updateLiveUpdate(notificationId, payload)
                promise.resolve(null)
            } catch (e: Exception) {
                promise.reject("E_UPDATE_LIVE_UPDATE", e)
            }
        }
    }

    override fun stopAndroidLiveUpdate(notificationId: String, promise: Promise) {
        scope.launch {
            try {
                notificationManager.stopLiveUpdate(notificationId)
                promise.resolve(null)
            } catch (e: Exception) {
                promise.reject("E_STOP_LIVE_UPDATE", e)
            }
        }
    }

    override fun isAndroidLiveUpdateActive(updateName: String): Boolean =
        notificationManager.isLiveUpdateActive(updateName)

    override fun endAllAndroidLiveUpdates(promise: Promise) {
        scope.launch {
            try {
                notificationManager.endAllLiveUpdates()
                promise.resolve(null)
            } catch (e: Exception) {
                promise.reject("E_END_ALL_LIVE_UPDATES", e)
            }
        }
    }

    // Android Widget APIs

    override fun updateAndroidWidget(widgetId: String, jsonString: String, options: ReadableMap?, promise: Promise) {
        scope.launch {
            try {
                val deepLinkUrl = options?.getString("deepLinkUrl")
                widgetManager.writeWidgetData(widgetId, jsonString, deepLinkUrl)
                widgetManager.updateWidget(widgetId)
                promise.resolve(null)
            } catch (e: Exception) {
                promise.reject("E_UPDATE_ANDROID_WIDGET", e)
            }
        }
    }

    override fun reloadAndroidWidgets(widgetIds: ReadableArray?, promise: Promise) {
        scope.launch {
            try {
                val ids = widgetIds?.toArrayList()?.mapNotNull { it as? String }
                widgetManager.reloadWidgets(ids)
                promise.resolve(null)
            } catch (e: Exception) {
                promise.reject("E_RELOAD_ANDROID_WIDGETS", e)
            }
        }
    }

    override fun clearAndroidWidget(widgetId: String, promise: Promise) {
        scope.launch {
            try {
                widgetManager.clearWidgetData(widgetId)
                widgetManager.updateWidget(widgetId)
                promise.resolve(null)
            } catch (e: Exception) {
                promise.reject("E_CLEAR_ANDROID_WIDGET", e)
            }
        }
    }

    override fun clearAllAndroidWidgets(promise: Promise) {
        scope.launch {
            try {
                widgetManager.clearAllWidgetData()
                widgetManager.reloadAllWidgets()
                promise.resolve(null)
            } catch (e: Exception) {
                promise.reject("E_CLEAR_ALL_ANDROID_WIDGETS", e)
            }
        }
    }

    override fun requestPinGlanceAppWidget(widgetId: String, options: ReadableMap?, promise: Promise) {
        scope.launch {
            try {
                val context = reactApplicationContext
                val receiverClassName = "${context.packageName}.widget.VoltraWidget_${widgetId}Receiver"
                val receiverClass =
                    try {
                        Class.forName(receiverClassName) as Class<out androidx.glance.appwidget.GlanceAppWidgetReceiver>
                    } catch (e: ClassNotFoundException) {
                        throw IllegalArgumentException("Widget receiver not found for id: $widgetId", e)
                    }

                val glanceManager = GlanceAppWidgetManager(context)

                val previewSize =
                    if (options != null && options.hasKey("previewWidth") && options.hasKey("previewHeight")) {
                        val width = options.getDouble("previewWidth").toFloat()
                        val height = options.getDouble("previewHeight").toFloat()
                        DpSize(width.dp, height.dp)
                    } else {
                        null
                    }

                val result =
                    if (previewSize != null) {
                        val previewWidget = VoltraGlanceWidget(widgetId)
                        glanceManager.requestPinGlanceAppWidget(
                            receiver = receiverClass,
                            preview = previewWidget,
                            previewState = previewSize,
                        )
                    } else {
                        glanceManager.requestPinGlanceAppWidget(receiverClass)
                    }

                promise.resolve(result)
            } catch (e: Exception) {
                promise.reject("E_REQUEST_PIN_WIDGET", e)
            }
        }
    }

    override fun preloadImages(images: ReadableArray, promise: Promise) {
        scope.launch {
            try {
                val results =
                    images.toArrayList().mapNotNull { it as? ReadableMap }.map { img ->
                        async(Dispatchers.IO) {
                            val url = img.getString("url") ?: return@async Pair("", "Missing url")
                            val key = img.getString("key") ?: return@async Pair("", "Missing key")
                            val method = img.getString("method") ?: "GET"
                            val headers = if (img.hasKey("headers")) img.getMap("headers") else null

                            val headerMap = headers?.toHashMap()?.mapValues { it.value as String }

                            val resultKey = imageManager.preloadImage(url, key, method, headerMap)
                            if (resultKey != null) {
                                Pair(key, null)
                            } else {
                                Pair(key, "Failed to download image")
                            }
                        }
                    }.awaitAll()

                val succeeded = results.filter { it.second == null }.map { it.first }
                val failed = results.filter { it.second != null }.map {
                    Arguments.createMap().apply {
                        putString("key", it.first)
                        putString("error", it.second)
                    }
                }

                val resultMap = Arguments.createMap().apply {
                    val succeededArray = Arguments.createArray()
                    succeeded.forEach { succeededArray.pushString(it) }
                    val failedArray = Arguments.createArray()
                    failed.forEach { failedArray.pushMap(it) }
                    putArray("succeeded", succeededArray)
                    putArray("failed", failedArray)
                }

                promise.resolve(resultMap)
            } catch (e: Exception) {
                promise.reject("E_PRELOAD_IMAGES", e)
            }
        }
    }

    override fun clearPreloadedImages(keys: ReadableArray?, promise: Promise) {
        try {
            val keyList = keys?.toArrayList()?.mapNotNull { it as? String }
            imageManager.clearPreloadedImages(keyList)
            promise.resolve(null)
        } catch (e: Exception) {
            promise.reject("E_CLEAR_PRELOADED_IMAGES", e)
        }
    }

    override fun reloadLiveActivities(activityNames: ReadableArray?, promise: Promise) {
        Log.d(TAG, "reloadLiveActivities called (no-op on Android)")
        promise.resolve(null)
    }

    // iOS widget APIs (unsupported on Android)

    override fun updateWidget(widgetId: String, jsonString: String, options: ReadableMap?, promise: Promise) {
        promise.reject("E_UNSUPPORTED", "iOS widgets are not supported on Android.")
    }

    override fun scheduleWidget(widgetId: String, timelineJson: String, promise: Promise) {
        promise.reject("E_UNSUPPORTED", "iOS widgets are not supported on Android.")
    }

    override fun reloadWidgets(widgetIds: ReadableArray?, promise: Promise) {
        promise.reject("E_UNSUPPORTED", "iOS widgets are not supported on Android.")
    }

    override fun clearWidget(widgetId: String, promise: Promise) {
        promise.reject("E_UNSUPPORTED", "iOS widgets are not supported on Android.")
    }

    override fun clearAllWidgets(promise: Promise) {
        promise.reject("E_UNSUPPORTED", "iOS widgets are not supported on Android.")
    }

    override fun addListener(eventName: String) {
        if (eventBusUnsubscribe != null) return

        val persistedEvents = eventBus.popAll()
        persistedEvents.forEach { event ->
            emitEvent(event.type, Arguments.makeNativeMap(event.toMap()))
        }

        eventBusUnsubscribe = eventBus.addListener { event ->
            emitEvent(event.type, Arguments.makeNativeMap(event.toMap()))
        }
    }

    override fun removeListeners(count: Double) {
        eventBusUnsubscribe?.invoke()
        eventBusUnsubscribe = null
    }
}
