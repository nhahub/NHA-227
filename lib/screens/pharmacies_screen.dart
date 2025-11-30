import 'package:medilink_app/widgets/pharmacy_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:medilink_app/core/constants/app_strings.dart';
import 'package:medilink_app/shared/widgets/custom_app_bar.dart';
import 'package:medilink_app/shared/widgets/custom_search_bar.dart';
import 'package:medilink_app/repositories/product_repository.dart';


class PharmaciesScreen extends StatelessWidget {
  const PharmaciesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pharmacies = context.watch<ProductRepository>().pharmacies;

    return Scaffold(
      appBar: const CustomAppBar(
        title: AppStrings.pharmacies,
        showBackButton: true,
      ),
      body: Column(
        children: [
          const CustomSearchBar(),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: pharmacies.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                // Use a constrained width for vertical list
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: PharmacyCard(pharmacy: pharmacies[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
