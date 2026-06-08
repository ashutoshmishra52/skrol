package com.ashutoshmishra.scrollless

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class ScrollLessWidget : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (appWidgetId in appWidgetIds) {
            val widgetData = HomeWidgetPlugin.getData(context)
            val attentionScore = widgetData.getInt("attention_score", 0)
            val focusTime = widgetData.getString("focus_time", "0m") ?: "0m"
            val streak = widgetData.getInt("focus_streak", 0)
            val goalProgress = widgetData.getInt("goal_progress", 0)

            val views = RemoteViews(context.packageName, R.layout.scrollless_widget).apply {
                setTextViewText(R.id.widget_attention_score, "$attentionScore")
                setTextViewText(R.id.widget_focus_time, focusTime)
                setTextViewText(R.id.widget_streak, "$streak days")
                setTextViewText(R.id.widget_goal_progress, "$goalProgress%")
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
