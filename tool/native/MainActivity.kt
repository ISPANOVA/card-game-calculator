package com.smrh.card_game_calculator

import android.content.ClipData
import android.content.Intent
import android.media.AudioAttributes
import android.media.SoundPool
import android.view.WindowManager
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/** Keeps the screen on during a game, plays the card sounds and shares the result image. */
class MainActivity : FlutterActivity() {
    private var pool: SoundPool? = null
    private val sounds = HashMap<String, Int>()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "cgc/app").setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "keepAwake" -> {
                        if (call.argument<Boolean>("on") == true) {
                            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        } else {
                            window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        }
                        result.success(true)
                    }
                    "loadSound" -> {
                        val name = call.argument<String>("name")!!
                        val bytes = call.argument<ByteArray>("bytes")!!
                        val dir = File(cacheDir, "sounds").apply { mkdirs() }
                        val file = File(dir, "$name.wav")
                        file.writeBytes(bytes)
                        val p = pool ?: SoundPool.Builder()
                            .setMaxStreams(4)
                            .setAudioAttributes(
                                AudioAttributes.Builder()
                                    .setUsage(AudioAttributes.USAGE_GAME)
                                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                                    .build()
                            )
                            .build()
                            .also { pool = it }
                        sounds[name] = p.load(file.absolutePath, 1)
                        result.success(true)
                    }
                    "play" -> {
                        val id = sounds[call.argument<String>("name") ?: ""]
                        val volume = (call.argument<Double>("volume") ?: 1.0).toFloat()
                        if (id != null) pool?.play(id, volume, volume, 1, 0, 1f)
                        result.success(id != null)
                    }
                    "shareImage" -> {
                        val bytes = call.argument<ByteArray>("bytes")!!
                        val text = call.argument<String>("text") ?: ""
                        val dir = File(cacheDir, "share").apply { mkdirs() }
                        val file = File(dir, "card-game-result.png")
                        file.writeBytes(bytes)
                        val uri = FileProvider.getUriForFile(this, "$packageName.share", file)
                        val send = Intent(Intent.ACTION_SEND).apply {
                            type = "image/png"
                            putExtra(Intent.EXTRA_STREAM, uri)
                            putExtra(Intent.EXTRA_TEXT, text)
                            clipData = ClipData.newRawUri("", uri)
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        }
                        startActivity(Intent.createChooser(send, null).addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION))
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                result.error("cgc", e.message, null)
            }
        }
    }

    override fun onDestroy() {
        pool?.release()
        pool = null
        super.onDestroy()
    }
}
