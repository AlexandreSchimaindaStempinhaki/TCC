package com.example.tcc

import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val mapsChannel = "indigo/maps_config"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, mapsChannel)
            .setMethodCallHandler { call, result ->
                if (call.method == "getApiKey") {
                    try {
                        val appInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            packageManager.getApplicationInfo(
                                packageName,
                                PackageManager.ApplicationInfoFlags.of(
                                    PackageManager.GET_META_DATA.toLong()
                                )
                            )
                        } else {
                            @Suppress("DEPRECATION")
                            packageManager.getApplicationInfo(
                                packageName,
                                PackageManager.GET_META_DATA
                            )
                        }
                        val apiKey = appInfo.metaData?.getString("com.google.android.geo.API_KEY")
                        result.success(apiKey)
                    } catch (e: Exception) {
                        result.success(null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }
}