package com.example.orbit_3d_flutter

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        AppLogChannel.register(flutterEngine, this)
        NightFocusChannel.register(flutterEngine, this)
        PlayerConfigChannel.register(flutterEngine, this)
        HardwareChannel.register(flutterEngine, this)
        PipChannel.register(flutterEngine, this)
        PlaybackServiceChannel.register(flutterEngine, this)
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
        PlaybackServiceChannel.detach()
        super.onDestroy()
    }
}
