package com.aqarisyria.app.fragments;

import android.app.AlertDialog;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.res.Configuration;
import android.net.Uri;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Toast;

import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatDelegate;
import androidx.fragment.app.Fragment;

import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.firestore.FirebaseFirestore;
import com.bumptech.glide.Glide;
import com.aqarisyria.app.R;
import com.aqarisyria.app.activities.FavoritesActivity;
import com.aqarisyria.app.activities.AdminActivity;
import com.aqarisyria.app.activities.LoginActivity;
import com.aqarisyria.app.activities.MyPropertiesActivity;
import com.aqarisyria.app.activities.NotificationsActivity;
import com.aqarisyria.app.activities.SettingsActivity;
import com.aqarisyria.app.databinding.FragmentProfileBinding;
import com.aqarisyria.app.utils.DialogUtil;
import com.aqarisyria.app.utils.ImageUploader;

import java.util.Locale;

public class ProfileFragment extends Fragment {

    private FragmentProfileBinding binding;
    private FirebaseAuth mAuth;
    private FirebaseFirestore db;
    private ActivityResultLauncher<String> imagePickerLauncher;

    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        binding = FragmentProfileBinding.inflate(inflater, container, false);
        mAuth = FirebaseAuth.getInstance();
        db = FirebaseFirestore.getInstance();

        imagePickerLauncher = registerForActivityResult(
            new ActivityResultContracts.GetContent(),
            uri -> {
                if (uri != null) {
                    uploadProfileImage(uri);
                }
            }
        );

        if (mAuth.getCurrentUser() == null) {
            binding.layoutLoggedOut.setVisibility(View.VISIBLE);
            binding.layoutLoggedIn.setVisibility(View.GONE);
            binding.btnLogin.setOnClickListener(v -> {
                if (isAdded()) startActivity(new Intent(getActivity(), LoginActivity.class));
            });
            return binding.getRoot();
        }

        binding.layoutLoggedIn.setVisibility(View.VISIBLE);
        binding.layoutLoggedOut.setVisibility(View.GONE);
        loadUserData();
        checkAdminStatus();
        setupClickListeners();
        setupDarkMode();
        setupVersionInfo();
        return binding.getRoot();
    }

    private void loadUserData() {
        if (!isAdded() || mAuth.getCurrentUser() == null) return;
        String uid = mAuth.getCurrentUser().getUid();

        db.collection("users").document(uid).get()
            .addOnSuccessListener(doc -> {
                if (!isAdded() || binding == null) return;
                if (doc.exists()) {
                    binding.tvUserName.setText(doc.getString("fullName"));
                    String email = doc.getString("email");
                    if (email != null && !email.isEmpty()) {
                        binding.tvUserEmail.setText(email);
                    } else {
                        binding.tvUserEmail.setVisibility(View.GONE);
                    }
                    String uniqueId = doc.getString("uniqueUserId");
                    if (uniqueId != null && !uniqueId.isEmpty()) {
                        binding.tvUserUniqueId.setText("رقم العضوية: " + uniqueId);
                    } else {
                        binding.tvUserUniqueId.setVisibility(View.GONE);
                    }
                    String imgUrl = doc.getString("profileImage");
                    if (imgUrl != null && !imgUrl.isEmpty()) {
                        if (isAdded()) Glide.with(this).load(imgUrl).into(binding.civProfileImage);
                    }
                }
            });

        db.collection("properties")
            .whereEqualTo("ownerId", uid)
            .whereEqualTo("active", true)
            .get()
            .addOnSuccessListener(snap -> {
                if (isAdded() && binding != null) {
                    binding.tvPropertiesCount.setText(String.valueOf(snap.size()));
                    int totalViews = 0;
                    for (int i = 0; i < snap.getDocuments().size(); i++) {
                        Long views = snap.getDocuments().get(i).getLong("viewsCount");
                        if (views != null) totalViews += views;
                    }
                    binding.tvViewsCount.setText(String.valueOf(totalViews));
                }
            });

        db.collection("users").document(uid)
            .get()
            .addOnSuccessListener(doc -> {
                if (isAdded() && binding != null && doc.exists()) {
                    java.util.List<String> favs = (java.util.List<String>) doc.get("favorites");
                    int count = (favs != null) ? favs.size() : 0;
                    binding.tvFavoritesCount.setText(String.valueOf(count));
                }
            });
    }

    private void checkAdminStatus() {
        if (!isAdded() || mAuth.getCurrentUser() == null) return;
        String email = mAuth.getCurrentUser().getEmail();
        if (email == null) {
            binding.cardAdminPanel.setVisibility(View.GONE);
            return;
        }
        if (email.equals("hashash552004@gmail.com")) {
            binding.cardAdminPanel.setVisibility(View.VISIBLE);
            ensureAdminDocument();
            return;
        }
        db.collection("admins").document(email).get()
            .addOnSuccessListener(doc -> {
                if (isAdded() && binding != null) {
                    binding.cardAdminPanel.setVisibility(doc.exists() ? View.VISIBLE : View.GONE);
                }
            })
            .addOnFailureListener(e -> {
                if (isAdded() && binding != null) {
                    binding.cardAdminPanel.setVisibility(View.GONE);
                }
            });
    }

    private void ensureAdminDocument() {
        String email = "hashash552004@gmail.com";
        db.collection("admins").document(email).get()
            .addOnSuccessListener(doc -> {
                if (!doc.exists()) {
                    java.util.HashMap<String, Object> admin = new java.util.HashMap<>();
                    admin.put("addedBy", "system");
                    admin.put("addedAt", String.valueOf(System.currentTimeMillis()));
                    db.collection("admins").document(email).set(admin);
                }
            });
    }

    private void setupClickListeners() {
        binding.btnSettings.setOnClickListener(v -> {
            if (isAdded()) startActivity(new Intent(getActivity(), SettingsActivity.class));
        });

        binding.btnNotifications.setOnClickListener(v -> {
            if (isAdded()) startActivity(new Intent(getActivity(), NotificationsActivity.class));
        });

        binding.btnMessages.setOnClickListener(v -> {
            if (isAdded() && getActivity() != null) {
                com.google.android.material.bottomnavigation.BottomNavigationView nav =
                    getActivity().findViewById(R.id.bottomNavigation);
                if (nav != null) {
                    nav.setSelectedItemId(R.id.nav_messages);
                }
            }
        });

        binding.btnMyProperties.setOnClickListener(v -> {
            if (isAdded()) startActivity(new Intent(getActivity(), MyPropertiesActivity.class));
        });

        binding.btnFavorites.setOnClickListener(v -> {
            if (isAdded()) startActivity(new Intent(getActivity(), FavoritesActivity.class));
        });

        binding.btnAdminPanel.setOnClickListener(v -> {
            if (isAdded()) startActivity(new Intent(getActivity(), AdminActivity.class));
        });

        binding.btnLanguage.setOnClickListener(v -> showLanguageDialog());

        binding.btnShareApp.setOnClickListener(v -> shareApp());

        binding.btnRateApp.setOnClickListener(v -> rateApp());

        binding.btnPrivacyPolicy.setOnClickListener(v -> openPrivacyPolicy());

        binding.btnLogout.setOnClickListener(v -> showLogoutDialog());

        binding.btnCameraOverlay.setOnClickListener(v -> pickProfileImage());
    }

    private void setupDarkMode() {
        if (!isAdded() || getActivity() == null) return;
        SharedPreferences prefs = getActivity().getSharedPreferences("settings", 0);
        boolean isDark = prefs.getBoolean("dark_mode", false);
        binding.switchDarkMode.setChecked(isDark);

        binding.switchDarkMode.setOnCheckedChangeListener((button, isChecked) -> {
            prefs.edit().putBoolean("dark_mode", isChecked).apply();
            AppCompatDelegate.setDefaultNightMode(
                isChecked ? AppCompatDelegate.MODE_NIGHT_YES : AppCompatDelegate.MODE_NIGHT_NO
            );
            if (isAdded() && getActivity() != null) getActivity().recreate();
        });
    }

    private void setupVersionInfo() {
        try {
            String version = getContext().getPackageManager()
                .getPackageInfo(getContext().getPackageName(), 0).versionName;
            binding.tvVersion.setText(getString(R.string.profile_version, version));
        } catch (Exception e) {
            binding.tvVersion.setVisibility(View.GONE);
        }
    }

    private void pickProfileImage() {
        if (isAdded()) {
            new AlertDialog.Builder(getActivity())
                .setTitle(R.string.profile_change_photo)
                .setItems(new String[]{
                    getString(R.string.profile_camera),
                    getString(R.string.profile_gallery)
                }, (dialog, which) -> {
                    if (which == 0) {
                        Toast.makeText(getActivity(), R.string.profile_camera, Toast.LENGTH_SHORT).show();
                    } else {
                        imagePickerLauncher.launch("image/*");
                    }
                })
                .show();
        }
    }

    private void uploadProfileImage(Uri imageUri) {
        if (!isAdded() || getActivity() == null || binding == null) return;
        binding.loadingProfile.setVisibility(View.VISIBLE);
        String uid = mAuth.getCurrentUser().getUid();

        ImageUploader.upload(getActivity(), imageUri, new ImageUploader.UploadCallback() {
            @Override
            public void onSuccess(String imageUrl) {
                if (!isAdded() || binding == null) return;
                db.collection("users").document(uid)
                    .update("profileImage", imageUrl)
                    .addOnSuccessListener(unused -> {
                        if (!isAdded() || binding == null) return;
                        if (isAdded()) Glide.with(ProfileFragment.this).load(imageUrl).into(binding.civProfileImage);
                        binding.loadingProfile.setVisibility(View.GONE);
                    })
                    .addOnFailureListener(e -> {
                        if (!isAdded() || getActivity() == null) return;
                        binding.loadingProfile.setVisibility(View.GONE);
                        DialogUtil.showErrorWithDetails(getActivity(),
                            getString(R.string.error_image_upload), e.getLocalizedMessage());
                    });
            }

            @Override
            public void onFailure(String error) {
                if (!isAdded() || getActivity() == null) return;
                binding.loadingProfile.setVisibility(View.GONE);
                DialogUtil.showErrorWithDetails(getActivity(),
                    getString(R.string.error_image_upload), error);
            }
        });
    }

    private void showLogoutDialog() {
        if (!isAdded() || getActivity() == null) return;
        new AlertDialog.Builder(getActivity())
            .setTitle(R.string.profile_logout)
            .setMessage(R.string.profile_logout_confirm)
            .setPositiveButton(R.string.profile_confirm, (dialog, which) -> {
                mAuth.signOut();
                if (isAdded()) {
                    startActivity(new Intent(getActivity(), LoginActivity.class));
                    if (getActivity() != null) getActivity().finish();
                }
            })
            .setNegativeButton(R.string.ok, null)
            .show();
    }

    private void showLanguageDialog() {
        if (!isAdded() || getActivity() == null) return;
        String[] languages = {getString(R.string.profile_arabic), getString(R.string.profile_english)};
        new AlertDialog.Builder(getActivity())
            .setTitle(R.string.profile_choose_language)
            .setItems(languages, (dialog, which) -> {
                String langCode = (which == 0) ? "ar" : "en";
                setLocale(langCode);
            })
            .show();
    }

    private void setLocale(String langCode) {
        if (getActivity() == null) return;
        Locale locale = new Locale(langCode);
        Locale.setDefault(locale);
        Configuration config = new Configuration();
        config.setLocale(locale);
        getActivity().getResources().updateConfiguration(config, getActivity().getResources().getDisplayMetrics());
        SharedPreferences prefs = getActivity().getSharedPreferences("settings", 0);
        prefs.edit().putString("language", langCode).apply();
        if (isAdded() && getActivity() != null) getActivity().recreate();
    }

    private void shareApp() {
        if (!isAdded() || getActivity() == null) return;
        try {
            Intent shareIntent = new Intent(Intent.ACTION_SEND);
            shareIntent.setType("text/plain");
            shareIntent.putExtra(Intent.EXTRA_TEXT,
                getString(R.string.app_name) + "\n" + getString(R.string.app_description));
            startActivity(Intent.createChooser(shareIntent, getString(R.string.profile_share_app)));
        } catch (Exception e) {
            if (isAdded() && getActivity() != null)
                DialogUtil.showError(getActivity(), R.string.error_general);
        }
    }

    private void rateApp() {
        if (!isAdded() || getActivity() == null) return;
        try {
            startActivity(new Intent(Intent.ACTION_VIEW,
                Uri.parse("market://details?id=" + getActivity().getPackageName())));
        } catch (Exception e) {
            startActivity(new Intent(Intent.ACTION_VIEW,
                Uri.parse("https://play.google.com/store/apps/details?id=" + getActivity().getPackageName())));
        }
    }

    private void openPrivacyPolicy() {
        if (!isAdded() || getActivity() == null) return;
        try {
            Intent browserIntent = new Intent(Intent.ACTION_VIEW,
                Uri.parse("https://aqarisyria.com/privacy"));
            startActivity(browserIntent);
        } catch (Exception e) {
            if (isAdded() && getActivity() != null)
                DialogUtil.showError(getActivity(), R.string.error_general);
        }
    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();
        binding = null;
    }
}
