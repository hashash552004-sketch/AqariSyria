package com.aqarisyria.app.activities;

import android.app.AlertDialog;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.view.Gravity;
import android.view.View;
import android.view.animation.Animation;
import android.view.animation.AnimationUtils;
import android.widget.FrameLayout;
import android.widget.GridLayout;
import android.widget.ImageView;

import androidx.appcompat.app.AppCompatActivity;
import androidx.core.content.ContextCompat;

import com.bumptech.glide.Glide;
import com.google.android.material.chip.Chip;
import com.google.android.material.chip.ChipGroup;
import com.google.android.material.snackbar.Snackbar;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.firestore.FieldValue;
import com.google.firebase.firestore.FirebaseFirestore;
import com.google.firebase.storage.FirebaseStorage;
import com.google.firebase.storage.StorageReference;

import com.aqarisyria.app.R;
import com.aqarisyria.app.databinding.ActivityAddPropertyBinding;
import com.aqarisyria.app.models.Property;

import java.text.DecimalFormat;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

public class AddPropertyActivity extends AppCompatActivity {

    private ActivityAddPropertyBinding binding;
    private FirebaseFirestore db;
    private FirebaseAuth mAuth;
    private FirebaseStorage storage;

    private int currentStep = 1;
    private static final int TOTAL_STEPS = 3;

    private String propertyType = "";
    private String operationType = "";
    private double price = 0;
    private double area = 0;
    private int rooms = 1;
    private int bathrooms = 1;
    private int floor = 1;
    private String city = "";
    private String address = "";

    private boolean hasElevator, hasParking, hasAC, hasHeating;
    private boolean hasGarden, hasPool, hasBalcony, hasInternet, hasGas, isFurnished;

    private List<Uri> selectedImages = new ArrayList<>();
    private List<String> uploadedImageUrls = new ArrayList<>();
    private static final int MAX_IMAGES = 10;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        binding = ActivityAddPropertyBinding.inflate(getLayoutInflater());
        setContentView(binding.getRoot());

        db = FirebaseFirestore.getInstance();
        mAuth = FirebaseAuth.getInstance();
        storage = FirebaseStorage.getInstance();

        if (mAuth.getCurrentUser() == null) {
            showDialog(getString(R.string.error_enter_email_first));
            finish();
            return;
        }

        setupListeners();
        updateStepUI();
    }

    private void setupListeners() {
        binding.btnBack.setOnClickListener(v -> handleBack());
        binding.btnBackStep.setOnClickListener(v -> handleBack());
        binding.btnNext.setOnClickListener(v -> handleNext());
        binding.btnAddImage.setOnClickListener(v -> pickImages());
        setupCounters();
    }

    private void setupCounters() {
        binding.btnRoomsMinus.setOnClickListener(v -> {
            if (rooms > 1) {
                rooms--;
                binding.tvRoomsCount.setText(String.valueOf(rooms));
            }
        });
        binding.btnRoomsPlus.setOnClickListener(v -> {
            if (rooms < 20) {
                rooms++;
                binding.tvRoomsCount.setText(String.valueOf(rooms));
            }
        });
        binding.btnBathroomsMinus.setOnClickListener(v -> {
            if (bathrooms > 1) {
                bathrooms--;
                binding.tvBathroomsCount.setText(String.valueOf(bathrooms));
            }
        });
        binding.btnBathroomsPlus.setOnClickListener(v -> {
            if (bathrooms < 20) {
                bathrooms++;
                binding.tvBathroomsCount.setText(String.valueOf(bathrooms));
            }
        });
    }

    private void handleNext() {
        if (!validateCurrentStep()) return;
        collectCurrentStepData();
        if (currentStep < TOTAL_STEPS) {
            animateSlideOut(binding.getRoot().findViewById(
                currentStep == 1 ? R.id.step1Container :
                currentStep == 2 ? R.id.step2Container : R.id.step3Container), true);
            currentStep++;
            animateSlideIn(binding.getRoot().findViewById(
                currentStep == 1 ? R.id.step1Container :
                currentStep == 2 ? R.id.step2Container : R.id.step3Container), false);
            updateStepUI();
        } else {
            submitProperty();
        }
    }

    private void handleBack() {
        if (currentStep > 1) {
            animateSlideOut(binding.getRoot().findViewById(
                currentStep == 1 ? R.id.step1Container :
                currentStep == 2 ? R.id.step2Container : R.id.step3Container), false);
            currentStep--;
            animateSlideIn(binding.getRoot().findViewById(
                currentStep == 1 ? R.id.step1Container :
                currentStep == 2 ? R.id.step2Container : R.id.step3Container), true);
            updateStepUI();
        } else {
            finish();
        }
    }

    private void animateSlideOut(View view, boolean toLeft) {
        if (view == null) return;
        Animation anim = AnimationUtils.loadAnimation(this,
            toLeft ? R.anim.slide_out_left : R.anim.slide_out_right);
        view.startAnimation(anim);
        view.setVisibility(View.GONE);
    }

    private void animateSlideIn(View view, boolean fromLeft) {
        if (view == null) return;
        Animation anim = AnimationUtils.loadAnimation(this,
            fromLeft ? R.anim.slide_in_left : R.anim.slide_in_right);
        view.startAnimation(anim);
        view.setVisibility(View.VISIBLE);
    }

    private boolean validateCurrentStep() {
        switch (currentStep) {
            case 1:
                String title = binding.etTitle.getText().toString().trim();
                if (title.isEmpty()) {
                    binding.tilTitle.setError(getString(R.string.error_title_required));
                    binding.etTitle.requestFocus();
                    return false;
                }
                binding.tilTitle.setError(null);

                Chip selectedType = findViewById(binding.chipGroupPropertyType.getCheckedChipId());
                if (selectedType == null) {
                    showSnackbar(getString(R.string.required_field));
                    return false;
                }

                Chip selectedOp = findViewById(binding.chipGroupOperationType.getCheckedChipId());
                if (selectedOp == null) {
                    showSnackbar(getString(R.string.required_field));
                    return false;
                }

                String priceStr = binding.etPrice.getText().toString().trim();
                if (priceStr.isEmpty() || Double.parseDouble(priceStr) <= 0) {
                    binding.tilPrice.setError(getString(R.string.error_price_positive));
                    binding.etPrice.requestFocus();
                    return false;
                }
                binding.tilPrice.setError(null);
                return true;

            case 2:
                String areaStr = binding.etArea.getText().toString().trim();
                if (areaStr.isEmpty() || Double.parseDouble(areaStr) <= 0) {
                    binding.tilArea.setError(getString(R.string.error_area_positive));
                    binding.etArea.requestFocus();
                    return false;
                }
                binding.tilArea.setError(null);

                if (binding.etCity.getText().toString().trim().isEmpty()) {
                    binding.tilCity.setError(getString(R.string.required_field));
                    binding.etCity.requestFocus();
                    return false;
                }
                binding.tilCity.setError(null);
                return true;

            case 3:
                if (selectedImages.isEmpty()) {
                    showSnackbar(getString(R.string.error_at_least_one_image));
                    return false;
                }
                return true;

            default:
                return true;
        }
    }

    private void collectCurrentStepData() {
        switch (currentStep) {
            case 1:
                int checkedTypeId = binding.chipGroupPropertyType.getCheckedChipId();
                if (checkedTypeId != View.NO_ID) {
                    Chip typeChip = findViewById(checkedTypeId);
                    if (typeChip != null) {
                        propertyType = getPropertyTypeValue(typeChip.getText().toString());
                    }
                }
                int checkedOpId = binding.chipGroupOperationType.getCheckedChipId();
                if (checkedOpId != View.NO_ID) {
                    Chip opChip = findViewById(checkedOpId);
                    if (opChip != null) {
                        operationType = getOperationTypeValue(opChip.getText().toString());
                    }
                }
                try {
                    price = Double.parseDouble(binding.etPrice.getText().toString().trim().replace(",", ""));
                } catch (NumberFormatException e) {
                    price = 0;
                }
                break;

            case 2:
                try {
                    area = Double.parseDouble(binding.etArea.getText().toString().trim());
                } catch (NumberFormatException e) {
                    area = 0;
                }
                try {
                    floor = Integer.parseInt(binding.etFloor.getText().toString().trim());
                } catch (NumberFormatException e) {
                    floor = 1;
                }
                address = binding.etAddress.getText().toString().trim();
                city = binding.etCity.getText().toString().trim();

                hasElevator = binding.chipElevator.isChecked();
                hasParking = binding.chipParking.isChecked();
                hasAC = binding.chipAC.isChecked();
                hasHeating = binding.chipHeating.isChecked();
                hasGarden = binding.chipGarden.isChecked();
                hasPool = binding.chipPool.isChecked();
                hasBalcony = binding.chipBalcony.isChecked();
                hasInternet = binding.chipInternet.isChecked();
                hasGas = binding.chipGas.isChecked();
                isFurnished = binding.chipFurnished.isChecked();
                break;

            case 3:
                break;
        }
    }

    private String getPropertyTypeValue(String label) {
        if (getString(R.string.category_apartment).equals(label)) return "apartment";
        if (getString(R.string.category_villa).equals(label)) return "villa";
        if (getString(R.string.category_house).equals(label)) return "house";
        if (getString(R.string.category_land).equals(label)) return "land";
        if (getString(R.string.category_shop).equals(label)) return "shop";
        if (getString(R.string.category_warehouse).equals(label)) return "warehouse";
        return "apartment";
    }

    private String getOperationTypeValue(String label) {
        if (getString(R.string.for_sale).equals(label)) return "sell";
        if (getString(R.string.for_rent).equals(label)) return "rent";
        if (getString(R.string.for_invest).equals(label)) return "invest";
        return "sell";
    }

    private void updateStepUI() {
        binding.step1Container.setVisibility(currentStep == 1 ? View.VISIBLE : View.GONE);
        binding.step2Container.setVisibility(currentStep == 2 ? View.VISIBLE : View.GONE);
        binding.step3Container.setVisibility(currentStep == 3 ? View.VISIBLE : View.GONE);

        binding.tvStepCounter.setText(getString(R.string.step_x_of_y, currentStep, TOTAL_STEPS));
        updateStepIndicator();

        boolean isFirstStep = currentStep == 1;
        binding.btnBack.setVisibility(isFirstStep ? View.VISIBLE : View.GONE);
        binding.btnBackStep.setVisibility(isFirstStep ? View.GONE : View.VISIBLE);

        if (currentStep == TOTAL_STEPS) {
            binding.btnNext.setText(getString(R.string.publish_listing));
            binding.btnNext.setBackgroundTintList(ContextCompat.getColorStateList(this, R.color.accent));
            updateReviewSummary();
        } else {
            binding.btnNext.setText(getString(R.string.next));
            binding.btnNext.setBackgroundTintList(ContextCompat.getColorStateList(this, R.color.primary));
        }
    }

    private void updateStepIndicator() {
        for (int i = 1; i <= TOTAL_STEPS; i++) {
            TextView dot = getStepDot(i);
            TextView label = getStepLabel(i);
            if (dot == null || label == null) continue;

            if (i == currentStep) {
                dot.setBackgroundResource(R.drawable.bg_step_active);
                dot.setTextColor(ContextCompat.getColor(this, R.color.text_white));
                label.setTextColor(ContextCompat.getColor(this, R.color.text_white));
            } else if (i < currentStep) {
                dot.setBackgroundResource(R.drawable.bg_step_completed);
                dot.setTextColor(ContextCompat.getColor(this, R.color.text_white));
                label.setTextColor(ContextCompat.getColor(this, R.color.text_white));
            } else {
                dot.setBackgroundResource(R.drawable.bg_step_inactive);
                dot.setTextColor(ContextCompat.getColor(this, R.color.text_hint));
                label.setTextColor(ContextCompat.getColor(this, R.color.text_hint));
            }
        }

        View line1 = findViewById(R.id.stepLine1);
        View line2 = findViewById(R.id.stepLine2);
        if (line1 != null) {
            line1.setBackgroundColor(ContextCompat.getColor(this,
                currentStep > 1 ? R.color.accent : R.color.border));
        }
        if (line2 != null) {
            line2.setBackgroundColor(ContextCompat.getColor(this,
                currentStep > 2 ? R.color.accent : R.color.border));
        }
    }

    private TextView getStepDot(int step) {
        switch (step) {
            case 1: return findViewById(R.id.stepDot1);
            case 2: return findViewById(R.id.stepDot2);
            case 3: return findViewById(R.id.stepDot3);
            default: return null;
        }
    }

    private TextView getStepLabel(int step) {
        switch (step) {
            case 1: return findViewById(R.id.tvStepLabel1);
            case 2: return findViewById(R.id.tvStepLabel2);
            case 3: return findViewById(R.id.tvStepLabel3);
            default: return null;
        }
    }

    private void updateReviewSummary() {
        String title = binding.etTitle.getText().toString().trim();
        binding.tvReviewTitle.setText(title.isEmpty() ? getString(R.string.add_property) : title);

        StringBuilder typeInfo = new StringBuilder();
        Chip typeChip = findViewById(binding.chipGroupPropertyType.getCheckedChipId());
        if (typeChip != null) typeInfo.append(typeChip.getText()).append(" - ");
        Chip opChip = findViewById(binding.chipGroupOperationType.getCheckedChipId());
        if (opChip != null) typeInfo.append(opChip.getText());
        if (!city.isEmpty()) typeInfo.append(" - ").append(city);
        binding.tvReviewType.setText(typeInfo.toString());

        DecimalFormat df = new DecimalFormat("#,##0");
        binding.tvReviewPrice.setText(df.format(price) + " $");
    }

    private void pickImages() {
        if (selectedImages.size() >= MAX_IMAGES) {
            showSnackbar(getString(R.string.add_images) + " (" + MAX_IMAGES + ")");
            return;
        }
        Intent intent = new Intent(Intent.ACTION_GET_CONTENT);
        intent.setType("image/*");
        intent.putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true);
        imagePickerLauncher.launch(intent);
    }

    private final androidx.activity.result.ActivityResultLauncher<Intent> imagePickerLauncher =
        registerForActivityResult(
            new androidx.activity.result.contract.ActivityResultContracts.StartActivityForResult(),
            result -> {
                if (result.getResultCode() == RESULT_OK && result.getData() != null) {
                    Intent data = result.getData();
                    int existingCount = selectedImages.size();
                    if (data.getClipData() != null) {
                        int count = data.getClipData().getItemCount();
                        int maxNew = MAX_IMAGES - existingCount;
                        int toAdd = Math.min(count, maxNew);
                        for (int i = 0; i < toAdd; i++) {
                            selectedImages.add(data.getClipData().getItemAt(i).getUri());
                        }
                    } else if (data.getData() != null) {
                        if (existingCount < MAX_IMAGES) {
                            selectedImages.add(data.getData());
                        }
                    }
                    updateImageGrid();
                }
            });

    private void updateImageGrid() {
        binding.gridImages.removeAllViews();
        binding.gridImages.addView(binding.btnAddImage);

        for (int i = 0; i < selectedImages.size(); i++) {
            Uri uri = selectedImages.get(i);
            int index = i;

            FrameLayout frame = new FrameLayout(this);
            GridLayout.LayoutParams params = new GridLayout.LayoutParams();
            params.width = 0;
            params.height = 200;
            params.columnSpec = GridLayout.spec(GridLayout.UNDEFINED, 1f);
            params.rowSpec = GridLayout.spec(GridLayout.UNDEFINED, 1f);
            params.setMargins(8, 8, 8, 8);
            frame.setLayoutParams(params);

            ImageView imageView = new ImageView(this);
            imageView.setLayoutParams(new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT));
            imageView.setScaleType(ImageView.ScaleType.CENTER_CROP);

            Glide.with(this)
                .load(uri)
                .centerCrop()
                .into(imageView);

            ImageView btnDelete = new ImageView(this);
            FrameLayout.LayoutParams delParams = new FrameLayout.LayoutParams(36, 36);
            delParams.gravity = Gravity.TOP | Gravity.END;
            delParams.setMargins(0, 8, 8, 0);
            btnDelete.setLayoutParams(delParams);
            btnDelete.setImageResource(R.drawable.ic_close);
            btnDelete.setBackgroundResource(R.drawable.bg_white_circle);
            btnDelete.setPadding(6, 6, 6, 6);
            btnDelete.setOnClickListener(v -> {
                selectedImages.remove(index);
                updateImageGrid();
            });

            frame.addView(imageView);
            frame.addView(btnDelete);
            binding.gridImages.addView(frame, binding.gridImages.getChildCount() - 1);
        }

        binding.tvImageCount.setText(selectedImages.size() + " / " + MAX_IMAGES);
    }

    private void submitProperty() {
        binding.btnNext.setEnabled(false);
        binding.loadingOverlay.setVisibility(View.VISIBLE);
        binding.tvUploadProgress.setText(R.string.publish);

        if (selectedImages.isEmpty()) {
            savePropertyToFirestore(new ArrayList<>());
        } else {
            uploadImages();
        }
    }

    private void uploadImages() {
        uploadedImageUrls.clear();
        String uid = mAuth.getCurrentUser().getUid();
        String propertyFolder = "properties/" + uid + "/" + UUID.randomUUID();
        int[] completedCount = {0};

        for (Uri uri : selectedImages) {
            String fileName = UUID.randomUUID() + ".jpg";
            StorageReference ref = storage.getReference()
                .child(propertyFolder)
                .child(fileName);

            ref.putFile(uri)
                .continueWithTask(task -> {
                    if (!task.isSuccessful()) {
                        throw task.getException();
                    }
                    return ref.getDownloadUrl();
                })
                .addOnSuccessListener(downloadUri -> {
                    uploadedImageUrls.add(downloadUri.toString());
                    completedCount[0]++;
                    if (completedCount[0] == selectedImages.size()) {
                        savePropertyToFirestore(uploadedImageUrls);
                    }
                })
                .addOnFailureListener(e -> {
                    completedCount[0]++;
                    if (completedCount[0] == selectedImages.size()) {
                        if (uploadedImageUrls.isEmpty()) {
                            showSnackbar(getString(R.string.error_general));
                            resetLoadingState();
                        } else {
                            savePropertyToFirestore(uploadedImageUrls);
                        }
                    }
                });
        }
    }

    private void resetLoadingState() {
        if (isFinishing() || isDestroyed()) return;
        binding.btnNext.setEnabled(true);
        binding.loadingOverlay.setVisibility(View.GONE);
    }

    private void savePropertyToFirestore(List<String> imageUrls) {
        String uid = mAuth.getCurrentUser().getUid();
        String title = binding.etTitle.getText().toString().trim();
        String description = binding.etDescription.getText().toString().trim();

        Property prop = new Property(title, description, propertyType, operationType,
            price, area, rooms, bathrooms, floor,
            city, address, "", "",
            uid, "", "");

        prop.setImages(imageUrls);
        prop.setHasElevator(hasElevator);
        prop.setHasParking(hasParking);
        prop.setHasAC(hasAC);
        prop.setHasHeating(hasHeating);
        prop.setHasGarden(hasGarden);
        prop.setHasPool(hasPool);
        prop.setHasBalcony(hasBalcony);
        prop.setHasInternet(hasInternet);
        prop.setHasGas(hasGas);
        prop.setFurnished(isFurnished);
        prop.setActive(true);

        db.collection("properties").add(prop)
            .addOnSuccessListener(ref -> {
                if (isFinishing() || isDestroyed()) return;
                Intent resultIntent = new Intent();
                resultIntent.putExtra("property_id", ref.getId());
                setResult(RESULT_OK, resultIntent);
                showDialog(getString(R.string.property_published));
                finish();
            })
            .addOnFailureListener(e -> {
                if (isFinishing() || isDestroyed()) return;
                resetLoadingState();
                showSnackbar(getString(R.string.error_general) + ": " + e.getMessage());
            });
    }

    private void showDialog(String message) {
        if (isFinishing() || isDestroyed()) return;
        new AlertDialog.Builder(this)
            .setTitle(R.string.add_property)
            .setMessage(message)
            .setPositiveButton(R.string.ok, null)
            .show();
    }

    private void showSnackbar(String message) {
        if (isFinishing() || isDestroyed()) return;
        Snackbar.make(binding.getRoot(), message, Snackbar.LENGTH_SHORT).show();
    }
}
