package com.aqarisyria.app.activities;

import android.content.Intent;
import android.os.Bundle;
import android.view.MenuItem;
import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.fragment.app.Fragment;
import com.google.android.material.bottomnavigation.BottomNavigationView;
import com.aqarisyria.app.R;
import com.aqarisyria.app.databinding.ActivityMainBinding;
import com.aqarisyria.app.fragments.HomeFragment;
import com.aqarisyria.app.fragments.SearchFragment;
import com.aqarisyria.app.fragments.FavoritesFragment;
import com.aqarisyria.app.fragments.MessagesFragment;
import com.aqarisyria.app.fragments.ProfileFragment;

public class MainActivity extends AppCompatActivity {

    private ActivityMainBinding binding;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        binding = ActivityMainBinding.inflate(getLayoutInflater());
        setContentView(binding.getRoot());

        setupBottomNavigation();

        if (savedInstanceState == null) {
            loadFragment(new HomeFragment());
        }

        binding.fabAddProperty.setOnClickListener(v ->
            startActivity(new Intent(this, AddPropertyActivity.class)));
    }

    private void setupBottomNavigation() {
        binding.bottomNavigation.setOnItemSelectedListener(item -> {
            Fragment fragment = null;
            int id = item.getItemId();

            if (id == R.id.nav_home) {
                fragment = new HomeFragment();
            } else if (id == R.id.nav_search) {
                fragment = new SearchFragment();
            } else if (id == R.id.nav_favorites) {
                fragment = new FavoritesFragment();
            } else if (id == R.id.nav_messages) {
                fragment = new MessagesFragment();
            } else if (id == R.id.nav_profile) {
                fragment = new ProfileFragment();
            }

            if (fragment != null) {
                loadFragment(fragment);
                return true;
            }
            return false;
        });
    }

    private void loadFragment(Fragment fragment) {
        getSupportFragmentManager()
            .beginTransaction()
            .replace(R.id.fragment_container, fragment)
            .commit();
    }
}
