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

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık kısmı
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1.0,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Son olarak',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ilgi alanlarınızı seçiniz',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Kategori sayacı ve bilgi
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: areCategoriesValid ? Colors.green.shade50 : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: areCategoriesValid ? Colors.green.shade200 : Colors.orange.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  areCategoriesValid ? Icons.check_circle : Icons.info_outline,
                  color: areCategoriesValid ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    areCategoriesValid ? 'Harika! Yeterli kategori seçtiniz' : 'En az 3 kategori seçmeniz gerekiyor',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: areCategoriesValid ? Colors.green.shade700 : Colors.orange.shade800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: areCategoriesValid ? Colors.green.shade100 : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '$selectedCount/3',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: areCategoriesValid ? Colors.green.shade800 : Colors.orange.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Kategoriler başlığı
          Text(
            'Kategoriler',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 8),

          // Kategoriler listesi - Scroll View içine alındı
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: !areCategoriesValid ? Border.all(color: Colors.orange.shade300, width: 1.0) : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: Categories.values.length,
                itemBuilder: (context, index) {
                  final category = Categories.values[index];
                  final isSelected = viewModel.customer.favoriteCategories?.contains(category) ?? false;

                  return Material(
                    color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => viewModel.handleCategorySelection(category, !isSelected),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? Icons.check_circle : Icons.circle_outlined,
                              color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade400,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                category.text,
                                style: TextStyle(
                                  color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
