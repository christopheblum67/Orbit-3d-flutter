package com.example.orbit_3d_flutter

import android.content.Context
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.videoplayer.OrbitPlayerConfig

/**
 * Pont Dart <-> natif : transmet les paramètres de lecture (tampon media3 et
 * limite de résolution) au fork video_player_android.
 *
 * Méthodes (MethodChannel « orbit/player_config ») :
 *  - `configure` : {minBufferMs, maxBufferMs, bufferForPlaybackMs,
 *    bufferForPlaybackAfterRebufferMs, maxVideoWidth, maxVideoHeight} —
 *    copie dans OrbitPlayerConfig avant construction de l'ExoPlayer.
 */
object PlayerConfigChannel {
    private const val CHANNEL = "orbit/player_config"

    fun register(engine: FlutterEngine, context: Context) {
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "configure" -> {
                    val args = call.arguments as? Map<*, *> ?: emptyMap<Any?, Any?>()
                    OrbitPlayerConfig.minBufferMs = (args["minBufferMs"] as? Number)?.toInt()
                        ?: OrbitPlayerConfig.minBufferMs
                    OrbitPlayerConfig.maxBufferMs = (args["maxBufferMs"] as? Number)?.toInt()
                        ?: OrbitPlayerConfig.maxBufferMs
                    OrbitPlayerConfig.bufferForPlaybackMs = (args["bufferForPlaybackMs"] as? Number)
                        ?.toInt() ?: OrbitPlayerConfig.bufferForPlaybackMs
                    OrbitPlayerConfig.bufferForPlaybackAfterRebufferMs =
                        (args["bufferForPlaybackAfterRebufferMs"] as? Number)?.toInt()
                            ?: OrbitPlayerConfig.bufferForPlaybackAfterRebufferMs
                    OrbitPlayerConfig.maxVideoWidth = (args["maxVideoWidth"] as? Number)?.toInt()
                        ?: OrbitPlayerConfig.maxVideoWidth
                    OrbitPlayerConfig.maxVideoHeight = (args["maxVideoHeight"] as? Number)?.toInt()
                        ?: OrbitPlayerConfig.maxVideoHeight
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}