package com.aqarisyria.app.fragments;

import android.app.AlertDialog;
import android.content.Intent;
import android.content.SharedPreferences;
import android.net.Uri;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatDelegate;
import androidx.fragment.app.Fragment;

import com.google.firebase.auth.EmailAuthProvider;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseUser;
import com.google.firebase.firestore.FirebaseFirestore;
import com.google.firebase.storage.FirebaseStorage;
import com.google.firebase.storage.StorageReference;
import com.bumptech.glide.Glide;
import com.aqarisyria.app.R;
import com.aqarisyria.app.activities.AddPropertyActivity;
import com.aqarisyria.app.activities.AdminActivity;
import com.aqarisyria.app.activities.LoginActivity;
import com.aqarisyria.app.databinding.FragmentProfileBinding;
import com.aqarisyria.app.utils.AdminUtil;

import java.util.UUID;

public class ProfileFragment extends Fragment {

    private static final int PICK_IMAGE_REQUEST = 200;
    private FragmentProfileBinding binding;
    private FirebaseAuth mAuth;
    private FirebaseFirestore db;
    private FirebaseStorage storage;

    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        binding = FragmentProfileBinding.inflate(inflater, container, false);
        mAuth = FirebaseAuth.getInstance();
        db = FirebaseFirestore.getInstance();
        storage = FirebaseStorage.getInstance();

        if (mAuth.getCurrentUser() == null) {
            binding.layoutLoggedOut.setVisibility(View.VISIBLE);
            binding.layoutLoggedIn.setVisibility(View.GONE);
            binding.btnLogin.setOnClickListener(v -> {
                if (isAdded()) startActivity(new Intent(getActivity(), LoginActivity.class));
            });
            return binding.getRoot();
        }

        loadUserData();
        setupButtons();
        setupDarkMode();
        setupProfileImageClick();
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
                    binding.tvUserEmail.setText(doc.getString("email"));
                    binding.tvUserPhone.setText(doc.getString("phone"));
                    if (binding.tvUserUniqueId != null) {
                        binding.tvUserUniqueId.setText("رقم العضوية: " + (doc.getString("uniqueUserId") != null ? doc.getString("uniqueUserId") : "---"));
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
                if (isAdded() && binding != null)
                    binding.tvMyAdsCount.setText(String.valueOf(snap.size()));
            });
    }

    private void setupButtons() {
        binding.btnAddProperty.setOnClickListener(v -> {
            if (isAdded()) startActivity(new Intent(getActivity(), AddPropertyActivity.class));
        });

        binding.btnLogout.setOnClickListener(v -> {
            mAuth.signOut();
            if (isAdded()) {
                startActivity(new Intent(getActivity(), LoginActivity.class));
                if (getActivity() != null) getActivity().finish();
            }
        });

        binding.btnChangePassword.setOnClickListener(v -> showChangePasswordDialog());

        AdminUtil.isAdmin(isAdmin -> {
            if (!isAdded() || binding == null) return;
            if (isAdmin) {
                binding.cardAdminPanel.setVisibility(View.VISIBLE);
                binding.btnAdminPanel.setOnClickListener(v -> {
                    if (isAdded()) startActivity(new Intent(getActivity(), AdminActivity.class));
                });
            }
        });
    }

    private void setupDarkMode() {
        if (!isAdded() || getActivity() == null) return;
        SharedPreferences prefs = getActivity().getSharedPreferences("settings", 0);
        boolean isDark = prefs.getBoolean("dark_mode", false);
        binding.switchDarkMode.setChecked(isDark);

        binding.switchDarkMode.setOnCheckedChangeListener((button, isChecked) -> {
            prefs.edit().putBoolean("dark_mode", isChecked).apply();
            AppCompatDelegate.setDefaultNightMode(isChecked ? AppCompatDelegate.MODE_NIGHT_YES : AppCompatDelegate.MODE_NIGHT_NO);
            if (isAdded() && getActivity() != null) getActivity().recreate();
        });
    }

    private void setupProfileImageClick() {
        binding.civProfileImage.setOnClickListener(v -> {
            if (isAdded()) pickProfileImage();
        });
    }

    private void pickProfileImage() {
        Intent intent = new Intent(Intent.ACTION_GET_CONTENT);
        intent.setType("image/*");
        startActivityForResult(Intent.createChooser(intent, "اختر صورة"), PICK_IMAGE_REQUEST);
    }

    @Override
    public void onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == PICK_IMAGE_REQUEST && resultCode == getActivity().RESULT_OK && data != null && data.getData() != null) {
            uploadProfileImage(data.getData());
        }
    }

    private void uploadProfileImage(Uri imageUri) {
        if (!isAdded() || binding == null) return;
        binding.loadingProfile.setVisibility(View.VISIBLE);
        String uid = mAuth.getCurrentUser().getUid();
        String fileName = "profile_" + UUID.randomUUID() + ".jpg";
        StorageReference ref = storage.getReference().child("profiles").child(uid).child(fileName);

        ref.putFile(imageUri)
            .continueWithTask(task -> ref.getDownloadUrl())
            .addOnSuccessListener(downloadUri -> {
                if (!isAdded() || binding == null) return;
                String url = downloadUri.toString();
                db.collection("users").document(uid).update("profileImage", url)
                    .addOnSuccessListener(unused -> {
                        if (!isAdded() || binding == null) return;
                        if (isAdded()) Glide.with(this).load(url).into(binding.civProfileImage);
                        binding.loadingProfile.setVisibility(View.GONE);
                        showCenterDialog("تم تحديث الصورة الشخصية");
                    })
                    .addOnFailureListener(e -> {
                        if (!isAdded() || binding == null) return;
                        binding.loadingProfile.setVisibility(View.GONE);
                        showCenterDialog("فشل حفظ الصورة");
                    });
            })
            .addOnFailureListener(e -> {
                if (!isAdded() || binding == null) return;
                binding.loadingProfile.setVisibility(View.GONE);
                showCenterDialog("فشل رفع الصورة");
            });
    }

    private void showChangePasswordDialog() {
        if (!isAdded() || getActivity() == null) return;
        AlertDialog.Builder builder = new AlertDialog.Builder(getActivity());
        View view = getLayoutInflater().inflate(R.layout.dialog_change_password, null);
        builder.setView(view);
        builder.setTitle("تغيير كلمة المرور");
        builder.setCancelable(true);

        TextView etOldPassword = view.findViewById(R.id.etOldPassword);
        TextView etNewPassword = view.findViewById(R.id.etNewPassword);
        TextView etConfirmNewPassword = view.findViewById(R.id.etConfirmNewPassword);

        AlertDialog dialog = builder.create();

        view.findViewById(R.id.btnCancelChange).setOnClickListener(v -> dialog.dismiss());
        view.findViewById(R.id.btnConfirmChange).setOnClickListener(v -> {
            String oldPass = etOldPassword.getText().toString().trim();
            String newPass = etNewPassword.getText().toString().trim();
            String confirmPass = etConfirmNewPassword.getText().toString().trim();

            if (oldPass.isEmpty() || newPass.isEmpty() || confirmPass.isEmpty()) {
                showCenterDialog("يرجى ملء جميع الحقول");
                return;
            }
            if (newPass.length() < 6) {
                showCenterDialog("كلمة المرور الجديدة يجب أن تكون 6 أحرف على الأقل");
                return;
            }
            if (!newPass.equals(confirmPass)) {
                showCenterDialog("كلمات المرور غير متطابقة");
                return;
            }

            FirebaseUser user = mAuth.getCurrentUser();
            if (user != null && user.getEmail() != null) {
                user.reauthenticate(EmailAuthProvider.getCredential(user.getEmail(), oldPass))
                    .addOnSuccessListener(unused -> user.updatePassword(newPass)
                        .addOnSuccessListener(v2 -> {
                            if (!isAdded()) return;
                            showCenterDialog("تم تغيير كلمة المرور بنجاح");
                            dialog.dismiss();
                        })
                        .addOnFailureListener(e -> {
                            if (!isAdded()) return;
                            showCenterDialog("فشل تغيير كلمة المرور");
                        }))
                    .addOnFailureListener(e -> {
                        if (!isAdded()) return;
                        showCenterDialog("كلمة المرور القديمة غير صحيحة");
                    });
            }
        });

        dialog.show();
    }

    private void showCenterDialog(String message) {
        if (!isAdded() || getActivity() == null) return;
        AlertDialog.Builder builder = new AlertDialog.Builder(getActivity());
        builder.setMessage(message)
            .setPositiveButton("حسناً", null)
            .show();
    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();
        binding = null;
    }
}
