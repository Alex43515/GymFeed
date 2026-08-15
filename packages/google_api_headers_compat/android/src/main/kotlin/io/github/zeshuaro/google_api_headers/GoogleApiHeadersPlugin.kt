package io.github.zeshuaro.google_api_headers

import android.annotation.SuppressLint
import android.content.Context
import android.content.pm.PackageManager
import android.content.pm.Signature
import androidx.annotation.UiThread
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.math.BigInteger
import java.security.MessageDigest

class GoogleApiHeadersPlugin : MethodCallHandler, FlutterPlugin {
    private var channel: MethodChannel? = null
    private var context: Context? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "google_api_headers").apply {
            setMethodCallHandler(this@GoogleApiHeadersPlugin)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        context = null
    }

    @SuppressLint("PackageManagerGetSignatures")
    @UiThread
    override fun onMethodCall(call: MethodCall, result: Result) {
        if (call.method != "getSigningCertSha1") {
            result.notImplemented()
            return
        }

        val packageName = call.arguments<String>()
        if (packageName.isNullOrBlank()) {
            result.error("ARGUMENT_ERROR", "Package name is missing", null)
            return
        }

        try {
            val packageManager = context?.packageManager
                ?: throw IllegalStateException("Plugin is not attached")
            val signatures = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P) {
                packageManager.getPackageInfo(
                    packageName,
                    PackageManager.GET_SIGNING_CERTIFICATES
                ).signingInfo?.apkContentsSigners
            } else {
                @Suppress("DEPRECATION")
                packageManager.getPackageInfo(
                    packageName,
                    PackageManager.GET_SIGNATURES
                ).signatures
            }
            val signature = signatures?.firstOrNull()
            if (signature == null) {
                result.error("SIGNATURE_MISSING", "No signing certificate found", null)
                return
            }
            result.success(parseSignature(signature))
        } catch (error: Exception) {
            result.error("ERROR", error.message, null)
        }
    }

    private fun parseSignature(signature: Signature): String {
        val digest = MessageDigest.getInstance("SHA1").digest(signature.toByteArray())
        val number = BigInteger(1, digest)
        return String.format("%0" + (digest.size shl 1) + "x", number)
    }
}
