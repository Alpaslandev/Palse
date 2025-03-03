import 'package:flutter/material.dart';
import 'package:palseapp/core/provider/subscription_provider.dart';
import 'package:purchases_flutter/models/package_wrapper.dart';

class PackageCard extends StatelessWidget {
  const PackageCard(
      {super.key,
      required this.package,
      required this.context,
      required this.subscriptionProvider,
      required this.onTap,
      required this.isSelected,
      required this.packageType,
      required this.monthlyPrice});

  final Package package;
  final BuildContext context;
  final SubscriptionProvider subscriptionProvider;
  final Function(Package) onTap;
  final bool isSelected;
  final PackageType packageType;
  final double monthlyPrice;

  @override
  Widget build(BuildContext context) {
    double calculateNoDiscount() {
      if (packageType == PackageType.annual) {
        return monthlyPrice * 12;
      } else if (packageType == PackageType.sixMonth) {
        return monthlyPrice * 6;
      }
      return package.storeProduct.price;
    }

    return GestureDetector(
      onTap: () => onTap(package),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12.0),
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            // Seçim göstergesi
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).primaryColor,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
              ),

            // Paket bilgileri
            Expanded(
              child: Text(
                package.storeProduct.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Theme.of(context).primaryColor : Colors.black,
                ),
              ),
            ),

            // Fiyat
            Row(
              children: [
                if (packageType != PackageType.monthly)
                  Text(
                    calculateNoDiscount().toStringAsFixed(2),
                    style: TextStyle(
                      color: isSelected ? Colors.black54 : Colors.black26,
                      decoration: TextDecoration.lineThrough,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                const SizedBox(width: 4),
                Text(
                  package.storeProduct.priceString,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
