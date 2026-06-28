package com.aqarisyria.app.fragments;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import androidx.annotation.NonNull;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.LinearLayoutManager;
import com.google.firebase.firestore.FirebaseFirestore;
import com.google.firebase.firestore.Query;
import com.aqarisyria.app.R;
import com.aqarisyria.app.adapters.PropertyAdapter;
import com.aqarisyria.app.databinding.FragmentSearchBinding;
import com.aqarisyria.app.models.Property;
import java.util.ArrayList;
import java.util.List;

public class SearchFragment extends Fragment {

    private FragmentSearchBinding binding;
    private FirebaseFirestore db;
    private PropertyAdapter adapter;
    private List<Property> resultList = new ArrayList<>();

    private String selectedType = "";
    private String selectedGovernorate = "";
    private String selectedOperation = "";
    private double minPrice = 0;
    private double maxPrice = Double.MAX_VALUE;
    private double minArea = 0;
    private double maxArea = Double.MAX_VALUE;
    private int selectedRooms = 0;

    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        binding = FragmentSearchBinding.inflate(inflater, container, false);
        db = FirebaseFirestore.getInstance();

        setupRecyclerView();
        setupFilters();
        setupSliders();

        binding.btnSearch.setOnClickListener(v -> performSearch());
        binding.btnReset.setOnClickListener(v -> resetFilters());

        performSearch();
        return binding.getRoot();
    }

    private void setupRecyclerView() {
        adapter = new PropertyAdapter(resultList, getActivity());
        binding.rvResults.setLayoutManager(new LinearLayoutManager(getActivity()));
        binding.rvResults.setAdapter(adapter);
    }

    private void setupFilters() {
        // Operation type buttons
        binding.btnOpSell.setOnClickListener(v -> selectOperation("sell"));
        binding.btnOpRent.setOnClickListener(v -> selectOperation("rent"));
        binding.btnOpInvest.setOnClickListener(v -> selectOperation("invest"));

        // Rooms buttons
        binding.btnRoom1.setOnClickListener(v -> selectRooms(1));
        binding.btnRoom2.setOnClickListener(v -> selectRooms(2));
        binding.btnRoom3.setOnClickListener(v -> selectRooms(3));
        binding.btnRoom4.setOnClickListener(v -> selectRooms(4));
        binding.btnRoomPlus.setOnClickListener(v -> selectRooms(5));

        // Governorate spinner
        String[] govs = {"كل المحافظات", "دمشق", "حلب", "حمص", "حماه", "اللاذقية",
            "طرطوس", "دير الزور", "درعا", "إدلب", "الرقة", "الحسكة",
            "القنيطرة", "السويداء", "ريف دمشق"};
        ArrayAdapter<String> govAdapter = new ArrayAdapter<>(getActivity(),
            android.R.layout.simple_spinner_item, govs);
        govAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        binding.spinnerGovernorate.setAdapter(govAdapter);
        binding.spinnerGovernorate.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> parent, View view, int position, long id) {
                selectedGovernorate = position == 0 ? "" : govs[position];
            }
            @Override
            public void onNothingSelected(AdapterView<?> parent) {}
        });

        // Property type spinner
        String[] types = {"كل الأنواع", "شقة", "أرض", "فيلا", "مكتب", "محل", "أرض زراعية"};
        String[] typeValues = {"", "apartment", "land", "villa", "office", "shop", "farm"};
        ArrayAdapter<String> typeAdapter = new ArrayAdapter<>(getActivity(),
            android.R.layout.simple_spinner_item, types);
        typeAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        binding.spinnerPropertyType.setAdapter(typeAdapter);
        binding.spinnerPropertyType.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> parent, View view, int position, long id) {
                selectedType = typeValues[position];
            }
            @Override
            public void onNothingSelected(AdapterView<?> parent) {}
        });
    }

    private void setupSliders() {
        binding.sliderPrice.addOnChangeListener((slider, value, fromUser) -> {
            List<Float> values = slider.getValues();
            if (values.size() >= 2) {
                minPrice = values.get(0) * 1000;
                maxPrice = values.get(1) * 1000;
                binding.tvPriceRange.setText(String.format("%.0f,000 $ - %.0f,000 $", values.get(0), values.get(1)));
            }
        });

        binding.sliderArea.addOnChangeListener((slider, value, fromUser) -> {
            List<Float> values = slider.getValues();
            if (values.size() >= 2) {
                minArea = values.get(0);
                maxArea = values.get(1);
                binding.tvAreaRange.setText(String.format("%.0f - %.0f م²", values.get(0), values.get(1)));
            }
        });
    }

    private void selectOperation(String op) {
        selectedOperation = selectedOperation.equals(op) ? "" : op;
        binding.btnOpSell.setSelected(selectedOperation.equals("sell"));
        binding.btnOpRent.setSelected(selectedOperation.equals("rent"));
        binding.btnOpInvest.setSelected(selectedOperation.equals("invest"));
    }

    private void selectRooms(int rooms) {
        selectedRooms = selectedRooms == rooms ? 0 : rooms;
        binding.btnRoom1.setSelected(selectedRooms == 1);
        binding.btnRoom2.setSelected(selectedRooms == 2);
        binding.btnRoom3.setSelected(selectedRooms == 3);
        binding.btnRoom4.setSelected(selectedRooms == 4);
        binding.btnRoomPlus.setSelected(selectedRooms == 5);
    }

    private void performSearch() {
        binding.progressSearch.setVisibility(View.VISIBLE);
        binding.rvResults.setVisibility(View.GONE);

        Query query = db.collection("properties").whereEqualTo("active", true);

        if (!selectedOperation.isEmpty()) query = query.whereEqualTo("operationType", selectedOperation);
        if (!selectedGovernorate.isEmpty()) query = query.whereEqualTo("governorate", selectedGovernorate);
        if (!selectedType.isEmpty()) query = query.whereEqualTo("type", selectedType);

        query.orderBy("createdAt", Query.Direction.DESCENDING).limit(50)
            .get()
            .addOnSuccessListener(snapshot -> {
                resultList.clear();
                for (var doc : snapshot.getDocuments()) {
                    Property p = doc.toObject(Property.class);
                    if (p != null) {
                        p.setId(doc.getId());
                        // Client-side filters
                        if (p.getPrice() >= minPrice && p.getPrice() <= maxPrice &&
                            p.getArea() >= minArea && p.getArea() <= maxArea &&
                            (selectedRooms == 0 || (selectedRooms == 5 ? p.getRooms() >= 5 : p.getRooms() == selectedRooms))) {
                            resultList.add(p);
                        }
                    }
                }
                adapter.notifyDataSetChanged();
                binding.progressSearch.setVisibility(View.GONE);
                binding.rvResults.setVisibility(View.VISIBLE);
                binding.tvResultCount.setText("عرض النتائج (" + resultList.size() + ")");
                binding.tvEmpty.setVisibility(resultList.isEmpty() ? View.VISIBLE : View.GONE);
            });
    }

    private void resetFilters() {
        selectedOperation = "";
        selectedGovernorate = "";
        selectedType = "";
        selectedRooms = 0;
        minPrice = 0;
        maxPrice = Double.MAX_VALUE;
        minArea = 0;
        maxArea = Double.MAX_VALUE;
        binding.spinnerGovernorate.setSelection(0);
        binding.spinnerPropertyType.setSelection(0);
        binding.btnOpSell.setSelected(false);
        binding.btnOpRent.setSelected(false);
        binding.btnOpInvest.setSelected(false);
        binding.btnRoom1.setSelected(false);
        binding.btnRoom2.setSelected(false);
        binding.btnRoom3.setSelected(false);
        binding.btnRoom4.setSelected(false);
        binding.btnRoomPlus.setSelected(false);
        performSearch();
    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();
        binding = null;
    }
}
