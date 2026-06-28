package com.aqarisyria.app.utils;

import android.app.AlertDialog;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.AsyncTask;
import android.widget.Toast;

import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;

public class UpdateChecker {

    private static final String GITHUB_API = "https://api.github.com/repos/hashash552004-sketch/AqariSyria/releases/latest";

    public static void check(Context context, boolean showUpToDate) {
        new CheckTask(context, showUpToDate).execute();
    }

    private static class CheckTask extends AsyncTask<Void, Void, String> {
        private final Context context;
        private final boolean showUpToDate;

        CheckTask(Context context, boolean showUpToDate) {
            this.context = context.getApplicationContext();
            this.showUpToDate = showUpToDate;
        }

        @Override
        protected String doInBackground(Void... voids) {
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
                String apkUrl = json.optString("html_url", "");
                String body = json.optString("body", "");

                int remoteVersion = 0;
                if (tag.startsWith("v")) {
                    try {
                        remoteVersion = (int) (Double.parseDouble(tag.substring(1)) * 10);
                    } catch (NumberFormatException ignored) {}
                }

                int currentVersion = 0;
                try {
                    currentVersion = context.getPackageManager()
                        .getPackageInfo(context.getPackageName(), 0).versionCode;
                } catch (PackageManager.NameNotFoundException ignored) {}

                if (remoteVersion > currentVersion) {
                    return tag + "|||" + apkUrl + "|||" + body;
                }
                return "UP_TO_DATE";
            } catch (Exception e) {
                return null;
            }
        }

        @Override
        protected void onPostExecute(String result) {
            if (result == null) return;

            if (result.equals("UP_TO_DATE")) {
                if (showUpToDate) {
                    Toast.makeText(context, "التطبيق محدث", Toast.LENGTH_SHORT).show();
                }
                return;
            }

            String[] parts = result.split("\\|\\|\\|");
            if (parts.length < 2) return;

            String version = parts[0];
            String releaseUrl = "https://github.com/hashash552004-sketch/AqariSyria/releases/latest";

            new AlertDialog.Builder(context)
                .setTitle("تحديث متوفر " + version)
                .setMessage("يوجد إصدار أحدث من التطبيق. هل تريد التحميل الآن؟")
                .setPositiveButton("تحميل", (d, w) ->
                    context.startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse(releaseUrl))))
                .setNegativeButton("لاحقاً", null)
                .setCancelable(true)
                .show();
        }
    }
}
