package com.aqarisyria.app.adapters;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.DiffUtil;
import androidx.recyclerview.widget.ListAdapter;
import androidx.recyclerview.widget.RecyclerView;

import com.aqarisyria.app.R;
import com.aqarisyria.app.models.NotificationItem;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;
import java.util.concurrent.TimeUnit;

public class NotificationsAdapter extends ListAdapter<NotificationItem, NotificationsAdapter.ViewHolder> {

    private OnNotificationClickListener listener;

    public interface OnNotificationClickListener {
        void onNotificationClick(NotificationItem notification);
    }

    public NotificationsAdapter(OnNotificationClickListener listener) {
        super(new DiffUtil.ItemCallback<NotificationItem>() {
            @Override
            public boolean areItemsTheSame(@NonNull NotificationItem oldItem, @NonNull NotificationItem newItem) {
                return oldItem.getId() != null && oldItem.getId().equals(newItem.getId());
            }

            @Override
            public boolean areContentsTheSame(@NonNull NotificationItem oldItem, @NonNull NotificationItem newItem) {
                return oldItem.isRead() == newItem.isRead()
                    && oldItem.getTitle() != null && oldItem.getTitle().equals(newItem.getTitle());
            }
        });
        this.listener = listener;
    }

    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext())
            .inflate(R.layout.item_notification, parent, false);
        return new ViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder holder, int position) {
        NotificationItem item = getItem(position);
        holder.bind(item, listener);
    }

    static class ViewHolder extends RecyclerView.ViewHolder {

        private ImageView ivIcon;
        private TextView tvTitle;
        private TextView tvBody;
        private TextView tvTime;
        private View vUnreadDot;

        ViewHolder(@NonNull View itemView) {
            super(itemView);
            ivIcon = itemView.findViewById(R.id.ivNotificationIcon);
            tvTitle = itemView.findViewById(R.id.tvNotificationTitle);
            tvBody = itemView.findViewById(R.id.tvNotificationBody);
            tvTime = itemView.findViewById(R.id.tvNotificationTime);
            vUnreadDot = itemView.findViewById(R.id.vUnreadDot);
        }

        void bind(final NotificationItem notification, final OnNotificationClickListener listener) {
            tvTitle.setText(notification.getTitle());
            tvBody.setText(notification.getBody());
            tvTime.setText(getRelativeTime(notification.getTimestamp()));

            if (notification.isRead()) {
                tvTitle.setAlpha(0.7f);
                tvBody.setAlpha(0.7f);
                vUnreadDot.setVisibility(View.GONE);
            } else {
                tvTitle.setAlpha(1.0f);
                tvBody.setAlpha(1.0f);
                vUnreadDot.setVisibility(View.VISIBLE);
            }

            setNotificationIcon(notification.getType());

            itemView.setOnClickListener(v -> {
                if (listener != null) {
                    listener.onNotificationClick(notification);
                }
            });
        }

        private void setNotificationIcon(String type) {
            if (type == null) {
                ivIcon.setImageResource(R.drawable.ic_notification);
                return;
            }
            switch (type) {
                case "new_property":
                    ivIcon.setImageResource(R.drawable.ic_apartment);
                    break;
                case "message":
                    ivIcon.setImageResource(R.drawable.ic_message);
                    break;
                case "favorite":
                    ivIcon.setImageResource(R.drawable.ic_favorite_filled);
                    break;
                case "review":
                    ivIcon.setImageResource(R.drawable.ic_star);
                    break;
                case "follow":
                    ivIcon.setImageResource(R.drawable.ic_person);
                    break;
                default:
                    ivIcon.setImageResource(R.drawable.ic_notification);
                    break;
            }
        }

        private String getRelativeTime(Date timestamp) {
            if (timestamp == null) return "";

            long now = System.currentTimeMillis();
            long diff = now - timestamp.getTime();

            if (diff < 0) return "";

            long minutes = TimeUnit.MILLISECONDS.toMinutes(diff);
            long hours = TimeUnit.MILLISECONDS.toHours(diff);
            long days = TimeUnit.MILLISECONDS.toDays(diff);

            if (minutes < 1) return itemView.getContext().getString(R.string.just_now);
            if (minutes < 60) return itemView.getContext().getString(R.string.minutes_ago, (int) minutes);
            if (hours == 1) return itemView.getContext().getString(R.string.hour_ago);
            if (hours < 24) return itemView.getContext().getString(R.string.hours_ago, (int) hours);
            if (days == 1) return itemView.getContext().getString(R.string.day_ago);
            return itemView.getContext().getString(R.string.days_ago, (int) days);
        }
    }
}
