package com.aqarisyria.app.fragments;

import android.content.Intent;
import android.os.Bundle;
import android.text.Editable;
import android.text.TextWatcher;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import androidx.annotation.NonNull;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.LinearLayoutManager;
import com.google.firebase.firestore.FirebaseFirestore;
import com.google.firebase.firestore.ListenerRegistration;
import com.google.firebase.firestore.Query;
import com.aqarisyria.app.R;
import com.aqarisyria.app.activities.SearchActivity;
import com.aqarisyria.app.adapters.PropertyAdapter;
import com.aqarisyria.app.databinding.FragmentHomeBinding;
import com.aqarisyria.app.models.Property;
import java.util.ArrayList;
import java.util.List;

public class HomeFragment extends Fragment {

    private FragmentHomeBinding binding;
    private FirebaseFirestore db;
    private PropertyAdapter featuredAdapter;
    private PropertyAdapter recentAdapter;
    private List<Property> featuredList = new ArrayList<>();
    private List<Property> recentList = new ArrayList<>();
    private String currentFilter = "all";
    private ListenerRegistration featuredListener;
    private ListenerRegistration recentListener;

    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        binding = FragmentHomeBinding.inflate(inflater, container, false);
        db = FirebaseFirestore.getInstance();

        setupRecyclerViews();
        setupFilterButtons();
        setupSearchBar();
        loadFeaturedProperties();
        loadRecentProperties();

        binding.tvShowAll.setOnClickListener(v -> {
            if (isAdded()) startActivity(new Intent(getActivity(), SearchActivity.class));
        });

        binding.btnRefresh.setOnClickListener(v -> refreshData());

        return binding.getRoot();
    }

    private boolean isActive() {
        return isAdded() && binding != null;
    }

    private void refreshData() {
        binding.progressFeatured.setVisibility(View.VISIBLE);
        binding.progressRecent.setVisibility(View.VISIBLE);
        loadFeaturedProperties();
        loadRecentProperties();
    }

    private void setupRecyclerViews() {
        featuredAdapter = new PropertyAdapter(featuredList, getActivity());
        binding.rvFeatured.setLayoutManager(
            new LinearLayoutManager(getActivity(), LinearLayoutManager.HORIZONTAL, false));
        binding.rvFeatured.setAdapter(featuredAdapter);

        recentAdapter = new PropertyAdapter(recentList, getActivity());
        binding.rvRecent.setLayoutManager(new LinearLayoutManager(getActivity()));
        binding.rvRecent.setAdapter(recentAdapter);
    }

    private void setupFilterButtons() {
        binding.btnFilterAll.setOnClickListener(v -> { if (isActive()) { currentFilter = "all"; applyFilter(); } });
        binding.btnFilterSell.setOnClickListener(v -> { if (isActive()) { currentFilter = "sell"; applyFilter(); } });
        binding.btnFilterRent.setOnClickListener(v -> { if (isActive()) { currentFilter = "rent"; applyFilter(); } });
        binding.btnFilterInvest.setOnClickListener(v -> { if (isActive()) { currentFilter = "invest"; applyFilter(); } });
    }

    private void applyFilter() {
        updateFilterButtonsUI();
        loadRecentProperties();
    }

    private void updateFilterButtonsUI() {
        binding.btnFilterAll.setSelected(currentFilter.equals("all"));
        binding.btnFilterSell.setSelected(currentFilter.equals("sell"));
        binding.btnFilterRent.setSelected(currentFilter.equals("rent"));
        binding.btnFilterInvest.setSelected(currentFilter.equals("invest"));
    }

    private void setupSearchBar() {
        binding.etSearch.setOnClickListener(v ->
            startActivity(new Intent(getActivity(), SearchActivity.class)));
    }

    private void loadFeaturedProperties() {
        if (featuredListener != null) featuredListener.remove();
        featuredListener = db.collection("properties")
            .whereEqualTo("active", true)
            .orderBy("viewsCount", Query.Direction.DESCENDING)
            .limit(10)
            .addSnapshotListener((snapshot, error) -> {
                if (error != null) return;
                if (snapshot == null) return;
                if (!isActive()) return;
                featuredList.clear();
                for (var doc : snapshot.getDocuments()) {
                    Property p = doc.toObject(Property.class);
                    if (p != null) {
                        p.setId(doc.getId());
                        featuredList.add(p);
                    }
                }
                featuredAdapter.notifyDataSetChanged();
                binding.progressFeatured.setVisibility(View.GONE);
            });
    }

    private void loadRecentProperties() {
        if (recentListener != null) recentListener.remove();
        Query query = db.collection("properties").whereEqualTo("active", true);

        if (!currentFilter.equals("all")) {
            query = query.whereEqualTo("operationType", currentFilter);
        }

        recentListener = query.orderBy("createdAt", Query.Direction.DESCENDING)
            .limit(20)
            .addSnapshotListener((snapshot, error) -> {
                if (error != null) return;
                if (snapshot == null) return;
                if (!isActive()) return;
                recentList.clear();
                for (var doc : snapshot.getDocuments()) {
                    Property p = doc.toObject(Property.class);
                    if (p != null) {
                        p.setId(doc.getId());
                        recentList.add(p);
                    }
                }
                recentAdapter.notifyDataSetChanged();
                binding.progressRecent.setVisibility(View.GONE);

                binding.tvEmptyRecent.setVisibility(recentList.isEmpty() ? View.VISIBLE : View.GONE);
            });
    }

    @Override
    public void onDestroyView() {
        if (featuredListener != null) featuredListener.remove();
        if (recentListener != null) recentListener.remove();
        super.onDestroyView();
        binding = null;
    }
}
