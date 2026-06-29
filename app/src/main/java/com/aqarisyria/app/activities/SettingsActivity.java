package com.aqarisyria.app.activities;

import android.content.Intent;
import android.content.SharedPreferences;
import android.content.res.Configuration;
import android.net.Uri;
import android.os.Bundle;
import android.text.TextUtils;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.Toast;

import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.app.AppCompatDelegate;

import com.aqarisyria.app.R;
import com.aqarisyria.app.databinding.ActivitySettingsBinding;
import com.aqarisyria.app.utils.DialogUtil;
import com.bumptech.glide.Glide;
import com.google.android.material.dialog.MaterialAlertDialogBuilder;
import com.google.firebase.auth.AuthCredential;
import com.google.firebase.auth.EmailAuthProvider;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseUser;
import com.google.firebase.firestore.FirebaseFirestore;
import com.google.firebase.storage.FirebaseStorage;
import com.google.firebase.storage.StorageReference;

import java.util.Locale;
import java.util.UUID;

public class SettingsActivity extends AppCompatActivity {

    private ActivitySettingsBinding binding;
    private FirebaseAuth mAuth;
    private FirebaseFirestore db;
    private FirebaseStorage storage;
    private SharedPreferences prefs;
    private ActivityResultLauncher<String> imagePickerLauncher;
    private Uri selectedImageUri;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        binding = ActivitySettingsBinding.inflate(getLayoutInflater());
        setContentView(binding.getRoot());

        mAuth = FirebaseAuth.getInstance();
        db = FirebaseFirestore.getInstance();
        storage = FirebaseStorage.getInstance();
        prefs = getSharedPreferences("settings", 0);

        imagePickerLauncher = registerForActivityResult(
            new ActivityResultContracts.GetContent(),
            uri -> {
                if (uri != null) {
                    selectedImageUri = uri;
                    Glide.with(this).load(uri).into(binding.civAvatar);
                    uploadProfileImage(uri);
                }
            }
        );

        setupToolbar();
        loadUserData();
        setupClickListeners();
        setupDarkMode();
        setupNotificationSwitch();
        setupVersionInfo();
    }

    private void setupToolbar() {
        setSupportActionBar(binding.toolbar);
        if (getSupportActionBar() != null) {
            getSupportActionBar().setDisplayHomeAsUpEnabled(true);
            getSupportActionBar().setDisplayShowHomeEnabled(true);
        }
        binding.toolbar.setNavigationOnClickListener(v -> finish());
    }

    private void loadUserData() {
        FirebaseUser firebaseUser = mAuth.getCurrentUser();
        if (firebaseUser == null) {
            finish();
            return;
        }

        binding.progressBar.setVisibility(View.VISIBLE);

        String uid = firebaseUser.getUid();
        db.collection("users").document(uid).get()
            .addOnSuccessListener(doc -> {
                binding.progressBar.setVisibility(View.GONE);
                if (doc.exists()) {
                    String name = doc.getString("fullName");
                    String email = doc.getString("email");
                    String phone = doc.getString("phone");
                    String imgUrl = doc.getString("profileImage");

                    if (name != null) binding.etName.setText(name);
                    if (email != null) binding.etEmail.setText(email);
                    if (phone != null) binding.etPhone.setText(phone);

                    if (imgUrl != null && !imgUrl.isEmpty()) {
                        Glide.with(this).load(imgUrl).into(binding.civAvatar);
                    }
                }
            })
            .addOnFailureListener(e -> {
                binding.progressBar.setVisibility(View.GONE);
                DialogUtil.showError(this, R.string.loading_error);
            });
    }

    private void setupClickListeners() {
        binding.btnChangeImage.setOnClickListener(v -> showImagePickerDialog());
        binding.civAvatar.setOnClickListener(v -> showImagePickerDialog());

        binding.btnSave.setOnClickListener(v -> saveProfile());

        binding.rowLanguage.setOnClickListener(v -> showLanguageDialog());

        binding.rowAbout.setOnClickListener(v -> showAboutDialog());

        binding.rowPrivacy.setOnClickListener(v -> {
            try {
                startActivity(new Intent(Intent.ACTION_VIEW,
                    Uri.parse("https://aqarisyria.com/privacy")));
            } catch (Exception e) {
                DialogUtil.showError(this, R.string.error_general);
            }
        });

        binding.rowTerms.setOnClickListener(v -> {
            try {
                startActivity(new Intent(Intent.ACTION_VIEW,
                    Uri.parse("https://aqarisyria.com/terms")));
            } catch (Exception e) {
                DialogUtil.showError(this, R.string.error_general);
            }
        });

        binding.rowDeleteAccount.setOnClickListener(v -> showDeleteAccountDialog());
    }

    private void showImagePickerDialog() {
        String[] options = {getString(R.string.profile_camera), getString(R.string.profile_gallery)};
        new MaterialAlertDialogBuilder(this)
            .setTitle(R.string.profile_change_photo)
            .setItems(options, (dialog, which) -> {
                if (which == 0) {
                    Toast.makeText(this, R.string.profile_camera, Toast.LENGTH_SHORT).show();
                } else {
                    imagePickerLauncher.launch("image/*");
                }
            })
            .show();
    }

    private void uploadProfileImage(Uri imageUri) {
        binding.progressBar.setVisibility(View.VISIBLE);
        String uid = mAuth.getCurrentUser().getUid();
        String fileName = "profile_" + UUID.randomUUID() + ".jpg";
        StorageReference ref = storage.getReference().child("profiles").child(uid).child(fileName);

        ref.putFile(imageUri)
            .continueWithTask(task -> ref.getDownloadUrl())
            .addOnSuccessListener(downloadUri -> {
                String url = downloadUri.toString();
                db.collection("users").document(uid)
                    .update("profileImage", url)
                    .addOnSuccessListener(unused -> {
                        binding.progressBar.setVisibility(View.GONE);
                        DialogUtil.showSuccess(this, R.string.changes_saved);
                    })
                    .addOnFailureListener(e -> {
                        binding.progressBar.setVisibility(View.GONE);
                        DialogUtil.showErrorWithDetails(this,
                            getString(R.string.error_image_upload), e.getLocalizedMessage());
                    });
            })
            .addOnFailureListener(e -> {
                binding.progressBar.setVisibility(View.GONE);
                DialogUtil.showErrorWithDetails(this,
                    getString(R.string.error_image_upload), e.getLocalizedMessage());
            });
    }

    private void saveProfile() {
        String name = binding.etName.getText().toString().trim();
        String phone = binding.etPhone.getText().toString().trim();

        if (TextUtils.isEmpty(name)) {
            binding.tilName.setError(getString(R.string.error_enter_name));
            binding.tilName.requestFocus();
            return;
        }
        if (TextUtils.isEmpty(phone)) {
            binding.tilPhone.setError(getString(R.string.error_enter_phone));
            binding.tilPhone.requestFocus();
            return;
        }

        binding.btnSave.setEnabled(false);
        binding.progressBar.setVisibility(View.VISIBLE);

        String uid = mAuth.getCurrentUser().getUid();
        db.collection("users").document(uid)
            .update("fullName", name, "phone", phone)
            .addOnSuccessListener(unused -> {
                binding.btnSave.setEnabled(true);
                binding.progressBar.setVisibility(View.GONE);
                DialogUtil.showSuccess(this, R.string.changes_saved);
            })
            .addOnFailureListener(e -> {
                binding.btnSave.setEnabled(true);
                binding.progressBar.setVisibility(View.GONE);
                DialogUtil.showError(this, R.string.error_save_data);
            });
    }

    private void showLanguageDialog() {
        String[] languages = {getString(R.string.language_arabic), getString(R.string.language_english)};
        int currentLang = prefs.getString("language", "ar").equals("ar") ? 0 : 1;

        new MaterialAlertDialogBuilder(this)
            .setTitle(R.string.profile_choose_language)
            .setSingleChoiceItems(languages, currentLang, (dialog, which) -> {
                String langCode = (which == 0) ? "ar" : "en";
                saveLocale(langCode);
                dialog.dismiss();
                recreate();
            })
            .show();
    }

    private void saveLocale(String langCode) {
        prefs.edit().putString("language", langCode).apply();
        Locale locale = new Locale(langCode);
        Locale.setDefault(locale);
        Configuration config = new Configuration();
        config.setLocale(locale);
        getResources().updateConfiguration(config, getResources().getDisplayMetrics());
        String displayName = langCode.equals("ar") ? getString(R.string.language_arabic) : getString(R.string.language_english);
        binding.tvCurrentLanguage.setText(displayName);
    }

    private void setupDarkMode() {
        boolean isDark = prefs.getBoolean("dark_mode", false);
        binding.switchDarkMode.setChecked(isDark);

        binding.switchDarkMode.setOnCheckedChangeListener((button, isChecked) -> {
            prefs.edit().putBoolean("dark_mode", isChecked).apply();
            AppCompatDelegate.setDefaultNightMode(
                isChecked ? AppCompatDelegate.MODE_NIGHT_YES : AppCompatDelegate.MODE_NIGHT_NO
            );
        });
    }

    private void setupNotificationSwitch() {
        boolean enabled = prefs.getBoolean("notifications_enabled", true);
        binding.switchNotifications.setChecked(enabled);

        binding.switchNotifications.setOnCheckedChangeListener((button, isChecked) -> {
            prefs.edit().putBoolean("notifications_enabled", isChecked).apply();
        });
    }

    private void setupVersionInfo() {
        try {
            String version = getPackageManager()
                .getPackageInfo(getPackageName(), 0).versionName;
            binding.tvVersion.setText(version);
        } catch (Exception e) {
            binding.tvVersion.setVisibility(View.GONE);
        }
    }

    private void showAboutDialog() {
        String version;
        try {
            version = getPackageManager().getPackageInfo(getPackageName(), 0).versionName;
        } catch (Exception e) {
            version = "1.0";
        }

        new MaterialAlertDialogBuilder(this)
            .setTitle(getString(R.string.app_name))
            .setMessage(getString(R.string.app_description) + "\n\n" +
                getString(R.string.profile_version, version))
            .setPositiveButton(R.string.ok, null)
            .show();
    }

    private void showDeleteAccountDialog() {
        FirebaseUser firebaseUser = mAuth.getCurrentUser();
        if (firebaseUser == null) return;

        View view = LayoutInflater.from(this).inflate(R.layout.dialog_delete_account, null);
        com.google.android.material.textfield.TextInputEditText etPassword =
            view.findViewById(R.id.etPassword);

        new MaterialAlertDialogBuilder(this)
            .setTitle(R.string.confirm_delete_account)
            .setView(view)
            .setPositiveButton(R.string.confirm, (dialog, which) -> {
                String password = etPassword.getText() != null ?
                    etPassword.getText().toString().trim() : "";
                if (password.isEmpty()) {
                    DialogUtil.showWarning(this, getString(R.string.error_enter_password));
                    return;
                }
                reAuthAndDelete(firebaseUser, password);
            })
            .setNegativeButton(R.string.cancel, null)
            .show();
    }

    private void reAuthAndDelete(FirebaseUser firebaseUser, String password) {
        binding.progressBar.setVisibility(View.VISIBLE);

        AuthCredential credential = EmailAuthProvider.getCredential(firebaseUser.getEmail(), password);
        firebaseUser.reauthenticate(credential)
            .addOnSuccessListener(unused -> deleteAccount(firebaseUser))
            .addOnFailureListener(e -> {
                binding.progressBar.setVisibility(View.GONE);
                DialogUtil.showError(this, R.string.error_email_or_password);
            });
    }

    private void deleteAccount(FirebaseUser firebaseUser) {
        String uid = firebaseUser.getUid();

        db.collection("users").document(uid).delete()
            .addOnSuccessListener(unused -> {
                firebaseUser.delete()
                    .addOnSuccessListener(unused2 -> {
                        binding.progressBar.setVisibility(View.GONE);
                        DialogUtil.showSuccess(this, R.string.account_deleted);
                        mAuth.signOut();
                        Intent intent = new Intent(this, LoginActivity.class);
                        intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TASK | Intent.FLAG_ACTIVITY_NEW_TASK);
                        startActivity(intent);
                        finish();
                    })
                    .addOnFailureListener(e -> {
                        binding.progressBar.setVisibility(View.GONE);
                        DialogUtil.showError(this, R.string.error_delete_account);
                    });
            })
            .addOnFailureListener(e -> {
                binding.progressBar.setVisibility(View.GONE);
                DialogUtil.showError(this, R.string.error_delete_account);
            });
    }
}
