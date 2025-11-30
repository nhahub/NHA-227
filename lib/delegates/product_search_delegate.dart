import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repositories/product_repository.dart'; // Correct path
import '../widgets/product_card.dart'; // Correct path
import '../core/constants/app_colors.dart'; // Correct path

class ProductSearchDelegate extends SearchDelegate {
  
  // 1. Style the Search Bar text
  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: theme.appBarTheme.copyWith(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        elevation: 0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.grey),
      ),
    );
  }

  // 2. The "Clear" button (X)
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  // 3. The "Back" button
  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_ios, size: 20),
      onPressed: () => close(context, null), // Standard close for SearchDelegate
    );
  }

  // 4. Show Results (When user presses Enter or types)
  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  // 5. Show Suggestions (As user types)
  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    if (query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              "Search for medicines...",
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
            ),
          ],
        ),
      );
    }

    // Get the filtered list from Repository
    // Ensure searchProducts exists in ProductRepository
    final results = context.read<ProductRepository>().searchProducts(query);

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sentiment_dissatisfied, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              "No products found for '$query'",
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    // Display Results in a Grid
    return Container(
      color: const Color(0xFFF5F7FA), // App background color
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65, // Matches your other screens
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: results.length,
        itemBuilder: (context, index) {
          return ProductCard(product: results[index]);
        },
      ),
    );
  }
}