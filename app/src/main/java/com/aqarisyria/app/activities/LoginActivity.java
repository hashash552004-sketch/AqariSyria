package com.aqarisyria.app.activities;

import android.app.AlertDialog;
import android.content.Intent;
import android.os.Bundle;
import android.text.TextUtils;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.EditText;

import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;

import com.aqarisyria.app.R;
import com.aqarisyria.app.databinding.ActivityLoginBinding;
import com.aqarisyria.app.models.User;
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

        enterAnimation();
    }

    private void enterAnimation() {
        binding.ivLogo.setAlpha(0f);
        binding.tvWelcome.setAlpha(0f);
        binding.tilEmail.setAlpha(0f);
        binding.tilPassword.setAlpha(0f);
        binding.tvForgotPassword.setAlpha(0f);
        binding.btnLogin.setAlpha(0f);
        binding.dividerLayout.setAlpha(0f);
        binding.btnGoogleSignIn.setAlpha(0f);
        binding.registerContainer.setAlpha(0f);
        binding.btnGuest.setAlpha(0f);

        binding.ivLogo.animate().alpha(1f).setDuration(400).start();
        binding.tvWelcome.animate().alpha(1f).setDuration(400).setStartDelay(100).start();
        binding.tilEmail.animate().alpha(1f).setDuration(400).setStartDelay(200).start();
        binding.tilPassword.animate().alpha(1f).setDuration(400).setStartDelay(300).start();
        binding.tvForgotPassword.animate().alpha(1f).setDuration(400).setStartDelay(400).start();
        binding.btnLogin.animate().alpha(1f).setDuration(400).setStartDelay(500).start();
        binding.dividerLayout.animate().alpha(1f).setDuration(400).setStartDelay(600).start();
        binding.btnGoogleSignIn.animate().alpha(1f).setDuration(400).setStartDelay(700).start();
        binding.registerContainer.animate().alpha(1f).setDuration(400).setStartDelay(800).start();
        binding.btnGuest.animate().alpha(1f).setDuration(400).setStartDelay(900).start();
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
                showErrorDialog(getString(R.string.error_google_signin));
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
                showErrorDialog(getString(R.string.error_google_signin));
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
            if (name.isEmpty()) { etName.setError(getString(R.string.error_enter_name)); return; }
            if (phone.isEmpty()) { etPhone.setError(getString(R.string.error_enter_phone)); return; }

            String uid = firebaseUser.getUid();
            String email = firebaseUser.getEmail() != null ? firebaseUser.getEmail() : "";
            User user = new User(uid, name, email, phone);

            db.collection("users").document(uid).set(user)
                .addOnSuccessListener(unused -> {
                    dialog.dismiss();
                    startActivity(new Intent(this, MainActivity.class));
                    finish();
                })
                .addOnFailureListener(e -> showErrorDialog(getString(R.string.error_save_data)));
        });

        dialog.show();
    }

    private void loginUser() {
        String email = binding.etEmail.getText().toString().trim();
        String password = binding.etPassword.getText().toString().trim();

        if (TextUtils.isEmpty(email)) {
            binding.tilEmail.setError(getString(R.string.error_enter_email));
            return;
        }
        if (TextUtils.isEmpty(password)) {
            binding.tilPassword.setError(getString(R.string.error_enter_password));
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
                showErrorDialog(getString(R.string.error_email_or_password));
            });
    }

    private void showForgotPassword() {
        String email = binding.etEmail.getText().toString().trim();
        if (TextUtils.isEmpty(email)) {
            showErrorDialog(getString(R.string.error_enter_email_first));
            return;
        }
        mAuth.sendPasswordResetEmail(email)
            .addOnSuccessListener(unused ->
                showErrorDialog(getString(R.string.success_reset_email)))
            .addOnFailureListener(e ->
                showErrorDialog(getString(R.string.error_reset_password)));
    }

    private void showErrorDialog(String message) {
        if (isFinishing() || isDestroyed()) return;
        new AlertDialog.Builder(this)
            .setMessage(message)
            .setPositiveButton(getString(R.string.ok), null)
            .show();
    }
}
