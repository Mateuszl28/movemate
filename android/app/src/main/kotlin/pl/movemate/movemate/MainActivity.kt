package pl.movemate.movemate

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "pl.movemate.movemate/shortcuts"
    private var channel: MethodChannel? = null
    private var pendingAction: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        channel?.setMethodCallHandler { call, result ->
            if (call.method == "consume") {
                val action = pendingAction
                pendingAction = null
                result.success(action)
            } else {
                result.notImplemented()
            }
        }
        pendingAction = mapAction(intent?.action)
    }

    override fun onNewIntent(newIntent: Intent) {
        super.onNewIntent(newIntent)
        val action = mapAction(newIntent.action)
        if (action != null) {
            pendingAction = action
            channel?.invokeMethod("shortcut", action)
        }
    }

    private fun mapAction(action: String?): String? = when (action) {
        "pl.movemate.movemate.OPEN_PAIN" -> "pain"
        "pl.movemate.movemate.OPEN_STRETCH" -> "stretch"
        "pl.movemate.movemate.OPEN_BREATHING" -> "breathing"
        else -> null
    }
}
