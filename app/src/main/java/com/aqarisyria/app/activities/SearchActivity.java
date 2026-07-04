package com.aqarisyria.app.activities;

import android.content.Intent;
import android.os.Bundle;
import android.text.TextUtils;
import android.widget.ArrayAdapter;
import androidx.appcompat.app.AppCompatActivity;
import com.aqarisyria.app.R;
import com.aqarisyria.app.databinding.ActivitySearchBinding;

public class SearchActivity extends AppCompatActivity {

    private ActivitySearchBinding binding;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        binding = ActivitySearchBinding.inflate(getLayoutInflater());
        setContentView(binding.getRoot());

        binding.btnBack.setOnClickListener(v -> finish());

        setupGovernorateDropdown();
        setupSearchInput();
        setupSearchButton();
        setupChips();

        binding.chipAll.setChecked(true);
        binding.chipTypeAll.setChecked(true);

        String incomingType = getIntent().getStringExtra("type");
        if (incomingType != null) {
            switch (incomingType) {
                case "apartment": binding.chipApartment.setChecked(true); break;
                case "villa": binding.chipVilla.setChecked(true); break;
                case "house": binding.chipHouse.setChecked(true); break;
                case "land": binding.chipLand.setChecked(true); break;
                case "shop": binding.chipShop.setChecked(true); break;
                case "warehouse": binding.chipWarehouse.setChecked(true); break;
            }
        }
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
        // Single selection handles itself, no need for clearOperationChips
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
        if (governorate.equals(getString(R.string.all_governorates))) governorate = "";
        String type = "";
        if (binding.chipApartment.isChecked()) type = "apartment";
        else if (binding.chipVilla.isChecked()) type = "villa";
        else if (binding.chipLand.isChecked()) type = "land";
        else if (binding.chipHouse.isChecked()) type = "house";
        else if (binding.chipShop.isChecked()) type = "shop";
        else if (binding.chipWarehouse.isChecked()) type = "warehouse";

        String minPriceStr = binding.etMinPrice.getText().toString().trim();
        String maxPriceStr = binding.etMaxPrice.getText().toString().trim();
        String roomsStr = binding.etRooms.getText().toString().trim();
        String minAreaStr = binding.etMinArea.getText().toString().trim();

        double minPrice = 0, maxPrice = Double.MAX_VALUE;
        int rooms = 0;
        double minArea = 0;
        try { if (!minPriceStr.isEmpty()) minPrice = Double.parseDouble(minPriceStr); } catch (NumberFormatException ignored) {}
        try { if (!maxPriceStr.isEmpty()) maxPrice = Double.parseDouble(maxPriceStr); } catch (NumberFormatException ignored) {}
        try { if (!roomsStr.isEmpty()) rooms = Integer.parseInt(roomsStr); } catch (NumberFormatException ignored) {}
        try { if (!minAreaStr.isEmpty()) minArea = Double.parseDouble(minAreaStr); } catch (NumberFormatException ignored) {}

        Intent intent = new Intent(this, SearchResultsActivity.class);
        intent.putExtra("query", searchText);
        intent.putExtra("operation", operation);
        intent.putExtra("governorate", governorate);
        intent.putExtra("type", type);
        intent.putExtra("minPrice", minPrice);
        intent.putExtra("maxPrice", maxPrice);
        intent.putExtra("rooms", rooms);
        intent.putExtra("minArea", minArea);
        startActivity(intent);
    }
}
