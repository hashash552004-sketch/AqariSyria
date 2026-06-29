package com.aqarisyria.app.fragments;

import android.os.Bundle;
import android.os.Handler;
import android.text.Editable;
import android.text.TextWatcher;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import androidx.annotation.NonNull;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.LinearLayoutManager;
import com.google.firebase.firestore.FirebaseFirestore;
import com.google.firebase.firestore.Query;
import com.google.firebase.firestore.ListenerRegistration;
import com.aqarisyria.app.adapters.PropertyAdapter;
import com.aqarisyria.app.databinding.FragmentSearchBinding;
import com.aqarisyria.app.models.Property;
import java.util.ArrayList;
import java.util.List;

public class SearchFragment extends Fragment {

    private FragmentSearchBinding binding;
    private FirebaseFirestore db;
    private PropertyAdapter adapter;
    private List<Property> propertyList = new ArrayList<>();
    private ListenerRegistration searchListener;
    private Handler searchHandler = new Handler();
    private Runnable searchRunnable;
    private String currentFilter = "all";
    private String currentQuery = "";

    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        binding = FragmentSearchBinding.inflate(inflater, container, false);
        db = FirebaseFirestore.getInstance();

        setupRecyclerView();
        setupBackButton();
        setupSearchInput();
        setupFilterChips();

        return binding.getRoot();
    }

    private boolean isActive() {
        return isAdded() && binding != null;
    }

    private void setupRecyclerView() {
        adapter = new PropertyAdapter(propertyList, getActivity(), false);
        binding.rvResults.setLayoutManager(new LinearLayoutManager(getActivity()));
        binding.rvResults.setAdapter(adapter);
    }

    private void setupBackButton() {
        binding.btnBack.setOnClickListener(v -> {
            if (isAdded()) requireActivity().onBackPressed();
        });
    }

    private void setupSearchInput() {
        binding.etSearch.requestFocus();

        binding.etSearch.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {}

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
                if (searchRunnable != null) searchHandler.removeCallbacks(searchRunnable);
                searchRunnable = () -> {
                    currentQuery = s.toString().trim();
                    performSearch();
                };
                searchHandler.postDelayed(searchRunnable, 500);
            }

            @Override
            public void afterTextChanged(Editable s) {}
        });
    }

    private void setupFilterChips() {
        binding.chipAll.setOnCheckedChangeListener((buttonView, isChecked) -> {
            if (isChecked) { currentFilter = "all"; performSearch(); }
        });
        binding.chipForSale.setOnCheckedChangeListener((buttonView, isChecked) -> {
            if (isChecked) { currentFilter = "sell"; performSearch(); }
        });
        binding.chipForRent.setOnCheckedChangeListener((buttonView, isChecked) -> {
            if (isChecked) { currentFilter = "rent"; performSearch(); }
        });
        binding.chipForInvest.setOnCheckedChangeListener((buttonView, isChecked) -> {
            if (isChecked) { currentFilter = "invest"; performSearch(); }
        });
    }

    private void performSearch() {
        if (searchListener != null) searchListener.remove();

        if (currentQuery.isEmpty() && currentFilter.equals("all")) {
            showPlaceholder();
            return;
        }

        binding.progressSearch.setVisibility(View.VISIBLE);
        binding.emptyState.setVisibility(View.GONE);
        binding.placeholderState.setVisibility(View.GONE);

        Query query = db.collection("properties").whereEqualTo("active", true);

        if (!currentFilter.equals("all")) {
            query = query.whereEqualTo("operationType", currentFilter);
        }

        if (!currentQuery.isEmpty()) {
            query = query.orderBy("title")
                .startAt(currentQuery)
                .endAt(currentQuery + "\uf8ff");
        } else {
            query = query.orderBy("createdAt", Query.Direction.DESCENDING);
        }

        searchListener = query.limit(50).addSnapshotListener((snapshot, error) -> {
            if (error != null) {
                binding.progressSearch.setVisibility(View.GONE);
                return;
            }
            if (snapshot == null) return;
            if (!isActive()) return;

            propertyList.clear();
            for (var doc : snapshot.getDocuments()) {
                Property p = doc.toObject(Property.class);
                if (p != null) {
                    p.setId(doc.getId());
                    propertyList.add(p);
                }
            }
            adapter.notifyDataSetChanged();
            binding.progressSearch.setVisibility(View.GONE);

            if (propertyList.isEmpty()) {
                showEmpty();
            } else {
                showResults();
            }
        });
    }

    private void showPlaceholder() {
        binding.rvResults.setVisibility(View.GONE);
        binding.emptyState.setVisibility(View.GONE);
        binding.placeholderState.setVisibility(View.VISIBLE);
        binding.progressSearch.setVisibility(View.GONE);
    }

    private void showEmpty() {
        binding.rvResults.setVisibility(View.GONE);
        binding.emptyState.setVisibility(View.VISIBLE);
        binding.placeholderState.setVisibility(View.GONE);
        binding.progressSearch.setVisibility(View.GONE);
    }

    private void showResults() {
        binding.rvResults.setVisibility(View.VISIBLE);
        binding.emptyState.setVisibility(View.GONE);
        binding.placeholderState.setVisibility(View.GONE);
        binding.progressSearch.setVisibility(View.GONE);
    }

    @Override
    public void onDestroyView() {
        if (searchListener != null) searchListener.remove();
        searchHandler.removeCallbacksAndMessages(null);
        super.onDestroyView();
        binding = null;
    }
}
