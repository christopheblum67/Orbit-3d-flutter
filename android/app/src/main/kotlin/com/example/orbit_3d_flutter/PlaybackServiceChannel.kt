package com.example.orbit_3d_flutter

import android.content.Context
import android.content.Intent
import android.os.Build
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Pont Dart <-> natif pour piloter le [MediaPlaybackService].
 *
 * Méthodes (MethodChannel « orbit/playback_service ») :
 *  - `start` : {title, subtitle} — lance / met à jour le foreground service
 *    de type mediaPlayback (Android 14+).
 *  - `stop` : — arrête le foreground service et retire la notification.
 */
object PlaybackServiceChannel {
    private const val CHANNEL = "orbit/playback_service"

    fun register(engine: FlutterEngine, context: Context) {
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> {
                        val title = call.argument<String>("title") ?: "Orbit"
                        val subtitle = call.argument<String>("subtitle")
                            ?: "Lecture en cours"
                        val intent = Intent(context, MediaPlaybackService::class.java).apply {
                            action = MediaPlaybackService.ACTION_START
                            putExtra(MediaPlaybackService.EXTRA_TITLE, title)
                            putExtra(MediaPlaybackService.EXTRA_SUBTITLE, subtitle)
                        }
                        if (Build.VERSION.SDK_INT >= 26) {
                            context.startForegroundService(intent)
                        } else {
                            context.startService(intent)
                        }
                        result.success(true)
                    }
                    "stop" -> {
                        val intent = Intent(context, MediaPlaybackService::class.java).apply {
                            action = MediaPlaybackService.ACTION_STOP
                        }
                        context.startService(intent)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}