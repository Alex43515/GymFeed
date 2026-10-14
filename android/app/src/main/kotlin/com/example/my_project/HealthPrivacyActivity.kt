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
            text = "\nGymFeed reads steps, active calories and heart rate from Health Connect to show your daily activity. Your watch's companion app must first share these records with Health Connect.\n\nAccess is optional and read-only. Records stay on this device unless you separately enable AI sharing in Connected health. With explicit consent, today's summary and measurement times are sent securely through GymFeed's Supabase service to OpenAI or Google Gemini when you ask AI Coach a question. Private Coach questions, answers and plans may contain these numbers and are saved; health-assisted turns are excluded from rolling AI memory. Provider retention policies apply. Health data is not used for ads, sold or shared on your public profile.\n\nSync runs on the Connected health screen and, with separate consent, when sending a Coach question. Turn AI sharing off to stop future sharing; existing private history and plans are not deleted. Disconnect turns off both preferences and clears the on-screen data. Revoke system access in Health Connect → App permissions → GymFeed."
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
