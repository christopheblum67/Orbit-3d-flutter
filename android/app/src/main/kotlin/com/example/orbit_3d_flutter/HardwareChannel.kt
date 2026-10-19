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

    @Volatile private var channel: MethodChannel? = null

    fun register(engine: FlutterEngine, context: Context) {
        val ch = MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
        channel = ch
        ch.setMethodCallHandler { call, result ->
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