package com.aqarisyria.app.activities;

import android.content.Intent;
import android.os.Bundle;
import android.view.View;

import androidx.appcompat.app.AppCompatActivity;

import java.util.Date;
import androidx.recyclerview.widget.LinearLayoutManager;

import com.aqarisyria.app.R;
import com.aqarisyria.app.activities.PropertyDetailActivity;
import com.aqarisyria.app.adapters.NotificationsAdapter;
import com.aqarisyria.app.databinding.ActivityNotificationsBinding;
import com.aqarisyria.app.models.NotificationItem;
import com.aqarisyria.app.utils.DialogUtil;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseUser;
import com.google.firebase.firestore.FirebaseFirestore;

public class NotificationsActivity extends AppCompatActivity {

    private ActivityNotificationsBinding binding;
    private FirebaseAuth mAuth;
    private FirebaseFirestore db;
    private NotificationsAdapter adapter;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        binding = ActivityNotificationsBinding.inflate(getLayoutInflater());
        setContentView(binding.getRoot());

        mAuth = FirebaseAuth.getInstance();
        db = FirebaseFirestore.getInstance();

        setupToolbar();
        setupRecyclerView();
        setupSwipeRefresh();
        loadNotifications();
    }

    private void setupToolbar() {
        setSupportActionBar(binding.toolbar);
        if (getSupportActionBar() != null) {
            getSupportActionBar().setDisplayHomeAsUpEnabled(true);
            getSupportActionBar().setDisplayShowHomeEnabled(true);
        }
        binding.toolbar.setNavigationOnClickListener(v -> finish());

        binding.btnMarkAllRead.setOnClickListener(v -> markAllAsRead());
    }

    private void setupRecyclerView() {
        adapter = new NotificationsAdapter(notification -> {
            markAsRead(notification);
            navigateToTarget(notification);
        });

        binding.rvNotifications.setLayoutManager(new LinearLayoutManager(this));
        binding.rvNotifications.setAdapter(adapter);
    }

    private void setupSwipeRefresh() {
        binding.swipeRefresh.setOnRefreshListener(this::loadNotifications);
        binding.swipeRefresh.setColorSchemeResources(R.color.primary, R.color.accent);
    }

    private void loadNotifications() {
        FirebaseUser currentUser = mAuth.getCurrentUser();
        if (currentUser == null) {
            showEmptyState();
            return;
        }

        String uid = currentUser.getUid();
        db.collection("notifications")
            .whereEqualTo("userId", uid)
            .get()
            .addOnSuccessListener(queryDocumentSnapshots -> {
                binding.swipeRefresh.setRefreshing(false);
                if (queryDocumentSnapshots.isEmpty()) {
                    showEmptyState();
                    return;
                }

                binding.rvNotifications.setVisibility(View.VISIBLE);
                binding.layoutEmpty.setVisibility(View.GONE);
                binding.btnMarkAllRead.setVisibility(View.VISIBLE);

                java.util.List<NotificationItem> notificationList = new java.util.ArrayList<>();
                boolean hasUnread = false;

                for (int i = 0; i < queryDocumentSnapshots.size(); i++) {
                    NotificationItem item = queryDocumentSnapshots.getDocuments().get(i).toObject(NotificationItem.class);
                    if (item != null) {
                        item.setId(queryDocumentSnapshots.getDocuments().get(i).getId());
                        notificationList.add(item);
                        if (!item.isRead()) {
                            hasUnread = true;
                        }
                    }
                }

                java.util.Collections.sort(notificationList, (a, b) -> {
                    Date ta = a.getTimestamp();
                    Date tb = b.getTimestamp();
                    if (ta == null && tb == null) return 0;
                    if (ta == null) return 1;
                    if (tb == null) return -1;
                    return tb.compareTo(ta);
                });

                adapter.submitList(notificationList);
                binding.btnMarkAllRead.setVisibility(hasUnread ? View.VISIBLE : View.GONE);
            })
            .addOnFailureListener(e -> {
                binding.swipeRefresh.setRefreshing(false);
                DialogUtil.showError(this, R.string.loading_error);
            });
    }

    private void markAsRead(NotificationItem notification) {
        if (notification.isRead() || notification.getId() == null) return;

        db.collection("notifications").document(notification.getId())
            .update("read", true)
            .addOnSuccessListener(unused -> {
                notification.setRead(true);
                adapter.notifyDataSetChanged();
            });
    }

    private void markAllAsRead() {
        FirebaseUser currentUser = mAuth.getCurrentUser();
        if (currentUser == null) return;

        String uid = currentUser.getUid();
        db.collection("notifications")
            .whereEqualTo("userId", uid)
            .get()
            .addOnSuccessListener(queryDocumentSnapshots -> {
                for (int i = 0; i < queryDocumentSnapshots.size(); i++) {
                    NotificationItem item = queryDocumentSnapshots.getDocuments().get(i).toObject(NotificationItem.class);
                    if (item != null && !item.isRead()) {
                        String docId = queryDocumentSnapshots.getDocuments().get(i).getId();
                        db.collection("notifications").document(docId).update("read", true);
                    }
                }
                loadNotifications();
                DialogUtil.showSuccess(this, R.string.mark_all_read);
            })
            .addOnFailureListener(e -> {
                DialogUtil.showErrorWithDetails(this, getString(R.string.error_general), e.getLocalizedMessage());
            });
    }

    private void navigateToTarget(NotificationItem notification) {
        if (notification.getType() == null) return;

        switch (notification.getType()) {
            case "new_property":
                if (notification.getTargetId() != null) {
                    Intent propertyIntent = new Intent(this, PropertyDetailActivity.class);
                    propertyIntent.putExtra(PropertyDetailActivity.EXTRA_PROPERTY_ID, notification.getTargetId());
                    startActivity(propertyIntent);
                }
                break;
            case "message":
                if (notification.getSenderId() != null) {
                    Intent chatIntent = new Intent(this, ChatActivity.class);
                    chatIntent.putExtra("ownerId", notification.getSenderId());
                    startActivity(chatIntent);
                }
                break;
            case "favorite":
                if (notification.getTargetId() != null) {
                    Intent propertyIntent = new Intent(this, PropertyDetailActivity.class);
                    propertyIntent.putExtra(PropertyDetailActivity.EXTRA_PROPERTY_ID, notification.getTargetId());
                    startActivity(propertyIntent);
                }
                break;
            case "review":
                if (notification.getTargetId() != null) {
                    Intent propertyIntent = new Intent(this, PropertyDetailActivity.class);
                    propertyIntent.putExtra(PropertyDetailActivity.EXTRA_PROPERTY_ID, notification.getTargetId());
                    startActivity(propertyIntent);
                }
                break;
            case "follow":
                if (notification.getSenderId() != null) {
                    startActivity(new Intent(this, ProfileActivity.class));
                }
                break;
        }
    }

    private void showEmptyState() {
        binding.rvNotifications.setVisibility(View.GONE);
        binding.layoutEmpty.setVisibility(View.VISIBLE);
        binding.btnMarkAllRead.setVisibility(View.GONE);
    }
}
