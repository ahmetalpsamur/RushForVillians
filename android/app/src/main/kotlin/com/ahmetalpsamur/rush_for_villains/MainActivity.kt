package com.ahmetalpsamur.rush_for_villains

import android.media.AudioAttributes
import android.media.MediaPlayer
import io.flutter.FlutterInjector
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var launchPlayer: MediaPlayer? = null
    private var hasPlayedLaunchSound = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "rush_for_villains/launch_sound",
        ).setMethodCallHandler { call, result ->
            if (call.method != "play") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            try {
                playLaunchSound()
                result.success(null)
            } catch (error: Exception) {
                result.error("launch_sound_failed", error.message, null)
            }
        }
    }

    private fun playLaunchSound() {
        if (hasPlayedLaunchSound) return
        hasPlayedLaunchSound = true

        val assetKey = FlutterInjector.instance().flutterLoader()
            .getLookupKeyForAsset("lib/Start/anime_kiz_sesi.mp3")
        val descriptor = assets.openFd(assetKey)
        val player = MediaPlayer()

        player.setAudioAttributes(
            AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_GAME)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build(),
        )
        player.setDataSource(
            descriptor.fileDescriptor,
            descriptor.startOffset,
            descriptor.length,
        )
        descriptor.close()
        player.setOnCompletionListener { completedPlayer ->
            completedPlayer.release()
            if (launchPlayer === completedPlayer) launchPlayer = null
        }
        player.setOnErrorListener { failedPlayer, _, _ ->
            failedPlayer.release()
            if (launchPlayer === failedPlayer) launchPlayer = null
            true
        }
        player.prepare()
        launchPlayer = player
        player.start()
    }

    override fun onDestroy() {
        launchPlayer?.release()
        launchPlayer = null
        super.onDestroy()
    }
}
