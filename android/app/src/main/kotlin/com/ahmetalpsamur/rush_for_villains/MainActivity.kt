package com.ahmetalpsamur.rush_for_villains

import android.media.AudioAttributes
import android.media.MediaPlayer
import io.flutter.FlutterInjector
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var launchPlayer: MediaPlayer? = null
    private var rewardPlayer: MediaPlayer? = null
    private var hasPlayedLaunchSound = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "rush_for_villains/launch_sound",
        ).setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "play" -> playLaunchSound()
                    "playReward" -> playRewardSound()
                    else -> {
                        result.notImplemented()
                        return@setMethodCallHandler
                    }
                }
                result.success(null)
            } catch (error: Exception) {
                result.error("launch_sound_failed", error.message, null)
            }
        }
    }

    private fun playRewardSound() {
        rewardPlayer?.release()
        rewardPlayer = null

        val assetKey = FlutterInjector.instance().flutterLoader()
            .getLookupKeyForAsset("lib/SoundEffects/GatherMusic.wav")
        val player = MediaPlayer()
        try {
            player.setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_GAME)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build(),
            )
            assets.openFd(assetKey).use { descriptor ->
                player.setDataSource(
                    descriptor.fileDescriptor,
                    descriptor.startOffset,
                    descriptor.length,
                )
            }
            player.setOnCompletionListener { completedPlayer ->
                completedPlayer.release()
                if (rewardPlayer === completedPlayer) rewardPlayer = null
            }
            player.setOnErrorListener { failedPlayer, _, _ ->
                failedPlayer.release()
                if (rewardPlayer === failedPlayer) rewardPlayer = null
                true
            }
            player.prepare()
        } catch (error: Exception) {
            player.release()
            throw error
        }

        rewardPlayer = player
        player.start()
    }

    private fun playLaunchSound() {
        if (hasPlayedLaunchSound) return
        hasPlayedLaunchSound = true

        val assetKey = FlutterInjector.instance().flutterLoader()
            .getLookupKeyForAsset("lib/Start/anime_kiz_sesi.mp3")
        val player = MediaPlayer()

        // Hazırlık adımlarının herhangi biri patlarsa (asset yok, codec
        // desteklenmiyor, prepare hatası) native kaynak sızmasın: player ve
        // dosya tanımlayıcısı her durumda kapatılır.
        try {
            player.setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_GAME)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build(),
            )
            assets.openFd(assetKey).use { descriptor ->
                player.setDataSource(
                    descriptor.fileDescriptor,
                    descriptor.startOffset,
                    descriptor.length,
                )
            }
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
        } catch (error: Exception) {
            player.release()
            throw error
        }

        launchPlayer = player
        player.start()
    }

    override fun onDestroy() {
        launchPlayer?.release()
        launchPlayer = null
        rewardPlayer?.release()
        rewardPlayer = null
        super.onDestroy()
    }
}
