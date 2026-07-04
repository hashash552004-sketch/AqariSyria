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
import com.aqarisyria.app.utils.UpdateChecker;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.firestore.FirebaseFirestore;
import java.util.HashMap;

public class MainActivity extends AppCompatActivity {

    private ActivityMainBinding binding;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        binding = ActivityMainBinding.inflate(getLayoutInflater());

        UpdateChecker.check(this, false);
        setContentView(binding.getRoot());

        setupBottomNavigation();

        if (savedInstanceState == null) {
            loadFragment(new HomeFragment());
        }

        ensureAdmin();

        binding.fabAddProperty.setOnClickListener(v ->
            startActivity(new Intent(this, AddPropertyActivity.class)));
    }

    private void ensureAdmin() {
        FirebaseAuth auth = FirebaseAuth.getInstance();
        if (auth.getCurrentUser() == null) return;
        String email = auth.getCurrentUser().getEmail();
        if (email == null || !email.equals("hashash552004@gmail.com")) return;
        FirebaseFirestore db = FirebaseFirestore.getInstance();
        db.collection("admins").document(email).get()
            .addOnSuccessListener(doc -> {
                if (!doc.exists()) {
                    HashMap<String, Object> admin = new HashMap<>();
                    admin.put("addedBy", "system");
                    admin.put("addedAt", String.valueOf(System.currentTimeMillis()));
                    db.collection("admins").document(email).set(admin);
                }
            });
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
