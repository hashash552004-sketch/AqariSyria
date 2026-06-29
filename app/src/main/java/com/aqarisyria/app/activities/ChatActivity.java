package com.aqarisyria.app.activities;

import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.text.TextUtils;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.database.ChildEventListener;
import com.google.firebase.database.DataSnapshot;
import com.google.firebase.database.DatabaseError;
import com.google.firebase.database.DatabaseReference;
import com.google.firebase.database.FirebaseDatabase;
import com.google.firebase.database.ServerValue;
import com.google.firebase.firestore.FirebaseFirestore;
import com.bumptech.glide.Glide;
import com.aqarisyria.app.R;
import com.aqarisyria.app.databinding.ActivityChatBinding;

import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

public class ChatActivity extends AppCompatActivity {

    private ActivityChatBinding binding;
    private FirebaseAuth mAuth;
    private FirebaseFirestore db;
    private DatabaseReference messagesRef;
    private DatabaseReference metadataRef;
    private String currentUserId;
    private String ownerId;
    private String ownerName;
    private String ownerPhone;
    private String propertyId;
    private String chatId;
    private MessageAdapter adapter;
    private List<ChatMessage> messageList;
    private ChildEventListener messageListener;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        binding = ActivityChatBinding.inflate(getLayoutInflater());
        setContentView(binding.getRoot());

        mAuth = FirebaseAuth.getInstance();
        db = FirebaseFirestore.getInstance();

        if (mAuth.getCurrentUser() == null) {
            Toast.makeText(this, R.string.login, Toast.LENGTH_SHORT).show();
            finish();
            return;
        }

        currentUserId = mAuth.getCurrentUser().getUid();
        ownerId = getIntent().getStringExtra("ownerId");
        ownerName = getIntent().getStringExtra("ownerName");
        ownerPhone = getIntent().getStringExtra("ownerPhone");
        propertyId = getIntent().getStringExtra("propertyId");

        if (ownerId == null || ownerId.equals(currentUserId)) {
            finish();
            return;
        }

        chatId = generateChatId(currentUserId, ownerId);
        DatabaseReference chatRoot = FirebaseDatabase.getInstance().getReference("chats");
        messagesRef = chatRoot.child(chatId).child("messages");
        metadataRef = chatRoot.child(chatId).child("metadata");

        messageList = new ArrayList<>();
        adapter = new MessageAdapter();
        LinearLayoutManager lm = new LinearLayoutManager(this);
        lm.setReverseLayout(false);
        lm.setStackFromBottom(true);
        binding.rvMessages.setLayoutManager(lm);
        binding.rvMessages.setAdapter(adapter);

        setupToolbar();
        loadOwnerInfo();
        initializeChat();
        setupSendButton();
        setupCallButton();
        setupAttachButton();
        setupBackNavigation();
    }

    private String generateChatId(String uid1, String uid2) {
        String[] ids = {uid1, uid2};
        Arrays.sort(ids);
        return ids[0] + "_" + ids[1];
    }

    private void setupToolbar() {
        setSupportActionBar(binding.toolbar);
        if (getSupportActionBar() != null) {
            getSupportActionBar().setDisplayShowTitleEnabled(false);
        }
        if (ownerName != null) {
            binding.tvOwnerName.setText(ownerName);
        }
    }

    private void setupBackNavigation() {
        binding.toolbar.setNavigationOnClickListener(v -> finish());
    }

    private void loadOwnerInfo() {
        if (ownerId == null) return;
        db.collection("users").document(ownerId).get()
            .addOnSuccessListener(doc -> {
                if (doc.exists()) {
                    String name = doc.getString("fullName");
                    if (name != null) binding.tvOwnerName.setText(name);
                    ownerPhone = doc.getString("phone");
                    String imgUrl = doc.getString("profileImage");
                    if (imgUrl != null && !imgUrl.isEmpty()) {
                        Glide.with(this).load(imgUrl).into(binding.civOwnerAvatar);
                    }
                }
            });
    }

    private void initializeChat() {
        metadataRef.addListenerForSingleValueEvent(new com.google.firebase.database.ValueEventListener() {
            @Override
            public void onDataChange(@NonNull DataSnapshot snapshot) {
                if (!snapshot.exists()) {
                    Map<String, Object> metadata = new HashMap<>();
                    Map<String, Boolean> participants = new HashMap<>();
                    participants.put(currentUserId, true);
                    participants.put(ownerId, true);
                    metadata.put("participants", participants);
                    metadata.put("lastMessage", "");
                    metadata.put("lastMessageTime", ServerValue.TIMESTAMP);
                    metadata.put("lastSenderId", "");
                    metadataRef.setValue(metadata);
                }
                listenForMessages();
            }

            @Override
            public void onCancelled(@NonNull DatabaseError error) {
                Toast.makeText(ChatActivity.this, R.string.error_general, Toast.LENGTH_SHORT).show();
                finish();
            }
        });
    }

    private void listenForMessages() {
        if (messageListener != null) {
            messagesRef.removeEventListener(messageListener);
        }
        messageListener = new ChildEventListener() {
            @Override
            public void onChildAdded(@NonNull DataSnapshot snapshot, @Nullable String previousChildName) {
                ChatMessage msg = snapshot.getValue(ChatMessage.class);
                if (msg != null) {
                    msg.messageId = snapshot.getKey();
                    messageList.add(msg);
                    adapter.notifyItemInserted(messageList.size() - 1);
                    binding.rvMessages.smoothScrollToPosition(messageList.size() - 1);
                    binding.layoutEmptyState.setVisibility(View.GONE);
                }
            }

            @Override
            public void onChildChanged(@NonNull DataSnapshot snapshot, @Nullable String previousChildName) {
                ChatMessage updated = snapshot.getValue(ChatMessage.class);
                if (updated != null) {
                    for (int i = 0; i < messageList.size(); i++) {
                        if (messageList.get(i).messageId.equals(snapshot.getKey())) {
                            messageList.set(i, updated);
                            adapter.notifyItemChanged(i);
                            break;
                        }
                    }
                }
            }

            @Override
            public void onChildRemoved(@NonNull DataSnapshot snapshot) {
                for (int i = 0; i < messageList.size(); i++) {
                    if (messageList.get(i).messageId.equals(snapshot.getKey())) {
                        messageList.remove(i);
                        adapter.notifyItemRemoved(i);
                        break;
                    }
                }
                if (messageList.isEmpty()) {
                    binding.layoutEmptyState.setVisibility(View.VISIBLE);
                }
            }

            @Override
            public void onChildMoved(@NonNull DataSnapshot snapshot, @Nullable String previousChildName) {}

            @Override
            public void onCancelled(@NonNull DatabaseError error) {}
        };
        messagesRef.orderByChild("timestamp").addChildEventListener(messageListener);
    }

    private void setupSendButton() {
        binding.fabSend.setOnClickListener(v -> sendMessage());
    }

    private void sendMessage() {
        String text = binding.etMessage.getText().toString().trim();
        if (TextUtils.isEmpty(text)) return;

        binding.etMessage.setText("");
        String messageId = messagesRef.push().getKey();
        if (messageId == null) return;

        Map<String, Object> message = new HashMap<>();
        message.put("senderId", currentUserId);
        message.put("text", text);
        message.put("timestamp", ServerValue.TIMESTAMP);
        message.put("read", false);

        messagesRef.child(messageId).setValue(message)
            .addOnFailureListener(e ->
                Toast.makeText(ChatActivity.this, R.string.error_general, Toast.LENGTH_SHORT).show());

        metadataRef.child("lastMessage").setValue(text);
        metadataRef.child("lastMessageTime").setValue(ServerValue.TIMESTAMP);
        metadataRef.child("lastSenderId").setValue(currentUserId);

        DatabaseReference userChatsRef = FirebaseDatabase.getInstance().getReference("userChats");
        userChatsRef.child(currentUserId).child(chatId).setValue(true);
        userChatsRef.child(ownerId).child(chatId).setValue(true);
    }

    private void setupCallButton() {
        binding.btnCall.setOnClickListener(v -> {
            if (ownerPhone != null && !ownerPhone.isEmpty()) {
                Intent dialIntent = new Intent(Intent.ACTION_DIAL);
                dialIntent.setData(Uri.parse("tel:" + ownerPhone));
                startActivity(dialIntent);
            } else {
                Toast.makeText(this, R.string.error_general, Toast.LENGTH_SHORT).show();
            }
        });
    }

    private void setupAttachButton() {
        binding.btnAttach.setOnClickListener(v ->
            Toast.makeText(this, R.string.chat_attachment_soon, Toast.LENGTH_SHORT).show());
    }

    private class MessageAdapter extends RecyclerView.Adapter<RecyclerView.ViewHolder> {

        private static final int VIEW_TYPE_SENT = 1;
        private static final int VIEW_TYPE_RECEIVED = 2;

        @Override
        public int getItemViewType(int position) {
            ChatMessage msg = messageList.get(position);
            return msg.senderId.equals(currentUserId) ? VIEW_TYPE_SENT : VIEW_TYPE_RECEIVED;
        }

        @Override
        public int getItemCount() {
            return messageList.size();
        }

        @NonNull
        @Override
        public RecyclerView.ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
            LayoutInflater inflater = LayoutInflater.from(parent.getContext());
            if (viewType == VIEW_TYPE_SENT) {
                View v = inflater.inflate(R.layout.item_chat_message_sent, parent, false);
                return new SentViewHolder(v);
            } else {
                View v = inflater.inflate(R.layout.item_chat_message_received, parent, false);
                return new ReceivedViewHolder(v);
            }
        }

        @Override
        public void onBindViewHolder(@NonNull RecyclerView.ViewHolder holder, int position) {
            ChatMessage msg = messageList.get(position);
            String timeStr = formatTime(msg.timestamp);

            if (holder instanceof SentViewHolder) {
                SentViewHolder h = (SentViewHolder) holder;
                h.tvText.setText(msg.text);
                h.tvTime.setText(timeStr);
                h.ivReadStatus.setVisibility(msg.read ? View.VISIBLE : View.INVISIBLE);
            } else if (holder instanceof ReceivedViewHolder) {
                ReceivedViewHolder h = (ReceivedViewHolder) holder;
                h.tvText.setText(msg.text);
                h.tvTime.setText(timeStr);
            }
        }

        private String formatTime(long timestamp) {
            if (timestamp <= 0) return "";
            SimpleDateFormat sdf = new SimpleDateFormat("HH:mm", Locale.getDefault());
            return sdf.format(new Date(timestamp));
        }
    }

    private static class SentViewHolder extends RecyclerView.ViewHolder {
        TextView tvText, tvTime;
        ImageView ivReadStatus;

        SentViewHolder(View itemView) {
            super(itemView);
            tvText = itemView.findViewById(R.id.tvText);
            tvTime = itemView.findViewById(R.id.tvTime);
            ivReadStatus = itemView.findViewById(R.id.ivReadStatus);
        }
    }

    private static class ReceivedViewHolder extends RecyclerView.ViewHolder {
        TextView tvText, tvTime;

        ReceivedViewHolder(View itemView) {
            super(itemView);
            tvText = itemView.findViewById(R.id.tvText);
            tvTime = itemView.findViewById(R.id.tvTime);
        }
    }

    public static class ChatMessage {
        public String messageId;
        public String senderId;
        public String text;
        public long timestamp;
        public boolean read;

        public ChatMessage() {}

        public ChatMessage(String senderId, String text, long timestamp) {
            this.senderId = senderId;
            this.text = text;
            this.timestamp = timestamp;
            this.read = false;
        }
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        if (messageListener != null && messagesRef != null) {
            messagesRef.removeEventListener(messageListener);
        }
    }
}
