package com.example.orbit_3d_flutter

import android.app.PictureInPictureParams
import android.content.pm.PackageManager
import android.os.Build
import android.util.Rational
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Pont Dart <-> natif pour le mode Picture-in-Picture (Android 8+).
 *
 * Méthodes (MethodChannel « orbit/pip ») :
 *  - `isSupported` : bool — le device expose la fonctionnalité PiP.
 *  - `enter` : {width, height} — demande l'entrée en PiP avec ce ratio
 *    (défaut 16:9). Retourne vrai si la demande a été acceptée.
 */
object PipChannel {
    private const val CHANNEL = "orbit/pip"

    fun register(engine: FlutterEngine, activity: FlutterActivity) {
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isSupported" -> {
                        val supported = activity.packageManager
                            .hasSystemFeature(PackageManager.FEATURE_PICTURE_IN_PICTURE)
                        result.success(supported)
                    }
                    "enter" -> {
                        if (Build.VERSION.SDK_INT >= 26 &&
                            activity.packageManager
                                .hasSystemFeature(PackageManager.FEATURE_PICTURE_IN_PICTURE)
                        ) {
                            val width = (call.argument<Number>("width") ?: 16).toInt()
                            val height = (call.argument<Number>("height") ?: 9).toInt()
                            val safeW = if (width > 0) width else 16
                            val safeH = if (height > 0) height else 9
                            val params = PictureInPictureParams.Builder()
                                .setAspectRatio(Rational(safeW, safeH))
                                .build()
                            activity.enterPictureInPictureMode(params)
                            result.success(true)
                        } else {
                            result.success(false)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}