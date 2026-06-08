package com.ashutoshmishra.scrollless

import android.content.Context

object PackageFilters {

    const val PKG_INSTAGRAM = "com.instagram.android"
    const val PKG_YOUTUBE = "com.google.android.youtube"
    const val PKG_FACEBOOK = "com.facebook.katana"
    const val PKG_FACEBOOK_LITE = "com.facebook.lite"
    const val PKG_TWITTER = "com.twitter.android"
    const val PKG_X = "com.twitter.android"
    const val PKG_SNAPCHAT = "com.snapchat.android"
    const val PKG_LINKEDIN = "com.linkedin.android"

    val PRIMARY_SOCIAL = setOf(
        PKG_INSTAGRAM,
        PKG_YOUTUBE,
        PKG_FACEBOOK,
        PKG_FACEBOOK_LITE,
        PKG_TWITTER,
        PKG_SNAPCHAT,
    )

    val SOCIAL_APPS = PRIMARY_SOCIAL + setOf(
        PKG_LINKEDIN,
        "com.reddit.frontpage",
        "com.zhiliaoapp.musically",
        "com.ss.android.ugc.trill",
    )

    val REEL_APPS = setOf(
        PKG_INSTAGRAM,
        PKG_YOUTUBE,
        "com.zhiliaoapp.musically",
        "com.ss.android.ugc.trill",
    )

    fun isReelApp(packageName: String) = REEL_APPS.contains(packageName)

    fun isSocialApp(packageName: String) = SOCIAL_APPS.contains(packageName)

    fun socialCategory(packageName: String): String = when (packageName) {
        PKG_INSTAGRAM -> "instagram"
        PKG_YOUTUBE -> "youtube"
        PKG_FACEBOOK, PKG_FACEBOOK_LITE -> "facebook"
        PKG_TWITTER -> "x"
        PKG_SNAPCHAT -> "snapchat"
        else -> "other"
    }

    fun getAppLabel(context: Context, packageName: String): String {
        SOCIAL_LABELS[packageName]?.let { return it }
        return try {
            val pm = context.packageManager
            val info = pm.getApplicationInfo(packageName, 0)
            pm.getApplicationLabel(info).toString()
        } catch (_: Exception) {
            SOCIAL_LABELS[packageName] ?: packageName.substringAfterLast('.')
                .replaceFirstChar { it.uppercase() }
        }
    }

    private val SOCIAL_LABELS = mapOf(
        PKG_INSTAGRAM to "Instagram",
        PKG_YOUTUBE to "YouTube",
        PKG_LINKEDIN to "LinkedIn",
        PKG_TWITTER to "X",
        PKG_FACEBOOK to "Facebook",
        PKG_FACEBOOK_LITE to "Facebook Lite",
        PKG_SNAPCHAT to "Snapchat",
        "com.reddit.frontpage" to "Reddit",
        "com.zhiliaoapp.musically" to "TikTok",
        "com.ss.android.ugc.trill" to "TikTok",
    )
}
