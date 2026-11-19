package com.example.orbit_3d_flutter

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

object ExternalPlayerChannel {
    private const val requestCode = 20374
    private var channel: MethodChannel? = null
    private var pendingSession: Int? = null
    private var pendingEngine: String? = null

    fun register(engine: FlutterEngine, activity: Activity) {
        val playerChannel = MethodChannel(engine.dartExecutor.binaryMessenger, "orbit/external_player")
        channel = playerChannel
        playerChannel
            .setMethodCallHandler { call, result ->
                if (call.method != "open") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val url = call.argument<String>("url")
                val player = call.argument<String>("engine")
                val session = call.argument<Int>("session")
                val positionMs = call.argument<Number>("positionMs")?.toLong()
                val packages = when (player) {
                    "vlc" -> listOf("org.videolan.vlc")
                    "mxPlayer" -> listOf("com.mxtech.videoplayer.ad", "com.mxtech.videoplayer.pro")
                    else -> emptyList()
                }
                val uri = url?.let(Uri::parse)
                if (uri == null || uri.scheme !in listOf("http", "https") ||
                    packages.isEmpty() || (positionMs != null && positionMs < 0)) {
                    result.error("invalid_argument", "Invalid player or stream URL", null)
                    return@setMethodCallHandler
                }
                if (session != null && pendingSession != null) {
                    result.error("player_busy", "External player is already open", null)
                    return@setMethodCallHandler
                }
                val candidates = if (player == "mxPlayer" && session != null)
                    packages.map { it to true } + packages.map { it to false }
                else packages.map { it to false }
                for ((packageName, explicitMxActivity) in candidates) {
                    val intent = Intent(Intent.ACTION_VIEW).apply {
                        setDataAndType(uri, "video/*")
                        if (positionMs != null) {
                            if (player == "vlc") {
                                putExtra("from_start", positionMs == 0L)
                                putExtra("position", positionMs)
                            } else {
                                putExtra("position", positionMs.coerceAtMost(Int.MAX_VALUE.toLong()).toInt())
                            }
                        }
                        if (explicitMxActivity) {
                            val activityName = if (packageName.endsWith(".pro"))
                                "com.mxtech.videoplayer.ActivityScreen"
                            else
                                "com.mxtech.videoplayer.ad.ActivityScreen"
                            setClassName(packageName, activityName)
                            putExtra("return_result", true)
                        } else {
                            setPackage(packageName)
                        }
                    }
                    try {
                        if (session != null) {
                            pendingSession = session
                            pendingEngine = if (player == "vlc" || explicitMxActivity) player else null
                            activity.startActivityForResult(intent, requestCode)
                        } else {
                            activity.startActivity(intent)
                        }
                        result.success(true)
                        return@setMethodCallHandler
                    } catch (_: ActivityNotFoundException) {
                        pendingSession = null
                        pendingEngine = null
                        // Try the next supported edition.
                    } catch (_: SecurityException) {
                        pendingSession = null
                        pendingEngine = null
                        result.error("launch_denied", "External player launch denied", null)
                        return@setMethodCallHandler
                    }
                }
                result.success(false)
            }
    }

    fun onActivityResult(request: Int, resultCode: Int, data: Intent?): Boolean {
        if (request != requestCode) return false
        val session = pendingSession ?: return true
        val player = pendingEngine
        val completed = player == "mxPlayer" &&
            resultCode == Activity.RESULT_OK &&
            data?.getStringExtra("end_by") == "playback_completion"
        val position: Long?
        val duration: Long?
        if (resultCode == Activity.RESULT_OK && data != null && player == "vlc" &&
            data.hasExtra("extra_position") && data.hasExtra("extra_duration")) {
            position = data.getLongExtra("extra_position", -1)
            duration = data.getLongExtra("extra_duration", -1)
        } else if (resultCode == Activity.RESULT_OK && data != null && player == "mxPlayer" &&
            data.hasExtra("position") && data.hasExtra("duration")) {
            position = data.getIntExtra("position", -1).toLong()
            duration = data.getIntExtra("duration", -1).toLong()
        } else {
            position = null
            duration = null
        }
        pendingSession = null
        pendingEngine = null
        val result = mutableMapOf<String, Any>("session" to session, "completed" to completed)
        if (position != null && duration != null && position >= 0 &&
            duration > 0 && position <= duration) {
            result["positionMs"] = position
            result["durationMs"] = duration
        }
        channel?.invokeMethod("playbackFinished", result)
        return true
    }
}
