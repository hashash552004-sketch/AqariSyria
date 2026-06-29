package com.aqarisyria.app.fragments;

import android.content.Intent;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import androidx.annotation.NonNull;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.firestore.FirebaseFirestore;
import com.google.firebase.firestore.ListenerRegistration;
import com.google.firebase.firestore.Query;
import com.aqarisyria.app.R;
import com.aqarisyria.app.activities.PropertyDetailActivity;
import com.aqarisyria.app.activities.SearchActivity;
import com.aqarisyria.app.adapters.PropertyAdapter;
import com.aqarisyria.app.databinding.FragmentHomeBinding;
import com.aqarisyria.app.models.Property;
import java.util.ArrayList;
import java.util.List;

public class HomeFragment extends Fragment {

    private FragmentHomeBinding binding;
    private FirebaseFirestore db;
    private FirebaseAuth mAuth;
    private PropertyAdapter featuredAdapter;
    private PropertyAdapter recentAdapter;
    private List<Property> featuredList = new ArrayList<>();
    private List<Property> recentList = new ArrayList<>();
    private ListenerRegistration featuredListener;
    private ListenerRegistration recentListener;
    private String currentTypeFilter = "";

    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        binding = FragmentHomeBinding.inflate(inflater, container, false);
        db = FirebaseFirestore.getInstance();
        mAuth = FirebaseAuth.getInstance();

        setupRecyclerViews();
        setupSearchBar();
        setupNotifications();
        setupCategoryChips();
        setupRefresh();
        loadUserName();
        loadFeaturedProperties();
        loadRecentProperties();

        binding.tvShowAllFeatured.setOnClickListener(v -> {
            if (isAdded()) startActivity(new Intent(getActivity(), SearchActivity.class));
        });

        binding.tvShowAllLatest.setOnClickListener(v -> {
            if (isAdded()) startActivity(new Intent(getActivity(), SearchActivity.class));
        });

        return binding.getRoot();
    }

    private boolean isActive() {
        return isAdded() && binding != null;
    }

    private void setupRefresh() {
        binding.swipeRefresh.setColorSchemeResources(
            R.color.primary,
            R.color.accent
        );
        binding.swipeRefresh.setOnRefreshListener(() -> {
            loadFeaturedProperties();
            loadRecentProperties();
        });
    }

    private void setupRecyclerViews() {
        featuredAdapter = new PropertyAdapter(featuredList, getActivity(), true);
        LinearLayoutManager horizontalLayout = new LinearLayoutManager(getActivity(), LinearLayoutManager.HORIZONTAL, false);
        binding.rvFeatured.setLayoutManager(horizontalLayout);
        binding.rvFeatured.setAdapter(featuredAdapter);

        recentAdapter = new PropertyAdapter(recentList, getActivity(), false);
        binding.rvRecent.setLayoutManager(new LinearLayoutManager(getActivity()));
        binding.rvRecent.setAdapter(recentAdapter);
    }

    private void setupSearchBar() {
        binding.searchCard.setOnClickListener(v -> {
            if (isAdded()) startActivity(new Intent(getActivity(), SearchActivity.class));
        });
        binding.tvSearchHint.setOnClickListener(v -> {
            if (isAdded()) startActivity(new Intent(getActivity(), SearchActivity.class));
        });
    }

    private void setupNotifications() {
        binding.btnNotifications.setOnClickListener(v -> {
            if (isAdded()) {
                Intent intent = new Intent(getActivity(), SearchActivity.class);
                startActivity(intent);
            }
        });
    }

    private void setupCategoryChips() {
        View.OnClickListener chipListener = v -> {
            int id = v.getId();
            if (id == R.id.chipApartment) currentTypeFilter = "apartment";
            else if (id == R.id.chipVilla) currentTypeFilter = "villa";
            else if (id == R.id.chipHouse) currentTypeFilter = "house";
            else if (id == R.id.chipLand) currentTypeFilter = "land";
            else if (id == R.id.chipShop) currentTypeFilter = "shop";
            else if (id == R.id.chipWarehouse) currentTypeFilter = "warehouse";

            if (isAdded()) {
                Intent intent = new Intent(getActivity(), SearchActivity.class);
                intent.putExtra("type", currentTypeFilter);
                startActivity(intent);
            }
        };

        binding.chipApartment.setOnClickListener(chipListener);
        binding.chipVilla.setOnClickListener(chipListener);
        binding.chipHouse.setOnClickListener(chipListener);
        binding.chipLand.setOnClickListener(chipListener);
        binding.chipShop.setOnClickListener(chipListener);
        binding.chipWarehouse.setOnClickListener(chipListener);
    }

    private void loadUserName() {
        if (mAuth.getCurrentUser() != null) {
            String name = mAuth.getCurrentUser().getDisplayName();
            if (name != null && !name.isEmpty()) {
                binding.tvUserName.setText(name);
            }
        }
    }

    private void loadFeaturedProperties() {
        if (featuredListener != null) featuredListener.remove();

        binding.progressFeatured.setVisibility(View.VISIBLE);
        featuredListener = db.collection("properties")
            .whereEqualTo("active", true)
            .orderBy("viewsCount", Query.Direction.DESCENDING)
            .limit(10)
            .addSnapshotListener((snapshot, error) -> {
                if (error != null) {
                    binding.progressFeatured.setVisibility(View.GONE);
                    return;
                }
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
                if (binding.swipeRefresh.isRefreshing()) binding.swipeRefresh.setRefreshing(false);
            });
    }

    private void loadRecentProperties() {
        if (recentListener != null) recentListener.remove();

        binding.progressRecent.setVisibility(View.VISIBLE);
        recentListener = db.collection("properties")
            .whereEqualTo("active", true)
            .orderBy("createdAt", Query.Direction.DESCENDING)
            .limit(20)
            .addSnapshotListener((snapshot, error) -> {
                if (error != null) {
                    binding.progressRecent.setVisibility(View.GONE);
                    return;
                }
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
                if (binding.swipeRefresh.isRefreshing()) binding.swipeRefresh.setRefreshing(false);
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
