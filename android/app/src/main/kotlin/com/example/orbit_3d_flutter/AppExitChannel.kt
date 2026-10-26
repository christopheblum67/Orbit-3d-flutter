package com.example.orbit_3d_flutter

import android.app.Activity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Pont Dart <-> natif : sortie propre de l'application.
 *
 * Méthode (MethodChannel « orbit.iptv/app_exit ») :
 *  - `exitApp` : termine l'Activity et retire la tâche de la pile récents
 *    via finishAndRemoveTask() (API 21+). Fallback finishAffinity() + System.exit(0)
 *    pour les anciennes versions.
 */
object AppExitChannel {
    private const val CHANNEL = "orbit.iptv/app_exit"

    @Volatile private var channel: MethodChannel? = null

    fun register(engine: FlutterEngine, activity: Activity) {
        val ch = MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
        channel = ch
        ch.setMethodCallHandler { call, result ->
            when (call.method) {
                "exitApp" -> {
                    exitApplication(activity)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun exitApplication(activity: Activity) {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.LOLLIPOP) {
            // API 21+ : finishAndRemoveTask() retire l'app de la pile récents
            activity.finishAndRemoveTask()
        } else {
            // Ancien API : finishAffinity() + System.exit(0)
            activity.finishAffinity()
            System.exit(0)
        }
    }

    fun detach() {
        channel?.setMethodCallHandler(null)
        channel = null
    }
}