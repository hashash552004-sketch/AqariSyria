package com.aqarisyria.app.fragments;

import android.content.Intent;
import android.os.Bundle;
import android.text.TextUtils;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.EditText;
import android.widget.Filter;
import android.widget.Filterable;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.database.ChildEventListener;
import com.google.firebase.database.DataSnapshot;
import com.google.firebase.database.DatabaseError;
import com.google.firebase.database.DatabaseReference;
import com.google.firebase.database.FirebaseDatabase;
import com.google.firebase.database.ValueEventListener;
import com.google.firebase.firestore.FirebaseFirestore;
import com.bumptech.glide.Glide;
import com.aqarisyria.app.R;
import com.aqarisyria.app.activities.ChatActivity;
import com.aqarisyria.app.databinding.FragmentMessagesBinding;

import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

public class MessagesFragment extends Fragment {

    private FragmentMessagesBinding binding;
    private FirebaseAuth mAuth;
    private FirebaseFirestore db;
    private DatabaseReference userChatsRef;
    private String currentUserId;
    private ConversationAdapter adapter;
    private List<ConversationItem> conversationList;
    private Map<String, ConversationItem> conversationMap;
    private ChildEventListener chatListener;

    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        binding = FragmentMessagesBinding.inflate(inflater, container, false);
        mAuth = FirebaseAuth.getInstance();
        db = FirebaseFirestore.getInstance();

        conversationList = new ArrayList<>();
        conversationMap = new HashMap<>();
        adapter = new ConversationAdapter();

        binding.rvConversations.setLayoutManager(new LinearLayoutManager(getContext()));
        binding.rvConversations.setAdapter(adapter);

        if (mAuth.getCurrentUser() != null) {
            currentUserId = mAuth.getCurrentUser().getUid();
            userChatsRef = FirebaseDatabase.getInstance().getReference("userChats");
            listenForChats();
        }

        setupSearch();
        return binding.getRoot();
    }

    private void listenForChats() {
        if (chatListener != null) {
            userChatsRef.child(currentUserId).removeEventListener(chatListener);
        }
        chatListener = new ChildEventListener() {
            @Override
            public void onChildAdded(@NonNull DataSnapshot snapshot, @Nullable String previousChildName) {
                String chatId = snapshot.getKey();
                if (chatId != null) {
                    loadChatMetadata(chatId);
                }
            }

            @Override
            public void onChildChanged(@NonNull DataSnapshot snapshot, @Nullable String previousChildName) {
                String chatId = snapshot.getKey();
                if (chatId != null) {
                    loadChatMetadata(chatId);
                }
            }

            @Override
            public void onChildRemoved(@NonNull DataSnapshot snapshot) {
                String chatId = snapshot.getKey();
                if (chatId != null) {
                    conversationMap.remove(chatId);
                    rebuildList();
                }
            }

            @Override
            public void onChildMoved(@NonNull DataSnapshot snapshot, @Nullable String previousChildName) {}

            @Override
            public void onCancelled(@NonNull DatabaseError error) {}
        };
        userChatsRef.child(currentUserId).addChildEventListener(chatListener);
    }

    private void loadChatMetadata(String chatId) {
        DatabaseReference metadataRef = FirebaseDatabase.getInstance()
            .getReference("chats").child(chatId).child("metadata");

        metadataRef.addListenerForSingleValueEvent(new ValueEventListener() {
            @Override
            public void onDataChange(@NonNull DataSnapshot snapshot) {
                if (!snapshot.exists()) return;
                String lastMessage = snapshot.child("lastMessage").getValue(String.class);
                Long lastMessageTime = snapshot.child("lastMessageTime").getValue(Long.class);
                String lastSenderId = snapshot.child("lastSenderId").getValue(String.class);
                Map<String, Boolean> participants = (Map<String, Boolean>) snapshot.child("participants").getValue();

                if (participants == null) return;

                String otherUserId = null;
                for (String uid : participants.keySet()) {
                    if (!uid.equals(currentUserId)) {
                        otherUserId = uid;
                        break;
                    }
                }
                if (otherUserId == null) return;

                String otherUserIdFinal = otherUserId;
                db.collection("users").document(otherUserId).get()
                    .addOnSuccessListener(doc -> {
                        if (!isAdded() || binding == null) return;
                        String name = doc.getString("fullName");
                        String imgUrl = doc.getString("profileImage");
                        String phone = doc.getString("phone");

                        ConversationItem item = new ConversationItem();
                        item.chatId = chatId;
                        item.otherUserId = otherUserIdFinal;
                        item.otherUserName = name != null ? name : "";
                        item.otherUserImage = imgUrl != null ? imgUrl : "";
                        item.lastMessage = lastMessage != null ? lastMessage : "";
                        item.lastMessageTime = lastMessageTime != null ? lastMessageTime : 0;
                        item.lastSenderId = lastSenderId;
                        item.otherUserPhone = phone != null ? phone : "";

                        conversationMap.put(chatId, item);
                        rebuildList();
                    });
            }

            @Override
            public void onCancelled(@NonNull DatabaseError error) {}
        });
    }

    private void rebuildList() {
        conversationList.clear();
        conversationList.addAll(conversationMap.values());
        adapter.resetFilter();
        updateEmptyState();
    }

    private void updateEmptyState() {
        if (binding != null) {
            binding.layoutEmptyState.setVisibility(
                conversationList.isEmpty() ? View.VISIBLE : View.GONE);
        }
    }

    private void setupSearch() {
        binding.etSearchConversations.addTextChangedListener(new android.text.TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {}

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
                adapter.getFilter().filter(s.toString());
            }

            @Override
            public void afterTextChanged(android.text.Editable s) {}
        });
    }

    private class ConversationAdapter extends RecyclerView.Adapter<ConversationAdapter.ViewHolder>
            implements Filterable {

        private List<ConversationItem> filteredList;

        ConversationAdapter() {
            this.filteredList = new ArrayList<>(conversationList);
        }

        void resetFilter() {
            filteredList = new ArrayList<>(conversationList);
            notifyDataSetChanged();
        }

        @NonNull
        @Override
        public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
            View v = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.item_conversation, parent, false);
            return new ViewHolder(v);
        }

        @Override
        public void onBindViewHolder(@NonNull ViewHolder holder, int position) {
            ConversationItem item = filteredList.get(position);
            holder.tvName.setText(item.otherUserName);

            if (!TextUtils.isEmpty(item.otherUserImage)) {
                Glide.with(MessagesFragment.this).load(item.otherUserImage).into(holder.civAvatar);
            } else {
                holder.civAvatar.setImageResource(R.drawable.ic_person);
            }

            if (item.lastMessage != null && !item.lastMessage.isEmpty()) {
                String prefix = "";
                if (item.lastSenderId != null && item.lastSenderId.equals(currentUserId)) {
                    prefix = "";
                }
                holder.tvLastMessage.setText(prefix + item.lastMessage);
            } else {
                holder.tvLastMessage.setText("");
            }

            if (item.lastMessageTime > 0) {
                holder.tvTime.setText(formatConversationTime(item.lastMessageTime));
            } else {
                holder.tvTime.setText("");
            }

            holder.itemView.setOnClickListener(v -> {
                Intent intent = new Intent(getActivity(), ChatActivity.class);
                intent.putExtra("ownerId", item.otherUserId);
                intent.putExtra("ownerName", item.otherUserName);
                intent.putExtra("ownerPhone", item.otherUserPhone);
                startActivity(intent);
            });
        }

        @Override
        public int getItemCount() {
            return filteredList.size();
        }

        @Override
        public Filter getFilter() {
            return new Filter() {
                @Override
                protected FilterResults performFiltering(CharSequence constraint) {
                    String query = constraint.toString().trim().toLowerCase();
                    List<ConversationItem> result = new ArrayList<>();
                    if (query.isEmpty()) {
                        result.addAll(conversationList);
                    } else {
                        for (ConversationItem c : conversationList) {
                            if (c.otherUserName != null &&
                                c.otherUserName.toLowerCase().contains(query)) {
                                result.add(c);
                            }
                        }
                    }
                    FilterResults fr = new FilterResults();
                    fr.values = result;
                    return fr;
                }

                @Override
                @SuppressWarnings("unchecked")
                protected void publishResults(CharSequence constraint, FilterResults results) {
                    filteredList = (List<ConversationItem>) results.values;
                    if (filteredList == null) filteredList = new ArrayList<>();
                    notifyDataSetChanged();
                }
            };
        }

        class ViewHolder extends RecyclerView.ViewHolder {
            de.hdodenhof.circleimageview.CircleImageView civAvatar;
            ImageView ivOnlineDot;
            TextView tvName, tvTime, tvLastMessage, tvUnreadBadge;

            ViewHolder(View itemView) {
                super(itemView);
                civAvatar = itemView.findViewById(R.id.civAvatar);
                ivOnlineDot = itemView.findViewById(R.id.ivOnlineDot);
                tvName = itemView.findViewById(R.id.tvName);
                tvTime = itemView.findViewById(R.id.tvTime);
                tvLastMessage = itemView.findViewById(R.id.tvLastMessage);
                tvUnreadBadge = itemView.findViewById(R.id.tvUnreadBadge);
            }
        }
    }

    private String formatConversationTime(long timestamp) {
        Date date = new Date(timestamp);
        Date now = new Date();
        SimpleDateFormat sdf;
        if (now.getTime() - timestamp < 86400000) {
            sdf = new SimpleDateFormat("HH:mm", Locale.getDefault());
        } else if (now.getTime() - timestamp < 172800000) {
            return getString(R.string.yesterday);
        } else {
            sdf = new SimpleDateFormat("MM/dd", Locale.getDefault());
        }
        return sdf.format(date);
    }

    private static class ConversationItem {
        String chatId;
        String otherUserId;
        String otherUserName;
        String otherUserImage;
        String otherUserPhone;
        String lastMessage;
        long lastMessageTime;
        String lastSenderId;
    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();
        if (chatListener != null && userChatsRef != null && currentUserId != null) {
            userChatsRef.child(currentUserId).removeEventListener(chatListener);
        }
        binding = null;
    }
}
