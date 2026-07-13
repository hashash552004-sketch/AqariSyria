package com.aqarisyria.app.adapters;

import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.Toast;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import com.bumptech.glide.Glide;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.firestore.FieldValue;
import com.google.firebase.firestore.FirebaseFirestore;
import com.aqarisyria.app.R;
import com.aqarisyria.app.activities.PropertyDetailActivity;
import com.aqarisyria.app.databinding.ItemPropertyBinding;
import com.aqarisyria.app.models.Property;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

public class PropertyAdapter extends RecyclerView.Adapter<PropertyAdapter.PropertyViewHolder> {

    private List<Property> properties;
    private Context context;
    private boolean isHorizontal;
    private static final String COMPARE_PREFS = "compare_prefs";
    private static final String COMPARE_IDS = "compare_ids";
    private java.util.Set<String> cachedFavorites = new java.util.HashSet<>();
    private boolean favoritesLoaded = false;
    private static final int MAX_FAVORITES = 50;

    public PropertyAdapter(List<Property> properties, Context context) {
        this(properties, context, false);
    }

    public PropertyAdapter(List<Property> properties, Context context, boolean isHorizontal) {
        this.properties = properties;
        this.context = context;
        this.isHorizontal = isHorizontal;
        loadFavorites();
    }

    private void loadFavorites() {
        FirebaseAuth auth = FirebaseAuth.getInstance();
        if (auth.getCurrentUser() == null) return;
        String uid = auth.getCurrentUser().getUid();
        FirebaseFirestore db = FirebaseFirestore.getInstance();
        db.collection("users").document(uid).get()
            .addOnSuccessListener(doc -> {
                if (doc.exists()) {
                    java.util.List<String> favs = (java.util.List<String>) doc.get("favorites");
                    if (favs != null) {
                        cachedFavorites = new java.util.HashSet<>(favs);
                    }
                }
                favoritesLoaded = true;
                notifyDataSetChanged();
            })
            .addOnFailureListener(e -> favoritesLoaded = true);
    }

    @NonNull
    @Override
    public PropertyViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        ItemPropertyBinding binding = ItemPropertyBinding.inflate(LayoutInflater.from(context), parent, false);
        if (isHorizontal) {
            ViewGroup.MarginLayoutParams params = (ViewGroup.MarginLayoutParams) binding.getRoot().getLayoutParams();
            params.width = (int) (260 * context.getResources().getDisplayMetrics().density);
            params.height = ViewGroup.LayoutParams.MATCH_PARENT;
            params.setMarginEnd((int) (12 * context.getResources().getDisplayMetrics().density));
            binding.getRoot().setLayoutParams(params);
        }
        return new PropertyViewHolder(binding);
    }

    @Override
    public void onBindViewHolder(@NonNull PropertyViewHolder holder, int position) {
        if (position >= properties.size()) return;
        Property property = properties.get(position);
        if (property == null) return;

        holder.binding.tvTitle.setText(property.getTitle());
        holder.binding.tvLocation.setText(property.getLocationString());
        holder.binding.tvPrice.setText(property.getFormattedPrice(context));
        holder.binding.tvPriceBadge.setText(property.getFormattedPrice(context));

        String priceLabel;
        switch (property.getOperationType()) {
            case "rent":
                priceLabel = context.getString(R.string.payment_monthly);
                break;
            default:
                priceLabel = property.getOperationTypeLabel(context);
                break;
        }
        holder.binding.tvPriceLabel.setText(priceLabel);

        String typeLabel = property.getTypeLabel(context);
        holder.binding.chipType.setText(typeLabel);

        switch (property.getOperationType()) {
            case "sell":
                holder.binding.chipType.setChipBackgroundColorResource(R.color.tag_sell);
                holder.binding.chipType.setTextColor(context.getColor(R.color.tag_sell_text));
                break;
            case "rent":
                holder.binding.chipType.setChipBackgroundColorResource(R.color.tag_rent);
                holder.binding.chipType.setTextColor(context.getColor(R.color.tag_rent_text));
                break;
            case "invest":
                holder.binding.chipType.setChipBackgroundColorResource(R.color.tag_invest);
                holder.binding.chipType.setTextColor(context.getColor(R.color.tag_invest_text));
                break;
        }

        double area = property.getArea();
        int rooms = property.getRooms();
        int bathrooms = property.getBathrooms();
        int floor = property.getFloor();

        holder.binding.tvArea.setText(context.getString(R.string.area_value, area));
        holder.binding.tvRooms.setText(context.getString(R.string.rooms_count_value, rooms));
        holder.binding.tvBathrooms.setText(context.getString(R.string.bathrooms_count_value, bathrooms));
        holder.binding.tvFloor.setText(context.getString(R.string.floor_value, floor));

        String imageUrl = property.getFirstImage();
        if (imageUrl != null && !imageUrl.isEmpty()) {
            Glide.with(context)
                .load(imageUrl)
                .override(600, 400)
                .placeholder(R.drawable.placeholder_property)
                .centerCrop()
                .into(holder.binding.ivPropertyImage);
        } else {
            holder.binding.ivPropertyImage.setImageResource(R.drawable.placeholder_property);
        }

        setupBadge(holder, property);
        setupDate(holder, property);
        setupCompareButton(holder, property);
        setupFavoriteButton(holder, property);

        holder.binding.ivShare.setOnClickListener(v -> {
            if (context == null || property == null) return;
            Intent share = new Intent(Intent.ACTION_SEND);
            share.setType("text/plain");
            share.putExtra(Intent.EXTRA_TEXT,
                property.getTitle() + "\n" +
                property.getFormattedPrice(context) + "\n" +
                property.getLocationString() + "\n" +
                context.getString(R.string.app_name));
            context.startActivity(Intent.createChooser(share, context.getString(R.string.share)));
        });

        holder.binding.getRoot().setOnClickListener(v -> {
            if (context == null) return;
            Intent intent = new Intent(context, PropertyDetailActivity.class);
            intent.putExtra(PropertyDetailActivity.EXTRA_PROPERTY_ID, property.getId());
            context.startActivity(intent);
        });
    }

    private void setupBadge(PropertyViewHolder holder, Property property) {
        if (property.isUrgent()) {
            holder.binding.chipBadge.setVisibility(View.VISIBLE);
            holder.binding.chipBadge.setText(context.getString(R.string.badge_urgent));
            holder.binding.chipBadge.setChipBackgroundColorResource(R.color.error);
        } else if (property.isFeatured()) {
            holder.binding.chipBadge.setVisibility(View.VISIBLE);
            holder.binding.chipBadge.setText(context.getString(R.string.badge_featured));
            holder.binding.chipBadge.setChipBackgroundColorResource(R.color.warning);
        } else if (property.isNewProperty()) {
            holder.binding.chipBadge.setVisibility(View.VISIBLE);
            holder.binding.chipBadge.setText(context.getString(R.string.badge_new));
            holder.binding.chipBadge.setChipBackgroundColorResource(R.color.accent);
        } else {
            holder.binding.chipBadge.setVisibility(View.GONE);
        }
    }

    private void setupDate(PropertyViewHolder holder, Property property) {
        String relativeTime = property.getRelativeTime(context);
        if (!relativeTime.isEmpty()) {
            holder.binding.tvDate.setVisibility(View.VISIBLE);
            holder.binding.tvDate.setText(relativeTime);
        } else {
            holder.binding.tvDate.setVisibility(View.GONE);
        }
    }

    private void setupCompareButton(PropertyViewHolder holder, Property property) {
        SharedPreferences prefs = context.getSharedPreferences(COMPARE_PREFS, Context.MODE_PRIVATE);
        Set<String> compareIds = prefs.getStringSet(COMPARE_IDS, new HashSet<>());
        boolean inCompare = compareIds.contains(property.getId());
        int compareColor = inCompare ? R.color.icon_compare_active : R.color.icon_default;
        holder.binding.ivCompare.setColorFilter(
            context.getColor(compareColor),
            android.graphics.PorterDuff.Mode.SRC_IN
        );
        holder.binding.ivCompare.setTag(inCompare);

        holder.binding.frameCompare.setOnClickListener(v -> {
            Set<String> current = prefs.getStringSet(COMPARE_IDS, new HashSet<>());
            Set<String> updated = new HashSet<>(current);
            if (updated.contains(property.getId())) {
                updated.remove(property.getId());
                holder.binding.ivCompare.setColorFilter(
                    context.getColor(R.color.icon_default),
                    android.graphics.PorterDuff.Mode.SRC_IN
                );
                holder.binding.ivCompare.setTag(false);
                Toast.makeText(context, context.getString(R.string.remove_from_compare), Toast.LENGTH_SHORT).show();
            } else {
                if (updated.size() >= 4) {
                    Toast.makeText(context, context.getString(R.string.compare_max), Toast.LENGTH_SHORT).show();
                    return;
                }
                updated.add(property.getId());
                holder.binding.ivCompare.setColorFilter(
                    context.getColor(R.color.icon_compare_active),
                    android.graphics.PorterDuff.Mode.SRC_IN
                );
                holder.binding.ivCompare.setTag(true);
                Toast.makeText(context, context.getString(R.string.add_to_compare), Toast.LENGTH_SHORT).show();
            }
            prefs.edit().putStringSet(COMPARE_IDS, updated).apply();
        });
    }

    private void setupFavoriteButton(PropertyViewHolder holder, Property property) {
        FirebaseAuth auth = FirebaseAuth.getInstance();
        if (auth.getCurrentUser() == null) {
            holder.binding.ivFavorite.setVisibility(View.GONE);
            return;
        }
        holder.binding.ivFavorite.setVisibility(View.VISIBLE);
        String uid = auth.getCurrentUser().getUid();
        FirebaseFirestore db = FirebaseFirestore.getInstance();

        boolean isFav = cachedFavorites.contains(property.getId());
        updateHeartIcon(holder, isFav);
        holder.binding.ivFavorite.setTag(isFav);

        holder.binding.ivFavorite.setOnClickListener(v -> {
            boolean isFavNow = holder.binding.ivFavorite.getTag() != null && (boolean) holder.binding.ivFavorite.getTag();
            if (!isFavNow && cachedFavorites.size() >= MAX_FAVORITES) {
                Toast.makeText(context, context.getString(R.string.favorites_max_limit), Toast.LENGTH_SHORT).show();
                return;
            }
            if (isFavNow) {
                db.collection("users").document(uid)
                    .update("favorites", FieldValue.arrayRemove(property.getId()))
                    .addOnSuccessListener(unused -> {
                        updateHeartIcon(holder, false);
                        holder.binding.ivFavorite.setTag(false);
                        cachedFavorites.remove(property.getId());
                    });
            } else {
                db.collection("users").document(uid)
                    .update("favorites", FieldValue.arrayUnion(property.getId()))
                    .addOnSuccessListener(unused -> {
                        updateHeartIcon(holder, true);
                        holder.binding.ivFavorite.setTag(true);
                        cachedFavorites.add(property.getId());
                    })
                    .addOnFailureListener(e -> {
                        java.util.Map<String, Object> data = new java.util.HashMap<>();
                        java.util.List<String> favs = new java.util.ArrayList<>();
                        favs.add(property.getId());
                        data.put("favorites", favs);
                        db.collection("users").document(uid)
                            .set(data, com.google.firebase.firestore.SetOptions.merge())
                            .addOnSuccessListener(unused -> {
                                updateHeartIcon(holder, true);
                                holder.binding.ivFavorite.setTag(true);
                                cachedFavorites.add(property.getId());
                            });
                    });
            }
        });
    }

    private void updateHeartIcon(PropertyViewHolder holder, boolean isFav) {
        if (isFav) {
            holder.binding.ivFavorite.setImageResource(R.drawable.ic_favorite_filled);
            holder.binding.ivFavorite.setColorFilter(
                context.getColor(R.color.icon_favorite_active),
                android.graphics.PorterDuff.Mode.SRC_IN
            );
        } else {
            holder.binding.ivFavorite.setImageResource(R.drawable.ic_favorite_border);
            holder.binding.ivFavorite.setColorFilter(
                android.graphics.Color.WHITE,
                android.graphics.PorterDuff.Mode.SRC_IN
            );
        }
    }

    @Override
    public int getItemCount() { return properties.size(); }

    public static class PropertyViewHolder extends RecyclerView.ViewHolder {
        ItemPropertyBinding binding;

        public PropertyViewHolder(@NonNull ItemPropertyBinding binding) {
            super(binding.getRoot());
            this.binding = binding;
        }
    }
}
