package com.aqarisyria.app.utils;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.net.Uri;
import android.os.Handler;
import android.os.Looper;

import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLEncoder;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class ImageUploader {

    private static final int MAX_IMAGE_DIMENSION = 1200;
    private static final int JPEG_QUALITY = 80;
    private static final ExecutorService executor = Executors.newFixedThreadPool(2);

    public interface UploadCallback {
        void onSuccess(String imageUrl);
        void onFailure(String error);
    }

    public static void upload(Context context, Uri imageUri, UploadCallback callback) {
        Context appContext = context.getApplicationContext();
        executor.execute(() -> {
            String result = doUpload(appContext, imageUri);
            String error = null;
            if (result == null) {
                error = "Upload failed";
            }
            final String finalResult = result;
            final String finalError = error;
            new Handler(Looper.getMainLooper()).post(() -> {
                if (finalResult != null) {
                    callback.onSuccess(finalResult);
                } else {
                    callback.onFailure(finalError);
                }
            });
        });
    }

    private static String doUpload(Context context, Uri imageUri) {
        try {
            String apiKey = context.getString(
                context.getResources().getIdentifier("imgbb_api_key", "string", context.getPackageName()));

            InputStream is = context.getContentResolver().openInputStream(imageUri);
            if (is == null) return null;

            Bitmap bitmap = BitmapFactory.decodeStream(is);
            is.close();
            if (bitmap == null) return null;

            int width = bitmap.getWidth();
            int height = bitmap.getHeight();
            if (width > MAX_IMAGE_DIMENSION || height > MAX_IMAGE_DIMENSION) {
                float ratio = Math.min((float) MAX_IMAGE_DIMENSION / width, (float) MAX_IMAGE_DIMENSION / height);
                width = Math.round(width * ratio);
                height = Math.round(height * ratio);
                bitmap = Bitmap.createScaledBitmap(bitmap, width, height, true);
            }

            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            bitmap.compress(Bitmap.CompressFormat.JPEG, JPEG_QUALITY, baos);
            bitmap.recycle();

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

            if (responseCode >= 200 && responseCode < 300) {
                JSONObject json = new JSONObject(response.toString());
                JSONObject dataObj = json.optJSONObject("data");
                if (dataObj != null) {
                    return dataObj.optString("url", null);
                }
            }
            return null;

        } catch (Exception e) {
            return null;
        }
    }
}
