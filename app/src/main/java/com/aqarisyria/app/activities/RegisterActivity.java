package com.aqarisyria.app.activities;

import android.app.AlertDialog;
import android.content.Intent;
import android.os.Bundle;
import android.text.TextUtils;
import android.view.View;
import androidx.appcompat.app.AppCompatActivity;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.firestore.FirebaseFirestore;
import com.aqarisyria.app.databinding.ActivityRegisterBinding;
import com.aqarisyria.app.models.User;

public class RegisterActivity extends AppCompatActivity {

    private ActivityRegisterBinding binding;
    private FirebaseAuth mAuth;
    private FirebaseFirestore db;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        binding = ActivityRegisterBinding.inflate(getLayoutInflater());
        setContentView(binding.getRoot());

        mAuth = FirebaseAuth.getInstance();
        db = FirebaseFirestore.getInstance();

        binding.btnRegister.setOnClickListener(v -> registerUser());
        binding.btnBack.setOnClickListener(v -> finish());
    }

    private void registerUser() {
        String name = binding.etFullName.getText().toString().trim();
        String email = binding.etEmail.getText().toString().trim();
        String phone = binding.etPhone.getText().toString().trim();
        String password = binding.etPassword.getText().toString().trim();
        String confirmPassword = binding.etConfirmPassword.getText().toString().trim();

        if (TextUtils.isEmpty(name)) { binding.tilFullName.setError("أدخل اسمك الكامل"); return; }
        if (TextUtils.isEmpty(email)) { binding.tilEmail.setError("أدخل البريد الإلكتروني"); return; }
        if (TextUtils.isEmpty(phone)) { binding.tilPhone.setError("أدخل رقم الهاتف"); return; }
        if (TextUtils.isEmpty(password)) { binding.tilPassword.setError("أدخل كلمة المرور"); return; }
        if (password.length() < 6) { binding.tilPassword.setError("كلمة المرور يجب أن تكون 6 أحرف على الأقل"); return; }
        if (!password.equals(confirmPassword)) { binding.tilConfirmPassword.setError("كلمات المرور غير متطابقة"); return; }

        binding.btnRegister.setEnabled(false);
        binding.progressBar.setVisibility(View.VISIBLE);

        mAuth.createUserWithEmailAndPassword(email, password)
            .addOnSuccessListener(authResult -> {
                String uid = authResult.getUser().getUid();
                User user = new User(uid, name, email, phone);
                db.collection("users").document(uid).set(user)
                    .addOnSuccessListener(unused -> {
                        startActivity(new Intent(this, MainActivity.class));
                        finish();
                    })
                    .addOnFailureListener(e -> {
                        if (isFinishing() || isDestroyed()) return;
                        binding.btnRegister.setEnabled(true);
                        binding.progressBar.setVisibility(View.GONE);
                        showDialog("حدث خطأ في حفظ البيانات");
                    });
            })
            .addOnFailureListener(e -> {
                if (isFinishing() || isDestroyed()) return;
                binding.btnRegister.setEnabled(true);
                binding.progressBar.setVisibility(View.GONE);
                showDialog("حدث خطأ: " + e.getMessage());
            });
    }

    private void showDialog(String message) {
        if (isFinishing() || isDestroyed()) return;
        new AlertDialog.Builder(this)
            .setMessage(message)
            .setPositiveButton("حسناً", null)
            .show();
    }
}
