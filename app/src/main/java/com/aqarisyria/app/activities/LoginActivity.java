package com.aqarisyria.app.activities;

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
                binding.btnLogin.setEnabled(true);
                binding.progressBar.setVisibility(View.GONE);
                Toast.makeText(this, "البريد الإلكتروني أو كلمة المرور غير صحيحة", Toast.LENGTH_SHORT).show();
            });
    }

    private void showForgotPassword() {
        String email = binding.etEmail.getText().toString().trim();
        if (TextUtils.isEmpty(email)) {
            Toast.makeText(this, "أدخل بريدك الإلكتروني أولاً", Toast.LENGTH_SHORT).show();
            return;
        }
        mAuth.sendPasswordResetEmail(email)
            .addOnSuccessListener(unused ->
                Toast.makeText(this, "تم إرسال رابط إعادة تعيين كلمة المرور", Toast.LENGTH_LONG).show())
            .addOnFailureListener(e ->
                Toast.makeText(this, "حدث خطأ، تحقق من البريد الإلكتروني", Toast.LENGTH_SHORT).show());
    }
}
