package com.flutterflow.gymfeedofficial

import android.app.Activity
import android.os.Bundle
import android.graphics.Color
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Button
import android.widget.ScrollView

class HealthPrivacyActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(32, 64, 32, 32)
            setBackgroundColor(Color.rgb(10, 10, 10))
        }
        layout.addView(TextView(this).apply {
            text = "GymFeed • Connected health"
            textSize = 24f
            setTextColor(Color.rgb(0, 220, 110))
        })
        layout.addView(TextView(this).apply {
            text = "\nGymFeed reads steps, active calories and heart rate from Health Connect to show your daily activity. Your watch's companion app must first share these records with Health Connect.\n\nAccess is optional and read-only. GymFeed does not change health records, upload them to its servers, share them with other users, send them to AI services, or use them for advertising.\n\nSync runs only when you open Connected health or request a refresh. Disconnect stops reads and clears the on-screen data. You can revoke access at any time in Health Connect → App permissions → GymFeed."
            textSize = 17f
            setTextColor(Color.WHITE)
        })
        layout.addView(Button(this).apply {
            text = "Close"
            setOnClickListener { finish() }
        })
        setContentView(ScrollView(this).apply { addView(layout) })
    }
}
