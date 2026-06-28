package com.aqarisyria.app.activities;

import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.view.View;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;
import com.bumptech.glide.Glide;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.firestore.FieldValue;
import com.google.firebase.firestore.FirebaseFirestore;
import com.aqarisyria.app.R;
import com.aqarisyria.app.adapters.ImageSliderAdapter;
import com.aqarisyria.app.databinding.ActivityPropertyDetailBinding;
import com.aqarisyria.app.models.Property;

public class PropertyDetailActivity extends AppCompatActivity {

    public static final String EXTRA_PROPERTY_ID = "property_id";
    private ActivityPropertyDetailBinding binding;
    private FirebaseFirestore db;
    private FirebaseAuth mAuth;
    private Property property;
    private boolean isFavorite = false;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        binding = ActivityPropertyDetailBinding.inflate(getLayoutInflater());
        setContentView(binding.getRoot());

        db = FirebaseFirestore.getInstance();
        mAuth = FirebaseAuth.getInstance();

        String propertyId = getIntent().getStringExtra(EXTRA_PROPERTY_ID);
        if (propertyId != null) loadProperty(propertyId);

        binding.btnBack.setOnClickListener(v -> finish());
        binding.btnShare.setOnClickListener(v -> shareProperty());
        binding.btnFavorite.setOnClickListener(v -> toggleFavorite());
        binding.btnContact.setOnClickListener(v -> callOwner());
        binding.btnWhatsapp.setOnClickListener(v -> openWhatsApp());
    }

    private void loadProperty(String propertyId) {
        db.collection("properties").document(propertyId).get()
            .addOnSuccessListener(doc -> {
                if (doc.exists()) {
                    property = doc.toObject(Property.class);
                    if (property != null) {
                        property.setId(doc.getId());
                        displayProperty();
                        checkFavorite();
                        incrementViews(propertyId);
                    }
                }
            });
    }

    private void displayProperty() {
        binding.tvTitle.setText(property.getTitle());
        binding.tvPrice.setText(property.getFormattedPrice());
        binding.tvLocation.setText(property.getLocationString());
        binding.tvDescription.setText(property.getDescription());
        binding.tvRooms.setText(property.getRooms() + " غرف");
        binding.tvBathrooms.setText(property.getBathrooms() + " حمام");
        binding.tvArea.setText(property.getArea() + " م²");
        binding.tvFloor.setText("طابق " + property.getFloor());
        binding.tvOperationType.setText(property.getOperationTypeLabel());
        binding.tvOwnerName.setText(property.getOwnerName());

        // Setup image slider
        if (property.getImages() != null && !property.getImages().isEmpty()) {
            ImageSliderAdapter adapter = new ImageSliderAdapter(this, property.getImages());
            binding.viewPagerImages.setAdapter(adapter);
            binding.dotsIndicator.attachTo(binding.viewPagerImages);
        }

        // Show features
        binding.chipElevator.setVisibility(property.isHasElevator() ? View.VISIBLE : View.GONE);
        binding.chipParking.setVisibility(property.isHasParking() ? View.VISIBLE : View.GONE);
        binding.chipAC.setVisibility(property.isHasAC() ? View.VISIBLE : View.GONE);
        binding.chipHeating.setVisibility(property.isHasHeating() ? View.VISIBLE : View.GONE);
        binding.chipGarden.setVisibility(property.isHasGarden() ? View.VISIBLE : View.GONE);
        binding.chipPool.setVisibility(property.isHasPool() ? View.VISIBLE : View.GONE);
        binding.chipBalcony.setVisibility(property.isHasBalcony() ? View.VISIBLE : View.GONE);
        binding.chipInternet.setVisibility(property.isHasInternet() ? View.VISIBLE : View.GONE);
        binding.chipGas.setVisibility(property.isHasGas() ? View.VISIBLE : View.GONE);
        binding.chipFurnished.setVisibility(property.isFurnished() ? View.VISIBLE : View.GONE);
    }

    private void checkFavorite() {
        if (mAuth.getCurrentUser() == null) return;
        db.collection("users").document(mAuth.getCurrentUser().getUid()).get()
            .addOnSuccessListener(doc -> {
                if (doc.exists()) {
                    java.util.List<String> favs = (java.util.List<String>) doc.get("favorites");
                    isFavorite = favs != null && favs.contains(property.getId());
                    updateFavoriteButton();
                }
            });
    }

    private void toggleFavorite() {
        if (mAuth.getCurrentUser() == null) {
            Toast.makeText(this, "يجب تسجيل الدخول أولاً", Toast.LENGTH_SHORT).show();
            return;
        }
        String uid = mAuth.getCurrentUser().getUid();
        if (isFavorite) {
            db.collection("users").document(uid)
                .update("favorites", FieldValue.arrayRemove(property.getId()))
                .addOnSuccessListener(u -> { isFavorite = false; updateFavoriteButton(); });
        } else {
            db.collection("users").document(uid)
                .update("favorites", FieldValue.arrayUnion(property.getId()))
                .addOnSuccessListener(u -> { isFavorite = true; updateFavoriteButton(); });
        }
    }

    private void updateFavoriteButton() {
        binding.btnFavorite.setImageResource(
            isFavorite ? R.drawable.ic_favorite_filled : R.drawable.ic_favorite_border);
    }

    private void callOwner() {
        if (property == null) return;
        Intent intent = new Intent(Intent.ACTION_DIAL,
            Uri.parse("tel:" + property.getOwnerPhone()));
        startActivity(intent);
    }

    private void openWhatsApp() {
        if (property == null) return;
        String phone = property.getOwnerPhone().replaceAll("[^0-9]", "");
        String msg = "مرحباً، أنا مهتم بعقارك: " + property.getTitle();
        try {
            Intent intent = new Intent(Intent.ACTION_VIEW,
                Uri.parse("https://wa.me/963" + phone + "?text=" + Uri.encode(msg)));
            startActivity(intent);
        } catch (Exception e) {
            Toast.makeText(this, "لا يوجد تطبيق واتساب", Toast.LENGTH_SHORT).show();
        }
    }

    private void shareProperty() {
        if (property == null) return;
        Intent intent = new Intent(Intent.ACTION_SEND);
        intent.setType("text/plain");
        intent.putExtra(Intent.EXTRA_TEXT,
            property.getTitle() + "\n" + property.getFormattedPrice() +
            "\n" + property.getLocationString() + "\nعبر تطبيق عقاري سوريا");
        startActivity(Intent.createChooser(intent, "مشاركة العقار"));
    }

    private void incrementViews(String propertyId) {
        db.collection("properties").document(propertyId)
            .update("viewsCount", FieldValue.increment(1));
    }
}
