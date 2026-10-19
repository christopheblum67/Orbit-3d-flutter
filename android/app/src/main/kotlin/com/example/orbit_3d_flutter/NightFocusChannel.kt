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
 *    audioDelayMs, volumeNormalization} — copie les paramètres dans
 *    NightFocusDspConfig puis incrémente sa version pour que le processeur
 *    audio recharge la config à chaud pendant la lecture.
 */
object NightFocusChannel {
    private const val CHANNEL = "orbit/night_focus"

    @Volatile private var channel: MethodChannel? = null

    fun register(engine: FlutterEngine, context: Context) {
        val ch = MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
        channel = ch
        ch.setMethodCallHandler { call, result ->
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
                    NightFocusDspConfig.volumeNormalization =
                        (args["volumeNormalization"] as? Boolean)
                            ?: NightFocusDspConfig.volumeNormalization
                    NightFocusDspConfig.touchVersion()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
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