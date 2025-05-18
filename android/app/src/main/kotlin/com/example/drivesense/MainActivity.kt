package com.example.drivesense

import android.content.Context  
import android.net.ConnectivityManager  
import android.net.Network  
import android.net.NetworkCapabilities  
import android.net.NetworkRequest  
import android.os.Build  
import io.flutter.embedding.android.FlutterActivity  
import io.flutter.embedding.engine.FlutterEngine  
import io.flutter.plugin.common.MethodChannel  

class MainActivity: FlutterActivity() {
    private val CHANNEL = "network_binder"
    private lateinit var connectivityManager: ConnectivityManager
    private var wifiNetworkCallback: ConnectivityManager.NetworkCallback? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        connectivityManager = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
          .setMethodCallHandler { call, result -> 
            when (call.method) {
                "bindWifi" -> {
                    bindWifiNetwork()
                    result.success(null)
                }
                "unbind" -> {
                    unbindNetwork()
                    result.success(null)
                }
                "isWifiBound" -> {
                    result.success(isWifiBound())
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun bindWifiNetwork() {
        // First clear any existing callback
        unbindNetwork()
        
        val request = NetworkRequest.Builder()
            .addTransportType(NetworkCapabilities.TRANSPORT_WIFI)
            .build()
        
        val callback = object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: Network) {
                // Bind the entire process to Wi-Fi
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    connectivityManager.bindProcessToNetwork(network)
                } else {
                    @Suppress("DEPRECATION")
                    ConnectivityManager.setProcessDefaultNetwork(network)
                }
            }
            
            override fun onLost(network: Network) {
                // If this WiFi network is lost, unbind
                unbindNetwork()
            }
        }
        
        wifiNetworkCallback = callback
        connectivityManager.requestNetwork(request, callback)
    }

    private fun unbindNetwork() {
        // Remove the callback to stop listening for network changes
        wifiNetworkCallback?.let {
            try {
                connectivityManager.unregisterNetworkCallback(it)
            } catch (e: Exception) {
                // Ignore if already unregistered
            }
            wifiNetworkCallback = null
        }
        
        // Remove the binding
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            connectivityManager.bindProcessToNetwork(null)
        } else {
            @Suppress("DEPRECATION")
            ConnectivityManager.setProcessDefaultNetwork(null)
        }
    }

    // Add a new method to check binding status
    private fun isWifiBound(): Boolean {
        val activeNetwork = connectivityManager.activeNetwork ?: return false
        val capabilities = connectivityManager.getNetworkCapabilities(activeNetwork) ?: return false
        return capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)
    }

    override fun onDestroy() {
        unbindNetwork()
        super.onDestroy()
    }
}
