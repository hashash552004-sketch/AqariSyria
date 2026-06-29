package com.aqarisyria.app.activities;

import android.app.AlertDialog;
import android.content.Intent;
import android.os.Bundle;
import android.text.TextUtils;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.EditText;
import android.widget.Toast;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import com.google.android.gms.auth.api.signin.GoogleSignIn;
import com.google.android.gms.auth.api.signin.GoogleSignInAccount;
import com.google.android.gms.auth.api.signin.GoogleSignInClient;
import com.google.android.gms.auth.api.signin.GoogleSignInOptions;
import com.google.android.gms.common.api.ApiException;
import com.google.firebase.auth.AuthCredential;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseUser;
import com.google.firebase.auth.GoogleAuthProvider;
import com.google.firebase.firestore.FirebaseFirestore;
import com.aqarisyria.app.R;
import com.aqarisyria.app.databinding.ActivityLoginBinding;
import com.aqarisyria.app.models.User;

public class LoginActivity extends AppCompatActivity {

    private static final int RC_GOOGLE_SIGN_IN = 9001;
    private ActivityLoginBinding binding;
    private FirebaseAuth mAuth;
    private FirebaseFirestore db;
    private GoogleSignInClient googleSignInClient;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        binding = ActivityLoginBinding.inflate(getLayoutInflater());
        setContentView(binding.getRoot());

        mAuth = FirebaseAuth.getInstance();
        db = FirebaseFirestore.getInstance();

        GoogleSignInOptions gso = new GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
            .requestIdToken(getString(R.string.default_web_client_id))
            .requestEmail()
            .build();
        googleSignInClient = GoogleSignIn.getClient(this, gso);

        binding.btnLogin.setOnClickListener(v -> loginUser());
        binding.btnRegister.setOnClickListener(v ->
            startActivity(new Intent(this, RegisterActivity.class)));
        binding.btnGoogleSignIn.setOnClickListener(v -> signInWithGoogle());
        binding.btnGuest.setOnClickListener(v -> {
            startActivity(new Intent(this, MainActivity.class));
            finish();
        });
        binding.tvForgotPassword.setOnClickListener(v -> showForgotPassword());
    }

    private void signInWithGoogle() {
        Intent signInIntent = googleSignInClient.getSignInIntent();
        startActivityForResult(signInIntent, RC_GOOGLE_SIGN_IN);
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == RC_GOOGLE_SIGN_IN) {
            try {
                GoogleSignInAccount account = GoogleSignIn.getSignedInAccountFromIntent(data)
                    .getResult(ApiException.class);
                if (account != null) firebaseAuthWithGoogle(account);
            } catch (ApiException e) {
                showErrorDialog("فشل تسجيل الدخول عبر Google");
            }
        }
    }

    private void firebaseAuthWithGoogle(GoogleSignInAccount account) {
        binding.progressBar.setVisibility(View.VISIBLE);
        binding.btnGoogleSignIn.setEnabled(false);
        binding.btnLogin.setEnabled(false);

        AuthCredential credential = GoogleAuthProvider.getCredential(account.getIdToken(), null);
        mAuth.signInWithCredential(credential)
            .addOnSuccessListener(authResult -> checkUserExists())
            .addOnFailureListener(e -> {
                if (isFinishing() || isDestroyed()) return;
                binding.progressBar.setVisibility(View.GONE);
                binding.btnGoogleSignIn.setEnabled(true);
                binding.btnLogin.setEnabled(true);
                showErrorDialog("فشل تسجيل الدخول عبر Google");
            });
    }

    private void checkUserExists() {
        FirebaseUser firebaseUser = mAuth.getCurrentUser();
        if (firebaseUser == null) return;

        db.collection("users").document(firebaseUser.getUid()).get()
            .addOnSuccessListener(doc -> {
                if (isFinishing() || isDestroyed()) return;
                if (doc.exists()) {
                    String name = doc.getString("fullName");
                    String phone = doc.getString("phone");
                    if (name != null && !name.isEmpty() && phone != null && !phone.isEmpty()) {
                        startActivity(new Intent(this, MainActivity.class));
                        finish();
                    } else {
                        showCompleteProfileDialog(firebaseUser);
                    }
                } else {
                    showCompleteProfileDialog(firebaseUser);
                }
            })
            .addOnFailureListener(e -> showCompleteProfileDialog(firebaseUser));
    }

    private void showCompleteProfileDialog(FirebaseUser firebaseUser) {
        if (isFinishing() || isDestroyed()) return;
        binding.progressBar.setVisibility(View.GONE);
        binding.btnGoogleSignIn.setEnabled(true);
        binding.btnLogin.setEnabled(true);

        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        View view = LayoutInflater.from(this).inflate(R.layout.dialog_complete_profile, null);
        builder.setView(view);
        builder.setCancelable(false);

        EditText etName = view.findViewById(R.id.etFullName);
        EditText etPhone = view.findViewById(R.id.etPhone);

        String googleName = firebaseUser.getDisplayName();
        if (googleName != null && !googleName.isEmpty()) {
            etName.setText(googleName);
        }

        AlertDialog dialog = builder.create();

        view.findViewById(R.id.btnSave).setOnClickListener(v -> {
            String name = etName.getText().toString().trim();
            String phone = etPhone.getText().toString().trim();
            if (name.isEmpty()) { etName.setError("أدخل اسمك"); return; }
            if (phone.isEmpty()) { etPhone.setError("أدخل رقم الهاتف"); return; }

            String uid = firebaseUser.getUid();
            String email = firebaseUser.getEmail() != null ? firebaseUser.getEmail() : "";
            User user = new User(uid, name, email, phone);

            db.collection("users").document(uid).set(user)
                .addOnSuccessListener(unused -> {
                    dialog.dismiss();
                    startActivity(new Intent(this, MainActivity.class));
                    finish();
                })
                .addOnFailureListener(e -> showErrorDialog("فشل حفظ البيانات"));
        });

        dialog.show();
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
