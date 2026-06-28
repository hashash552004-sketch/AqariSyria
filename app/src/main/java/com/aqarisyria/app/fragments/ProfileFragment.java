package com.aqarisyria.app.fragments;

import android.content.Intent;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import androidx.annotation.NonNull;
import androidx.fragment.app.Fragment;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.firestore.FirebaseFirestore;
import com.aqarisyria.app.activities.AddPropertyActivity;
import com.aqarisyria.app.activities.LoginActivity;
import com.aqarisyria.app.databinding.FragmentProfileBinding;

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

        // Load my properties count
        db.collection("properties")
            .whereEqualTo("ownerId", uid)
            .whereEqualTo("active", true)
            .get()
            .addOnSuccessListener(snap ->
                binding.tvMyAdsCount.setText(snap.size() + " إعلان"));
    }

    private void setupButtons() {
        binding.btnAddProperty.setOnClickListener(v ->
            startActivity(new Intent(getActivity(), AddPropertyActivity.class)));

        binding.btnLogout.setOnClickListener(v -> {
            mAuth.signOut();
            startActivity(new Intent(getActivity(), LoginActivity.class));
            getActivity().finish();
        });
    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();
        binding = null;
    }
}
