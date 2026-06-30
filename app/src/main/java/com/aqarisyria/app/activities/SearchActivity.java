package com.aqarisyria.app.activities;

import android.os.Bundle;
import android.text.TextUtils;
import android.view.View;
import android.widget.ArrayAdapter;
import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import com.google.firebase.firestore.FirebaseFirestore;
import com.google.firebase.firestore.Query;
import com.aqarisyria.app.R;
import com.aqarisyria.app.adapters.PropertyAdapter;
import com.aqarisyria.app.databinding.ActivitySearchBinding;
import com.aqarisyria.app.models.Property;
import java.util.ArrayList;
import java.util.List;

public class SearchActivity extends AppCompatActivity {

    private ActivitySearchBinding binding;
    private FirebaseFirestore db;
    private PropertyAdapter adapter;
    private List<Property> resultList = new ArrayList<>();

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        binding = ActivitySearchBinding.inflate(getLayoutInflater());
        setContentView(binding.getRoot());

        db = FirebaseFirestore.getInstance();
        binding.btnBack.setOnClickListener(v -> finish());

        adapter = new PropertyAdapter(resultList, this);
        binding.rvResults.setLayoutManager(new LinearLayoutManager(this));
        binding.rvResults.setAdapter(adapter);

        setupGovernorateDropdown();
        setupChips();
        setupSearchButton();
        setupSearchInput();

        binding.chipAll.setChecked(true);
        binding.chipTypeAll.setChecked(true);
    }

    private void setupGovernorateDropdown() {
        String[] governorates = getResources().getStringArray(R.array.governorates);
        ArrayAdapter<String> govAdapter = new ArrayAdapter<>(this,
            android.R.layout.simple_dropdown_item_1line, governorates);
        binding.etGovernorate.setAdapter(govAdapter);
        binding.etGovernorate.setOnItemClickListener((parent, view, position, id) ->
            binding.tilGovernorate.setHintEnabled(false));
    }

    private void setupChips() {
        binding.chipAll.setOnCheckedChangeListener((button, isChecked) -> {
            if (isChecked) clearOperationChips();
        });
        binding.chipSell.setOnCheckedChangeListener((button, isChecked) -> {
            if (isChecked) clearOperationChips();
        });
        binding.chipRent.setOnCheckedChangeListener((button, isChecked) -> {
            if (isChecked) clearOperationChips();
        });
        binding.chipInvest.setOnCheckedChangeListener((button, isChecked) -> {
            if (isChecked) clearOperationChips();
        });
    }

    private void clearOperationChips() {
        if (!binding.chipAll.isChecked()) binding.chipAll.setChecked(false);
        if (!binding.chipSell.isChecked()) binding.chipSell.setChecked(false);
        if (!binding.chipRent.isChecked()) binding.chipRent.setChecked(false);
        if (!binding.chipInvest.isChecked()) binding.chipInvest.setChecked(false);
    }

    private void setupSearchInput() {
        binding.etSearch.setOnEditorActionListener((v, actionId, event) -> {
            performSearch();
            return true;
        });
    }

    private void setupSearchButton() {
        binding.btnSearch.setOnClickListener(v -> performSearch());
    }

    private void performSearch() {
        String searchText = binding.etSearch.getText().toString().trim().toLowerCase();
        String operation = "";
        if (binding.chipSell.isChecked()) operation = "sell";
        else if (binding.chipRent.isChecked()) operation = "rent";
        else if (binding.chipInvest.isChecked()) operation = "invest";

        String governorate = binding.etGovernorate.getText().toString().trim();
        if (governorate.equals("كل المحافظات")) governorate = "";
        String type = "";
        if (binding.chipApartment.isChecked()) type = "apartment";
        else if (binding.chipVilla.isChecked()) type = "villa";
        else if (binding.chipLand.isChecked()) type = "land";

        String minPriceStr = binding.etMinPrice.getText().toString().trim();
        String maxPriceStr = binding.etMaxPrice.getText().toString().trim();
        String roomsStr = binding.etRooms.getText().toString().trim();
        String minAreaStr = binding.etMinArea.getText().toString().trim();

        double minPrice = minPriceStr.isEmpty() ? 0 : Double.parseDouble(minPriceStr);
        double maxPrice = maxPriceStr.isEmpty() ? Double.MAX_VALUE : Double.parseDouble(maxPriceStr);
        int rooms = roomsStr.isEmpty() ? 0 : Integer.parseInt(roomsStr);
        double minArea = minAreaStr.isEmpty() ? 0 : Double.parseDouble(minAreaStr);

        loadFilteredProperties(searchText, operation, governorate, type, minPrice, maxPrice, rooms, minArea);
    }

    private void loadFilteredProperties(String searchText, String operation, String governorate,
                                         String type, double minPrice, double maxPrice,
                                         int rooms, double minArea) {
        binding.progressBar.setVisibility(View.VISIBLE);
        binding.rvResults.setVisibility(View.GONE);
        binding.tvEmpty.setVisibility(View.GONE);
        binding.tvResultCount.setVisibility(View.GONE);

        Query query = db.collection("properties").whereEqualTo("active", true);

        if (!TextUtils.isEmpty(operation))
            query = query.whereEqualTo("operationType", operation);
        if (!TextUtils.isEmpty(governorate))
            query = query.whereEqualTo("governorate", governorate);
        if (!TextUtils.isEmpty(type))
            query = query.whereEqualTo("type", type);

        query.orderBy("createdAt", Query.Direction.DESCENDING).limit(50)
            .get()
            .addOnSuccessListener(snapshot -> {
                if (isFinishing() || isDestroyed()) return;
                resultList.clear();
                for (var doc : snapshot.getDocuments()) {
                    Property p = doc.toObject(Property.class);
                    if (p != null) {
                        p.setId(doc.getId());

                        boolean matchesSearch = searchText.isEmpty() ||
                            (p.getTitle() != null && p.getTitle().toLowerCase().contains(searchText)) ||
                            (p.getDescription() != null && p.getDescription().toLowerCase().contains(searchText)) ||
                            (p.getLocationString() != null && p.getLocationString().toLowerCase().contains(searchText));

                        boolean matchesPrice = p.getPrice() >= minPrice && p.getPrice() <= maxPrice;
                        boolean matchesArea = p.getArea() >= minArea;
                        boolean matchesRooms = rooms == 0 || (rooms == 5 ? p.getRooms() >= 5 : p.getRooms() == rooms);

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
