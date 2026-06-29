package com.aqarisyria.app.adapters;

import android.content.Context;
import android.content.Intent;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.cardview.widget.CardView;
import androidx.recyclerview.widget.RecyclerView;
import com.bumptech.glide.Glide;
import com.aqarisyria.app.R;
import com.aqarisyria.app.activities.PropertyDetailActivity;
import com.aqarisyria.app.models.Property;
import java.util.List;

public class PropertyAdapter extends RecyclerView.Adapter<PropertyAdapter.PropertyViewHolder> {

    private List<Property> properties;
    private Context context;

    public PropertyAdapter(List<Property> properties, Context context) {
        this.properties = properties;
        this.context = context;
    }

    @NonNull
    @Override
    public PropertyViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(context).inflate(R.layout.item_property, parent, false);
        return new PropertyViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull PropertyViewHolder holder, int position) {
        if (position >= properties.size()) return;
        Property property = properties.get(position);
        if (property == null) return;

        holder.tvTitle.setText(property.getTitle());
        holder.tvPrice.setText(property.getFormattedPrice());
        holder.tvLocation.setText(property.getLocationString());
        holder.tvOperationType.setText(property.getOperationTypeLabel());

        String details = "";
        if (property.getRooms() > 0) details += property.getRooms() + " غرف  ";
        if (property.getBathrooms() > 0) details += property.getBathrooms() + " حمام  ";
        if (property.getArea() > 0) details += property.getArea() + " م²";
        holder.tvDetails.setText(details.trim());

        switch (property.getOperationType()) {
            case "sell":
                holder.tvOperationType.setBackgroundResource(R.drawable.bg_tag_sell);
                holder.tvOperationType.setTextColor(context.getColor(R.color.primary));
                break;
            case "rent":
                holder.tvOperationType.setBackgroundResource(R.drawable.bg_tag_rent);
                holder.tvOperationType.setTextColor(context.getColor(R.color.accent));
                break;
            case "invest":
                holder.tvOperationType.setBackgroundResource(R.drawable.bg_tag_invest);
                holder.tvOperationType.setTextColor(context.getColor(R.color.warning));
                break;
        }

        String imageUrl = property.getFirstImage();
        if (imageUrl != null && !imageUrl.isEmpty()) {
            Glide.with(context)
                .load(imageUrl)
                .override(600, 400)
                .placeholder(R.drawable.placeholder_property)
                .centerCrop()
                .into(holder.ivPropertyImage);
        } else {
            holder.ivPropertyImage.setImageResource(R.drawable.placeholder_property);
        }

        holder.cardView.setOnClickListener(v -> {
            if (context == null) return;
            Intent intent = new Intent(context, PropertyDetailActivity.class);
            intent.putExtra(PropertyDetailActivity.EXTRA_PROPERTY_ID, property.getId());
            context.startActivity(intent);
        });
    }

    @Override
    public int getItemCount() { return properties.size(); }

    public static class PropertyViewHolder extends RecyclerView.ViewHolder {
        CardView cardView;
        ImageView ivPropertyImage;
        TextView tvTitle, tvPrice, tvLocation, tvDetails, tvOperationType;

        public PropertyViewHolder(@NonNull View itemView) {
            super(itemView);
            cardView = itemView.findViewById(R.id.cardView);
            ivPropertyImage = itemView.findViewById(R.id.ivPropertyImage);
            tvTitle = itemView.findViewById(R.id.tvTitle);
            tvPrice = itemView.findViewById(R.id.tvPrice);
            tvLocation = itemView.findViewById(R.id.tvLocation);
            tvDetails = itemView.findViewById(R.id.tvDetails);
            tvOperationType = itemView.findViewById(R.id.tvOperationType);
        }
    }
}
