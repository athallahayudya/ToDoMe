package com.todome.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import java.util.TimeZone

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.todome/timezone"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        // REGISTER ALL PLUGINS (Firebase, Notifications, etc.)
        GeneratedPluginRegistrant.registerWith(flutterEngine)

        super.configureFlutterEngine(flutterEngine)

        // CUSTOM METHOD CHANNEL UNTUK TIMEZONE
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "getLocalTimezone") {
                    val timeZoneId = TimeZone.getDefault().id
                    result.success(timeZoneId)
                } else {
                    result.notImplemented()
                }
            }
    }
}
