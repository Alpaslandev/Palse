import 'package:flutter/material.dart';
import 'package:palseapp/core/constant/categories.dart';
import 'package:palseapp/core/localization/app_localizations.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/core/services/firestore/customer_service.dart';
import 'package:palseapp/core/utils/app_theme.dart';
import 'package:provider/provider.dart';

// Kategorileri ve favori kategorileri yönetip kaydeden view
class CategoriesView extends StatefulWidget {
  const CategoriesView({super.key});

  @override
  State<CategoriesView> createState() => _CategoriesViewState();
}

class _CategoriesViewState extends State<CategoriesView> {
  final CustomerService customerService = CustomerService();
  List<Categories> selectedCategories = [];
  List<Categories> categories = [];
  bool changed = false;
  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    selectedCategories = authProvider.user?.favoriteCategories ?? [];
    categories = Categories.values;
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(selectedCategories.toString());

    final allCategories = Categories.values;
    // Seçili olmayan kategorileri filtrele
    final unselectedCategories = allCategories.where((category) => !selectedCategories.contains(category)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('categories')),
        centerTitle: false,
        actions: [
          Row(
            children: [
              ElevatedButton(
                onPressed: changed ? saveCategories : null,
                child: Text(context.tr('save')),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (selectedCategories.isNotEmpty) ...[
              Text(
                context.tr('my_interests'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: selectedCategories
                    .map((category) => Chip(
                          avatar: Text(
                            category.emoji,
                            style: const TextStyle(fontSize: 16),
                          ),
                          backgroundColor: AppTheme.primaryColor,
                          label: Text(
                            category.getText(context),
                            style: const TextStyle(color: Colors.white),
                          ),
                          onDeleted: () {
                            setState(() {
                              selectedCategories.remove(category);
                              changed = true;
                            });
                          },
                          deleteIconColor: Colors.white,
                        ))
                    .toList(),
              ),
              const SizedBox(height: 24),
            ],
            Text(
              context.tr('all_categories'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: unselectedCategories // Sadece seçili olmayan kategorileri göster
                  .map((category) => FilterChip(
                        avatar: Text(
                          category.emoji,
                          style: const TextStyle(fontSize: 16),
                        ),
                        label: Text(category.getText(context), style: const TextStyle(color: Colors.black)),
                        selected: false,
                        backgroundColor: Colors.white,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              selectedCategories.add(category);
                              changed = true;
                            });
                          }
                        },
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> saveCategories() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user!;

    try {
      await customerService.updateCustomerCategories(user.userID!, selectedCategories);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('interests_saved'))),
      );
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}
