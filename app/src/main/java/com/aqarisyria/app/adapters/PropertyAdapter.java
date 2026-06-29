package com.aqarisyria.app.adapters;

import android.content.Context;
import android.content.Intent;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import com.bumptech.glide.Glide;
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
            ViewGroup.LayoutParams params = binding.getRoot().getLayoutParams();
            params.width = (int) (280 * context.getResources().getDisplayMetrics().density);
            params.height = ViewGroup.LayoutParams.MATCH_PARENT;
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

        String ownerName = property.getOwnerName();
        if (ownerName != null && !ownerName.isEmpty()) {
            holder.binding.tvOwnerName.setText(ownerName);
        } else {
            holder.binding.tvOwnerName.setText(context.getString(R.string.app_name));
        }

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

        holder.binding.getRoot().setOnClickListener(v -> {
            if (context == null) return;
            Intent intent = new Intent(context, PropertyDetailActivity.class);
            intent.putExtra(PropertyDetailActivity.EXTRA_PROPERTY_ID, property.getId());
            context.startActivity(intent);
        });
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
