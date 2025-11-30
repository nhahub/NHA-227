import 'package:flutter/material.dart';
import 'package:medilink_app/core/constants/app_colors.dart';
import 'package:medilink_app/models/pharmacy_model.dart';
import 'package:medilink_app/shared/widgets/custom_app_bar.dart';

class PharmacyDetailScreen extends StatelessWidget {
  final Pharmacy pharmacy;

  const PharmacyDetailScreen({super.key, required this.pharmacy});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: '', showBackButton: true),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. Main Header Image ---
            Container(
              height: 200,
              width: double.infinity,
              color: Colors.grey[100],
              child: pharmacy.imageUrl.startsWith('http')
                  ? Image.network(pharmacy.imageUrl, fit: BoxFit.contain) // Changed to contain for logos
                  : Image.asset(pharmacy.imageUrl, fit: BoxFit.contain),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- 2. Name & Verified Badge ---
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          pharmacy.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (pharmacy.isVerified) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.verified, color: AppColors.primary, size: 24),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // --- 3. Location ---
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on, color: Colors.grey, size: 18),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          pharmacy.location,
                          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // --- 4. Action Buttons (Call / WhatsApp / Map) ---
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.call,
                          label: "Call",
                          color: AppColors.primary,
                          onTap: () {
                            // Logic to launch phone dialer would go here
                            // launchUrl(Uri.parse("tel:${pharmacy.phone}"));
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.chat,
                          label: "WhatsApp",
                          color: Colors.green,
                          onTap: () {
                            // Logic to launch WhatsApp
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.map,
                          label: "Map",
                          color: Colors.orange,
                          onTap: () {
                            // Logic to open Google Maps with pharmacy.latitude/longitude
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // --- 5. Services Section ---
                  if (pharmacy.services.isNotEmpty) ...[
                    const Text(
                      "Services",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: pharmacy.services.map((service) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                          ),
                          child: Text(
                            service,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // --- 6. Gallery Section (If you have extra images) ---
                  if (pharmacy.imageGallery.isNotEmpty) ...[
                    const Text(
                      "Gallery",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 120,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: pharmacy.imageGallery.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              pharmacy.imageGallery[index],
                              height: 120,
                              width: 160,
                              fit: BoxFit.cover,
                              errorBuilder: (_,__,___) => Container(color: Colors.grey[200]),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // --- 7. Contact Details Text ---
                  const Divider(),
                  const SizedBox(height: 16),
                  _ContactRow(label: "Phone", value: pharmacy.phone),
                  const SizedBox(height: 12),
                  _ContactRow(label: "WhatsApp", value: pharmacy.whatsapp),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper Widget for Buttons
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper Widget for Contact Text
class _ContactRow extends StatelessWidget {
  final String label;
  final String value;

  const _ContactRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          "$label: ",
          style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
        ),
        Text(
          value.isEmpty ? "Not Available" : value,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}