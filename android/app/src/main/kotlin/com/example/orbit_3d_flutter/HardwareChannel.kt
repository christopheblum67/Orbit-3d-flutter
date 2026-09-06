package com.example.orbit_3d_flutter

import android.app.ActivityManager
import android.content.Context
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Pont Dart <-> natif : mémoire totale de l'appareil.
 *
 * Méthodes (MethodChannel « orbit/hardware ») :
 *  - `getMemory` : {totalMb, lowRam} via ActivityManager.MemoryInfo
 *    (device_info_plus n'expose pas la RAM totale).
 */
object HardwareChannel {
    private const val CHANNEL = "orbit/hardware"

    fun register(engine: FlutterEngine, context: Context) {
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getMemory" -> {
                    val activityManager =
                        context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                    val memoryInfo = ActivityManager.MemoryInfo()
                    activityManager.getMemoryInfo(memoryInfo)
                    val totalMb = (memoryInfo.totalMem / (1024 * 1024)).toDouble()
                    result.success(
                        mapOf(
                            "totalMb" to totalMb,
                            "lowRam" to activityManager.isLowRamDevice,
                        ),
                    )
                }
                else -> result.notImplemented()
            }
        }
    }
}