package voltra

import android.content.Context
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import androidx.glance.appwidget.ExperimentalGlanceRemoteViewsApi
import androidx.glance.appwidget.GlanceRemoteViews
import kotlin.math.abs
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import voltra.glance.GlanceFactory
import voltra.parsing.VoltraPayloadParser

@OptIn(ExperimentalGlanceRemoteViewsApi::class)
class VoltraView(context: Context) : FrameLayout(context) {
    private var mainScope: CoroutineScope? = null
    private val frameLayout = FrameLayout(context)
    private var viewId: String? = null
    private var payload: String? = null
    private var updateJob: Job? = null

    private var lastRenderedPayload: String? = null
    private var lastRenderedWidthDp: Float = 0f
    private var lastRenderedHeightDp: Float = 0f

    init {
        frameLayout.layoutParams =
                LayoutParams(
                        ViewGroup.LayoutParams.MATCH_PARENT,
                        ViewGroup.LayoutParams.MATCH_PARENT,
                )
        addView(frameLayout)
    }

    fun setViewId(id: String) {
        if (this.viewId == id) return
        this.viewId = id
        updateView()
    }

    fun setPayload(payload: String) {
        if (this.payload == payload) return
        this.payload = payload
        updateView()
    }

    private fun updateView() {
        val payloadStr = payload ?: return
        val id = viewId ?: return

        val density = context.resources.displayMetrics.density
        val widthDp = frameLayout.width.toFloat() / density
        val heightDp = frameLayout.height.toFloat() / density

        if (frameLayout.childCount > 0 &&
                        payloadStr == lastRenderedPayload &&
                        abs(widthDp - lastRenderedWidthDp) < 1.0f &&
                        abs(heightDp - lastRenderedHeightDp) < 1.0f
        ) {
            return
        }

        updateJob?.cancel()
        updateJob =
                mainScope?.launch {
                    try {
                        val voltraPayload =
                                withContext(Dispatchers.Default) {
                                    try {
                                        VoltraPayloadParser.parse(payloadStr)
                                    } catch (_: Exception) {
                                        null
                                    }
                                }
                                        ?: return@launch

                        val node =
                                voltraPayload.collapsed
                                        ?: voltraPayload.expanded
                                                ?: voltraPayload.variants?.get("content")
                                                ?: voltraPayload.variants?.values?.firstOrNull()

                        if (node == null) {
                            frameLayout.removeAllViews()
                            return@launch
                        }

                        val composeSize =
                                if (widthDp > 1f && heightDp > 1f) {
                                    DpSize(widthDp.dp, heightDp.dp)
                                } else {
                                    DpSize(300.dp, 200.dp)
                                }

                        val glanceRemoteViews = GlanceRemoteViews()
                        val factory = GlanceFactory(id, voltraPayload.e, voltraPayload.s)

                        val result =
                                withContext(Dispatchers.Default) {
                                    glanceRemoteViews.compose(context, composeSize) {
                                        factory.Render(node)
                                    }
                                }

                        ensureActive()

                        val remoteViews = result.remoteViews

                        withContext(Dispatchers.Main) {
                            try {
                                var applied = false
                                if (frameLayout.childCount > 0) {
                                    try {
                                        val existingView = frameLayout.getChildAt(0)
                                        remoteViews.reapply(context, existingView)
                                        applied = true
                                        lastRenderedPayload = payloadStr
                                        lastRenderedWidthDp = widthDp
                                        lastRenderedHeightDp = heightDp
                                    } catch (_: Exception) {}
                                }

                                if (!applied) {
                                    val inflatedView = remoteViews.apply(context, frameLayout)

                                    frameLayout.addView(inflatedView)

                                    val childCount = frameLayout.childCount
                                    if (childCount > 1) {
                                        frameLayout.removeViews(0, childCount - 1)
                                    }

                                    frameLayout.measure(
                                            View.MeasureSpec.makeMeasureSpec(
                                                    frameLayout.width,
                                                    View.MeasureSpec.EXACTLY
                                            ),
                                            View.MeasureSpec.makeMeasureSpec(
                                                    frameLayout.height,
                                                    View.MeasureSpec.EXACTLY
                                            ),
                                    )
                                    frameLayout.layout(
                                            frameLayout.left,
                                            frameLayout.top,
                                            frameLayout.right,
                                            frameLayout.bottom,
                                    )

                                    lastRenderedPayload = payloadStr
                                    lastRenderedWidthDp = widthDp
                                    lastRenderedHeightDp = heightDp
                                }
                            } catch (_: Exception) {}
                        }
                    } catch (_: CancellationException) {} catch (_: Exception) {}
                }
    }

    override fun onLayout(
            changed: Boolean,
            left: Int,
            top: Int,
            right: Int,
            bottom: Int,
    ) {
        super.onLayout(changed, left, top, right, bottom)
        if (changed) {
            val w = right - left
            val h = bottom - top
            if (w > 0 && h > 0) {
                updateView()
            }
        }
    }

    override fun onAttachedToWindow() {
        super.onAttachedToWindow()
        mainScope = CoroutineScope(Dispatchers.Main + SupervisorJob())
        updateView()
    }

    override fun onDetachedFromWindow() {
        super.onDetachedFromWindow()
        updateJob?.cancel()
        mainScope?.cancel()
        mainScope = null
    }
}
