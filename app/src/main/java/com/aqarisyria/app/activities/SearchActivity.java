package com.aqarisyria.app.activities;

import android.os.Bundle;
import android.view.View;
import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import com.google.firebase.firestore.FirebaseFirestore;
import com.google.firebase.firestore.Query;
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

    private String filterOperation = "";
    private String filterGovernorate = "";
    private String filterType = "";
    private double filterMinPrice = 0;
    private double filterMaxPrice = Double.MAX_VALUE;
    private double filterMinArea = 0;
    private double filterMaxArea = Double.MAX_VALUE;
    private int filterRooms = 0;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        binding = ActivitySearchBinding.inflate(getLayoutInflater());
        setContentView(binding.getRoot());

        db = FirebaseFirestore.getInstance();
        binding.btnBack.setOnClickListener(v -> finish());

        readFilterIntent();

        adapter = new PropertyAdapter(resultList, this);
        binding.rvResults.setLayoutManager(new LinearLayoutManager(this));
        binding.rvResults.setAdapter(adapter);

        loadFilteredProperties();
    }

    private void readFilterIntent() {
        if (getIntent() != null) {
            filterOperation = getIntent().getStringExtra("operation");
            filterGovernorate = getIntent().getStringExtra("governorate");
            filterType = getIntent().getStringExtra("type");
            filterMinPrice = getIntent().getDoubleExtra("minPrice", 0);
            filterMaxPrice = getIntent().getDoubleExtra("maxPrice", Double.MAX_VALUE);
            filterMinArea = getIntent().getDoubleExtra("minArea", 0);
            filterMaxArea = getIntent().getDoubleExtra("maxArea", Double.MAX_VALUE);
            filterRooms = getIntent().getIntExtra("rooms", 0);

            String subtitle = "نتائج البحث";
            if (filterOperation != null && !filterOperation.isEmpty()) {
                String op = filterOperation.equals("sell") ? "للبيع" : filterOperation.equals("rent") ? "للإيجار" : "استثمار";
                subtitle = op;
            }
            binding.tvTitle.setText(subtitle);
        }
    }

    private void loadFilteredProperties() {
        binding.progressBar.setVisibility(View.VISIBLE);

        Query query = db.collection("properties").whereEqualTo("active", true);

        if (filterOperation != null && !filterOperation.isEmpty())
            query = query.whereEqualTo("operationType", filterOperation);
        if (filterGovernorate != null && !filterGovernorate.isEmpty())
            query = query.whereEqualTo("governorate", filterGovernorate);
        if (filterType != null && !filterType.isEmpty())
            query = query.whereEqualTo("type", filterType);

        query.orderBy("createdAt", Query.Direction.DESCENDING).limit(50)
            .get()
            .addOnSuccessListener(snapshot -> {
                if (isFinishing() || isDestroyed()) return;
                resultList.clear();
                for (var doc : snapshot.getDocuments()) {
                    Property p = doc.toObject(Property.class);
                    if (p != null) {
                        p.setId(doc.getId());
                        if (p.getPrice() >= filterMinPrice && p.getPrice() <= filterMaxPrice &&
                            p.getArea() >= filterMinArea && p.getArea() <= filterMaxArea &&
                            (filterRooms == 0 || (filterRooms == 5 ? p.getRooms() >= 5 : p.getRooms() == filterRooms))) {
                            resultList.add(p);
                        }
                    }
                }
                adapter.notifyDataSetChanged();
                binding.progressBar.setVisibility(View.GONE);
                binding.tvEmpty.setVisibility(resultList.isEmpty() ? View.VISIBLE : View.GONE);
            })
            .addOnFailureListener(e -> {
                if (isFinishing() || isDestroyed()) return;
                binding.progressBar.setVisibility(View.GONE);
                binding.tvEmpty.setVisibility(View.VISIBLE);
            });
    }
}
