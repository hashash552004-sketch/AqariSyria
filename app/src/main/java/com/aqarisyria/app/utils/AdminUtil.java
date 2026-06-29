package com.aqarisyria.app.utils;

import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.firestore.FirebaseFirestore;

public class AdminUtil {
    private static final String MASTER_ADMIN_EMAIL = "hashash552004@gmail.com";

    public static boolean isMasterAdmin() {
        if (FirebaseAuth.getInstance().getCurrentUser() == null) return false;
        return MASTER_ADMIN_EMAIL.equals(FirebaseAuth.getInstance().getCurrentUser().getEmail());
    }

    public static void isAdmin(AdminCallback callback) {
        if (FirebaseAuth.getInstance().getCurrentUser() == null) {
            callback.onResult(false);
            return;
        }
        String email = FirebaseAuth.getInstance().getCurrentUser().getEmail();
        if (email == null) {
            callback.onResult(false);
            return;
        }
        if (MASTER_ADMIN_EMAIL.equals(email)) {
            callback.onResult(true);
            return;
        }
        FirebaseFirestore.getInstance().collection("admins").document(email).get()
            .addOnSuccessListener(doc -> callback.onResult(doc.exists()))
            .addOnFailureListener(e -> callback.onResult(false));
    }

    public interface AdminCallback {
        void onResult(boolean isAdmin);
    }
}
