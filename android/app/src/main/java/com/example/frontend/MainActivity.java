package com.example.frontend;

import android.app.AppOpsManager;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.provider.Settings;
import android.util.Log;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.TimeUnit;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "app.usage/access";
    private static final String SUMMARY_CHANNEL = "app.usage/summary";
    private static final int PERMISSION_REQUEST_CODE = 1001;
    private static final int USAGE_STATS_REQUEST_CODE = 1002;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        
        // 앱 사용량 접근 권한 확인 및 요청
        checkAndRequestUsageStatsPermission();
        
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler(
                        (call, result) -> {
                            if (call.method.equals("isUsageAccessGranted")) {
                                result.success(isUsageAccessGranted());
                            } else if (call.method.equals("getForegroundApp")) {
                                try {
                                    String foregroundApp = getForegroundApp();
                                    result.success(foregroundApp);
                                } catch (Exception e) {
                                    result.error("ERROR", "Failed to get foreground app: " + e.getMessage(), null);
                                }
                            } else {
                                result.notImplemented();
                            }
                        }
                );

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), SUMMARY_CHANNEL)
                .setMethodCallHandler(
                        (call, result) -> {
                            if (call.method.equals("fetchUsageSummary")) {
                                // 권한 확인
                                if (!isUsageAccessGranted()) {
                                    result.error("PERMISSION_DENIED", "Usage stats permission not granted", null);
                                    return;
                                }
                                
                                try {
                                    long begin = call.argument("begin");
                                    long end = call.argument("end");
                                    List<String> packages = call.argument("packages");
                                    
                                    Map<String, Long> usageSummary = fetchUsageSummary(begin, end, packages);
                                    result.success(usageSummary);
                                } catch (Exception e) {
                                    result.error("ERROR", "Failed to fetch usage summary: " + e.getMessage(), null);
                                }
                            } else if (call.method.equals("getInstalledApps")) {
                                try {
                                    List<Map<String, String>> apps = getInstalledApps();
                                    result.success(apps);
                                } catch (Exception e) {
                                    result.error("ERROR", "Failed to get installed apps: " + e.getMessage(), null);
                                }
                            } else {
                                result.notImplemented();
                            }
                        }
                );
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        // 앱 시작 시 권한 확인
        checkAndRequestPermissions();
    }

    private void checkAndRequestPermissions() {
        // 기본 권한들 확인 및 요청
        String[] permissions = {
                android.Manifest.permission.CAMERA,
                android.Manifest.permission.RECORD_AUDIO,
                android.Manifest.permission.ACCESS_FINE_LOCATION,
                android.Manifest.permission.ACCESS_COARSE_LOCATION,
                android.Manifest.permission.READ_EXTERNAL_STORAGE,
                android.Manifest.permission.WRITE_EXTERNAL_STORAGE
        };

        List<String> permissionsToRequest = new ArrayList<>();
        for (String permission : permissions) {
            if (ContextCompat.checkSelfPermission(this, permission) != PackageManager.PERMISSION_GRANTED) {
                permissionsToRequest.add(permission);
            }
        }

        if (!permissionsToRequest.isEmpty()) {
            ActivityCompat.requestPermissions(this, 
                permissionsToRequest.toArray(new String[0]), 
                PERMISSION_REQUEST_CODE);
        }
    }

    private void checkAndRequestUsageStatsPermission() {
        if (!isUsageAccessGranted()) {
            // 사용자에게 권한 요청 다이얼로그 표시
            Intent intent = new Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS);
            startActivityForResult(intent, USAGE_STATS_REQUEST_CODE);
        }
    }

    private boolean isUsageAccessGranted() {
        AppOpsManager appOps = (AppOpsManager) getSystemService(Context.APP_OPS_SERVICE);
        int mode = appOps.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(), getPackageName());
        return mode == AppOpsManager.MODE_ALLOWED;
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        
        if (requestCode == USAGE_STATS_REQUEST_CODE) {
            if (isUsageAccessGranted()) {
                Toast.makeText(this, "앱 사용량 접근 권한이 허용되었습니다", Toast.LENGTH_SHORT).show();
            } else {
                Toast.makeText(this, "앱 사용량 접근 권한이 필요합니다", Toast.LENGTH_LONG).show();
                // 다시 권한 요청
                checkAndRequestUsageStatsPermission();
            }
        }
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        
        if (requestCode == PERMISSION_REQUEST_CODE) {
            boolean allGranted = true;
            for (int result : grantResults) {
                if (result != PackageManager.PERMISSION_GRANTED) {
                    allGranted = false;
                    break;
                }
            }
            
            if (allGranted) {
                Toast.makeText(this, "모든 권한이 허용되었습니다", Toast.LENGTH_SHORT).show();
            } else {
                Toast.makeText(this, "일부 권한이 거부되었습니다", Toast.LENGTH_LONG).show();
            }
        }
    }

    private String getForegroundApp() {
        try {
            if (!isUsageAccessGranted()) return null;
            android.app.usage.UsageStatsManager usm = (android.app.usage.UsageStatsManager) getSystemService(Context.USAGE_STATS_SERVICE);
            long end = System.currentTimeMillis();
            long begin = end - TimeUnit.MINUTES.toMillis(5);
            android.app.usage.UsageEvents events = usm.queryEvents(begin, end);
            android.app.usage.UsageEvents.Event event = new android.app.usage.UsageEvents.Event();
            String lastPkg = null;
            long lastTime = 0L;
            while (events.hasNextEvent()) {
                events.getNextEvent(event);
                if (event == null) continue;
                if (event.getEventType() == android.app.usage.UsageEvents.Event.MOVE_TO_FOREGROUND
                        || (Build.VERSION.SDK_INT >= 29 && event.getEventType() == android.app.usage.UsageEvents.Event.ACTIVITY_RESUMED)) {
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

    private Map<String, Long> fetchUsageSummary(Long begin, Long end, List<String> packages) {
        Map<String, Long> out = new HashMap<>();
        try {
            if (begin == null || end == null) {
                long now = System.currentTimeMillis();
                end = now;
                begin = now - TimeUnit.DAYS.toMillis(1);
            }
            if (!isUsageAccessGranted()) return out;
            android.app.usage.UsageStatsManager usm = (android.app.usage.UsageStatsManager) getSystemService(Context.USAGE_STATS_SERVICE);
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

    private List<Map<String, String>> getInstalledApps() {
        List<Map<String, String>> apps = new ArrayList<>();
        try {
            android.content.pm.PackageManager pm = getPackageManager();
            List<android.content.pm.ApplicationInfo> packages = pm.getInstalledApplications(android.content.pm.PackageManager.GET_META_DATA);
            
            for (android.content.pm.ApplicationInfo packageInfo : packages) {
                // 유튜브 관련 앱 디버깅
                if (packageInfo.packageName.contains("youtube") || 
                    packageInfo.packageName.contains("YouTube") ||
                    pm.getApplicationLabel(packageInfo).toString().toLowerCase().contains("youtube")) {
                    Log.d("InstalledApps", "YouTube 관련 앱 발견: " + packageInfo.packageName + " - " + pm.getApplicationLabel(packageInfo).toString());
                    Log.d("InstalledApps", "시스템 앱 여부: " + ((packageInfo.flags & android.content.pm.ApplicationInfo.FLAG_SYSTEM) != 0));
                }
                
                // 모든 앱을 포함하도록 수정 (시스템 앱 제외 조건 완전 제거)
                Map<String, String> app = new HashMap<>();
                app.put("packageName", packageInfo.packageName);
                app.put("appName", pm.getApplicationLabel(packageInfo).toString());
                
                // 앱 아이콘 정보 추가
                try {
                    android.graphics.drawable.Drawable icon = pm.getApplicationIcon(packageInfo.packageName);
                    app.put("hasIcon", "true");
                } catch (Exception e) {
                    app.put("hasIcon", "false");
                }
                
                apps.add(app);
            }
            
            // 디버깅: 전체 앱 개수와 유튜브 관련 앱 개수 출력
            Log.d("InstalledApps", "전체 앱 개수: " + apps.size());
            int youtubeCount = 0;
            for (Map<String, String> app : apps) {
                String packageName = app.get("packageName");
                String appName = app.get("appName");
                if ((packageName != null && packageName.toLowerCase().contains("youtube")) ||
                    (appName != null && appName.toLowerCase().contains("youtube"))) {
                    youtubeCount++;
                    Log.d("InstalledApps", "최종 포함된 YouTube 앱: " + packageName + " - " + appName);
                }
            }
            Log.d("InstalledApps", "포함된 YouTube 관련 앱 개수: " + youtubeCount);
            
        } catch (Throwable t) {
            Log.e("InstalledApps", "getInstalledApps failed", t);
        }
        return apps;
    }
}
