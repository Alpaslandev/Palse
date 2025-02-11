import 'package:flutter/material.dart';
import 'package:palseapp/core/constant/categories.dart';
import 'package:palseapp/features/profile_setup_steps/viewmodel/profile_setup_view_model.dart';

class FavoriteCategoryStep extends StatelessWidget {
  const FavoriteCategoryStep({super.key, required this.viewModel});
  final ProfileSetupViewModel viewModel;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'İlgi Alanlarınız',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Text(
            'En az 3 kategori seçiniz',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _buildCategoryChips(context, viewModel),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCategoryChips(BuildContext context, ProfileSetupViewModel viewModel) {
    return categories.map((category) {
      final isSelected = viewModel.customer.favoriteCategories?.contains(category) ?? false;
      return ChoiceChip(
        label: Text(category),
        selected: isSelected,
        onSelected: (selected) => _handleCategorySelection(viewModel, category, selected),
        selectedColor: Theme.of(context).primaryColor,
      );
    }).toList();
  }

  void _handleCategorySelection(ProfileSetupViewModel viewModel, String category, bool selected) {
    final categories = List<String>.from(viewModel.customer.favoriteCategories ?? []);
    if (selected) {
      categories.add(category);
    } else {
      categories.remove(category);
    }
    viewModel.customer.favoriteCategories = categories;
    viewModel.notifyListeners();
  }
}
