package org.hanbova.hanbova

import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private companion object {
        const val sensitiveScreenChannel = "org.hanbova.hanbova/sensitive_screen"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, sensitiveScreenChannel)
            .setMethodCallHandler { call, result ->
                if (call.method != "setSensitiveScreen") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }

                if (call.argument<Boolean>("enabled") == true) {
                    window.setFlags(
                        WindowManager.LayoutParams.FLAG_SECURE,
                        WindowManager.LayoutParams.FLAG_SECURE,
                    )
                } else {
                    window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                }
                result.success(null)
            }
    }

    override fun onDestroy() {
        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
        super.onDestroy()
    }
}
