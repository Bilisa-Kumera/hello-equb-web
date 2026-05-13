package com.hello.equb

import android.os.Bundle
import android.util.Log
import androidx.appcompat.app.AppCompatActivity
import com.huawei.ethiopia.pay.sdk.api.core.data.PayInfo
import com.huawei.ethiopia.pay.sdk.api.core.utils.PaymentManager
import io.flutter.plugin.common.MethodChannel

class PaymentActivity : AppCompatActivity() {

    private val TAG = "PaymentActivity"
    private val CHANNEL = "app_channel"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val appId = intent.getStringExtra("appId") ?: ""
        val shortCode = intent.getStringExtra("shortCode") ?: ""
        val receiveCode = intent.getStringExtra("receiveCode") ?: ""



        val payInfo =
                PayInfo.Builder()
                        .setAppId(appId)
                        .setShortCode(shortCode)
                        .setReceiveCode(receiveCode)
                        .build()

        PaymentManager.getInstance().setPayCallback { code, errMsg ->

            FlutterEngineHolder.binaryMessenger?.let { messenger ->
                MethodChannel(messenger, CHANNEL)
                        .invokeMethod("onPaymentResult", mapOf("code" to code, "errMsg" to errMsg))
            }

            finish()
        }

        PaymentManager.getInstance().pay(this, payInfo)
    }
}
