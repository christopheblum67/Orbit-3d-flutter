package com.example.orbit_3d_flutter

import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Recoit les journaux de diagnostic Dart et les redistribue vers
 * `android.util.Log`, qui est toujours capture par logcat.
 *
 * `debugPrint` est throttle et `developer.log` peut etre filtre selon le niveau :
 * aucun des deux n'est fiable pour diagnostiquer sur un APK debug lance hors
 * de `flutter run`. Ce canal garantit la visibilite.
 */
object AppLogChannel {
    private const val CHANNEL = "com.example.orbit_3d_flutter/app_log"
    private const val TAG = "OrbitDiag"

    @Volatile private var channel: MethodChannel? = null

    fun register(engine: FlutterEngine, activity: android.app.Activity?) {
        val ch = MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
        channel = ch
        ch.setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
            when (call.method) {
                "log" -> {
                    val arg = call.arguments
                    val msg = when (arg) {
                        is Map<*, *> -> arg["message"] as? String ?: ""
                        is String -> arg
                        else -> ""
                    }
                    Log.i(TAG, msg)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        Log.i(TAG, "canal de log enregistre")
    }

    /**
     * Detache le canal : retire le handler du binaryMessenger et libere la
     * reference statique au MethodChannel.
     *
     * Appele depuis [MainActivity.onDestroy] avant la destruction de l'engine.
     * Le handler, qui capture l'Activity / le Context, n'est alors plus
     * atteignable depuis une racine statique.
     */
    fun detach() {
        channel?.setMethodCallHandler(null)
        channel = null
    }
}
