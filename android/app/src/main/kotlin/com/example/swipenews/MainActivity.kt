package com.example.swipenews

import android.content.Intent
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.swipenews/share"
    private val LIFECYCLE_CHANNEL = "com.example.swipenews/lifecycle"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "shareArticle" -> {
                    val text = call.argument<String>("text")
                    val subject = call.argument<String>("subject")
                    
                    if (text != null) {
                        shareArticle(text, subject)
                        result.success(null)
                    } else {
                        result.error("INVALID_ARGUMENT", "Text cannot be null", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d("MainActivity", "onCreate called")
    }

    override fun onResume() {
        super.onResume()
        Log.d("MainActivity", "onResume called")
        
        // Notify Flutter về app resume
        flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
            MethodChannel(messenger, LIFECYCLE_CHANNEL).invokeMethod("onAppResumed", null)
        }
    }

    override fun onPause() {
        Log.d("MainActivity", "onPause called")
        super.onPause()
    }

    override fun onStop() {
        Log.d("MainActivity", "onStop called")
        super.onStop()
    }

    override fun onDestroy() {
        Log.d("MainActivity", "onDestroy called")
        super.onDestroy()
    }

    override fun onRestart() {
        super.onRestart()
        Log.d("MainActivity", "onRestart called")
        
        // Removed recreateFlutterView() as it causes app reload
    }

    private fun recreateFlutterView() {
        runOnUiThread {
            try {
                // Trigger Flutter hot reload programmatically
                flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                    MethodChannel(messenger, LIFECYCLE_CHANNEL).invokeMethod("recreateView", null)
                }
            } catch (e: Exception) {
                Log.e("MainActivity", "Error recreating Flutter view: ${e.message}")
            }
        }
    }

    private fun shareWithNewTask(text: String, subject: String?) {
        val shareIntent = Intent().apply {
            action = Intent.ACTION_SEND
            type = "text/plain"
            putExtra(Intent.EXTRA_TEXT, text)
            if (subject != null) {
                putExtra(Intent.EXTRA_SUBJECT, subject)
            }
            
            // These flags force a completely separate task, which causes the app to reload.
            // Keeping this function for now, but it will not be called from Flutter.
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                   Intent.FLAG_ACTIVITY_CLEAR_TOP or
                   Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS or
                   Intent.FLAG_ACTIVITY_NO_HISTORY
        }
        
        val chooserIntent = Intent.createChooser(shareIntent, "Chia sẻ qua").apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                   Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS or
                   Intent.FLAG_ACTIVITY_NO_HISTORY
        }
        
        try {
            startActivity(chooserIntent)
        } catch (e: Exception) {
            Log.e("MainActivity", "Error sharing: ${e.message}")
        }
    }

    private fun shareArticle(text: String, subject: String?) {
        val shareIntent = Intent().apply {
            action = Intent.ACTION_SEND
            type = "text/plain"
            putExtra(Intent.EXTRA_TEXT, text)
            if (subject != null) {
                putExtra(Intent.EXTRA_SUBJECT, subject)
            }
            // No special flags are set here to allow the app to resume normally
        }
        
        val chooserIntent = Intent.createChooser(shareIntent, "Chia sẻ qua")
        
        try {
            startActivity(chooserIntent)
        } catch (e: Exception) {
            Log.e("MainActivity", "Error sharing: ${e.message}")
        }
    }
}