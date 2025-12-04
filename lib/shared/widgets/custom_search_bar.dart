import 'package:flutter/material.dart';
// Import the delegate we just created
import 'package:medilink_app/core/constants/app_colors.dart';
import 'package:medilink_app/core/constants/app_strings.dart';
import 'package:medilink_app/delegates/product_search_delegate.dart';

class CustomSearchBar extends StatelessWidget {
  const CustomSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                // Trigger the Search Screen
                showSearch(
                  context: context,
                  delegate: ProductSearchDelegate(),
                );
              },
              child: Container(
                height: 48, // Fixed height for consistency
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F1F8),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: AppColors.textSecondary),
                    const SizedBox(width: 12),
                    Text(
                      AppStrings.search, // "Search..."
                      style: TextStyle(
                        color: AppColors.textSecondary.withOpacity(0.5),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Filter Button
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.tune, color: Colors.white),
              onPressed: () {
                // Add filter logic here later if needed
              },
            ),
          ),
        ],
      ),
    );
  }
}