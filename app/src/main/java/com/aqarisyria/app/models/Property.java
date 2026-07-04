package com.aqarisyria.app.models;

import android.content.Context;

import com.aqarisyria.app.R;
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
    private boolean isFeatured;
    private boolean isUrgent;
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

    public boolean isFeatured() { return isFeatured; }
    public void setFeatured(boolean featured) { isFeatured = featured; }

    public boolean isUrgent() { return isUrgent; }
    public void setUrgent(boolean urgent) { isUrgent = urgent; }

    public int getViewsCount() { return viewsCount; }
    public void setViewsCount(int viewsCount) { this.viewsCount = viewsCount; }

    public Date getCreatedAt() { return createdAt; }
    public void setCreatedAt(Date createdAt) { this.createdAt = createdAt; }

    public String getFirstImage() {
        if (images != null && !images.isEmpty()) return images.get(0);
        return null;
    }

    public String getOperationTypeLabel() {
        return getOperationTypeLabel(null);
    }

    public String getOperationTypeLabel(Context context) {
        String op = operationType;
        if (op == null) return "";
        if (context != null) {
            switch (op) {
                case "sell": return context.getString(R.string.for_sale);
                case "rent": return context.getString(R.string.for_rent);
                case "invest": return context.getString(R.string.for_invest);
                default: return "";
            }
        }
        switch (op) {
            case "sell": return "\u0644\u0644\u0628\u064A\u0639";
            case "rent": return "\u0644\u0644\u0625\u064A\u062C\u0627\u0631";
            case "invest": return "\u0627\u0633\u062A\u062B\u0645\u0627\u0631";
            default: return "";
        }
    }

    public String getTypeLabel() {
        return getTypeLabel(null);
    }

    public String getTypeLabel(Context context) {
        String t = type;
        if (t == null) return "";
        if (context != null) {
            switch (t) {
                case "apartment": return context.getString(R.string.category_apartment);
                case "land": return context.getString(R.string.category_land);
                case "villa": return context.getString(R.string.category_villa);
                case "house": return context.getString(R.string.category_house);
                case "office": return context.getString(R.string.category_office);
                case "shop": return context.getString(R.string.category_shop);
                case "farm": return context.getString(R.string.category_farm);
                case "warehouse": return context.getString(R.string.category_warehouse);
                default: return t;
            }
        }
        switch (t) {
            case "apartment": return "\u0634\u0642\u0629";
            case "land": return "\u0623\u0631\u0636";
            case "villa": return "\u0641\u064A\u0644\u0627";
            case "house": return "\u0645\u0646\u0632\u0644";
            case "office": return "\u0645\u0643\u062A\u0628";
            case "shop": return "\u0645\u062D\u0644";
            case "farm": return "\u0623\u0631\u0636 \u0632\u0631\u0627\u0639\u064A\u0629";
            case "warehouse": return "\u0645\u0633\u062A\u0648\u062F\u0639";
            default: return t;
        }
    }

    public String getFormattedPrice() {
        return getFormattedPrice(null);
    }

    public String getFormattedPrice(Context context) {
        java.text.DecimalFormat df = new java.text.DecimalFormat("#,##0");
        if (context != null) {
            return df.format(price) + " " + context.getString(R.string.currency_symbol);
        }
        return df.format(price) + " $";
    }

    public String getLocationString() {
        String g = governorate != null ? governorate : "";
        String r = region != null ? region : "";
        return g + " - " + r;
    }

    public String getRelativeTime() {
        return getRelativeTime(null);
    }

    public String getRelativeTime(Context context) {
        if (createdAt == null) return "";
        long diff = new Date().getTime() - createdAt.getTime();
        long days = diff / (1000 * 60 * 60 * 24);
        if (context != null) {
            if (days < 1) return context.getString(R.string.today);
            if (days == 1) return context.getString(R.string.yesterday);
            if (days < 7) return context.getString(R.string.since_days, days);
            if (days < 30) return context.getString(R.string.since_weeks, days / 7);
            if (days < 365) return context.getString(R.string.since_months, days / 30);
            return context.getString(R.string.since_years, days / 365);
        }
        if (days < 1) return "\u0627\u0644\u064A\u0648\u0645";
        if (days == 1) return "\u0623\u0645\u0633";
        if (days < 7) return "\u0645\u0646\u0630 " + days + " \u0623\u064A\u0627\u0645";
        if (days < 30) return "\u0645\u0646\u0630 " + (days / 7) + " \u0623\u0633\u0627\u0628\u064A\u0639";
        if (days < 365) return "\u0645\u0646\u0630 " + (days / 30) + " \u0623\u0634\u0647\u0631";
        return "\u0645\u0646\u0630 " + (days / 365) + " \u0633\u0646\u0648\u0627\u062A";
    }

    public boolean isNewProperty() {
        if (createdAt == null) return false;
        long diff = new Date().getTime() - createdAt.getTime();
        return diff < 7 * 24 * 60 * 60 * 1000L;
    }
}
