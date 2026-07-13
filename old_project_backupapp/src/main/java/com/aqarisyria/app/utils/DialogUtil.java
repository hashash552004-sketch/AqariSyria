package com.aqarisyria.app.utils;

import android.app.Dialog;
import android.content.Context;
import android.graphics.drawable.Drawable;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.DrawableRes;
import androidx.annotation.StringRes;
import androidx.appcompat.app.AlertDialog;
import androidx.core.content.ContextCompat;

import com.aqarisyria.app.R;

public class DialogUtil {

    public static void showError(Context context, String message) {
        show(context, message, R.string.error, R.drawable.ic_dialog_error, null);
    }

    public static void showError(Context context, @StringRes int messageRes) {
        show(context, context.getString(messageRes), R.string.error, R.drawable.ic_dialog_error, null);
    }

    public static void showSuccess(Context context, String message) {
        show(context, message, R.string.success, R.drawable.ic_dialog_success, null);
    }

    public static void showSuccess(Context context, @StringRes int messageRes) {
        show(context, context.getString(messageRes), R.string.success, R.drawable.ic_dialog_success, null);
    }

    public static void showWarning(Context context, String message) {
        show(context, message, R.string.warning, R.drawable.ic_dialog_warning, null);
    }

    public static void showInfo(Context context, String message) {
        show(context, message, null, R.drawable.ic_dialog_info, null);
    }

    public static void showInfo(Context context, @StringRes int titleRes, String message) {
        show(context, message, titleRes, R.drawable.ic_dialog_info, null);
    }

    public static void showErrorWithDetails(Context context, String message, String details) {
        show(context, message + "\n" + details, R.string.error, R.drawable.ic_dialog_error, null);
    }

    private static void show(Context context, String message, @StringRes Integer titleRes,
                             @DrawableRes int iconRes, Runnable onDismiss) {
        if (context == null) return;

        AlertDialog.Builder builder = new AlertDialog.Builder(context, R.style.DialogTheme);
        View view = LayoutInflater.from(context).inflate(R.layout.dialog_custom, null);

        ImageView ivIcon = view.findViewById(R.id.dialogIcon);
        TextView tvTitle = view.findViewById(R.id.dialogTitle);
        TextView tvMessage = view.findViewById(R.id.dialogMessage);
        TextView btnOk = view.findViewById(R.id.btnDialogOk);

        ivIcon.setImageResource(iconRes);
        tvMessage.setText(message);

        if (titleRes != null) {
            tvTitle.setText(titleRes);
            tvTitle.setVisibility(View.VISIBLE);
        } else {
            tvTitle.setVisibility(View.GONE);
        }

        builder.setView(view);
        AlertDialog dialog = builder.create();

        btnOk.setOnClickListener(v -> dialog.dismiss());

        dialog.setCancelable(true);
        dialog.setCanceledOnTouchOutside(true);
        dialog.show();
    }
}