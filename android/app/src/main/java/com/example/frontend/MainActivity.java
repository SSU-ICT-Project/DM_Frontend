package com.example.frontend;

import android.app.AppOpsManager;
import android.content.Context;
import android.content.Intent;
import android.os.Binder;
import android.os.Build;
import android.provider.Settings;
import android.util.Log;
import android.app.usage.UsageEvents;
import android.app.usage.UsageStatsManager;
import java.util.concurrent.TimeUnit;
import java.util.Map;
import java.util.HashMap;
import java.util.List;

import java.util.List;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "app.usage/access";

    @Override
    public void configureFlutterEngine(FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler(this::onMethodCall);
    }

    private void onMethodCall(MethodCall call, MethodChannel.Result result) {
        switch (call.method) {
            case "isUsageAccessGranted":
                result.success(isUsageAccessGranted(this));
                break;
            case "openUsageAccessSettings":
                openUsageAccessSettings();
                result.success(true);
                break;
            case "getForegroundApp":
                result.success(getForegroundApp());
                break;
            case "getUsageSummary":
                Long begin = call.argument("begin");
                Long end = call.argument("end");
                List<String> packages = call.argument("packages");
                result.success(getUsageSummary(begin, end, packages));
                break;
            default:
                result.notImplemented();
        }
    }

    private boolean isUsageAccessGranted(Context context) {
        try {
            AppOpsManager appOps = (AppOpsManager) context.getSystemService(Context.APP_OPS_SERVICE);
            int mode;
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                mode = appOps.unsafeCheckOpNoThrow("android:get_usage_stats", android.os.Process.myUid(), context.getPackageName());
            } else {
                mode = appOps.checkOpNoThrow("android:get_usage_stats", Binder.getCallingUid(), context.getPackageName());
            }
            return mode == AppOpsManager.MODE_ALLOWED;
        } catch (Throwable t) {
            Log.e("UsageAccess", "check failed", t);
            return false;
        }
    }

    private void openUsageAccessSettings() {
        try {
            Intent intent = new Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS);
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            startActivity(intent);
        } catch (Throwable t) {
            Log.e("UsageAccess", "open settings failed", t);
        }
    }

    private String getForegroundApp() {
        try {
            if (!isUsageAccessGranted(this)) return null;
            UsageStatsManager usm = (UsageStatsManager) getSystemService(Context.USAGE_STATS_SERVICE);
            long end = System.currentTimeMillis();
            long begin = end - TimeUnit.MINUTES.toMillis(5);
            UsageEvents events = usm.queryEvents(begin, end);
            UsageEvents.Event event = new UsageEvents.Event();
            String lastPkg = null;
            long lastTime = 0L;
            while (events.hasNextEvent()) {
                events.getNextEvent(event);
                if (event == null) continue;
                if (event.getEventType() == UsageEvents.Event.MOVE_TO_FOREGROUND
                        || (Build.VERSION.SDK_INT >= 29 && event.getEventType() == UsageEvents.Event.ACTIVITY_RESUMED)) {
                    if (event.getTimeStamp() >= lastTime) {
                        lastTime = event.getTimeStamp();
                        lastPkg = event.getPackageName();
                    }
                }
            }
            return lastPkg;
        } catch (Throwable t) {
            Log.e("UsageAccess", "getForegroundApp failed", t);
            return null;
        }
    }

    private Map<String, Long> getUsageSummary(Long begin, Long end, List<String> packages) {
        Map<String, Long> out = new HashMap<>();
        try {
            if (begin == null || end == null) {
                long now = System.currentTimeMillis();
                end = now;
                begin = now - TimeUnit.DAYS.toMillis(1);
            }
            if (!isUsageAccessGranted(this)) return out;
            UsageStatsManager usm = (UsageStatsManager) getSystemService(Context.USAGE_STATS_SERVICE);
            Map<String, android.app.usage.UsageStats> map = usm.queryAndAggregateUsageStats(begin, end);
            if (map == null) return out;
            if (packages != null && !packages.isEmpty()) {
                for (String p : packages) {
                    android.app.usage.UsageStats s = map.get(p);
                    if (s != null) out.put(p, s.getTotalTimeInForeground());
                }
            } else {
                for (Map.Entry<String, android.app.usage.UsageStats> e : map.entrySet()) {
                    out.put(e.getKey(), e.getValue().getTotalTimeInForeground());
                }
            }
        } catch (Throwable t) {
            Log.e("UsageAccess", "getUsageSummary failed", t);
        }
        return out;
    }
}
