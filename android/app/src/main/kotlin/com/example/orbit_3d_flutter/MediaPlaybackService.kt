package com.example.orbit_3d_flutter

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

/**
 * Service de premier plan (foregroundServiceType = mediaPlayback) qui maintient
 * le processus vivant pendant la lecture en arrière-plan et satisfait l'exigence
 * Android 14+ (lecture en continu sans écran actif).
 *
 * L'audio/vidéo est piloté par ExoPlayer dans le fork video_player_android ;
 * ce service assure uniquement la persistance du processus et affiche la
 * notification de lecture obligatoire.
 *
 * Commandé par Intent (via PlaybackServiceChannel) :
 *  - ACTION_START(title, subtitle) → startForeground(type mediaPlayback)
 *  - ACTION_STOP → stopForeground + stopSelf
 */
class MediaPlaybackService : Service() {

    companion object {
        const val ACTION_START = "com.example.orbit_3d_flutter.ACTION_PLAYBACK_START"
        const val ACTION_STOP = "com.example.orbit_3d_flutter.ACTION_PLAYBACK_STOP"
        const val EXTRA_TITLE = "title"
        const val EXTRA_SUBTITLE = "subtitle"

        private const val CHANNEL_ID = "orbit_playback"
        private const val NOTIF_ID = 0xBEEF
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                val title = intent.getStringExtra(EXTRA_TITLE) ?: "Orbit"
                val subtitle = intent.getStringExtra(EXTRA_SUBTITLE) ?: "Lecture en cours"
                createNotificationChannel()
                val notification = buildNotification(title, subtitle)
                if (Build.VERSION.SDK_INT >= 29) {
                    startForeground(
                        NOTIF_ID,
                        notification,
                        ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK,
                    )
                } else {
                    startForeground(NOTIF_ID, notification)
                }
            }
            ACTION_STOP -> {
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
            }
        }
        return START_NOT_STICKY
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= 26) {
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (nm.getNotificationChannel(CHANNEL_ID) == null) {
                val channel = NotificationChannel(
                    CHANNEL_ID,
                    "Lecture en cours",
                    NotificationManager.IMPORTANCE_LOW,
                ).apply {
                    description = "Active pendant la lecture en arrière-plan"
                    setShowBadge(false)
                }
                nm.createNotificationChannel(channel)
            }
        }
    }

    private fun buildNotification(title: String, subtitle: String): Notification {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val contentIntent = PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_launcher_foreground)
            .setContentTitle(title)
            .setContentText(subtitle)
            .setContentIntent(contentIntent)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setCategory(NotificationCompat.CATEGORY_TRANSPORT)
            .build()
    }
}