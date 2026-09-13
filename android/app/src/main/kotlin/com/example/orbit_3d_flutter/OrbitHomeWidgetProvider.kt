package com.example.orbit_3d_flutter

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Widget d'accueil Orbit IPTV.
 *
 * Affiche le profil actif et le nombre de favoris, données envoyées depuis
 * Flutter via `HomeWidget.saveWidgetData`. Un tap ouvre l'application.
 */
class OrbitHomeWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views =
                RemoteViews(context.packageName, R.layout.orbit_widget_layout).apply {
                    val pendingIntent =
                        HomeWidgetLaunchIntent.getActivity(
                            context,
                            MainActivity::class.java,
                            Uri.parse("orbit://widget/home"),
                        )
                    setOnClickPendingIntent(R.id.widget_container, pendingIntent)

                    setTextViewText(
                        R.id.widget_title,
                        widgetData.getString("widget_title", null) ?: "Orbit IPTV",
                    )
                    setTextViewText(
                        R.id.widget_profile,
                        widgetData.getString("widget_profile", null) ?: "Profil : —",
                    )
                    setTextViewText(
                        R.id.widget_favorites,
                        widgetData.getString("widget_favorites", null) ?: "0 favoris",
                    )
                }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}