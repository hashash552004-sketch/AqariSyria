package com.aqarisyria.app.models;

import com.google.firebase.firestore.DocumentId;
import com.google.firebase.firestore.ServerTimestamp;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;

public class User {
    @DocumentId
    private String uid;
    private String fullName;
    private String email;
    private String phone;
    private String profileImage;
    private List<String> favorites;
    private boolean isVerified;
    @ServerTimestamp
    private Date createdAt;

    public User() {
        this.favorites = new ArrayList<>();
    }

    public User(String uid, String fullName, String email, String phone) {
        this.uid = uid;
        this.fullName = fullName;
        this.email = email;
        this.phone = phone;
        this.favorites = new ArrayList<>();
        this.isVerified = false;
    }

    public String getUid() { return uid; }
    public void setUid(String uid) { this.uid = uid; }

    public String getFullName() { return fullName; }
    public void setFullName(String fullName) { this.fullName = fullName; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }

    public String getProfileImage() { return profileImage; }
    public void setProfileImage(String profileImage) { this.profileImage = profileImage; }

    public List<String> getFavorites() { return favorites; }
    public void setFavorites(List<String> favorites) { this.favorites = favorites; }

    public boolean isVerified() { return isVerified; }
    public void setVerified(boolean verified) { isVerified = verified; }

    public Date getCreatedAt() { return createdAt; }
    public void setCreatedAt(Date createdAt) { this.createdAt = createdAt; }

    public boolean isFavorite(String propertyId) {
        return favorites != null && favorites.contains(propertyId);
    }
}
