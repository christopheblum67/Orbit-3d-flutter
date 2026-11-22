package com.example.orbit_3d_flutter

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.media.AudioManager
import android.os.Build
import android.os.Bundle
import android.view.KeyEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        if (isTvDevice()) {
            setTheme(R.style.TVTheme)
        } else {
            setTheme(R.style.NormalTheme)
        }
        super.onCreate(savedInstanceState)
    }

    private fun isTvDevice(): Boolean {
        val uiMode = resources.configuration.uiMode and Configuration.UI_MODE_TYPE_MASK
        return uiMode == Configuration.UI_MODE_TYPE_TELEVISION
            || (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R && packageManager.hasSystemFeature(PackageManager.FEATURE_LEANBACK))
    }

    @Deprecated("External players return their playback result through this callback")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (!ExternalPlayerChannel.onActivityResult(requestCode, resultCode, data)) {
            super.onActivityResult(requestCode, resultCode, data)
        }
    }

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
        ProfilePinChannel.register(flutterEngine)
        PipChannel.register(flutterEngine, this)
        PlaybackServiceChannel.register(flutterEngine, this)
        UpdateChannel.register(flutterEngine, this)
        RestartChannel.register(flutterEngine, this)
        AppExitChannel.register(flutterEngine, this)
    }

    /**
     * Détache les MethodChannel natifs avant que l'engine ne soit détruit.
     *
     * Doit s'exécuter **avant** `super.onDestroy()` : c'est là que
     * `FlutterActivityAndFragmentDelegate.onDetach()` détruit le `FlutterEngine`
     * (`shouldDestroyEngineWithHost()` vaut `true`, l'engine étant créé par
     * l'Activity — aucun `provideFlutterEngine` ni `FlutterEngineCache` ici).
     *
     * Chaque `detach()` retire son handler du binaryMessenger et libère sa
     * référence statique au MethodChannel. Sans cet appel, les singletons
     * `object` retiendraient le messenger de l'engine et, via les handlers
     * enregistrés, l'Activity/le Context capturé : une Activity détruite
     * resterait atteignable depuis une racine statique jusqu'à la fin du
     * processus.
     *
     * Comportement inchangé : les canaux sont ré-enregistrés à l'identique au
     * prochain `configureFlutterEngine`, et après destruction de l'engine il
     * n'existe plus de côté Dart pour appeler ces canaux.
     */
    override fun onDestroy() {
        AppLogChannel.detach()
        NightFocusChannel.detach()
        PlayerConfigChannel.detach()
        HardwareChannel.detach()
        PipChannel.detach()
        RestartChannel.detach()
        AppExitChannel.detach()
        super.onDestroy()
    }
}
