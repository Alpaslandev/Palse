import 'package:flutter/material.dart';
import 'package:palseapp/core/constant/categories.dart';
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
        title: const Text('Kategoriler'),
        centerTitle: false,
        actions: [
          Row(
            children: [
              ElevatedButton(
                onPressed: changed ? saveCategories : null,
                child: const Text('Kaydet'),
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
              const Text(
                'İlgi Alanlarım',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: selectedCategories
                    .map((category) => Chip(
                          avatar: Icon(
                            category.icon,
                          ),
                          backgroundColor: AppTheme.primaryColor,
                          label: Text(
                            category.text,
                          ),
                          onDeleted: () {
                            setState(() {
                              selectedCategories.remove(category);
                              changed = true;
                            });
                          },
                        ))
                    .toList(),
              ),
              const SizedBox(height: 24),
            ],
            const Text(
              'Tüm Kategoriler',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: unselectedCategories // Sadece seçili olmayan kategorileri göster
                  .map((category) => FilterChip(
                        avatar: Icon(category.icon, color: Colors.black),
                        label: Text(category.text, style: const TextStyle(color: Colors.black)),
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
        const SnackBar(content: Text('İlgi alanlarınız kaydedildi')),
      );
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}
