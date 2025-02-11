import 'package:flutter/material.dart';
import 'package:palseapp/core/constant/categories.dart';
import 'package:palseapp/features/profile_setup_steps/viewmodel/profile_setup_view_model.dart';

class FavoriteCategoryStep extends StatelessWidget {
  const FavoriteCategoryStep({super.key, required this.viewModel});
  final ProfileSetupViewModel viewModel;
  @override
  Widget build(BuildContext context) {
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
            Text(
              'En az 3 kategori seçiniz',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _buildCategoryChips(context, viewModel),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCategoryChips(BuildContext context, ProfileSetupViewModel viewModel) {
    return categories.map((category) {
      final isSelected = viewModel.customer.favoriteCategories?.contains(category) ?? false;
      return ChoiceChip(
        label: Text(category),
        selected: isSelected,
        onSelected: (selected) => viewModel.handleCategorySelection(category, selected),
        selectedColor: Theme.of(context).primaryColor,
      );
    }).toList();
  }
}
