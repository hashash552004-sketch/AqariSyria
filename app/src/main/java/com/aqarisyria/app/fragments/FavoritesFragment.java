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
import com.google.firebase.firestore.FirebaseFirestore;
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
        loadFavorites();
        return binding.getRoot();
    }

    private void setupRecyclerView() {
        adapter = new PropertyAdapter(favoritesList, getActivity());
        binding.rvFavorites.setLayoutManager(new LinearLayoutManager(getActivity()));
        binding.rvFavorites.setAdapter(adapter);
    }

    private void loadFavorites() {
        binding.progressBar.setVisibility(View.VISIBLE);
        String uid = mAuth.getCurrentUser().getUid();
        db.collection("users").document(uid).get()
            .addOnSuccessListener(doc -> {
                if (!doc.exists()) return;
                List<String> favoriteIds = (List<String>) doc.get("favorites");
                if (favoriteIds == null || favoriteIds.isEmpty()) {
                    binding.progressBar.setVisibility(View.GONE);
                    binding.tvEmpty.setVisibility(View.VISIBLE);
                    return;
                }
                favoritesList.clear();
                final int[] loaded = {0};
                for (String id : favoriteIds) {
                    db.collection("properties").document(id).get()
                        .addOnSuccessListener(propDoc -> {
                            if (propDoc.exists()) {
                                Property p = propDoc.toObject(Property.class);
                                if (p != null) {
                                    p.setId(propDoc.getId());
                                    favoritesList.add(p);
                                }
                            }
                            loaded[0]++;
                            if (loaded[0] == favoriteIds.size()) {
                                adapter.notifyDataSetChanged();
                                binding.progressBar.setVisibility(View.GONE);
                                binding.tvEmpty.setVisibility(favoritesList.isEmpty() ? View.VISIBLE : View.GONE);
                            }
                        });
                }
            });
    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();
        binding = null;
    }
}
