package com.example.orbit_3d_flutter

import android.content.Context
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.videoplayer.NightFocusDspConfig

/**
 * Pont Dart <-> natif : transmet la config tonore « Night Focus » au
 * processeur audio du renderer vendorisé (video_player_android).
 *
 * Méthodes (MethodChannel « orbit/night_focus ») :
 *  - `configure` : {enabled, dialogueBoostDb, bassKillerCutoffHz, vocalGainDb,
 *    audioDelayMs} — copie les paramètres dans NightFocusDspConfig.
 */
object NightFocusChannel {
    private const val CHANNEL = "orbit/night_focus"

    fun register(engine: FlutterEngine, context: Context) {
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "configure" -> {
                    val args = call.arguments as? Map<*, *> ?: emptyMap<Any?, Any?>()
                    NightFocusDspConfig.enabled = (args["enabled"] as? Boolean) ?: false
                    NightFocusDspConfig.dialogueBoostDb = (args["dialogueBoostDb"] as? Number)?.toDouble()
                        ?: NightFocusDspConfig.dialogueBoostDb
                    NightFocusDspConfig.bassKillerCutoffHz = (args["bassKillerCutoffHz"] as? Number)
                        ?.toDouble() ?: NightFocusDspConfig.bassKillerCutoffHz
                    NightFocusDspConfig.vocalGainDb = (args["vocalGainDb"] as? Number)?.toDouble()
                        ?: NightFocusDspConfig.vocalGainDb
                    NightFocusDspConfig.audioDelayMs = (args["audioDelayMs"] as? Number)?.toInt()
                        ?: NightFocusDspConfig.audioDelayMs
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}