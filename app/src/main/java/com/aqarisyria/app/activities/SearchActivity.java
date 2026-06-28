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

        loadAllProperties();
    }

    private void loadAllProperties() {
        binding.progressBar.setVisibility(View.VISIBLE);
        db.collection("properties")
            .whereEqualTo("active", true)
            .orderBy("createdAt", Query.Direction.DESCENDING)
            .limit(50)
            .get()
            .addOnSuccessListener(snapshot -> {
                resultList.clear();
                for (var doc : snapshot.getDocuments()) {
                    Property p = doc.toObject(Property.class);
                    if (p != null) { p.setId(doc.getId()); resultList.add(p); }
                }
                adapter.notifyDataSetChanged();
                binding.progressBar.setVisibility(View.GONE);
                binding.tvEmpty.setVisibility(resultList.isEmpty() ? View.VISIBLE : View.GONE);
            });
    }
}
