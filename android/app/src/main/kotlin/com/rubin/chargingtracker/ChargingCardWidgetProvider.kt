package com.rubin.chargingtracker

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/** Shows the card image drawn by the app; a tap opens the log charge sheet. */
class ChargingCardWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val card = widgetData.getString(IMAGE_KEY, null)?.let(BitmapFactory::decodeFile)
        val logCharge = HomeWidgetLaunchIntent.getActivity(
            context,
            MainActivity::class.java,
            Uri.parse(LOG_CHARGE_URI),
        )

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.charging_card_widget).apply {
                setOnClickPendingIntent(R.id.widget_root, logCharge)
                if (card != null) {
                    setImageViewBitmap(R.id.widget_card, card)
                    setViewVisibility(R.id.widget_card, View.VISIBLE)
                    setViewVisibility(R.id.widget_placeholder, View.GONE)
                }
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    private companion object {
        const val IMAGE_KEY = "charging_card"
        const val LOG_CHARGE_URI = "chargingtracker://log"
    }
}
