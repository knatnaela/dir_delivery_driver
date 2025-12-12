package com.dir_delivery_driver

import android.content.Intent
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.dir_delivery_driver/app_lifecycle"
    private var rideRequestIdFromIntent: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Check for ride_request_id in Intent extras
        rideRequestIdFromIntent = intent.getStringExtra("ride_request_id")
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        // Check for ride_request_id in new Intent
        rideRequestIdFromIntent = intent.getStringExtra("ride_request_id")
        if (rideRequestIdFromIntent != null) {
            // Send to Flutter via method channel if engine is ready
            flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                MethodChannel(messenger, CHANNEL).invokeMethod("handleRideRequestFromIntent", mapOf("ride_request_id" to rideRequestIdFromIntent))
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "bringToFront" -> {
                    try {
                        bringToFront()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to bring app to front: ${e.message}", null)
                    }
                }
                "bringToFrontWithRideRequest" -> {
                    try {
                        val rideRequestId = call.argument<String>("ride_request_id")
                        bringToFrontWithRideRequest(rideRequestId)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to bring app to front with ride request: ${e.message}", null)
                    }
                }
                "launchAppWithRideRequest" -> {
                    try {
                        val rideRequestId = call.argument<String>("ride_request_id")
                        launchAppWithRideRequest(rideRequestId)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to launch app with ride request: ${e.message}", null)
                    }
                }
                "getRideRequestFromIntent" -> {
                    // Return the ride_request_id from Intent if available
                    result.success(rideRequestIdFromIntent)
                    rideRequestIdFromIntent = null // Clear after reading
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // If we have a ride_request_id from Intent, send it to Flutter
        rideRequestIdFromIntent?.let { id ->
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).invokeMethod("handleRideRequestFromIntent", mapOf("ride_request_id" to id))
            rideRequestIdFromIntent = null
        }
    }

    private fun bringToFront() {
        // Create intent to bring MainActivity to front
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or 
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or 
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or
                    Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
        }
        
        startActivity(intent)
        
        // For Android 10+, also try to move task to front using ActivityManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            try {
                val activityManager = getSystemService(ACTIVITY_SERVICE) as android.app.ActivityManager
                val tasks = activityManager.appTasks
                if (tasks.isNotEmpty()) {
                    tasks[0].moveToFront()
                }
            } catch (e: Exception) {
                // Fallback: intent already started, that should be enough
            }
        }
    }

    private fun bringToFrontWithRideRequest(rideRequestId: String?) {
        // Create intent to bring MainActivity to front with ride request data
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or 
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or 
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or
                    Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
            // Add ride request ID as extra data
            if (rideRequestId != null) {
                putExtra("ride_request_id", rideRequestId)
                putExtra("action", "open_trip_from_overlay")
            }
        }
        
        startActivity(intent)
        
        // For Android 10+, also try to move task to front using ActivityManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            try {
                val activityManager = getSystemService(ACTIVITY_SERVICE) as android.app.ActivityManager
                val tasks = activityManager.appTasks
                if (tasks.isNotEmpty()) {
                    tasks[0].moveToFront()
                }
            } catch (e: Exception) {
                // Fallback: intent already started, that should be enough
            }
        }
    }

    private fun launchAppWithRideRequest(rideRequestId: String?) {
        // Create intent to launch MainActivity with ride request data
        // This is called from the overlay isolate, so we need to use application context
        val intent = Intent(applicationContext, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or 
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or 
                    Intent.FLAG_ACTIVITY_SINGLE_TOP
            // Add ride request ID as extra data
            if (rideRequestId != null) {
                putExtra("ride_request_id", rideRequestId)
                putExtra("action", "open_trip_from_overlay")
            }
        }
        
        applicationContext.startActivity(intent)
        
        // For Android 10+, also try to move task to front using ActivityManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            try {
                val activityManager = applicationContext.getSystemService(ACTIVITY_SERVICE) as android.app.ActivityManager
                val tasks = activityManager.appTasks
                if (tasks.isNotEmpty()) {
                    tasks[0].moveToFront()
                }
            } catch (e: Exception) {
                // Fallback: intent already started, that should be enough
            }
        }
    }
}
