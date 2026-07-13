package com.aqarisyria.app.activities;

import android.os.Bundle;
import android.view.View;
import android.widget.Toast;

import androidx.appcompat.app.AlertDialog;
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
        binding.btnBanUser.setOnClickListener(v -> banUser());
        binding.btnUnbanUser.setOnClickListener(v -> unbanUser());
        binding.btnDeleteProperties.setOnClickListener(v -> deleteUserProperties());

        loadStats();
        loadAdmins();
    }

    private void loadStats() {
        binding.progressBar.setVisibility(View.VISIBLE);

        db.collection("properties").get()
            .addOnSuccessListener(snap -> {
                int total = snap.size();
                int sell = 0, rent = 0, invest = 0, inactive = 0;
                long totalViews = 0;
                for (var doc : snap.getDocuments()) {
                    String op = doc.getString("operationType");
                    Boolean active = doc.getBoolean("active");
                    if (active == null || !active) {
                        inactive++;
                    } else if ("sell".equals(op)) sell++;
                    else if ("rent".equals(op)) rent++;
                    else if ("invest".equals(op)) invest++;

                    Object views = doc.get("viewsCount");
                    if (views instanceof Number) totalViews += ((Number) views).longValue();
                }
                binding.tvTotalProperties.setText(String.valueOf(total));
                binding.tvSellCount.setText(String.valueOf(sell));
                binding.tvRentCount.setText(String.valueOf(rent));
                binding.tvInvestCount.setText(String.valueOf(invest));
                binding.tvInactiveCount.setText(String.valueOf(inactive));
                binding.tvTotalViews.setText(String.valueOf(totalViews));
            });

        db.collection("users").get()
            .addOnSuccessListener(snap ->
                binding.tvTotalUsers.setText(String.valueOf(snap.size())));
    }

    private void loadAdmins() {
        db.collection("admins").get()
            .addOnSuccessListener(snap -> {
                adminEmails.clear();
                StringBuilder sb = new StringBuilder(getString(R.string.current_admins));
                for (var doc : snap.getDocuments()) {
                    String email = doc.getId();
                    adminEmails.add(email);
                    sb.append("• ").append(email).append("\n");
                }
                if (adminEmails.isEmpty()) {
                    sb.append(getString(R.string.no_extra_admins));
                }
                binding.tvAdminList.setText(sb.toString());
                binding.progressBar.setVisibility(View.GONE);
            });
    }

    private void addAdmin() {
        String email = binding.etAdminEmail.getText().toString().trim();
        if (email.isEmpty()) {
            binding.etAdminEmail.setError(getString(R.string.enter_email));
            return;
        }
        binding.btnAddAdmin.setEnabled(false);

        if (adminEmails.contains(email)) {
            Toast.makeText(this, getString(R.string.already_admin), Toast.LENGTH_SHORT).show();
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
                Toast.makeText(this, getString(R.string.admin_added, email), Toast.LENGTH_SHORT).show();
                binding.etAdminEmail.setText("");
                binding.btnAddAdmin.setEnabled(true);
                loadAdmins();
            })
            .addOnFailureListener(e -> {
                Toast.makeText(this, "فشل: " + e.getMessage(), Toast.LENGTH_SHORT).show();
                binding.btnAddAdmin.setEnabled(true);
            });
    }

    private void banUser() {
        String input = binding.etBanUser.getText().toString().trim();
        if (input.isEmpty()) {
            binding.etBanUser.setError(getString(R.string.enter_email));
            return;
        }
        findUserAndUpdate(input, true);
    }

    private void unbanUser() {
        String input = binding.etBanUser.getText().toString().trim();
        if (input.isEmpty()) {
            binding.etBanUser.setError(getString(R.string.enter_email));
            return;
        }
        findUserAndUpdate(input, false);
    }

    private void deleteUserProperties() {
        String email = binding.etDeletePropertyOwner.getText().toString().trim();
        if (email.isEmpty()) {
            binding.etDeletePropertyOwner.setError(getString(R.string.enter_email));
            return;
        }
        new AlertDialog.Builder(this)
            .setTitle(getString(R.string.delete_user_properties_title))
            .setMessage(getString(R.string.delete_user_properties_message, email))
            .setPositiveButton(getString(R.string.delete_all), (dialog, which) -> {
                db.collection("users")
                    .whereEqualTo("email", email)
                    .get()
                    .addOnSuccessListener(userSnap -> {
                                if (userSnap.isEmpty()) {
                                    Toast.makeText(this, getString(R.string.user_not_found), Toast.LENGTH_SHORT).show();
                                    return;
                                }
                                String uid = userSnap.getDocuments().get(0).getId();

                                if (uid == null) {
                                    Toast.makeText(this, getString(R.string.uid_error), Toast.LENGTH_SHORT).show();
                                    return;
                                }
                        db.collection("properties")
                            .whereEqualTo("ownerId", uid)
                            .get()
                            .addOnSuccessListener(snap -> {
                                if (snap == null || snap.isEmpty()) {
                                    Toast.makeText(this, getString(R.string.no_properties_found), Toast.LENGTH_SHORT).show();
                                    return;
                                }
                                com.google.firebase.firestore.WriteBatch batch = db.batch();
                                for (var doc : snap.getDocuments()) {
                                    batch.delete(doc.getReference());
                                }
                                batch.commit()
                                    .addOnSuccessListener(v -> {
                                        Toast.makeText(this, getString(R.string.deleted_count_properties, snap.size()), Toast.LENGTH_SHORT).show();
                                        binding.etDeletePropertyOwner.setText("");
                                        loadStats();
                                    })
            .addOnFailureListener(e ->
                Toast.makeText(this, getString(R.string.failed, e.getMessage()), Toast.LENGTH_SHORT).show());
                            })
                            .addOnFailureListener(e ->
                                Toast.makeText(this, getString(R.string.error_general) + ": " + e.getMessage(), Toast.LENGTH_SHORT).show());
                    })
                    .addOnFailureListener(e ->
                        Toast.makeText(this, getString(R.string.error_general) + ": " + e.getMessage(), Toast.LENGTH_SHORT).show());
            })
            .setNegativeButton(getString(R.string.cancel), null)
            .show();
    }

    private void findUserAndUpdate(String input, boolean ban) {
        String action = ban ? getString(R.string.ban) : getString(R.string.unban);
        db.collection("users")
            .whereEqualTo("email", input)
            .get()
            .addOnSuccessListener(snap -> {
                if (snap.isEmpty()) {
                    Toast.makeText(this, getString(R.string.user_not_found_email), Toast.LENGTH_SHORT).show();
                    return;
                }
                String uid = snap.getDocuments().get(0).getId();
                db.collection("users").document(uid)
                    .update("banned", ban)
                    .addOnSuccessListener(v -> {
                        Toast.makeText(this, getString(R.string.action_success, action), Toast.LENGTH_SHORT).show();
                        binding.etBanUser.setText("");
                    })
                    .addOnFailureListener(e ->
                        Toast.makeText(this, getString(R.string.failed, e.getMessage()), Toast.LENGTH_SHORT).show());
            })
            .addOnFailureListener(e ->
                Toast.makeText(this, getString(R.string.error_general) + ": " + e.getMessage(), Toast.LENGTH_SHORT).show());
    }
}
