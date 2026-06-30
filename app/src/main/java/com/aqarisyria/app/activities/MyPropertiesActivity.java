package com.aqarisyria.app.activities;

import android.os.Bundle;
import android.view.View;
import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.firestore.FirebaseFirestore;
import com.aqarisyria.app.adapters.PropertyAdapter;
import com.aqarisyria.app.databinding.ActivityMyPropertiesBinding;
import com.aqarisyria.app.models.Property;
import java.util.ArrayList;
import java.util.List;

public class MyPropertiesActivity extends AppCompatActivity {

    private ActivityMyPropertiesBinding binding;
    private FirebaseFirestore db;
    private FirebaseAuth mAuth;
    private PropertyAdapter adapter;
    private List<Property> propertyList = new ArrayList<>();

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        binding = ActivityMyPropertiesBinding.inflate(getLayoutInflater());
        setContentView(binding.getRoot());

        db = FirebaseFirestore.getInstance();
        mAuth = FirebaseAuth.getInstance();

        binding.btnBack.setOnClickListener(v -> finish());

        adapter = new PropertyAdapter(propertyList, this);
        binding.rvMyProperties.setLayoutManager(new LinearLayoutManager(this));
        binding.rvMyProperties.setAdapter(adapter);

        loadMyProperties();
    }

    private void loadMyProperties() {
        if (mAuth.getCurrentUser() == null) return;
        String uid = mAuth.getCurrentUser().getUid();

        binding.progressBar.setVisibility(View.VISIBLE);
        db.collection("properties")
            .whereEqualTo("ownerId", uid)
            .orderBy("createdAt", com.google.firebase.firestore.Query.Direction.DESCENDING)
            .get()
            .addOnSuccessListener(snapshot -> {
                binding.progressBar.setVisibility(View.GONE);
                propertyList.clear();
                for (var doc : snapshot.getDocuments()) {
                    Property p = doc.toObject(Property.class);
                    if (p != null) {
                        p.setId(doc.getId());
                        propertyList.add(p);
                    }
                }
                adapter.notifyDataSetChanged();
                binding.tvEmpty.setVisibility(propertyList.isEmpty() ? View.VISIBLE : View.GONE);
            })
            .addOnFailureListener(e -> {
                binding.progressBar.setVisibility(View.GONE);
                binding.tvEmpty.setVisibility(View.VISIBLE);
            });
    }
}
