package com.aqarisyria.app.fragments;

import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatDelegate;
import androidx.fragment.app.Fragment;

import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.firestore.FirebaseFirestore;
import com.aqarisyria.app.R;
import com.aqarisyria.app.activities.AddPropertyActivity;
import com.aqarisyria.app.activities.AdminActivity;
import com.aqarisyria.app.activities.LoginActivity;
import com.aqarisyria.app.databinding.FragmentProfileBinding;
import com.aqarisyria.app.utils.AdminUtil;

public class ProfileFragment extends Fragment {

    private FragmentProfileBinding binding;
    private FirebaseAuth mAuth;
    private FirebaseFirestore db;

    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        binding = FragmentProfileBinding.inflate(inflater, container, false);
        mAuth = FirebaseAuth.getInstance();
        db = FirebaseFirestore.getInstance();

        if (mAuth.getCurrentUser() == null) {
            binding.layoutLoggedOut.setVisibility(View.VISIBLE);
            binding.layoutLoggedIn.setVisibility(View.GONE);
            binding.btnLogin.setOnClickListener(v ->
                startActivity(new Intent(getActivity(), LoginActivity.class)));
            return binding.getRoot();
        }

        loadUserData();
        setupButtons();
        setupDarkMode();
        return binding.getRoot();
    }

    private void loadUserData() {
        String uid = mAuth.getCurrentUser().getUid();
        db.collection("users").document(uid).get()
            .addOnSuccessListener(doc -> {
                if (doc.exists()) {
                    binding.tvUserName.setText(doc.getString("fullName"));
                    binding.tvUserEmail.setText(doc.getString("email"));
                    binding.tvUserPhone.setText(doc.getString("phone"));
                }
            });

        db.collection("properties")
            .whereEqualTo("ownerId", uid)
            .whereEqualTo("active", true)
            .get()
            .addOnSuccessListener(snap ->
                binding.tvMyAdsCount.setText(String.valueOf(snap.size())));
    }

    private void setupButtons() {
        binding.btnAddProperty.setOnClickListener(v ->
            startActivity(new Intent(getActivity(), AddPropertyActivity.class)));

        binding.btnLogout.setOnClickListener(v -> {
            mAuth.signOut();
            startActivity(new Intent(getActivity(), LoginActivity.class));
            if (getActivity() != null) getActivity().finish();
        });

        binding.btnChangePassword.setOnClickListener(v -> changePassword());

        AdminUtil.isAdmin(isAdmin -> {
            if (isAdmin) {
                binding.cardAdminPanel.setVisibility(View.VISIBLE);
                binding.btnAdminPanel.setOnClickListener(v ->
                    startActivity(new Intent(getActivity(), AdminActivity.class)));
            }
        });
    }

    private void setupDarkMode() {
        SharedPreferences prefs = getActivity().getSharedPreferences("settings", 0);
        boolean isDark = prefs.getBoolean("dark_mode", false);
        binding.switchDarkMode.setChecked(isDark);

        binding.switchDarkMode.setOnCheckedChangeListener((button, isChecked) -> {
            prefs.edit().putBoolean("dark_mode", isChecked).apply();
            if (isChecked) {
                AppCompatDelegate.setDefaultNightMode(AppCompatDelegate.MODE_NIGHT_YES);
            } else {
                AppCompatDelegate.setDefaultNightMode(AppCompatDelegate.MODE_NIGHT_NO);
            }
            if (getActivity() != null) getActivity().recreate();
        });
    }

    private void changePassword() {
        String email = mAuth.getCurrentUser().getEmail();
        if (email == null) {
            Toast.makeText(getActivity(), "لا يوجد بريد إلكتروني مرتبط", Toast.LENGTH_SHORT).show();
            return;
        }
        FirebaseAuth.getInstance().sendPasswordResetEmail(email)
            .addOnSuccessListener(v ->
                Toast.makeText(getActivity(), "تم إرسال رابط إعادة تعيين كلمة المرور إلى " + email, Toast.LENGTH_LONG).show())
            .addOnFailureListener(e ->
                Toast.makeText(getActivity(), "فشل: " + e.getMessage(), Toast.LENGTH_SHORT).show());
    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();
        binding = null;
    }
}
