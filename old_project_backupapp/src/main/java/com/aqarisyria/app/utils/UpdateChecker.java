package com.aqarisyria.app.utils;

import android.app.AlertDialog;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Handler;
import android.os.Looper;
import android.widget.Toast;

import com.aqarisyria.app.R;

import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class UpdateChecker {

    private static final String GITHUB_API = "https://api.github.com/repos/hashash552004-sketch/AqariSyria/releases/latest";
    private static final ExecutorService executor = Executors.newSingleThreadExecutor();

    public static void check(Context context, boolean showUpToDate) {
        Context appContext = context.getApplicationContext();
        executor.execute(() -> {
            String result = doCheck(appContext);
            new Handler(Looper.getMainLooper()).post(() -> handleResult(appContext, result, showUpToDate));
        });
    }

    private static String doCheck(Context context) {
        try {
            HttpURLConnection conn = (HttpURLConnection) new URL(GITHUB_API).openConnection();
            conn.setRequestProperty("Accept", "application/vnd.github+json");
            conn.setConnectTimeout(8000);
            conn.setReadTimeout(8000);

            int code = conn.getResponseCode();
            if (code != 200) return null;

            BufferedReader reader = new BufferedReader(new InputStreamReader(conn.getInputStream()));
            StringBuilder resp = new StringBuilder();
            String line;
            while ((line = reader.readLine()) != null) resp.append(line);
            reader.close();

            JSONObject json = new JSONObject(resp.toString());
            String tag = json.optString("tag_name", "");

            long remoteVersion = 0;
            if (tag.startsWith("v")) {
                try {
                    String[] parts = tag.substring(1).split("\\.");
                    remoteVersion = 0;
                    long multiplier = 1;
                    for (int i = parts.length - 1; i >= 0; i--) {
                        remoteVersion += Integer.parseInt(parts[i]) * multiplier;
                        multiplier *= 100;
                    }
                } catch (NumberFormatException ignored) {}
            }

            long currentVersion = 0;
            try {
                currentVersion = context.getPackageManager()
                    .getPackageInfo(context.getPackageName(), 0).versionCode;
            } catch (PackageManager.NameNotFoundException ignored) {}

            if (remoteVersion > currentVersion) {
                return tag;
            }
            return "UP_TO_DATE";
        } catch (Exception e) {
            return null;
        }
    }

    private static void handleResult(Context context, String result, boolean showUpToDate) {
        if (result == null) return;

        if (result.equals("UP_TO_DATE")) {
            if (showUpToDate) {
                Toast.makeText(context, context.getString(R.string.app_updated), Toast.LENGTH_SHORT).show();
            }
            return;
        }

        String releaseUrl = "https://github.com/hashash552004-sketch/AqariSyria/releases/latest";

        new AlertDialog.Builder(context)
            .setTitle(context.getString(R.string.update_available, result))
            .setMessage(context.getString(R.string.update_message))
            .setPositiveButton(context.getString(R.string.download), (d, w) ->
                context.startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse(releaseUrl))))
            .setNegativeButton(context.getString(R.string.later), null)
            .setCancelable(true)
            .show();
    }
}
