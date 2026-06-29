package com.aqarisyria.app.models;

import com.google.firebase.firestore.DocumentId;
import com.google.firebase.firestore.ServerTimestamp;
import java.util.Date;
import java.util.List;

public class Property {
    @DocumentId
    private String id;
    private String title;
    private String description;
    private String type; // apartment, land, villa, office, shop, farm
    private String operationType; // sell, rent, invest
    private double price;
    private double area;
    private int rooms;
    private int bathrooms;
    private int floor;
    private String governorate;
    private String region;
    private String neighborhood;
    private String detailedAddress;
    private List<String> images;
    private String ownerId;
    private String ownerName;
    private String ownerPhone;
    private boolean hasElevator;
    private boolean hasParking;
    private boolean hasAC;
    private boolean hasHeating;
    private boolean hasGarden;
    private boolean hasPool;
    private boolean hasBalcony;
    private boolean hasInternet;
    private boolean hasGas;
    private boolean isFurnished;
    private boolean isActive;
    private int viewsCount;
    @ServerTimestamp
    private Date createdAt;

    public Property() {}

    public Property(String title, String description, String type, String operationType,
                    double price, double area, int rooms, int bathrooms, int floor,
                    String governorate, String region, String neighborhood,
                    String detailedAddress, String ownerId, String ownerName, String ownerPhone) {
        this.title = title;
        this.description = description;
        this.type = type;
        this.operationType = operationType;
        this.price = price;
        this.area = area;
        this.rooms = rooms;
        this.bathrooms = bathrooms;
        this.floor = floor;
        this.governorate = governorate;
        this.region = region;
        this.neighborhood = neighborhood;
        this.detailedAddress = detailedAddress;
        this.ownerId = ownerId;
        this.ownerName = ownerName;
        this.ownerPhone = ownerPhone;
        this.isActive = true;
        this.viewsCount = 0;
    }

    // Getters and Setters
    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public String getType() { return type; }
    public void setType(String type) { this.type = type; }

    public String getOperationType() { return operationType; }
    public void setOperationType(String operationType) { this.operationType = operationType; }

    public double getPrice() { return price; }
    public void setPrice(double price) { this.price = price; }

    public double getArea() { return area; }
    public void setArea(double area) { this.area = area; }

    public int getRooms() { return rooms; }
    public void setRooms(int rooms) { this.rooms = rooms; }

    public int getBathrooms() { return bathrooms; }
    public void setBathrooms(int bathrooms) { this.bathrooms = bathrooms; }

    public int getFloor() { return floor; }
    public void setFloor(int floor) { this.floor = floor; }

    public String getGovernorate() { return governorate; }
    public void setGovernorate(String governorate) { this.governorate = governorate; }

    public String getRegion() { return region; }
    public void setRegion(String region) { this.region = region; }

    public String getNeighborhood() { return neighborhood; }
    public void setNeighborhood(String neighborhood) { this.neighborhood = neighborhood; }

    public String getDetailedAddress() { return detailedAddress; }
    public void setDetailedAddress(String detailedAddress) { this.detailedAddress = detailedAddress; }

    public List<String> getImages() { return images; }
    public void setImages(List<String> images) { this.images = images; }

    public String getOwnerId() { return ownerId; }
    public void setOwnerId(String ownerId) { this.ownerId = ownerId; }

    public String getOwnerName() { return ownerName; }
    public void setOwnerName(String ownerName) { this.ownerName = ownerName; }

    public String getOwnerPhone() { return ownerPhone; }
    public void setOwnerPhone(String ownerPhone) { this.ownerPhone = ownerPhone; }

    public boolean isHasElevator() { return hasElevator; }
    public void setHasElevator(boolean hasElevator) { this.hasElevator = hasElevator; }

    public boolean isHasParking() { return hasParking; }
    public void setHasParking(boolean hasParking) { this.hasParking = hasParking; }

    public boolean isHasAC() { return hasAC; }
    public void setHasAC(boolean hasAC) { this.hasAC = hasAC; }

    public boolean isHasHeating() { return hasHeating; }
    public void setHasHeating(boolean hasHeating) { this.hasHeating = hasHeating; }

    public boolean isHasGarden() { return hasGarden; }
    public void setHasGarden(boolean hasGarden) { this.hasGarden = hasGarden; }

    public boolean isHasPool() { return hasPool; }
    public void setHasPool(boolean hasPool) { this.hasPool = hasPool; }

    public boolean isHasBalcony() { return hasBalcony; }
    public void setHasBalcony(boolean hasBalcony) { this.hasBalcony = hasBalcony; }

    public boolean isHasInternet() { return hasInternet; }
    public void setHasInternet(boolean hasInternet) { this.hasInternet = hasInternet; }

    public boolean isHasGas() { return hasGas; }
    public void setHasGas(boolean hasGas) { this.hasGas = hasGas; }

    public boolean isFurnished() { return isFurnished; }
    public void setFurnished(boolean furnished) { isFurnished = furnished; }

    public boolean isActive() { return isActive; }
    public void setActive(boolean active) { isActive = active; }

    public int getViewsCount() { return viewsCount; }
    public void setViewsCount(int viewsCount) { this.viewsCount = viewsCount; }

    public Date getCreatedAt() { return createdAt; }
    public void setCreatedAt(Date createdAt) { this.createdAt = createdAt; }

    public String getFirstImage() {
        if (images != null && !images.isEmpty()) return images.get(0);
        return null;
    }

    public String getOperationTypeLabel() {
        switch (operationType) {
            case "sell": return "للبيع";
            case "rent": return "للإيجار";
            case "invest": return "استثمار";
            default: return "";
        }
    }

    public String getTypeLabel() {
        switch (type) {
            case "apartment": return "شقة";
            case "land": return "أرض";
            case "villa": return "فيلا";
            case "house": return "منزل";
            case "office": return "مكتب";
            case "shop": return "محل";
            case "farm": return "أرض زراعية";
            case "warehouse": return "مستودع";
            default: return type;
        }
    }

    public String getFormattedPrice() {
        java.text.DecimalFormat df = new java.text.DecimalFormat("#,##0");
        return df.format(price) + " $";
    }

    public String getLocationString() {
        return governorate + " - " + region;
    }
}
