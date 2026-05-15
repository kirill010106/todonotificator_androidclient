package com.chkpnk.pomodorotodo.pomorodo_todo

import android.app.*
import android.content.pm.ServiceInfo
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

class ForegroundTimerService : Service() {
    companion object {
        const val CHANNEL_ID = "pomodoro_ongoing"
        const val NOTIF_ID = 2000
        const val EXTRA_ACTION = "action"
        const val EXTRA_TITLE = "title"
        const val EXTRA_BODY = "body"
        const val ACTION_START = "start"
        const val ACTION_UPDATE = "update"
        const val ACTION_STOP = "stop"
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createChannel()
    }

    private fun createChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "Pomodoro Ongoing"
            val chan = NotificationChannel(CHANNEL_ID, name, NotificationManager.IMPORTANCE_LOW)
            chan.setShowBadge(false)
            val nm = getSystemService(NotificationManager::class.java)
            nm.createNotificationChannel(chan)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.getStringExtra(EXTRA_ACTION) ?: ACTION_START
        val title = intent?.getStringExtra(EXTRA_TITLE) ?: "Таймер запущен"
        val body = intent?.getStringExtra(EXTRA_BODY) ?: ""

        when (action) {
            ACTION_START, ACTION_UPDATE -> {
                val notif = buildNotification(title, body)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    startForeground(
                        NOTIF_ID,
                        notif,
                        ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC,
                    )
                } else {
                    startForeground(NOTIF_ID, notif)
                }
            }
            ACTION_STOP -> {
                stopForeground(true)
                stopSelf()
            }
        }

        return START_STICKY
    }

    private fun buildNotification(title: String, body: String): Notification {
        val pendingIntent = packageManager.getLaunchIntentForPackage(packageName)?.let { launch ->
            PendingIntent.getActivity(this, 0, launch, PendingIntent.FLAG_IMMUTABLE)
        }
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(body)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setContentIntent(pendingIntent)
            .build()
    }

    override fun onDestroy() {
        stopForeground(true)
        super.onDestroy()
    }
}
