package com.aqarisyria.app.activities;

import android.animation.ObjectAnimator;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.text.TextUtils;
import android.view.View;
import android.view.ViewGroup;
import android.view.animation.AccelerateDecelerateInterpolator;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.content.ContextCompat;
import androidx.recyclerview.widget.RecyclerView;

import com.bumptech.glide.Glide;
import com.bumptech.glide.load.resource.bitmap.CircleCrop;
import com.google.android.material.snackbar.Snackbar;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.firestore.DocumentSnapshot;
import com.google.firebase.firestore.FieldValue;
import com.google.firebase.firestore.FirebaseFirestore;

import com.aqarisyria.app.R;
import com.aqarisyria.app.adapters.ImageSliderAdapter;
import com.aqarisyria.app.databinding.ActivityPropertyDetailBinding;
import com.aqarisyria.app.models.Property;

import java.text.DecimalFormat;
import java.util.ArrayList;
import java.util.List;

public class PropertyDetailActivity extends AppCompatActivity {

    public static final String EXTRA_PROPERTY_ID = "property_id";
    private ActivityPropertyDetailBinding binding;
    private FirebaseFirestore db;
    private FirebaseAuth mAuth;
    private Property property;
    private boolean isFavorite = false;
    private boolean isDescriptionExpanded = false;
    private List<Property> similarProperties = new ArrayList<>();
    private SimilarPropertiesAdapter similarAdapter;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        binding = ActivityPropertyDetailBinding.inflate(getLayoutInflater());
        setContentView(binding.getRoot());

        db = FirebaseFirestore.getInstance();
        mAuth = FirebaseAuth.getInstance();

        setSupportActionBar(binding.toolbar);
        if (getSupportActionBar() != null) {
            getSupportActionBar().setDisplayHomeAsUpEnabled(false);
            getSupportActionBar().setTitle("");
        }

        binding.toolbar.setNavigationOnClickListener(v -> finish());

        String propertyId = getIntent().getStringExtra(EXTRA_PROPERTY_ID);
        if (propertyId != null) {
            loadProperty(propertyId);
        } else {
            finish();
        }

        binding.btnShare.setOnClickListener(v -> shareProperty());
        binding.btnFavorite.setOnClickListener(v -> toggleFavorite());
        binding.btnWhatsapp.setOnClickListener(v -> openWhatsApp());
        binding.btnCallOwner.setOnClickListener(v -> callOwner());
        binding.btnWhatsappOwner.setOnClickListener(v -> openWhatsApp());
        binding.btnMessage.setOnClickListener(v -> callOwner());
        binding.btnDeleteProperty.setOnClickListener(v -> deleteProperty());
        binding.btnOpenMap.setOnClickListener(v -> openMap());
        binding.btnOpenMapFull.setOnClickListener(v -> openMap());
        binding.tvToggleDescription.setOnClickListener(v -> toggleDescription());
        
    }

    private void loadProperty(String propertyId) {
        db.collection("properties").document(propertyId).get()
            .addOnSuccessListener(doc -> {
                if (isFinishing() || isDestroyed()) return;
                if (doc == null || !doc.exists()) {
                    finish();
                    return;
                }
                property = doc.toObject(Property.class);
                if (property != null) {
                    property.setId(doc.getId());
                    displayProperty();
                    checkFavorite();
                    loadSimilarProperties();
                    incrementViews(propertyId);
                }
            })
            .addOnFailureListener(e -> {
                if (isFinishing() || isDestroyed()) return;
                Snackbar.make(binding.getRoot(), getString(R.string.error_general), Snackbar.LENGTH_SHORT).show();
                finish();
            });
    }

    private void displayProperty() {
        binding.tvTitle.setText(property.getTitle());
        binding.tvPrice.setText(property.getFormattedPrice());
        binding.tvLocation.setText(property.getLocationString());
        binding.tvDescription.setText(property.getDescription());
        binding.tvOwnerName.setText(property.getOwnerName());
        binding.tvOwnerPhone.setText(property.getOwnerPhone());

        String currentUid = mAuth.getCurrentUser() != null ? mAuth.getCurrentUser().getUid() : "";
        boolean isOwner = property.getOwnerId() != null && property.getOwnerId().equals(currentUid);
        if (isOwner) {
            binding.btnDeleteProperty.setVisibility(View.VISIBLE);
        } else {
            checkAdminAndShowDelete();
        }

        String areaText = new DecimalFormat("#.#").format(property.getArea()) + " " + getString(R.string.area);
        binding.tvArea.setText(areaText);
        binding.tvRooms.setText(getString(R.string.rooms_count_value, property.getRooms()) + " " + getString(R.string.rooms_label));
        binding.tvBathrooms.setText(getString(R.string.bathrooms_count_value, property.getBathrooms()) + " " + getString(R.string.bathrooms_label));
        binding.tvFloor.setText(getString(R.string.floor_value, property.getFloor()) + " " + getString(R.string.floor_label));

        String opLabel = property.getOperationTypeLabel();
        binding.tvOperationType.setText(opLabel);
        if ("للبيع".equals(opLabel)) {
            binding.tvOperationType.setBackgroundResource(R.drawable.bg_tag_sell);
            binding.tvOperationType.setTextColor(ContextCompat.getColor(this, R.color.tag_sell_text));
        } else if ("للإيجار".equals(opLabel)) {
            binding.tvOperationType.setBackgroundResource(R.drawable.bg_tag_rent);
            binding.tvOperationType.setTextColor(ContextCompat.getColor(this, R.color.tag_rent_text));
        } else {
            binding.tvOperationType.setBackgroundResource(R.drawable.bg_tag_invest);
            binding.tvOperationType.setTextColor(ContextCompat.getColor(this, R.color.tag_invest_text));
        }

        binding.tvPropertyType.setText(property.getTypeLabel());
        binding.tvPropertyType.setVisibility(View.VISIBLE);

        if (property.getImages() != null && !property.getImages().isEmpty()) {
            ImageSliderAdapter adapter = new ImageSliderAdapter(this, property.getImages());
            binding.viewPagerImages.setAdapter(adapter);
            binding.dotsIndicator.attachTo(binding.viewPagerImages);
        }

        setupAmenities();

        if (property.getDescription() != null && property.getDescription().length() > 100) {
            binding.tvToggleDescription.setVisibility(View.VISIBLE);
        }

        Glide.with(this)
            .load(R.drawable.ic_person)
            .transform(new CircleCrop())
            .into(binding.ivOwnerAvatar);
    }

    private void setupAmenities() {
        boolean hasAny = false;

        if (property.isHasElevator()) { binding.chipElevator.setVisibility(View.VISIBLE); hasAny = true; }
        if (property.isHasParking()) { binding.chipParking.setVisibility(View.VISIBLE); hasAny = true; }
        if (property.isHasAC()) { binding.chipAC.setVisibility(View.VISIBLE); hasAny = true; }
        if (property.isHasHeating()) { binding.chipHeating.setVisibility(View.VISIBLE); hasAny = true; }
        if (property.isHasGarden()) { binding.chipGarden.setVisibility(View.VISIBLE); hasAny = true; }
        if (property.isHasPool()) { binding.chipPool.setVisibility(View.VISIBLE); hasAny = true; }
        if (property.isHasBalcony()) { binding.chipBalcony.setVisibility(View.VISIBLE); hasAny = true; }
        if (property.isHasInternet()) { binding.chipInternet.setVisibility(View.VISIBLE); hasAny = true; }
        if (property.isHasGas()) { binding.chipGas.setVisibility(View.VISIBLE); hasAny = true; }
        if (property.isFurnished()) { binding.chipFurnished.setVisibility(View.VISIBLE); hasAny = true; }

        binding.tvNoAmenities.setVisibility(hasAny ? View.GONE : View.VISIBLE);
    }

    private void toggleDescription() {
        if (isDescriptionExpanded) {
            binding.tvDescription.setMaxLines(3);
            binding.tvDescription.setEllipsize(TextUtils.TruncateAt.END);
            binding.tvToggleDescription.setText(R.string.more);
            isDescriptionExpanded = false;
        } else {
            binding.tvDescription.setMaxLines(Integer.MAX_VALUE);
            binding.tvDescription.setEllipsize(null);
            binding.tvToggleDescription.setText(R.string.show_less);
            isDescriptionExpanded = true;
        }
    }

    private void checkFavorite() {
        if (mAuth.getCurrentUser() == null || property == null) return;
        String uid = mAuth.getCurrentUser().getUid();
        db.collection("users").document(uid).get()
            .addOnSuccessListener(doc -> {
                if (isFinishing() || isDestroyed() || property == null) return;
                if (doc.exists()) {
                    List<String> favs = (List<String>) doc.get("favorites");
                    isFavorite = favs != null && favs.contains(property.getId());
                    updateFavoriteButton();
                }
            });
    }

    private void toggleFavorite() {
        if (mAuth.getCurrentUser() == null) {
            Snackbar.make(binding.getRoot(), R.string.error_enter_email_first, Snackbar.LENGTH_SHORT).show();
            return;
        }
        if (property == null) return;
        String uid = mAuth.getCurrentUser().getUid();

        animateFavoriteButton();

        if (isFavorite) {
            db.collection("users").document(uid)
                .update("favorites", FieldValue.arrayRemove(property.getId()))
                .addOnSuccessListener(u -> {
                    isFavorite = false;
                    updateFavoriteButton();
                })
                .addOnFailureListener(e -> {
                    isFavorite = true;
                    updateFavoriteButton();
                });
        } else {
            db.collection("users").document(uid)
                .update("favorites", FieldValue.arrayUnion(property.getId()))
                .addOnSuccessListener(u -> {
                    isFavorite = true;
                    updateFavoriteButton();
                })
                .addOnFailureListener(e -> {
                    isFavorite = false;
                    updateFavoriteButton();
                });
        }
    }

    private void animateFavoriteButton() {
        ObjectAnimator scaleX = ObjectAnimator.ofFloat(binding.btnFavorite, View.SCALE_X, 1f, 1.3f, 1f);
        ObjectAnimator scaleY = ObjectAnimator.ofFloat(binding.btnFavorite, View.SCALE_Y, 1f, 1.3f, 1f);
        scaleX.setDuration(300);
        scaleY.setDuration(300);
        scaleX.setInterpolator(new AccelerateDecelerateInterpolator());
        scaleY.setInterpolator(new AccelerateDecelerateInterpolator());
        scaleX.start();
        scaleY.start();
    }

    private void updateFavoriteButton() {
        binding.btnFavorite.setImageResource(
            isFavorite ? R.drawable.ic_favorite_filled : R.drawable.ic_favorite_border);
    }

    private void callOwner() {
        if (property == null || property.getOwnerPhone() == null) return;
        Intent intent = new Intent(Intent.ACTION_DIAL,
            Uri.parse("tel:" + property.getOwnerPhone()));
        startActivity(intent);
    }

    private void openMessages() {
        if (property == null) return;
        Intent intent = new Intent(PropertyDetailActivity.this, com.aqarisyria.app.activities.MainActivity.class);
        intent.putExtra("openTab", "messages");
        intent.putExtra("propertyId", property.getId());
        intent.putExtra("ownerId", property.getOwnerId());
        intent.putExtra("ownerName", property.getOwnerName());
        intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);
        startActivity(intent);
    }

    private void openWhatsApp() {
        if (property == null || property.getOwnerPhone() == null) return;
        String phone = property.getOwnerPhone().replaceAll("[^0-9]", "");
        String msg = getString(R.string.app_name) + ": " + property.getTitle();
        try {
            Intent intent = new Intent(Intent.ACTION_VIEW,
                Uri.parse("https://wa.me/" + phone + "?text=" + Uri.encode(msg)));
            startActivity(intent);
        } catch (Exception e) {
            Snackbar.make(binding.getRoot(), R.string.error_general, Snackbar.LENGTH_SHORT).show();
        }
    }

    private void shareProperty() {
        if (property == null) return;
        String details = property.getTitle() + "\n" +
            "💰 " + property.getFormattedPrice() + "\n" +
            "📍 " + property.getLocationString() + "\n" +
            "📐 " + getString(R.string.area_value, property.getArea()) + "\n" +
            "🛏 " + getString(R.string.rooms_count_value, property.getRooms()) + " " + getString(R.string.rooms_label) + "\n" +
            "🛁 " + getString(R.string.bathrooms_count_value, property.getBathrooms()) + " " + getString(R.string.bathrooms_label) + "\n" +
            "🏢 " + getString(R.string.floor_value, property.getFloor()) + " " + getString(R.string.floor_label) + "\n" +
            "📞 " + property.getOwnerPhone() + "\n\n" +
            getString(R.string.app_name) + " - " + getString(R.string.app_tagline);
        Intent intent = new Intent(Intent.ACTION_SEND);
        intent.setType("text/plain");
        intent.putExtra(Intent.EXTRA_TEXT, details);
        startActivity(Intent.createChooser(intent, getString(R.string.share)));
    }

    private void openMap() {
        if (property == null) return;
        String uri = "geo:0,0?q=" + Uri.encode(property.getLocationString());
        Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(uri));
        startActivity(Intent.createChooser(intent, getString(R.string.open_map)));
    }

    private void incrementViews(String propertyId) {
        db.collection("properties").document(propertyId)
            .update("viewsCount", FieldValue.increment(1));
    }

    private void loadSimilarProperties() {
        if (property == null || property.getGovernorate() == null) return;
        db.collection("properties")
            .whereEqualTo("governorate", property.getGovernorate())
            .whereEqualTo("active", true)
            .limit(5)
            .get()
            .addOnSuccessListener(querySnapshots -> {
                if (isFinishing() || isDestroyed()) return;
                similarProperties.clear();
                for (DocumentSnapshot doc : querySnapshots) {
                    Property p = doc.toObject(Property.class);
                    if (p != null) {
                        p.setId(doc.getId());
                        if (!doc.getId().equals(property.getId())) {
                            similarProperties.add(p);
                        }
                    }
                }
                if (similarAdapter == null) {
                    similarAdapter = new SimilarPropertiesAdapter();
                    binding.rvSimilarProperties.setAdapter(similarAdapter);
                } else {
                    similarAdapter.notifyDataSetChanged();
                }
            });
    }

    private class SimilarPropertiesAdapter extends RecyclerView.Adapter<SimilarPropertiesAdapter.ViewHolder> {

        @NonNull
        @Override
        public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
            View view = getLayoutInflater().inflate(R.layout.item_similar_property, parent, false);
            return new ViewHolder(view);
        }

        @Override
        public void onBindViewHolder(@NonNull ViewHolder holder, int position) {
            Property p = similarProperties.get(position);
            holder.title.setText(p.getTitle());
            holder.price.setText(p.getFormattedPrice());
            holder.location.setText(p.getLocationString());

            if (p.getFirstImage() != null) {
                Glide.with(PropertyDetailActivity.this)
                    .load(p.getFirstImage())
                    .placeholder(R.drawable.placeholder_property)
                    .centerCrop()
                    .into(holder.image);
            } else {
                holder.image.setImageResource(R.drawable.placeholder_property);
            }

            holder.itemView.setOnClickListener(v -> {
                Intent intent = new Intent(PropertyDetailActivity.this, PropertyDetailActivity.class);
                intent.putExtra(EXTRA_PROPERTY_ID, p.getId());
                startActivity(intent);
            });
        }

        @Override
        public int getItemCount() {
            return similarProperties.size();
        }

    private void checkAdminAndShowDelete() {
        com.google.firebase.auth.FirebaseUser user = mAuth.getCurrentUser();
        if (user == null) return;
        db.collection("admins").document(user.getEmail()).get()
            .addOnSuccessListener(doc -> {
                if (doc.exists()) binding.btnDeleteProperty.setVisibility(View.VISIBLE);
            });
    }

    private void deleteProperty() {
        if (property == null || property.getId() == null) return;
        new androidx.appcompat.app.AlertDialog.Builder(this)
            .setTitle("حذف العقار")
            .setMessage("هل أنت متأكد من حذف هذا العقار؟")
            .setPositiveButton("حذف", (dialog, which) -> {
                db.collection("properties").document(property.getId()).delete()
                    .addOnSuccessListener(v -> {
                        Snackbar.make(binding.getRoot(), "تم حذف العقار", Snackbar.LENGTH_SHORT).show();
                        finish();
                    })
                    .addOnFailureListener(e ->
                        Snackbar.make(binding.getRoot(), "فشل الحذف: " + e.getMessage(), Snackbar.LENGTH_SHORT).show());
            })
            .setNegativeButton("إلغاء", null)
            .show();
    }

        class ViewHolder extends RecyclerView.ViewHolder {
            ImageView image;
            TextView title, price, location;

            ViewHolder(@NonNull View itemView) {
                super(itemView);
                image = itemView.findViewById(R.id.ivSimilarImage);
                title = itemView.findViewById(R.id.tvSimilarTitle);
                price = itemView.findViewById(R.id.tvSimilarPrice);
                location = itemView.findViewById(R.id.tvSimilarLocation);
            }
        }
    }
}
