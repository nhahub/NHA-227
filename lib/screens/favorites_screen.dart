import 'package:medilink_app/repositories/product_repository.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:medilink_app/core/constants/app_strings.dart';
import 'package:medilink_app/shared/widgets/custom_app_bar.dart';
import 'package:medilink_app/shared/widgets/custom_search_bar.dart';
import 'package:medilink_app/widgets/product_card.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favoriteProducts = context.watch<ProductRepository>().favoriteProducts;

    return Scaffold(
      appBar: const CustomAppBar(
        title: AppStrings.favorite,
        showBackButton: true,
      ),
      body: Column(
        children: [
          const CustomSearchBar(),
          Expanded(
            child: favoriteProducts.isEmpty
                ? const Center(
                    child: Text('No favorites yet'),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.65,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: favoriteProducts.length,
                    itemBuilder: (context, index) {
                      return ProductCard(product: favoriteProducts[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}