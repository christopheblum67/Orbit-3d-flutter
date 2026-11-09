package com.example.orbit_3d_flutter

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

object ExternalPlayerChannel {
    fun register(engine: FlutterEngine, activity: Activity) {
        MethodChannel(engine.dartExecutor.binaryMessenger, "orbit/external_player")
            .setMethodCallHandler { call, result ->
                if (call.method != "open") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val url = call.argument<String>("url")
                val packages = when (call.argument<String>("engine")) {
                    "vlc" -> listOf("org.videolan.vlc")
                    "mxPlayer" -> listOf("com.mxtech.videoplayer.ad", "com.mxtech.videoplayer.pro")
                    else -> emptyList()
                }
                val uri = url?.let(Uri::parse)
                if (uri == null || uri.scheme !in listOf("http", "https") || packages.isEmpty()) {
                    result.error("invalid_argument", "Invalid player or stream URL", null)
                    return@setMethodCallHandler
                }
                for (packageName in packages) {
                    val intent = Intent(Intent.ACTION_VIEW).apply {
                        setDataAndType(uri, "video/*")
                        setPackage(packageName)
                    }
                    try {
                        activity.startActivity(intent)
                        result.success(true)
                        return@setMethodCallHandler
                    } catch (_: ActivityNotFoundException) {
                        // Try the next supported edition.
                    } catch (_: SecurityException) {
                        result.error("launch_denied", "External player launch denied", null)
                        return@setMethodCallHandler
                    }
                }
                result.success(false)
            }
    }
}
