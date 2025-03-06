import 'package:flutter/material.dart';
import 'package:palseapp/core/constant/categories.dart';
import 'package:palseapp/features/profile_setup_steps/viewmodel/profile_setup_view_model.dart';

class FavoriteCategoryStep extends StatelessWidget {
  const FavoriteCategoryStep({super.key, required this.viewModel});
  final ProfileSetupViewModel viewModel;
  @override
  Widget build(BuildContext context) {
    // Favori kategoriler geçerli mi kontrol et
    final bool areCategoriesValid = viewModel.areFavoriteCategoriesValid();
    final int selectedCount = viewModel.customer.favoriteCategories?.length ?? 0;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Son olarak,\nilgi alanlarınızı seçiniz',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'En az 3 kategori seçiniz',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                Text(
                  '$selectedCount/3',
                  style: TextStyle(
                    color: !areCategoriesValid ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            // Kategoriler yeterli değilse uyarı mesajı göster
            if (!areCategoriesValid)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Lütfen en az 3 kategori seçin',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),

            const SizedBox(height: 16),

            // Kategorileri kırmızı kenarlıkla çevrele
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: !areCategoriesValid ? Colors.red : Colors.transparent,
                  width: 1.0,
                ),
                borderRadius: BorderRadius.circular(8.0),
              ),
              padding: const EdgeInsets.all(8.0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _buildCategoryChips(context, viewModel),
              ),
            ),

            // Kategoriler yeterliyse onay mesajı göster
            if (areCategoriesValid)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 8),
                        const Text(
                          'Harika! Yeterli sayıda kategori seçtiniz.',
                          style: TextStyle(color: Colors.green),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCategoryChips(BuildContext context, ProfileSetupViewModel viewModel) {
    return Categories.values.map((category) {
      final isSelected = viewModel.customer.favoriteCategories?.contains(category) ?? false;
      return ChoiceChip(
        label: Text(category.text),
        selected: isSelected,
        onSelected: (selected) => viewModel.handleCategorySelection(category, selected),
        selectedColor: Theme.of(context).colorScheme.primary,
      );
    }).toList();
  }
}
