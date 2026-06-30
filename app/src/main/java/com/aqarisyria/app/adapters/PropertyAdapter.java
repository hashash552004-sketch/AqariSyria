package com.aqarisyria.app.adapters;

import android.content.Context;
import android.content.Intent;
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
import java.util.List;

public class PropertyAdapter extends RecyclerView.Adapter<PropertyAdapter.PropertyViewHolder> {

    private List<Property> properties;
    private Context context;
    private boolean isHorizontal;

    public PropertyAdapter(List<Property> properties, Context context) {
        this(properties, context, false);
    }

    public PropertyAdapter(List<Property> properties, Context context, boolean isHorizontal) {
        this.properties = properties;
        this.context = context;
        this.isHorizontal = isHorizontal;
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
        holder.binding.tvPrice.setText(property.getFormattedPrice());
        holder.binding.tvPriceBadge.setText(property.getFormattedPrice());

        String priceLabel;
        switch (property.getOperationType()) {
            case "rent":
                priceLabel = context.getString(R.string.payment_monthly);
                break;
            default:
                priceLabel = property.getOperationTypeLabel();
                break;
        }
        holder.binding.tvPriceLabel.setText(priceLabel);

        String typeLabel = property.getTypeLabel();
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

        setupFavoriteButton(holder, property);

        holder.binding.ivShare.setOnClickListener(v -> {
            if (context == null || property == null) return;
            Intent share = new Intent(Intent.ACTION_SEND);
            share.setType("text/plain");
            share.putExtra(Intent.EXTRA_TEXT,
                property.getTitle() + "\n" +
                property.getFormattedPrice() + "\n" +
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

    private void setupFavoriteButton(PropertyViewHolder holder, Property property) {
        FirebaseAuth auth = FirebaseAuth.getInstance();
        if (auth.getCurrentUser() == null) {
            holder.binding.ivFavorite.setVisibility(View.GONE);
            return;
        }
        holder.binding.ivFavorite.setVisibility(View.VISIBLE);
        String uid = auth.getCurrentUser().getUid();
        FirebaseFirestore db = FirebaseFirestore.getInstance();

        db.collection("users").document(uid).get()
            .addOnSuccessListener(doc -> {
                if (doc.exists()) {
                    java.util.List<String> favs = (java.util.List<String>) doc.get("favorites");
                    boolean isFav = favs != null && favs.contains(property.getId());
                    updateHeartIcon(holder, isFav);
                    holder.binding.ivFavorite.setTag(isFav);
                }
            });

        holder.binding.ivFavorite.setOnClickListener(v -> {
            boolean isFav = holder.binding.ivFavorite.getTag() != null && (boolean) holder.binding.ivFavorite.getTag();
            if (isFav) {
                db.collection("users").document(uid)
                    .update("favorites", FieldValue.arrayRemove(property.getId()))
                    .addOnSuccessListener(unused -> {
                        updateHeartIcon(holder, false);
                        holder.binding.ivFavorite.setTag(false);
                    });
            } else {
                db.collection("users").document(uid)
                    .update("favorites", FieldValue.arrayUnion(property.getId()))
                    .addOnSuccessListener(unused -> {
                        updateHeartIcon(holder, true);
                        holder.binding.ivFavorite.setTag(true);
                    })
                    .addOnFailureListener(e -> {
                        db.collection("users").document(uid)
                            .set(new java.util.HashMap<String, Object>() {{
                                put("favorites", new java.util.ArrayList<String>() {{
                                    add(property.getId());
                                }});
                            }}, com.google.firebase.firestore.SetOptions.merge())
                            .addOnSuccessListener(unused -> {
                                updateHeartIcon(holder, true);
                                holder.binding.ivFavorite.setTag(true);
                            });
                    });
            }
        });
    }

    private void updateHeartIcon(PropertyViewHolder holder, boolean isFav) {
        if (isFav) {
            holder.binding.ivFavorite.setImageResource(R.drawable.ic_favorite_filled);
            holder.binding.ivFavorite.setColorFilter(
                android.graphics.Color.parseColor("#F44336"),
                android.graphics.PorterDuff.Mode.SRC_IN
            );
            holder.binding.ivFavorite.getBackground().setTint(android.graphics.Color.WHITE);
        } else {
            holder.binding.ivFavorite.setImageResource(R.drawable.ic_favorite_border);
            holder.binding.ivFavorite.setColorFilter(
                android.graphics.Color.WHITE,
                android.graphics.PorterDuff.Mode.SRC_IN
            );
            holder.binding.ivFavorite.getBackground().setTint(android.graphics.Color.WHITE);
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
