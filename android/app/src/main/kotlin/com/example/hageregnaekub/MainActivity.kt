


package com.hello.equb

import android.content.Intent
import android.os.Build
import android.app.NotificationChannel
import android.app.NotificationManager
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "app_channel"
    companion object {
        @JvmStatic var latestOrderData: String? = null
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        createNotificationChannel()

        FlutterEngineHolder.binaryMessenger = flutterEngine.dartExecutor.binaryMessenger

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call,
                result ->
            when (call.method) {
                "launchMainActivity" -> {
                    val args = call.arguments as? Map<*, *>
                    val orderData = args?.get("orderData") as? String
                    try {
                        var launchIntent = packageManager.getLaunchIntentForPackage(packageName)
                        if (launchIntent == null) {
                            launchIntent = Intent(this, MainActivity::class.java)
                        }
                        launchIntent.addFlags(
                            Intent.FLAG_ACTIVITY_NEW_TASK or
                            Intent.FLAG_ACTIVITY_CLEAR_TOP or
                            Intent.FLAG_ACTIVITY_SINGLE_TOP or
                            Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                            Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED
                        )
                        if (orderData != null) {
                            launchIntent.putExtra("orderData", orderData)
                            latestOrderData = orderData
                        }
                        startActivity(launchIntent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("LAUNCH_ERROR", e.message, null)
                    }
                }
                "getInitialOrderData" -> {
                    val orderData = intent.getStringExtra("orderData")
                    result.success(orderData)
                }
                "getLatestOrderData" -> {
                    result.success(latestOrderData)
                }
                "getLaunchOrderData" -> {
                    val payload = latestOrderData ?: intent.getStringExtra("orderData")
                    result.success(payload)
                }
                "clearLaunchOrderData" -> {
                    latestOrderData = null
                    try { intent.removeExtra("orderData") } catch (_: Exception) {}
                    result.success(true)
                }
                "startTelebirrPayment" -> {
                    val args = call.arguments as Map<*, *>

                    val appId = args["appId"] as String
                    val shortCode = args["shortCode"] as String
                    val receiveCode = args["receiveCode"] as String 

                    val intent = Intent(this, PaymentActivity::class.java).apply {
                        putExtra("appId", appId)
                        putExtra("shortCode", shortCode)
                        putExtra("receiveCode", receiveCode)
                    }
                    startActivity(intent)
                    result.success("PaymentActivity launched")
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        latestOrderData = intent.getStringExtra("orderData")
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channelId = "websocket_background"
            val channelName = "WebSocket Background"
            val channelDescription = "Background service for WebSocket connections"
            val importance = NotificationManager.IMPORTANCE_LOW

            val channel = NotificationChannel(channelId, channelName, importance)
            channel.description = channelDescription

            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }
}
