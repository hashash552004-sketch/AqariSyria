package com.aqarisyria.app.activities;

import android.app.AlertDialog;
import android.content.Intent;
import android.os.Bundle;
import android.text.TextUtils;
import android.view.View;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;
import com.google.firebase.auth.FirebaseAuth;
import com.aqarisyria.app.R;
import com.aqarisyria.app.databinding.ActivityLoginBinding;

public class LoginActivity extends AppCompatActivity {

    private ActivityLoginBinding binding;
    private FirebaseAuth mAuth;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        binding = ActivityLoginBinding.inflate(getLayoutInflater());
        setContentView(binding.getRoot());

        mAuth = FirebaseAuth.getInstance();

        binding.btnLogin.setOnClickListener(v -> loginUser());

        binding.btnRegister.setOnClickListener(v ->
            startActivity(new Intent(this, RegisterActivity.class)));

        binding.btnGuest.setOnClickListener(v -> {
            startActivity(new Intent(this, MainActivity.class));
            finish();
        });

        binding.tvForgotPassword.setOnClickListener(v -> showForgotPassword());
    }

    private void loginUser() {
        String email = binding.etEmail.getText().toString().trim();
        String password = binding.etPassword.getText().toString().trim();

        if (TextUtils.isEmpty(email)) {
            binding.tilEmail.setError("أدخل البريد الإلكتروني");
            return;
        }
        if (TextUtils.isEmpty(password)) {
            binding.tilPassword.setError("أدخل كلمة المرور");
            return;
        }

        binding.btnLogin.setEnabled(false);
        binding.progressBar.setVisibility(View.VISIBLE);

        mAuth.signInWithEmailAndPassword(email, password)
            .addOnSuccessListener(authResult -> {
                startActivity(new Intent(this, MainActivity.class));
                finish();
            })
            .addOnFailureListener(e -> {
                if (isFinishing() || isDestroyed()) return;
                binding.btnLogin.setEnabled(true);
                binding.progressBar.setVisibility(View.GONE);
                showErrorDialog("البريد الإلكتروني أو كلمة المرور غير صحيحة");
            });
    }

    private void showForgotPassword() {
        String email = binding.etEmail.getText().toString().trim();
        if (TextUtils.isEmpty(email)) {
            showErrorDialog("أدخل بريدك الإلكتروني أولاً");
            return;
        }
        mAuth.sendPasswordResetEmail(email)
            .addOnSuccessListener(unused ->
                showErrorDialog("تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك"))
            .addOnFailureListener(e ->
                showErrorDialog("حدث خطأ، تحقق من البريد الإلكتروني"));
    }

    private void showErrorDialog(String message) {
        if (isFinishing() || isDestroyed()) return;
        new AlertDialog.Builder(this)
            .setMessage(message)
            .setPositiveButton("حسناً", null)
            .show();
    }
}
