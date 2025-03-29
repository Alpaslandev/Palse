// İlan filtreleme görünümü
import 'package:flutter/material.dart';
import 'package:palseapp/core/constant/categories.dart';
import 'package:palseapp/core/localization/app_localizations.dart';
import 'package:palseapp/core/models/advert.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/core/services/firestore/advert_service.dart';
import 'package:palseapp/core/utils/app_theme.dart';
import 'package:palseapp/core/widgets/advert_card.dart';
import 'package:palseapp/core/widgets/premium_overlay.dart';
import 'package:provider/provider.dart';

// List extension for firstOrNull
extension ListExtension<T> on List<T>? {
  T? get firstOrNull {
    if (this == null || this!.isEmpty) return null;
    return this!.first;
  }
}

class FilterView extends StatefulWidget {
  const FilterView({
    super.key,
  });

  @override
  State<FilterView> createState() => _FilterViewState();
}

class _FilterViewState extends State<FilterView> {
  int? _distance;
  Gender? _selectedGender;
  List<Categories>? _selectedCategories;
  bool _isFiltered = false;
  List<Advert> _filteredAdverts = [];
  Customer? _currentUser;
  bool _isLoading = false;
  @override
  void initState() {
    super.initState();
  }

  Future<void> _applyFilters() async {
    setState(() {
      _isFiltered = true;
      _isLoading = true;
    });

    // Tüm ilanları çek
    final advertService = AdvertService();
    List<Advert> allAdverts = await advertService.fetchAdverts(limit: 100);

    // Cinsiyet filtrelemesi
    if (_selectedGender != null) {
      allAdverts = allAdverts.where((advert) {
        return advert.creatorGender.name.toLowerCase() == _selectedGender!.name.toLowerCase();
      }).toList();

      debugPrint('Filtreleme sonucu kalan ilan sayısı: ${allAdverts.length}');
    }

    if (_selectedCategories != null && _selectedCategories!.isNotEmpty) {
      debugPrint('Seçilen kategoriler: ${_selectedCategories!.map((e) => e.name).toList()}');

      allAdverts = allAdverts.where((advert) {
        final ilanKategori = advert.advertType;
        debugPrint('İlan kategorisi: ${ilanKategori.name} - Seçilen kategorilerde var mı: ${_selectedCategories!.contains(ilanKategori)}');

        return _selectedCategories!.contains(advert.advertType);
      }).toList();

      debugPrint('Kategori filtrelemesi sonucu kalan ilan sayısı: ${allAdverts.length}');
    }

    setState(() {
      _filteredAdverts = allAdverts;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    _currentUser = authProvider.user; // Kullanıcıyı burada atayalım

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('filtering')),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_isFiltered
              ? PremiumOverlay(
                  child: _filterView(context),
                )
              : _filteredList(adverts: _filteredAdverts, context: context),
    );
  }

  Container _filterView(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mesafe seçici
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${context.tr('distance')}: ${_distance ?? 0} km'),
              Slider(
                activeColor: AppTheme.primaryColor,
                value: (_distance ?? 0).toDouble(),
                min: 0,
                max: 500,
                divisions: 20,
                onChanged: (value) {
                  setState(() {
                    _distance = value.round();
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Cinsiyet seçici
          DropdownButtonFormField<Gender>(
            value: _selectedGender,
            decoration: InputDecoration(
              labelText: context.tr('gender'),
              border: const OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(value: null, child: Text(context.tr('all'))),
              DropdownMenuItem(value: Gender.male, child: Text(context.tr('male'))),
              DropdownMenuItem(value: Gender.female, child: Text(context.tr('female')))
            ],
            onChanged: (value) {
              setState(() {
                _selectedGender = value;
              });
            },
          ),
          const SizedBox(height: 16),
          // Kategori seçici
          DropdownButtonFormField<Categories?>(
            value: _selectedCategories?.firstOrNull,
            decoration: InputDecoration(
              labelText: context.tr('category'),
              border: const OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem<Categories?>(value: null, child: Text(context.tr('all'))),
              ...Categories.values.map((category) {
                return DropdownMenuItem<Categories?>(
                  value: category,
                  child: Text(category.getText(context)),
                );
              }),
            ],
            onChanged: (value) {
              setState(() {
                _selectedCategories = value != null ? [value] : null;
              });
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              _applyFilters(); // Filtreleri uygula butonuna basıldığında _applyFilters metodunu çağır
            },
            child: Text(context.tr('apply')),
          ),
        ],
      ),
    );
  }

  Widget _filteredList({required List<Advert> adverts, required BuildContext context}) {
    return ListView.builder(
      itemCount: adverts.length,
      itemBuilder: (context, index) {
        final advert = adverts[index];
        // Mesafeyi göstermek için AdvertCard'a mesafe bilgisini ekleyebiliriz
        return AdvertCard(
          advert: advert,
          isLiked: _currentUser != null ? advert.likers.contains(_currentUser?.userID) : false,
          onLikeTap: _currentUser != null
              ? () async {
                  final userId = _currentUser?.userID;
                  if (userId == null) return;

                  final advertService = AdvertService();
                  if (advert.likers.contains(userId)) {
                    await advertService.unlikeAdvert(advert.advertID ?? '', userId);
                  } else {
                    await advertService.likeAdvert(advert.advertID ?? '', userId, advert.creatorUserID);
                  }

                  // Filtreleri yeniden uygula
                  _applyFilters();
                }
              : null,
        );
      },
    );
  }
}
