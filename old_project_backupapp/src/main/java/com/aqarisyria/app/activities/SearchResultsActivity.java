package com.aqarisyria.app.activities;

import android.content.Intent;
import android.os.Bundle;
import android.text.TextUtils;
import android.view.View;

import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;

import com.google.firebase.firestore.FirebaseFirestore;
import com.google.firebase.firestore.Query;
import com.aqarisyria.app.R;
import com.aqarisyria.app.adapters.PropertyAdapter;
import com.aqarisyria.app.databinding.ActivitySearchResultsBinding;
import com.aqarisyria.app.models.Property;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;

public class SearchResultsActivity extends AppCompatActivity {

    private ActivitySearchResultsBinding binding;
    private FirebaseFirestore db;
    private PropertyAdapter adapter;
    private List<Property> resultList = new ArrayList<>();
    private List<Property> fullList = new ArrayList<>();

    private String queryText, operation, governorate, type;
    private double minPrice, maxPrice, minArea;
    private int rooms;

    private String currentSort = "newest";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        binding = ActivitySearchResultsBinding.inflate(getLayoutInflater());
        setContentView(binding.getRoot());

        db = FirebaseFirestore.getInstance();

        binding.btnBack.setOnClickListener(v -> finish());
        binding.btnCompare.setOnClickListener(v ->
            startActivity(new Intent(this, ComparisonActivity.class)));

        adapter = new PropertyAdapter(resultList, this);
        binding.rvResults.setLayoutManager(new LinearLayoutManager(this));
        binding.rvResults.setAdapter(adapter);

        queryText = getIntent().getStringExtra("query");
        operation = getIntent().getStringExtra("operation");
        governorate = getIntent().getStringExtra("governorate");
        type = getIntent().getStringExtra("type");
        minPrice = getIntent().getDoubleExtra("minPrice", 0);
        maxPrice = getIntent().getDoubleExtra("maxPrice", Double.MAX_VALUE);
        rooms = getIntent().getIntExtra("rooms", 0);
        minArea = getIntent().getDoubleExtra("minArea", 0);

        String title = getString(R.string.search_results);
        if (!TextUtils.isEmpty(queryText)) {
            title = "\"" + queryText + "\"";
        }
        binding.tvTitle.setText(title);

        setupSortChips();
        setupBathroomChips();
        setupFurnishedFilter();

        loadFilteredProperties();
    }

    private void setupSortChips() {
        binding.chipGroupSort.setVisibility(View.VISIBLE);
        binding.chipSortNewest.setChecked(true);

        binding.chipGroupSort.setOnCheckedStateChangeListener((group, checkedIds) -> {
            if (checkedIds.isEmpty()) {
                binding.chipSortNewest.setChecked(true);
                return;
            }
            int id = checkedIds.get(0);
            if (id == R.id.chipSortNewest) currentSort = "newest";
            else if (id == R.id.chipSortOldest) currentSort = "oldest";
            else if (id == R.id.chipSortCheapest) currentSort = "cheapest";
            else if (id == R.id.chipSortExpensive) currentSort = "expensive";
            else if (id == R.id.chipSortViewed) currentSort = "viewed";
            applyFilters();
        });
    }

    private void setupBathroomChips() {
        binding.layoutBathrooms.setVisibility(View.VISIBLE);
        binding.chipBathAny.setChecked(true);
    }

    private void setupFurnishedFilter() {
        binding.chkFurnished.setVisibility(View.VISIBLE);
        binding.chkFurnished.setOnCheckedChangeListener((buttonView, isChecked) -> applyFilters());
    }

    private void loadFilteredProperties() {
        binding.progressBar.setVisibility(View.VISIBLE);

        Query query = db.collection("properties").whereEqualTo("active", true);

        if (!TextUtils.isEmpty(operation))
            query = query.whereEqualTo("operationType", operation);
        if (!TextUtils.isEmpty(governorate))
            query = query.whereEqualTo("governorate", governorate);
        if (!TextUtils.isEmpty(type))
            query = query.whereEqualTo("type", type);

        query.limit(50)
            .get()
            .addOnSuccessListener(snapshot -> {
                if (isFinishing() || isDestroyed()) return;
                fullList.clear();
                for (var doc : snapshot.getDocuments()) {
                    Property p = doc.toObject(Property.class);
                    if (p != null) {
                        p.setId(doc.getId());

                        boolean matchesSearch = TextUtils.isEmpty(queryText) ||
                            (p.getTitle() != null && p.getTitle().toLowerCase().contains(queryText)) ||
                            (p.getDescription() != null && p.getDescription().toLowerCase().contains(queryText)) ||
                            (p.getLocationString() != null && p.getLocationString().toLowerCase().contains(queryText));

                        boolean matchesPrice = p.getPrice() >= minPrice && p.getPrice() <= maxPrice;
                        boolean matchesArea = p.getArea() >= minArea;
                        boolean matchesRooms = rooms <= 0 || p.getRooms() >= rooms;

                        if (matchesSearch && matchesPrice && matchesArea && matchesRooms) {
                            fullList.add(p);
                        }
                    }
                }
                applyFilters();
                binding.progressBar.setVisibility(View.GONE);
            })
            .addOnFailureListener(e -> {
                if (isFinishing() || isDestroyed()) return;
                binding.progressBar.setVisibility(View.GONE);
                binding.tvEmpty.setVisibility(View.VISIBLE);
            });
    }

    private void applyFilters() {
        resultList.clear();
        resultList.addAll(fullList);

        int minBathrooms = getSelectedBathrooms();
        if (minBathrooms > 0) {
            resultList.removeIf(p -> p.getBathrooms() < minBathrooms);
        }

        if (binding.chkFurnished.isChecked()) {
            resultList.removeIf(p -> !p.isFurnished());
        }

        applySort();

        adapter.notifyDataSetChanged();

        binding.tvResultCount.setVisibility(View.VISIBLE);
        binding.tvResultCount.setText(getString(R.string.search_results_count, resultList.size()));

        if (resultList.isEmpty()) {
            binding.tvEmpty.setVisibility(View.VISIBLE);
            binding.rvResults.setVisibility(View.GONE);
        } else {
            binding.tvEmpty.setVisibility(View.GONE);
            binding.rvResults.setVisibility(View.VISIBLE);
        }
    }

    private int getSelectedBathrooms() {
        if (binding.chipBathAny.isChecked()) return 0;
        if (binding.chipBath1.isChecked()) return 1;
        if (binding.chipBath2.isChecked()) return 2;
        if (binding.chipBath3.isChecked()) return 3;
        if (binding.chipBath4.isChecked()) return 4;
        return 0;
    }

    private void applySort() {
        switch (currentSort) {
            case "oldest":
                Collections.sort(resultList, (a, b) -> {
                    if (a.getCreatedAt() == null && b.getCreatedAt() == null) return 0;
                    if (a.getCreatedAt() == null) return 1;
                    if (b.getCreatedAt() == null) return -1;
                    return a.getCreatedAt().compareTo(b.getCreatedAt());
                });
                break;
            case "cheapest":
                Collections.sort(resultList, Comparator.comparingDouble(Property::getPrice));
                break;
            case "expensive":
                Collections.sort(resultList, (a, b) -> Double.compare(b.getPrice(), a.getPrice()));
                break;
            case "viewed":
                Collections.sort(resultList, (a, b) -> Integer.compare(b.getViewsCount(), a.getViewsCount()));
                break;
            default:
                Collections.sort(resultList, (a, b) -> {
                    if (a.getCreatedAt() == null && b.getCreatedAt() == null) return 0;
                    if (a.getCreatedAt() == null) return 1;
                    if (b.getCreatedAt() == null) return -1;
                    return b.getCreatedAt().compareTo(a.getCreatedAt());
                });
                break;
        }
    }
}
