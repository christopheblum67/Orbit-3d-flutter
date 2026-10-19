package com.example.orbit_3d_flutter

import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Pont Dart <-> natif pour piloter le [MediaPlaybackService].
 *
 * Méthodes Dart -> natif (MethodChannel « orbit/playback_service ») :
 *  - `start` : {title, subtitle, playing} — lance / met à jour le foreground
 *    service de type mediaPlayback (Android 14+) et la MediaSession.
 *  - `update` : {title, subtitle, playing} — met à jour métadonnées et état
 *    play/pause de la MediaSession sans relancer le service.
 *  - `stop` : — arrête le foreground service et retire la notification.
 *
 * Sens natif -> Dart : la MediaSession émet une commande distante
 * (`play`/`pause`/`stop`/`next`/`previous`) via [sendCommand], consommée par
 * `BackgroundPlaybackService.commands` côté Flutter.
 *
 * Le canal est conservé en référence statique : le service natif doit pouvoir
 * émettre vers Dart sans dépendre d'une instance de pont.
 */
object PlaybackServiceChannel {
    private const val CHANNEL = "orbit/playback_service"

    @Volatile private var channel: MethodChannel? = null

    private val mainHandler = Handler(Looper.getMainLooper())

    fun register(engine: FlutterEngine, context: Context) {
        val ch = MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
        channel = ch
        ch.setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    sendToService(context, MediaPlaybackService.ACTION_START, call, foreground = true)
                    result.success(true)
                }
                "update" -> {
                    sendToService(context, MediaPlaybackService.ACTION_UPDATE, call, foreground = true)
                    result.success(true)
                }
                "stop" -> {
                    val intent = Intent(context, MediaPlaybackService::class.java).apply {
                        action = MediaPlaybackService.ACTION_STOP
                    }
                    context.startService(intent)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    /** Émet une commande vers Dart. Flutter impose le main thread. */
    fun sendCommand(command: String) {
        val ch = channel ?: return
        mainHandler.post {
            runCatching { ch.invokeMethod("command", command) }
        }
    }

    /**
     * Détache le canal de l'engine : retire le handler du binaryMessenger, libère
     * la référence statique et purge les commandes en attente sur le main thread.
     *
     * À appeler depuis [MainActivity.onDestroy] avant la destruction de l'engine.
     * Sans cela `channel` (référence statique, conservée volontairement pour que le
     * service natif puisse émettre vers Dart) maintient le messenger de l'engine et,
     * à travers le handler enregistré, le `context` capturé — donc l'Activity
     * détruite resterait fortement atteignable jusqu'à la fin du processus.
     *
     * Comportement inchangé : après détachement, [sendCommand] retourne simplement
     * sans rien faire, exactement comme l'appel à `invokeMethod` sur un engine déjà
     * détruit, dont l'exception était déjà avalée par `runCatching`.
     */
    fun detach() {
        channel?.setMethodCallHandler(null)
        channel = null
        mainHandler.removeCallbacksAndMessages(null)
    }

    private fun sendToService(
        context: Context,
        action: String,
        call: MethodCall,
        foreground: Boolean,
    ) {
        val intent = Intent(context, MediaPlaybackService::class.java).apply {
            this.action = action
            putExtra(
                MediaPlaybackService.EXTRA_TITLE,
                call.argument<String>("title") ?: "Orbit",
            )
            putExtra(
                MediaPlaybackService.EXTRA_SUBTITLE,
                call.argument<String>("subtitle") ?: "Lecture en cours",
            )
            putExtra(MediaPlaybackService.EXTRA_PLAYING, call.argument<Boolean>("playing") ?: true)
        }
        if (foreground && Build.VERSION.SDK_INT >= 26) {
            context.startForegroundService(intent)
        } else {
            context.startService(intent)
        }
    }
}
