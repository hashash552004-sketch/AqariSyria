package com.aqarisyria.app.activities;

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
import java.util.List;

public class SearchResultsActivity extends AppCompatActivity {

    private ActivitySearchResultsBinding binding;
    private FirebaseFirestore db;
    private PropertyAdapter adapter;
    private List<Property> resultList = new ArrayList<>();

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        binding = ActivitySearchResultsBinding.inflate(getLayoutInflater());
        setContentView(binding.getRoot());

        db = FirebaseFirestore.getInstance();

        binding.btnBack.setOnClickListener(v -> finish());

        adapter = new PropertyAdapter(resultList, this);
        binding.rvResults.setLayoutManager(new LinearLayoutManager(this));
        binding.rvResults.setAdapter(adapter);

        String queryText = getIntent().getStringExtra("query");
        String operation = getIntent().getStringExtra("operation");
        String governorate = getIntent().getStringExtra("governorate");
        String type = getIntent().getStringExtra("type");
        double minPrice = getIntent().getDoubleExtra("minPrice", 0);
        double maxPrice = getIntent().getDoubleExtra("maxPrice", Double.MAX_VALUE);
        int rooms = getIntent().getIntExtra("rooms", 0);
        double minArea = getIntent().getDoubleExtra("minArea", 0);

        String title = getString(R.string.search_results);
        if (!TextUtils.isEmpty(queryText)) {
            title = "\"" + queryText + "\"";
        }
        binding.tvTitle.setText(title);

        loadFilteredProperties(queryText, operation, governorate, type, minPrice, maxPrice, rooms, minArea);
    }

    private void loadFilteredProperties(String searchText, String operation, String governorate,
                                         String type, double minPrice, double maxPrice,
                                         int rooms, double minArea) {
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
                resultList.clear();
                for (var doc : snapshot.getDocuments()) {
                    Property p = doc.toObject(Property.class);
                    if (p != null) {
                        p.setId(doc.getId());

                        boolean matchesSearch = TextUtils.isEmpty(searchText) ||
                            (p.getTitle() != null && p.getTitle().toLowerCase().contains(searchText)) ||
                            (p.getDescription() != null && p.getDescription().toLowerCase().contains(searchText)) ||
                            (p.getLocationString() != null && p.getLocationString().toLowerCase().contains(searchText));

                        boolean matchesPrice = p.getPrice() >= minPrice && p.getPrice() <= maxPrice;
                        boolean matchesArea = p.getArea() >= minArea;
                        boolean matchesRooms = rooms <= 0 || p.getRooms() >= rooms;

                        if (matchesSearch && matchesPrice && matchesArea && matchesRooms) {
                            resultList.add(p);
                        }
                    }
                }
                adapter.notifyDataSetChanged();
                binding.progressBar.setVisibility(View.GONE);

                if (resultList.isEmpty()) {
                    binding.tvEmpty.setVisibility(View.VISIBLE);
                } else {
                    binding.rvResults.setVisibility(View.VISIBLE);
                    binding.tvResultCount.setVisibility(View.VISIBLE);
                    binding.tvResultCount.setText(getString(R.string.search_results_count, resultList.size()));
                }
            })
            .addOnFailureListener(e -> {
                if (isFinishing() || isDestroyed()) return;
                binding.progressBar.setVisibility(View.GONE);
                binding.tvEmpty.setVisibility(View.VISIBLE);
            });
    }
}
