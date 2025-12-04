import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:medilink_app/core/constants/app_colors.dart';
import 'package:medilink_app/core/constants/app_strings.dart';
import 'package:medilink_app/models/product_model.dart';
import 'package:medilink_app/repositories/product_repository.dart';
import 'package:medilink_app/widgets/product_card.dart';

class ActiveIngredientWidget extends StatelessWidget {
  final Product currentProduct;

  const ActiveIngredientWidget({super.key, required this.currentProduct});

  @override
  Widget build(BuildContext context) {
    final allProducts = context.watch<ProductRepository>().products;
    final similarProducts = allProducts
        .where((p) => p.id != currentProduct.id)
        .take(4)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                AppStrings.activeIngredient,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () {
                  context.push('/active_ingredient', extra: currentProduct);
                },
                child: Row(
                  children: const [
                    Text(
                      AppStrings.more,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        similarProducts.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: Text('No similar products available')),
              )
            : SizedBox(
                height: 280,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: similarProducts.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) =>
                      ProductCard(product: similarProducts[index]),
                ),
              ),
      ],
    );
  }
}
