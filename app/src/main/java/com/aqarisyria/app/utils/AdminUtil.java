package com.aqarisyria.app.utils;

import com.google.firebase.auth.FirebaseAuth;

public class AdminUtil {
    private static final String ADMIN_EMAIL = "hashash552004@gmail.com";

    public static boolean isAdmin() {
        if (FirebaseAuth.getInstance().getCurrentUser() == null) return false;
        return ADMIN_EMAIL.equals(FirebaseAuth.getInstance().getCurrentUser().getEmail());
    }
}
