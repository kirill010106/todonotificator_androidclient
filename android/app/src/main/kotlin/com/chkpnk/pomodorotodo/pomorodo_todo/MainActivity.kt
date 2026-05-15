package com.chkpnk.pomodorotodo.pomorodo_todo

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent

private const val CHANNEL = "pomodoro/foreground"

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startForeground" -> {
                    val title = call.argument<String>("title") ?: "Таймер запущен"
                    val body = call.argument<String>("body") ?: ""
                    val intent = Intent(this, ForegroundTimerService::class.java).apply {
                        putExtra(ForegroundTimerService.EXTRA_ACTION, ForegroundTimerService.ACTION_START)
                        putExtra(ForegroundTimerService.EXTRA_TITLE, title)
                        putExtra(ForegroundTimerService.EXTRA_BODY, body)
                    }
                    startForegroundService(intent)
                    result.success(null)
                }
                "updateForeground" -> {
                    val title = call.argument<String>("title") ?: "Таймер запущен"
                    val body = call.argument<String>("body") ?: ""
                    val intent = Intent(this, ForegroundTimerService::class.java).apply {
                        putExtra(ForegroundTimerService.EXTRA_ACTION, ForegroundTimerService.ACTION_UPDATE)
                        putExtra(ForegroundTimerService.EXTRA_TITLE, title)
                        putExtra(ForegroundTimerService.EXTRA_BODY, body)
                    }
                    startForegroundService(intent)
                    result.success(null)
                }
                "stopForeground" -> {
                    val intent = Intent(this, ForegroundTimerService::class.java).apply {
                        putExtra(ForegroundTimerService.EXTRA_ACTION, ForegroundTimerService.ACTION_STOP)
                    }
                    startService(intent)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
