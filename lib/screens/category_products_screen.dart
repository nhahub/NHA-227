import 'package:medilink_app/repositories/product_repository.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:medilink_app/shared/widgets/custom_app_bar.dart';
import 'package:medilink_app/shared/widgets/custom_search_bar.dart';
import 'package:medilink_app/models/category_model.dart';
import 'package:medilink_app/widgets/product_card.dart';

class CategoryProductsScreen extends StatelessWidget {
  final Category category;

  const CategoryProductsScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final allProducts = context.watch<ProductRepository>().products;
    final categoryProducts = allProducts
        .where(
            (p) => p.categoryId == category.id || p.category == category.name)
        .toList();
    return Scaffold(
      appBar: CustomAppBar(
        title: category.name,
        showBackButton: true,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: category.backgroundColor,
            child: Row(
              children: [
                category.iconPath.startsWith('http')
                    ? Image.network(
                        category.iconPath,
                        width: 32,
                        height: 32,
                        fit: BoxFit.contain,
                      )
                    : Image.asset(
                        category.iconPath,
                        width: 32,
                        height: 32,
                        fit: BoxFit.contain,
                      ),
                const SizedBox(width: 12),
                Text(
                  category.name,
                  style: TextStyle(
                    color: category.iconColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const CustomSearchBar(),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.65,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: categoryProducts.length,
              itemBuilder: (context, index) =>
                  ProductCard(product: categoryProducts[index]),
            ),
          ),
        ],
      ),
    );
  }
}
