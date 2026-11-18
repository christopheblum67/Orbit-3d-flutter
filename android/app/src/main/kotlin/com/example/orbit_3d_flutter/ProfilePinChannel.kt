package com.example.orbit_3d_flutter

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMethodCodec
import java.security.NoSuchAlgorithmException
import javax.crypto.SecretKeyFactory
import javax.crypto.spec.PBEKeySpec

object ProfilePinChannel {
    fun register(engine: FlutterEngine) {
        val messenger = engine.dartExecutor.binaryMessenger
        val queue = messenger.makeBackgroundTaskQueue()
        MethodChannel(messenger, "orbit/profile_pin", StandardMethodCodec.INSTANCE, queue)
            .setMethodCallHandler { call, result ->
                if (call.method != "derive") {
                    result.notImplemented()
                } else {
                    val pin = call.argument<String>("pin")
                    val salt = call.argument<ByteArray>("salt")
                    val iterations = call.argument<Int>("iterations")
                    if (pin == null || !pin.matches(Regex("[0-9]{4}")) ||
                        salt == null || salt.size != 16 ||
                        iterations == null || iterations !in 1..120000
                    ) {
                        result.error("INVALID_ARGUMENT", "Invalid PIN derivation parameters", null)
                    } else {
                        try {
                            val factory = SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256")
                            val spec = PBEKeySpec(pin.toCharArray(), salt, iterations, 256)
                            try {
                                result.success(factory.generateSecret(spec).encoded)
                            } finally {
                                spec.clearPassword()
                            }
                        } catch (e: NoSuchAlgorithmException) {
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("DERIVATION_FAILED", e.message, null)
                        }
                    }
                }
            }
    }
}
