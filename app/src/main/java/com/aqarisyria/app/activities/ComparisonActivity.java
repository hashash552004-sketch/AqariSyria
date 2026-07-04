package com.aqarisyria.app.activities;

import android.content.Context;
import android.content.SharedPreferences;
import android.graphics.Typeface;
import android.os.Bundle;
import android.view.Gravity;
import android.view.View;
import android.widget.ImageView;
import android.widget.TableLayout;
import android.widget.TableRow;
import android.widget.TextView;

import androidx.appcompat.app.AppCompatActivity;
import androidx.core.content.res.ResourcesCompat;

import com.bumptech.glide.Glide;
import com.google.firebase.firestore.FirebaseFirestore;
import com.aqarisyria.app.R;
import com.aqarisyria.app.databinding.ActivityComparisonBinding;
import com.aqarisyria.app.models.Property;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

public class ComparisonActivity extends AppCompatActivity {

    private ActivityComparisonBinding binding;
    private FirebaseFirestore db;
    private List<Property> compareList = new ArrayList<>();

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        binding = ActivityComparisonBinding.inflate(getLayoutInflater());
        setContentView(binding.getRoot());

        db = FirebaseFirestore.getInstance();

        binding.btnBack.setOnClickListener(v -> finish());
        binding.btnClear.setOnClickListener(v -> clearCompare());

        loadComparedProperties();
    }

    private void loadComparedProperties() {
        SharedPreferences prefs = getSharedPreferences("compare_prefs", Context.MODE_PRIVATE);
        Set<String> ids = prefs.getStringSet("compare_ids", new HashSet<>());

        if (ids.isEmpty()) {
            binding.progressBar.setVisibility(View.GONE);
            binding.tvEmpty.setVisibility(View.VISIBLE);
            return;
        }

        binding.progressBar.setVisibility(View.VISIBLE);
        compareList.clear();

        final int[] loaded = {0};
        int total = ids.size();

        for (String id : ids) {
            db.collection("properties").document(id).get()
                .addOnSuccessListener(doc -> {
                    Property p = doc.toObject(Property.class);
                    if (p != null) {
                        p.setId(doc.getId());
                        compareList.add(p);
                    }
                    loaded[0]++;
                    if (loaded[0] >= total) {
                        binding.progressBar.setVisibility(View.GONE);
                        buildComparisonTable();
                    }
                })
                .addOnFailureListener(e -> {
                    loaded[0]++;
                    if (loaded[0] >= total) {
                        binding.progressBar.setVisibility(View.GONE);
                        buildComparisonTable();
                    }
                });
        }
    }

    private void buildComparisonTable() {
        binding.tableCompare.removeAllViews();

        if (compareList.isEmpty()) {
            binding.tvEmpty.setVisibility(View.VISIBLE);
            return;
        }

        binding.tvEmpty.setVisibility(View.GONE);

        int cellWidth = (int) (180 * getResources().getDisplayMetrics().density);

        addImageRow(cellWidth);
        addTextRow(getString(R.string.compare_price_label), p -> p.getFormattedPrice(ComparisonActivity.this), cellWidth);
        addTextRow(getString(R.string.compare_type_label), Property::getTypeLabel, cellWidth);
        addTextRow(getString(R.string.compare_operation_label), Property::getOperationTypeLabel, cellWidth);
        addTextRow(getString(R.string.compare_area_label), p -> String.format(getString(R.string.area_value), p.getArea()), cellWidth);
        addTextRow(getString(R.string.compare_rooms_label), p -> String.valueOf(p.getRooms()), cellWidth);
        addTextRow(getString(R.string.compare_bathrooms_label), p -> String.valueOf(p.getBathrooms()), cellWidth);
        addTextRow(getString(R.string.compare_floor_label), p -> String.valueOf(p.getFloor()), cellWidth);
        addTextRow(getString(R.string.compare_location_label), Property::getLocationString, cellWidth);
        addTextRow(getString(R.string.compare_furnished_label), p -> p.isFurnished() ? getString(R.string.compare_yes) : getString(R.string.compare_no), cellWidth);
    }

    private void addImageRow(int cellWidth) {
        TableRow row = new TableRow(this);
        row.setPadding(0, 0, 0, 12);

        TextView label = createCell(getString(R.string.compare_spec), true, cellWidth);
        row.addView(label);

        for (Property p : compareList) {
            ImageView imageView = new ImageView(this);
            imageView.setLayoutParams(new TableRow.LayoutParams(cellWidth, (int) (120 * getResources().getDisplayMetrics().density)));
            imageView.setScaleType(ImageView.ScaleType.CENTER_CROP);
            imageView.setPadding(4, 0, 4, 0);

            String url = p.getFirstImage();
            if (url != null) {
                Glide.with(this).load(url).centerCrop().into(imageView);
            } else {
                imageView.setImageResource(R.drawable.placeholder_property);
            }
            row.addView(imageView);
        }
        binding.tableCompare.addView(row);
    }

    private void addTextRow(String label, java.util.function.Function<Property, String> extractor, int cellWidth) {
        TableRow row = new TableRow(this);

        TextView labelCell = createCell(label, true, cellWidth);
        row.addView(labelCell);

        for (Property p : compareList) {
            String value = extractor.apply(p);
            TextView cell = createCell(value, false, cellWidth);
            row.addView(cell);
        }
        binding.tableCompare.addView(row);
    }

    private TextView createCell(String text, boolean isHeader, int width) {
        TextView tv = new TextView(this);
        TableRow.LayoutParams params = new TableRow.LayoutParams(width, TableRow.LayoutParams.WRAP_CONTENT);
        params.setMargins(4, 4, 4, 4);
        tv.setLayoutParams(params);
        tv.setText(text != null ? text : getString(R.string.feature_not_available));
        tv.setTextSize(isHeader ? 13 : 12);
        tv.setGravity(Gravity.CENTER);
        tv.setPadding(12, 14, 12, 14);
        tv.setTypeface(null, isHeader ? Typeface.BOLD : Typeface.NORMAL);

        if (isHeader) {
            tv.setTextColor(ResourcesCompat.getColor(getResources(), R.color.text_primary, null));
            tv.setBackgroundResource(R.drawable.bg_price_badge);
        } else {
            tv.setTextColor(ResourcesCompat.getColor(getResources(), R.color.text_secondary, null));
            tv.setBackgroundResource(R.color.surface);
        }
        return tv;
    }

    private void clearCompare() {
        SharedPreferences prefs = getSharedPreferences("compare_prefs", Context.MODE_PRIVATE);
        prefs.edit().putStringSet("compare_ids", new HashSet<>()).apply();
        compareList.clear();
        binding.tableCompare.removeAllViews();
        binding.tvEmpty.setVisibility(View.VISIBLE);
    }
}
