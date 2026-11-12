package com.example.orbit_3d_flutter

import android.content.Context
import android.content.pm.PackageManager
import android.media.AudioManager
import android.view.KeyEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        val handled = super.dispatchKeyEvent(event)
        if (event.action == KeyEvent.ACTION_DOWN &&
            packageManager.hasSystemFeature(PackageManager.FEATURE_LEANBACK) &&
            (event.keyCode == KeyEvent.KEYCODE_VOLUME_UP ||
                event.keyCode == KeyEvent.KEYCODE_VOLUME_DOWN ||
                event.keyCode == KeyEvent.KEYCODE_VOLUME_MUTE ||
                event.keyCode == KeyEvent.KEYCODE_MUTE)
        ) {
            val audio = getSystemService(Context.AUDIO_SERVICE) as AudioManager
            audio.adjustSuggestedStreamVolume(
                AudioManager.ADJUST_SAME,
                AudioManager.USE_DEFAULT_STREAM_TYPE,
                AudioManager.FLAG_SHOW_UI,
            )
        }
        return handled
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        AppLogChannel.register(flutterEngine, this)
        NightFocusChannel.register(flutterEngine, this)
        PlayerConfigChannel.register(flutterEngine, this)
        ExternalPlayerChannel.register(flutterEngine, this)
        HardwareChannel.register(flutterEngine, this)
        PipChannel.register(flutterEngine, this)
        PlaybackServiceChannel.register(flutterEngine, this)
    }
}
