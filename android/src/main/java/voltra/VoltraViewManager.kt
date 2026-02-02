package voltra

import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.annotations.ReactProp

@ReactModule(name = VoltraViewManager.REACT_CLASS)
class VoltraViewManager : SimpleViewManager<VoltraView>() {
    companion object {
        const val REACT_CLASS = "VoltraView"
    }

    override fun getName(): String = REACT_CLASS

    override fun createViewInstance(reactContext: ThemedReactContext): VoltraView {
        return VoltraView(reactContext)
    }

    @ReactProp(name = "payload")
    fun setPayload(view: VoltraView, payload: String) {
        view.setPayload(payload)
    }

    @ReactProp(name = "viewId")
    fun setViewId(view: VoltraView, viewId: String) {
        view.setViewId(viewId)
    }
}
