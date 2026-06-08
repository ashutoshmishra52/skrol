package com.ashutoshmishra.scrollless

import android.content.Context
import com.android.installreferrer.api.InstallReferrerClient
import com.android.installreferrer.api.InstallReferrerStateListener

object InstallReferrerHelper {

    fun fetchReferrer(context: Context, callback: (Map<String, String>?) -> Unit) {
        val client = InstallReferrerClient.newBuilder(context).build()
        client.startConnection(object : InstallReferrerStateListener {
            override fun onInstallReferrerSetupFinished(responseCode: Int) {
                when (responseCode) {
                    InstallReferrerClient.InstallReferrerResponse.OK -> {
                        try {
                            val referrer = client.installReferrer.installReferrer
                            callback(parseReferrer(referrer))
                        } catch (_: Exception) {
                            callback(null)
                        } finally {
                            client.endConnection()
                        }
                    }
                    else -> {
                        callback(null)
                        client.endConnection()
                    }
                }
            }

            override fun onInstallReferrerServiceDisconnected() {
                callback(null)
            }
        })
    }

    private fun parseReferrer(raw: String?): Map<String, String>? {
        if (raw.isNullOrBlank()) return null
        val params = mutableMapOf<String, String>()
        for (part in raw.split("&")) {
            val kv = part.split("=", limit = 2)
            if (kv.size == 2) {
                params[kv[0]] = java.net.URLDecoder.decode(kv[1], "UTF-8")
            }
        }
        val challengeId = params["challenge"] ?: params["utm_content"]
        if (challengeId.isNullOrBlank()) return null
        return mapOf(
            "challengeId" to challengeId,
            "inviterName" to (params["inviter"] ?: params["utm_source"] ?: "A friend"),
            "inviterId" to (params["from"] ?: ""),
        )
    }
}
