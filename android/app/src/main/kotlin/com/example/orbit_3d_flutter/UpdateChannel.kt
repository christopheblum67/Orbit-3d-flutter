package com.example.orbit_3d_flutter

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

object UpdateChannel {
    @Suppress("DEPRECATION")
    private fun versionCode(info: PackageInfo): Long =
        if (Build.VERSION.SDK_INT >= 28) info.longVersionCode else info.versionCode.toLong()

    @Suppress("DEPRECATION")
    private fun signatures(info: PackageInfo): Set<List<Byte>> =
        (if (Build.VERSION.SDK_INT >= 28) info.signingInfo?.apkContentsSigners
         else info.signatures)?.map { it.toByteArray().toList() }?.toSet() ?: emptySet()

    @Suppress("DEPRECATION")
    fun register(engine: FlutterEngine, activity: Activity) {
        MethodChannel(engine.dartExecutor.binaryMessenger, "orbit/update")
            .setMethodCallHandler { call, result ->
                val pm = activity.packageManager
                val flags = if (Build.VERSION.SDK_INT >= 28)
                    PackageManager.GET_SIGNING_CERTIFICATES else PackageManager.GET_SIGNATURES
                try {
                    when (call.method) {
                        "version" -> {
                            val info = pm.getPackageInfo(activity.packageName, 0)
                            result.success(mapOf("versionName" to info.versionName, "versionCode" to versionCode(info)))
                        }
                        "install" -> {
                            val apk = File(activity.cacheDir, "updates/update.apk")
                            val expected = call.argument<String>("version")
                                ?.removePrefix("v")?.split("+")
                            val installed = pm.getPackageInfo(activity.packageName, flags)
                            val candidate = pm.getPackageArchiveInfo(apk.absolutePath, flags)
                            val trusted = signatures(installed)
                            if (!apk.isFile || candidate == null ||
                                expected == null || expected.isEmpty() ||
                                candidate.versionName != expected[0] ||
                                (expected.size > 1 && expected[1].toLongOrNull() != versionCode(candidate)) ||
                                candidate.packageName != activity.packageName ||
                                versionCode(candidate) <= versionCode(installed) ||
                                trusted.isEmpty() || signatures(candidate) != trusted) {
                                result.error("invalid_apk", "APK incompatible, incorrectement signé ou non plus récent", null)
                            } else if (Build.VERSION.SDK_INT >= 26 && !pm.canRequestPackageInstalls()) {
                                activity.startActivity(
                                    Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES)
                                        .setData(Uri.parse("package:${activity.packageName}"))
                                )
                                result.success(false)
                            } else {
                                val uri = FileProvider.getUriForFile(
                                    activity, "${activity.packageName}.updates", apk
                                )
                                activity.startActivity(Intent(Intent.ACTION_VIEW).apply {
                                    setDataAndType(uri, "application/vnd.android.package-archive")
                                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                })
                                result.success(true)
                            }
                        }
                        else -> result.notImplemented()
                    }
                } catch (_: ActivityNotFoundException) {
                    result.error("installer_unavailable", "Installateur Android indisponible", null)
                } catch (_: SecurityException) {
                    result.error("install_denied", "Installation refusée par Android", null)
                } catch (_: IllegalArgumentException) {
                    result.error("invalid_apk", "Fichier de mise à jour inaccessible", null)
                } catch (_: PackageManager.NameNotFoundException) {
                    result.error("package_unavailable", "Informations de l'application indisponibles", null)
                }
            }
    }
}
