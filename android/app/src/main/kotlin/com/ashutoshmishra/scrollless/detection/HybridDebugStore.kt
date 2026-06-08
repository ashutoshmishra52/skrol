package com.ashutoshmishra.scrollless.detection

/**
 * Live debug state for hybrid hash + gesture detection (Flutter debug panel).
 */
object HybridDebugStore {
    @Volatile var currentApp: String = ""

    @Volatile var currentScreen: String = "idle"

    @Volatile var reelsActive: Boolean = false

    @Volatile var shortsActive: Boolean = false

    @Volatile var reelsCurrentHash: String = ""

    @Volatile var reelsPreviousHash: String = ""

    @Volatile var shortsCurrentHash: String = ""

    @Volatile var shortsPreviousHash: String = ""

    @Volatile var reelsLastCountTime: Long = 0L

    @Volatile var shortsLastCountTime: Long = 0L

    @Volatile var reelsLastTrigger: String = ""

    @Volatile var shortsLastTrigger: String = ""

    @Volatile var reelsPendingHash: String = ""

    @Volatile var shortsPendingHash: String = ""

    @Volatile var reelsPendingEvents: Int = 0

    @Volatile var shortsPendingEvents: Int = 0

    @Volatile var reelsEventQueueSize: Int = 0

    @Volatile var shortsEventQueueSize: Int = 0

    @Volatile var reelsLastHashChangeTime: Long = 0L

    @Volatile var shortsLastHashChangeTime: Long = 0L

    @Volatile var reelsAbsorbedTransitions: Int = 0

    @Volatile var shortsAbsorbedTransitions: Int = 0

    @Volatile var reelsBurstWarning: String = ""

    @Volatile var shortsBurstWarning: String = ""

    @Volatile var totalReels: Int = 0

    @Volatile var totalShorts: Int = 0

    @Volatile var lastEventType: String = ""

    // Reels detection debugger fields
    @Volatile var instagramPackageActive: Boolean = false

    @Volatile var currentPackage: String = ""

    @Volatile var currentActivity: String = ""

    @Volatile var visibleTexts: String = ""

    @Volatile var visibleDescriptions: String = ""

    @Volatile var nodeCount: Int = 0

    @Volatile var hierarchyDepth: Int = 0

    @Volatile var reelsRejectCode: String = ""

    @Volatile var reelsRejectDetail: String = ""

    @Volatile var reelsAcceptReason: String = ""

    fun toMap(): Map<String, Any> = mapOf(
        "currentApp" to currentApp,
        "currentScreen" to currentScreen,
        "reelsActive" to reelsActive,
        "shortsActive" to shortsActive,
        "reelsCurrentHash" to reelsCurrentHash,
        "reelsPreviousHash" to reelsPreviousHash,
        "shortsCurrentHash" to shortsCurrentHash,
        "shortsPreviousHash" to shortsPreviousHash,
        "reelsLastCountTime" to reelsLastCountTime,
        "shortsLastCountTime" to shortsLastCountTime,
        "reelsLastTrigger" to reelsLastTrigger,
        "shortsLastTrigger" to shortsLastTrigger,
        "reelsPendingHash" to reelsPendingHash,
        "shortsPendingHash" to shortsPendingHash,
        "reelsPendingEvents" to reelsPendingEvents,
        "shortsPendingEvents" to shortsPendingEvents,
        "reelsEventQueueSize" to reelsEventQueueSize,
        "shortsEventQueueSize" to shortsEventQueueSize,
        "reelsLastHashChangeTime" to reelsLastHashChangeTime,
        "shortsLastHashChangeTime" to shortsLastHashChangeTime,
        "reelsAbsorbedTransitions" to reelsAbsorbedTransitions,
        "shortsAbsorbedTransitions" to shortsAbsorbedTransitions,
        "reelsBurstWarning" to reelsBurstWarning,
        "shortsBurstWarning" to shortsBurstWarning,
        "totalReels" to totalReels,
        "totalShorts" to totalShorts,
        "lastEventType" to lastEventType,
        "instagramPackageActive" to instagramPackageActive,
        "currentPackage" to currentPackage,
        "currentActivity" to currentActivity,
        "visibleTexts" to visibleTexts,
        "visibleDescriptions" to visibleDescriptions,
        "nodeCount" to nodeCount,
        "hierarchyDepth" to hierarchyDepth,
        "reelsRejectCode" to reelsRejectCode,
        "reelsRejectDetail" to reelsRejectDetail,
        "reelsAcceptReason" to reelsAcceptReason,
        // Legacy keys for older debug widgets
        "reelsState" to if (reelsActive) "in_reels" else "idle",
        "shortsState" to if (shortsActive) "in_shorts" else "idle",
        "reelsNodeHash" to reelsCurrentHash,
        "shortsNodeHash" to shortsCurrentHash,
        "reelsInSession" to reelsActive,
        "shortsInSession" to shortsActive,
        "reelsSessionCount" to totalReels,
        "shortsSessionCount" to totalShorts,
        "reelsLastTimestamp" to reelsLastCountTime,
        "shortsLastTimestamp" to shortsLastCountTime,
    )
}
