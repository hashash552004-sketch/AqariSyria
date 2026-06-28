package com.aqarisyria.app.activities;

import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.view.View;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.firestore.FirebaseFirestore;
import com.google.firebase.storage.FirebaseStorage;
import com.google.firebase.storage.StorageReference;
import com.aqarisyria.app.R;
import com.aqarisyria.app.databinding.ActivityAddPropertyBinding;
import com.aqarisyria.app.models.Property;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

public class AddPropertyActivity extends AppCompatActivity {

    private static final int PICK_IMAGES_REQUEST = 100;
    private ActivityAddPropertyBinding binding;
    private FirebaseFirestore db;
    private FirebaseAuth mAuth;
    private FirebaseStorage storage;

    private int currentStep = 1;
    private static final int TOTAL_STEPS = 5;

    // Property data
    private String operationType = "";
    private String propertyType = "";
    private String governorate = "";
    private String region = "";
    private String neighborhood = "";
    private String detailedAddress = "";
    private double price = 0;
    private double area = 0;
    private int rooms = 1;
    private int bathrooms = 1;
    private int floor = 1;
    private String description = "";
    private boolean hasElevator, hasParking, hasAC, hasHeating;
    private boolean hasGarden, hasPool, hasBalcony, hasInternet, hasGas, isFurnished;
    private List<Uri> selectedImages = new ArrayList<>();
    private List<String> uploadedImageUrls = new ArrayList<>();

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        binding = ActivityAddPropertyBinding.inflate(getLayoutInflater());
        setContentView(binding.getRoot());

        db = FirebaseFirestore.getInstance();
        mAuth = FirebaseAuth.getInstance();
        storage = FirebaseStorage.getInstance();

        if (mAuth.getCurrentUser() == null) {
            Toast.makeText(this, "يجب تسجيل الدخول لإضافة عقار", Toast.LENGTH_SHORT).show();
            finish();
            return;
        }

        setupStep1();
        setupStep2();
        setupStep3Counters();

        binding.btnBack.setOnClickListener(v -> handleBack());
        binding.btnNext.setOnClickListener(v -> handleNext());
        updateStepUI();
    }

    private void setupStep1() {
        binding.btnOperationSell.setOnClickListener(v -> selectOperation("sell"));
        binding.btnOperationRent.setOnClickListener(v -> selectOperation("rent"));
        binding.btnOperationInvest.setOnClickListener(v -> selectOperation("invest"));
    }

    private void setupStep2() {
        String[] types = getResources().getStringArray(R.array.property_types);
        ArrayAdapter<String> typeAdapter = new ArrayAdapter<>(this,
            android.R.layout.simple_spinner_item, types);
        typeAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        binding.spinnerPropertyType.setAdapter(typeAdapter);

        String[] govs = getResources().getStringArray(R.array.governorates);
        ArrayAdapter<String> govAdapter = new ArrayAdapter<>(this,
            android.R.layout.simple_spinner_item, govs);
        govAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        binding.spinnerGovernorate.setAdapter(govAdapter);
    }

    private void setupStep3Counters() {
        // Rooms
        binding.btnRoomsMinus.setOnClickListener(v -> {
            if (rooms > 1) { rooms--; binding.tvRoomsCount.setText(String.valueOf(rooms)); }
        });
        binding.btnRoomsPlus.setOnClickListener(v -> {
            rooms++; binding.tvRoomsCount.setText(String.valueOf(rooms));
        });

        // Bathrooms
        binding.btnBathroomsMinus.setOnClickListener(v -> {
            if (bathrooms > 1) { bathrooms--; binding.tvBathroomsCount.setText(String.valueOf(bathrooms)); }
        });
        binding.btnBathroomsPlus.setOnClickListener(v -> {
            bathrooms++; binding.tvBathroomsCount.setText(String.valueOf(bathrooms));
        });

        // Floor
        binding.btnFloorMinus.setOnClickListener(v -> {
            if (floor > 1) { floor--; binding.tvFloorCount.setText(String.valueOf(floor)); }
        });
        binding.btnFloorPlus.setOnClickListener(v -> {
            floor++; binding.tvFloorCount.setText(String.valueOf(floor));
        });
    }

    private void selectOperation(String type) {
        operationType = type;
        binding.btnOperationSell.setBackgroundTintList(
            type.equals("sell") ? getColorStateList(R.color.primary) :
            getColorStateList(R.color.primary_light));
        binding.btnOperationRent.setBackgroundTintList(
            type.equals("rent") ? getColorStateList(R.color.primary) :
            getColorStateList(R.color.primary_light));
        binding.btnOperationInvest.setBackgroundTintList(
            type.equals("invest") ? getColorStateList(R.color.primary) :
            getColorStateList(R.color.primary_light));
    }

    private void handleNext() {
        if (!validateCurrentStep()) return;
        collectCurrentStepData();
        if (currentStep < TOTAL_STEPS) {
            currentStep++;
            updateStepUI();
        } else {
            submitProperty();
        }
    }

    private void handleBack() {
        if (currentStep > 1) { currentStep--; updateStepUI(); }
        else { finish(); }
    }

    private boolean validateCurrentStep() {
        switch (currentStep) {
            case 1:
                if (operationType.isEmpty()) {
                    Toast.makeText(this, "اختر نوع العملية", Toast.LENGTH_SHORT).show();
                    return false;
                }
                return true;
            case 2:
                if (binding.spinnerPropertyType.getSelectedItemPosition() == 0) {
                    Toast.makeText(this, "اختر نوع العقار", Toast.LENGTH_SHORT).show();
                    return false;
                }
                if (binding.spinnerGovernorate.getSelectedItemPosition() == 0) {
                    Toast.makeText(this, "اختر المحافظة", Toast.LENGTH_SHORT).show();
                    return false;
                }
                return true;
            case 3:
                String priceStr = binding.etPrice.getText().toString().trim();
                if (priceStr.isEmpty()) {
                    binding.tilPrice.setError("أدخل السعر");
                    return false;
                }
                return true;
            default:
                return true;
        }
    }

    private void collectCurrentStepData() {
        switch (currentStep) {
            case 2:
                String[] typeValues = {"", "apartment", "land", "villa", "office", "shop", "farm"};
                int idx = binding.spinnerPropertyType.getSelectedItemPosition();
                if (idx > 0 && idx < typeValues.length) propertyType = typeValues[idx];
                governorate = binding.spinnerGovernorate.getSelectedItem().toString();
                region = binding.etRegion.getText().toString().trim();
                neighborhood = binding.etNeighborhood.getText().toString().trim();
                detailedAddress = binding.etDetailedAddress.getText().toString().trim();
                break;
            case 3:
                try {
                    price = Double.parseDouble(binding.etPrice.getText().toString().trim().replace(",", ""));
                    String areaStr = binding.etArea.getText().toString().trim();
                    area = areaStr.isEmpty() ? 0 : Double.parseDouble(areaStr);
                } catch (NumberFormatException e) { price = 0; }
                description = binding.etDescription.getText().toString().trim();
                break;
            case 4:
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
        }
    }

    private void updateStepUI() {
        binding.step1Container.setVisibility(currentStep == 1 ? View.VISIBLE : View.GONE);
        binding.step2Container.setVisibility(currentStep == 2 ? View.VISIBLE : View.GONE);
        binding.step3Container.setVisibility(currentStep == 3 ? View.VISIBLE : View.GONE);
        binding.step4Container.setVisibility(currentStep == 4 ? View.VISIBLE : View.GONE);
        binding.step5Container.setVisibility(currentStep == 5 ? View.VISIBLE : View.GONE);

        if (currentStep == 5) {
            binding.btnAddImages.setOnClickListener(v -> pickImages());
        }

        binding.tvStepCounter.setText(currentStep + "/" + TOTAL_STEPS);
        binding.progressBar.setProgress((currentStep * 100) / TOTAL_STEPS);

        binding.btnBack.setVisibility(currentStep > 1 ? View.VISIBLE : View.GONE);
        binding.btnBackStep.setVisibility(currentStep > 1 ? View.VISIBLE : View.GONE);
        binding.btnNext.setText(currentStep == TOTAL_STEPS ? "إرسال الإعلان" : "التالي");
    }

    private void pickImages() {
        Intent intent = new Intent(Intent.ACTION_GET_CONTENT);
        intent.setType("image/*");
        intent.putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true);
        startActivityForResult(Intent.createChooser(intent, "اختر الصور"), PICK_IMAGES_REQUEST);
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == PICK_IMAGES_REQUEST && resultCode == RESULT_OK && data != null) {
            selectedImages.clear();
            if (data.getClipData() != null) {
                int count = Math.min(data.getClipData().getItemCount(), 10);
                for (int i = 0; i < count; i++)
                    selectedImages.add(data.getClipData().getItemAt(i).getUri());
            } else if (data.getData() != null) {
                selectedImages.add(data.getData());
            }
            binding.tvImageCount.setText(selectedImages.size() + " صورة مختارة");
        }
    }

    private void submitProperty() {
        binding.btnNext.setEnabled(false);
        binding.loadingContainer.setVisibility(View.VISIBLE);
        if (selectedImages.isEmpty()) {
            savePropertyToFirestore(new ArrayList<>());
        } else {
            uploadImages();
        }
    }

    private void uploadImages() {
        uploadedImageUrls.clear();
        int[] failedCount = {0};
        for (Uri uri : selectedImages) {
            String fileName = UUID.randomUUID() + ".jpg";
            StorageReference ref = storage.getReference()
                .child("properties").child(mAuth.getCurrentUser().getUid()).child(fileName);
            ref.putFile(uri)
                .continueWithTask(task -> ref.getDownloadUrl())
                .addOnSuccessListener(downloadUri -> {
                    uploadedImageUrls.add(downloadUri.toString());
                    if (uploadedImageUrls.size() + failedCount[0] == selectedImages.size()) {
                        if (uploadedImageUrls.isEmpty()) {
                            Toast.makeText(this, "فشل رفع جميع الصور", Toast.LENGTH_SHORT).show();
                            resetLoadingState();
                        } else {
                            savePropertyToFirestore(uploadedImageUrls);
                        }
                    }
                })
                .addOnFailureListener(e -> {
                    failedCount[0]++;
                    if (uploadedImageUrls.size() + failedCount[0] == selectedImages.size()) {
                        if (uploadedImageUrls.isEmpty()) {
                            Toast.makeText(this, "فشل رفع الصور، تحقق من اتصالك", Toast.LENGTH_SHORT).show();
                            resetLoadingState();
                        } else {
                            savePropertyToFirestore(uploadedImageUrls);
                        }
                    }
                });
        }
    }

    private void resetLoadingState() {
        binding.btnNext.setEnabled(true);
        binding.loadingContainer.setVisibility(View.GONE);
    }

    private void savePropertyToFirestore(List<String> imageUrls) {
        String uid = mAuth.getCurrentUser().getUid();
        db.collection("users").document(uid).get()
            .addOnSuccessListener(doc -> {
                String ownerName = doc.exists() ? doc.getString("fullName") : "مجهول";
                String ownerPhone = doc.exists() ? doc.getString("phone") : "";
                String title = getTypeLabel() + " - " + governorate + " - " + region;

                Property prop = new Property(title, description, propertyType, operationType,
                    price, area, rooms, bathrooms, floor,
                    governorate, region, neighborhood, detailedAddress,
                    uid, ownerName, ownerPhone);

                prop.setImages(imageUrls);
                prop.setHasElevator(hasElevator); prop.setHasParking(hasParking);
                prop.setHasAC(hasAC); prop.setHasHeating(hasHeating);
                prop.setHasGarden(hasGarden); prop.setHasPool(hasPool);
                prop.setHasBalcony(hasBalcony); prop.setHasInternet(hasInternet);
                prop.setHasGas(hasGas); prop.setFurnished(isFurnished);

                db.collection("properties").add(prop)
                    .addOnSuccessListener(ref -> {
                        Toast.makeText(this, "تم نشر الإعلان بنجاح!", Toast.LENGTH_LONG).show();
                        finish();
                    })
                    .addOnFailureListener(e -> {
                        resetLoadingState();
                        Toast.makeText(this, "حدث خطأ: " + e.getMessage(), Toast.LENGTH_SHORT).show();
                    });
            })
            .addOnFailureListener(e -> {
                resetLoadingState();
                Toast.makeText(this, "فشل تحميل بيانات المستخدم", Toast.LENGTH_SHORT).show();
            });
    }

    private String getTypeLabel() {
        switch (propertyType) {
            case "apartment": return "شقة";
            case "land": return "أرض";
            case "villa": return "فيلا";
            case "office": return "مكتب";
            case "shop": return "محل";
            case "farm": return "أرض زراعية";
            default: return propertyType;
        }
    }
}
