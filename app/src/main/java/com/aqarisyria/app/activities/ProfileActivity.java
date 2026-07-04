package com.aqarisyria.app.activities;

import android.content.Intent;
import android.os.Bundle;
import androidx.appcompat.app.AppCompatActivity;
import com.aqarisyria.app.databinding.ActivityProfileBinding;

public class ProfileActivity extends AppCompatActivity {
    private ActivityProfileBinding binding;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        binding = ActivityProfileBinding.inflate(getLayoutInflater());
        setContentView(binding.getRoot());
        binding.btnBack.setOnClickListener(v -> finish());
        binding.btnCompare.setOnClickListener(v ->
            startActivity(new Intent(this, ComparisonActivity.class)));
        binding.btnOpenCompare.setOnClickListener(v ->
            startActivity(new Intent(this, ComparisonActivity.class)));
    }
}
