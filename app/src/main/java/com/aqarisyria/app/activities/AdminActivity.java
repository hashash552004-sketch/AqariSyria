package com.aqarisyria.app.activities;

import android.os.Bundle;
import android.view.View;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;

import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.firestore.FirebaseFirestore;
import com.aqarisyria.app.R;
import com.aqarisyria.app.databinding.ActivityAdminBinding;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

public class AdminActivity extends AppCompatActivity {

    private ActivityAdminBinding binding;
    private FirebaseFirestore db;
    private final List<String> adminEmails = new ArrayList<>();

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        binding = ActivityAdminBinding.inflate(getLayoutInflater());
        setContentView(binding.getRoot());

        db = FirebaseFirestore.getInstance();

        binding.btnBack.setOnClickListener(v -> finish());
        binding.btnAddAdmin.setOnClickListener(v -> addAdmin());

        loadStats();
        loadAdmins();
    }

    private void loadStats() {
        binding.progressBar.setVisibility(View.VISIBLE);

        db.collection("properties").get()
            .addOnSuccessListener(snap -> {
                int total = snap.size();
                int sell = 0, rent = 0, invest = 0, inactive = 0;
                for (var doc : snap.getDocuments()) {
                    String op = doc.getString("operationType");
                    Boolean active = doc.getBoolean("active");
                    if (active == null || !active) {
                        inactive++;
                    } else if ("sell".equals(op)) sell++;
                    else if ("rent".equals(op)) rent++;
                    else if ("invest".equals(op)) invest++;
                }
                binding.tvTotalProperties.setText(String.valueOf(total));
                binding.tvSellCount.setText(String.valueOf(sell));
                binding.tvRentCount.setText(String.valueOf(rent));
                binding.tvInvestCount.setText(String.valueOf(invest));
                binding.tvInactiveCount.setText(String.valueOf(inactive));
            });

        db.collection("users").get()
            .addOnSuccessListener(snap ->
                binding.tvTotalUsers.setText(String.valueOf(snap.size())));
    }

    private void loadAdmins() {
        db.collection("admins").get()
            .addOnSuccessListener(snap -> {
                adminEmails.clear();
                StringBuilder sb = new StringBuilder("المشرفون الحاليون:\n");
                for (var doc : snap.getDocuments()) {
                    String email = doc.getId();
                    adminEmails.add(email);
                    sb.append("• ").append(email).append("\n");
                }
                if (adminEmails.isEmpty()) {
                    sb.append("لا يوجد مشرفون إضافيون");
                }
                binding.tvAdminList.setText(sb.toString());
                binding.progressBar.setVisibility(View.GONE);
            });
    }

    private void addAdmin() {
        String email = binding.etAdminEmail.getText().toString().trim();
        if (email.isEmpty()) {
            binding.etAdminEmail.setError("أدخل البريد الإلكتروني");
            return;
        }
        binding.btnAddAdmin.setEnabled(false);

        if (adminEmails.contains(email)) {
            Toast.makeText(this, "هذا البريد مشرف بالفعل", Toast.LENGTH_SHORT).show();
            binding.btnAddAdmin.setEnabled(true);
            return;
        }

        String addedBy = FirebaseAuth.getInstance().getCurrentUser() != null
            ? FirebaseAuth.getInstance().getCurrentUser().getEmail() : "unknown";
        HashMap<String, Object> data = new HashMap<>();
        data.put("addedBy", addedBy);
        data.put("addedAt", String.valueOf(System.currentTimeMillis()));
        db.collection("admins").document(email).set(data)
            .addOnSuccessListener(v -> {
                Toast.makeText(this, "تم إضافة " + email + " كمشرف", Toast.LENGTH_SHORT).show();
                binding.etAdminEmail.setText("");
                binding.btnAddAdmin.setEnabled(true);
                loadAdmins();
            })
            .addOnFailureListener(e -> {
                Toast.makeText(this, "فشل: " + e.getMessage(), Toast.LENGTH_SHORT).show();
                binding.btnAddAdmin.setEnabled(true);
            });
    }
}
