package com.aqarisyria.app.utils;

import android.content.Context;
import android.net.Uri;
import android.os.AsyncTask;

import java.io.BufferedReader;
import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLEncoder;

public class ImageUploader {

    public interface UploadCallback {
        void onSuccess(String imageUrl);
        void onFailure(String error);
    }

    public static void upload(Context context, Uri imageUri, UploadCallback callback) {
        new UploadTask(context, imageUri, callback).execute();
    }

    private static class UploadTask extends AsyncTask<Void, Void, String> {
        private final Context context;
        private final Uri imageUri;
        private final UploadCallback callback;
        private String errorMessage;

        UploadTask(Context context, Uri imageUri, UploadCallback callback) {
            this.context = context.getApplicationContext();
            this.imageUri = imageUri;
            this.callback = callback;
        }

        @Override
        protected String doInBackground(Void... voids) {
            try {
                String apiKey = context.getString(
                    context.getResources().getIdentifier("imgbb_api_key", "string", context.getPackageName()));

                InputStream is = context.getContentResolver().openInputStream(imageUri);
                if (is == null) {
                    errorMessage = "Cannot open image file";
                    return null;
                }

                ByteArrayOutputStream baos = new ByteArrayOutputStream();
                byte[] buffer = new byte[8192];
                int bytesRead;
                while ((bytesRead = is.read(buffer)) != -1) {
                    baos.write(buffer, 0, bytesRead);
                }
                is.close();

                byte[] imageBytes = baos.toByteArray();
                String base64Image = android.util.Base64.encodeToString(imageBytes, android.util.Base64.NO_WRAP);

                URL url = new URL("https://api.imgbb.com/1/upload");
                HttpURLConnection conn = (HttpURLConnection) url.openConnection();
                conn.setRequestMethod("POST");
                conn.setDoOutput(true);
                conn.setConnectTimeout(30000);
                conn.setReadTimeout(30000);

                String data = "key=" + URLEncoder.encode(apiKey, "UTF-8")
                    + "&image=" + URLEncoder.encode(base64Image, "UTF-8");

                OutputStreamWriter writer = new OutputStreamWriter(conn.getOutputStream());
                writer.write(data);
                writer.flush();
                writer.close();

                int responseCode = conn.getResponseCode();
                BufferedReader reader;
                if (responseCode >= 200 && responseCode < 300) {
                    reader = new BufferedReader(new InputStreamReader(conn.getInputStream()));
                } else {
                    reader = new BufferedReader(new InputStreamReader(conn.getErrorStream()));
                }

                StringBuilder response = new StringBuilder();
                String line;
                while ((line = reader.readLine()) != null) {
                    response.append(line);
                }
                reader.close();

                String json = response.toString();
                if (responseCode >= 200 && responseCode < 300) {
                    String urlKey = "\"url\":\"";
                    int urlStart = json.indexOf(urlKey);
                    if (urlStart != -1) {
                        urlStart += urlKey.length();
                        int urlEnd = json.indexOf("\"", urlStart);
                        if (urlEnd != -1) {
                            return json.substring(urlStart, urlEnd).replace("\\/", "/");
                        }
                    }
                    errorMessage = "Failed to parse upload response";
                } else {
                    errorMessage = json;
                }
                return null;

            } catch (Exception e) {
                errorMessage = e.getMessage() != null ? e.getMessage() : "Upload failed";
                return null;
            }
        }

        @Override
        protected void onPostExecute(String result) {
            if (result != null) {
                callback.onSuccess(result);
            } else {
                callback.onFailure(errorMessage);
            }
        }
    }
}