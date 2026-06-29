package com.aqarisyria.app.activities;

import android.animation.AnimatorSet;
import android.animation.ObjectAnimator;
import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.view.animation.OvershootInterpolator;

import androidx.appcompat.app.AppCompatActivity;

import com.aqarisyria.app.R;
import com.aqarisyria.app.databinding.ActivitySplashBinding;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseUser;

public class SplashActivity extends AppCompatActivity {

    private static final int SPLASH_DELAY = 2000;
    private ActivitySplashBinding binding;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        setTheme(R.style.Theme_AqariSyria_Splash);
        super.onCreate(savedInstanceState);
        binding = ActivitySplashBinding.inflate(getLayoutInflater());
        setContentView(binding.getRoot());

        binding.ivLogo.setAlpha(0f);
        binding.ivLogo.setScaleX(0f);
        binding.ivLogo.setScaleY(0f);
        binding.tvAppName.setAlpha(0f);
        binding.tvTagline.setAlpha(0f);
        binding.progressBar.setAlpha(0f);

        startAnimation();
        new Handler(Looper.getMainLooper()).postDelayed(this::navigateNext, SPLASH_DELAY);
    }

    private void startAnimation() {
        ObjectAnimator logoScaleX = ObjectAnimator.ofFloat(binding.ivLogo, "scaleX", 0f, 1f);
        ObjectAnimator logoScaleY = ObjectAnimator.ofFloat(binding.ivLogo, "scaleY", 0f, 1f);
        ObjectAnimator logoFade = ObjectAnimator.ofFloat(binding.ivLogo, "alpha", 0f, 1f);

        logoScaleX.setDuration(600);
        logoScaleY.setDuration(600);
        logoFade.setDuration(600);
        logoScaleX.setInterpolator(new OvershootInterpolator());
        logoScaleY.setInterpolator(new OvershootInterpolator());

        ObjectAnimator nameFade = ObjectAnimator.ofFloat(binding.tvAppName, "alpha", 0f, 1f);
        nameFade.setDuration(500);
        nameFade.setStartDelay(400);

        ObjectAnimator taglineFade = ObjectAnimator.ofFloat(binding.tvTagline, "alpha", 0f, 1f);
        taglineFade.setDuration(500);
        taglineFade.setStartDelay(700);

        ObjectAnimator progressFade = ObjectAnimator.ofFloat(binding.progressBar, "alpha", 0f, 1f);
        progressFade.setDuration(400);
        progressFade.setStartDelay(1000);

        AnimatorSet animatorSet = new AnimatorSet();
        animatorSet.playTogether(logoScaleX, logoScaleY, logoFade, nameFade, taglineFade, progressFade);
        animatorSet.start();
    }

    private void navigateNext() {
        if (isFinishing() || isDestroyed()) return;
        FirebaseUser currentUser = FirebaseAuth.getInstance().getCurrentUser();
        Intent intent;
        if (currentUser != null) {
            intent = new Intent(SplashActivity.this, MainActivity.class);
        } else {
            intent = new Intent(SplashActivity.this, LoginActivity.class);
        }
        startActivity(intent);
        finish();
    }
}
