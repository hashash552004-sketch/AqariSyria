package com.aqarisyria.app.fragments;

import android.content.Intent;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import androidx.annotation.NonNull;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.LinearLayoutManager;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.firestore.FieldPath;
import com.google.firebase.firestore.FirebaseFirestore;
import com.google.firebase.firestore.ListenerRegistration;
import com.aqarisyria.app.activities.LoginActivity;
import com.aqarisyria.app.adapters.PropertyAdapter;
import com.aqarisyria.app.databinding.FragmentFavoritesBinding;
import com.aqarisyria.app.models.Property;
import java.util.ArrayList;
import java.util.List;

public class FavoritesFragment extends Fragment {

    private FragmentFavoritesBinding binding;
    private FirebaseFirestore db;
    private FirebaseAuth mAuth;
    private PropertyAdapter adapter;
    private List<Property> favoritesList = new ArrayList<>();
    private ListenerRegistration userListener;
    private final List<ListenerRegistration> batchListeners = new ArrayList<>();

    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        binding = FragmentFavoritesBinding.inflate(inflater, container, false);
        db = FirebaseFirestore.getInstance();
        mAuth = FirebaseAuth.getInstance();

        if (mAuth.getCurrentUser() == null) {
            binding.layoutLoggedOut.setVisibility(View.VISIBLE);
            binding.rvFavorites.setVisibility(View.GONE);
            binding.btnLogin.setOnClickListener(v ->
                startActivity(new Intent(getActivity(), LoginActivity.class)));
            return binding.getRoot();
        }

        setupRecyclerView();
        listenFavorites();
        return binding.getRoot();
    }

    private void setupRecyclerView() {
        adapter = new PropertyAdapter(favoritesList, getActivity());
        binding.rvFavorites.setLayoutManager(new LinearLayoutManager(getActivity()));
        binding.rvFavorites.setAdapter(adapter);
    }

    private void listenFavorites() {
        binding.progressBar.setVisibility(View.VISIBLE);
        String uid = mAuth.getCurrentUser().getUid();
        userListener = db.collection("users").document(uid)
            .addSnapshotListener((userDoc, error) -> {
                if (error != null) return;
                if (userDoc == null || !userDoc.exists()) {
                    binding.progressBar.setVisibility(View.GONE);
                    binding.tvEmpty.setVisibility(View.VISIBLE);
                    return;
                }
                List<String> favoriteIds = (List<String>) userDoc.get("favorites");
                if (favoriteIds == null || favoriteIds.isEmpty()) {
                    favoritesList.clear();
                    adapter.notifyDataSetChanged();
                    binding.progressBar.setVisibility(View.GONE);
                    binding.tvEmpty.setVisibility(View.VISIBLE);
                    return;
                }
                loadFavoriteProperties(favoriteIds);
            });
    }

    private void loadFavoriteProperties(List<String> favoriteIds) {
        for (ListenerRegistration reg : batchListeners) {
            reg.remove();
        }
        batchListeners.clear();
        favoritesList.clear();
        binding.tvEmpty.setVisibility(View.GONE);

        int batchSize = 10;
        for (int i = 0; i < favoriteIds.size(); i += batchSize) {
            int end = Math.min(i + batchSize, favoriteIds.size());
            List<String> batch = favoriteIds.subList(i, end);
            ListenerRegistration reg = db.collection("properties")
                .whereIn(FieldPath.documentId(), batch)
                .addSnapshotListener((snapshot, error) -> {
                    if (error != null || snapshot == null) return;
                    favoritesList.removeIf(p -> batch.contains(p.getId()));
                    for (var doc : snapshot.getDocuments()) {
                        if (doc.exists()) {
                            Property p = doc.toObject(Property.class);
                            if (p != null) {
                                p.setId(doc.getId());
                                favoritesList.add(p);
                            }
                        }
                    }
                    adapter.notifyDataSetChanged();
                    binding.progressBar.setVisibility(View.GONE);
                    binding.tvEmpty.setVisibility(favoritesList.isEmpty() ? View.VISIBLE : View.GONE);
                });
            batchListeners.add(reg);
        }
    }

    @Override
    public void onDestroyView() {
        if (userListener != null) userListener.remove();
        for (ListenerRegistration reg : batchListeners) {
            reg.remove();
        }
        batchListeners.clear();
        super.onDestroyView();
        binding = null;
    }
}
