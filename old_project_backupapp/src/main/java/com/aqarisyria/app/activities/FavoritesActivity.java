package com.aqarisyria.app.activities;

import android.os.Bundle;
import androidx.appcompat.app.AppCompatActivity;
import com.aqarisyria.app.databinding.ActivityFavoritesBinding;

public class FavoritesActivity extends AppCompatActivity {
    private ActivityFavoritesBinding binding;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        binding = ActivityFavoritesBinding.inflate(getLayoutInflater());
        setContentView(binding.getRoot());
        binding.btnBack.setOnClickListener(v -> finish());
    }
}
