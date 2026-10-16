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
import android.support.v4.media.MediaMetadataCompat
import android.support.v4.media.session.MediaSessionCompat
import android.support.v4.media.session.PlaybackStateCompat
import androidx.media.session.MediaButtonReceiver
import androidx.core.app.NotificationCompat
import androidx.media.app.NotificationCompat.MediaStyle

/**
 * Service de premier plan (foregroundServiceType = mediaPlayback) qui maintient
 * le processus vivant pendant la lecture, affiche la notification de lecture et
 * porte la [MediaSessionCompat] de l'application.
 *
 * L'audio/vidéo reste piloté par ExoPlayer dans le fork video_player_android :
 * ce service ne lit rien lui-même. Il expose en revanche la session média qui
 * reçoit les commandes de la télécommande TV, d'un casque Bluetooth ou des
 * contrôles système, et les relaie à Flutter via [PlaybackServiceChannel].
 *
 * Commandé par Intent (via PlaybackServiceChannel) :
 *  - ACTION_START(title, subtitle, playing) → startForeground(type mediaPlayback)
 *  - ACTION_UPDATE(title, subtitle, playing) → met à jour session + notification
 *  - ACTION_STOP → stopForeground + stopSelf
 *  - ACTION_MEDIA_BUTTON → routé vers la session (MediaButtonReceiver)
 */
class MediaPlaybackService : Service() {

    companion object {
        const val ACTION_START = "com.example.orbit_3d_flutter.ACTION_PLAYBACK_START"
        const val ACTION_UPDATE = "com.example.orbit_3d_flutter.ACTION_PLAYBACK_UPDATE"
        const val ACTION_STOP = "com.example.orbit_3d_flutter.ACTION_PLAYBACK_STOP"
        const val EXTRA_TITLE = "title"
        const val EXTRA_SUBTITLE = "subtitle"
        const val EXTRA_PLAYING = "playing"

        private const val CHANNEL_ID = "orbit_playback"
        private const val NOTIF_ID = 0xBEEF
        private const val SESSION_TAG = "OrbitMediaSession"
    }

    private var session: MediaSessionCompat? = null
    private var title: String = "Orbit"
    private var subtitle: String = "Lecture en cours"
    private var playing: Boolean = true

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        val s = MediaSessionCompat(this, SESSION_TAG).apply {
            setCallback(object : MediaSessionCompat.Callback() {
                override fun onPlay() = dispatch("play")
                override fun onPause() = dispatch("pause")
                override fun onStop() = dispatch("stop")
                override fun onSkipToNext() = dispatch("next")
                override fun onSkipToPrevious() = dispatch("previous")
            })
            // Sans PendingIntent de bouton média, les touches d'un casque/TV
            // ne sont pas routées vers la session.
            setMediaButtonReceiver(
                MediaButtonReceiver.buildMediaButtonPendingIntent(
                    this@MediaPlaybackService,
                    PlaybackStateCompat.ACTION_PLAY_PAUSE,
                ),
            )
            isActive = true
        }
        session = s
    }

    override fun onDestroy() {
        session?.release()
        session = null
        super.onDestroy()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // Un ACTION_MEDIA_BUTTON arrive ici via MediaButtonReceiver : on le
        // renvoie à la session, dont le callback relaiera la commande à Flutter.
        session?.let { MediaButtonReceiver.handleIntent(it, intent) }

        when (intent?.action) {
            ACTION_START, ACTION_UPDATE -> {
                title = intent.getStringExtra(EXTRA_TITLE) ?: title
                subtitle = intent.getStringExtra(EXTRA_SUBTITLE) ?: subtitle
                playing = intent.getBooleanExtra(EXTRA_PLAYING, playing)
                createNotificationChannel()
                updateSessionState()
                startForegroundCompat()
            }
            ACTION_STOP -> {
                session?.isActive = false
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
            }
        }
        return START_NOT_STICKY
    }

    private fun dispatch(command: String) {
        PlaybackServiceChannel.sendCommand(command)
    }

    private fun updateSessionState() {
        val s = session ?: return
        s.setMetadata(
            MediaMetadataCompat.Builder()
                .putString(MediaMetadataCompat.METADATA_KEY_TITLE, title)
                .putString(MediaMetadataCompat.METADATA_KEY_ARTIST, subtitle)
                .build(),
        )
        val state =
            if (playing) PlaybackStateCompat.STATE_PLAYING else PlaybackStateCompat.STATE_PAUSED
        s.setPlaybackState(
            PlaybackStateCompat.Builder()
                .setActions(
                    PlaybackStateCompat.ACTION_PLAY or
                        PlaybackStateCompat.ACTION_PAUSE or
                        PlaybackStateCompat.ACTION_PLAY_PAUSE or
                        PlaybackStateCompat.ACTION_STOP or
                        PlaybackStateCompat.ACTION_SKIP_TO_NEXT or
                        PlaybackStateCompat.ACTION_SKIP_TO_PREVIOUS,
                )
                .setState(state, PlaybackStateCompat.PLAYBACK_POSITION_UNKNOWN, if (playing) 1f else 0f)
                .build(),
        )
    }

    private fun startForegroundCompat() {
        val notification = buildNotification()
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

    private fun buildNotification(): Notification {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val contentIntent = PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_launcher_foreground)
            .setContentTitle(title)
            .setContentText(subtitle)
            .setContentIntent(contentIntent)
            .setOngoing(playing)
            .setOnlyAlertOnce(true)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setCategory(NotificationCompat.CATEGORY_TRANSPORT)

        val token = session?.sessionToken
        if (token != null) {
            builder.setStyle(
                MediaStyle()
                    .setMediaSession(token)
                    .setShowActionsInCompactView(0, 1),
            )
            builder.addAction(
                NotificationCompat.Action(
                    android.R.drawable.ic_media_previous,
                    "Précédent",
                    MediaButtonReceiver.buildMediaButtonPendingIntent(
                        this,
                        PlaybackStateCompat.ACTION_SKIP_TO_PREVIOUS,
                    ),
                ),
            )
            builder.addAction(
                NotificationCompat.Action(
                    if (playing) android.R.drawable.ic_media_pause else android.R.drawable.ic_media_play,
                    if (playing) "Pause" else "Lecture",
                    MediaButtonReceiver.buildMediaButtonPendingIntent(
                        this,
                        PlaybackStateCompat.ACTION_PLAY_PAUSE,
                    ),
                ),
            )
            builder.addAction(
                NotificationCompat.Action(
                    android.R.drawable.ic_media_next,
                    "Suivant",
                    MediaButtonReceiver.buildMediaButtonPendingIntent(
                        this,
                        PlaybackStateCompat.ACTION_SKIP_TO_NEXT,
                    ),
                ),
            )
        }

        return builder.build()
    }
}
