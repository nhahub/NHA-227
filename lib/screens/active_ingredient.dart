import 'package:medilink_app/widgets/product_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:medilink_app/core/constants/app_strings.dart';
import 'package:medilink_app/shared/widgets/custom_app_bar.dart';
import 'package:medilink_app/shared/widgets/custom_search_bar.dart';
import 'package:medilink_app/repositories/product_repository.dart';
import 'package:medilink_app/models/product_model.dart';

class ActiveIngredientScreen extends StatelessWidget {
  final Product currentProduct;

  const ActiveIngredientScreen({
    super.key,
    required this.currentProduct,
  });

  @override
  Widget build(BuildContext context) {
    final allProducts = context.watch<ProductRepository>().products;
    
    // Get products with similar names (similar active ingredients)
    // In real app, you'd match by actual active ingredient field
    final similarProducts = allProducts
        .where((p) => p.id != currentProduct.id)
        .toList();

    return Scaffold(
      appBar: const CustomAppBar(
        title: AppStrings.activeIngredient,
        showBackButton: true,
      ),
      body: Column(
        children: [
          const CustomSearchBar(),
          Expanded(
            child: similarProducts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.science_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No products with similar active ingredients',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.65,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: similarProducts.length,
                    itemBuilder: (context, index) {
                      return ProductCard(product: similarProducts[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}