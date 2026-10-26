package com.example.orbit_3d_flutter

import android.app.Activity
import android.content.Intent
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Pont Dart <-> natif : redémarrage de l'application.
 *
 * Méthode (MethodChannel « orbit/restart ») :
 *  - `restartApp` : relance l'Activity principale (MainActivity) via Intent
 *    avec FLAG_ACTIVITY_CLEAR_TOP | FLAG_ACTIVITY_NEW_TASK.
 */
object RestartChannel {
    private const val CHANNEL = "orbit/restart"

    @Volatile private var channel: MethodChannel? = null

    fun register(engine: FlutterEngine, activity: Activity) {
        val ch = MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
        channel = ch
        ch.setMethodCallHandler { call, result ->
            when (call.method) {
                "restartApp" -> {
                    restartApplication(activity)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun restartApplication(activity: Activity) {
        val intent = Intent(activity, MainActivity::class.java)
        intent.apply {
            addFlags(
                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TASK
            )
        }
        activity.startActivity(intent)
        activity.finishAffinity()
        System.exit(0)
    }

    fun detach() {
        channel?.setMethodCallHandler(null)
        channel = null
    }
}