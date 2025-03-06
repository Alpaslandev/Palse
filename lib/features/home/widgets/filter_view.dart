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
import 'package:provider/provider.dart';

class FilterView extends StatefulWidget {
  const FilterView({
    super.key,
  });

  @override
  State<FilterView> createState() => _FilterViewState();
}

class _FilterViewState extends State<FilterView> {
  int? _distance;
  String? _selectedGender;
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
    List<Advert> allAdverts = await advertService.fetchAdverts(limit: 100); // Limit artırılabilir

    // Mesafe filtrelemesi
    if (_distance != null && _distance! > 0) {
      allAdverts = allAdverts.where((advert) {
        // Kullanıcının konumu ile ilanın konumu arasındaki mesafeyi hesapla
        if (advert.location == null || _currentUser?.location == null) return false;

        int distance = _currentUser!.location!.distanceTo(advert.location!);
        return distance <= _distance!;
      }).toList();
    }

    // Cinsiyet filtrelemesi
    if (_selectedGender != null) {
      allAdverts = allAdverts.where((advert) {
        // Seçilen cinsiyete göre filtrele
        if (_selectedGender == context.tr('male')) {
          return advert.creatorGender == Gender.male;
        } else if (_selectedGender == context.tr('female')) {
          return advert.creatorGender == Gender.female;
        }

        return true; // Eğer 'Hepsi' seçilmişse tüm ilanları göster
      }).toList();
    }

    if (_selectedCategories != null) {
      allAdverts = allAdverts.where((advert) {
        return _selectedCategories!.contains(advert.advertType);
      }).toList();
    }

    setState(() {
      _filteredAdverts = allAdverts;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    _currentUser = authProvider.user; // Kullanıcıyı burada atayalım

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('filtering')),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_isFiltered
              ? _filterView(context)
              : _filteredList(adverts: _filteredAdverts, currentCustomer: _currentUser!, currentUser: _currentUser!, context: context),
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
          DropdownButtonFormField<String>(
            value: _selectedGender,
            decoration: InputDecoration(
              labelText: context.tr('gender'),
              border: const OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(value: null, child: Text(context.tr('all'))),
              DropdownMenuItem(value: context.tr('male'), child: Text(context.tr('male'))),
              DropdownMenuItem(value: context.tr('female'), child: Text(context.tr('female'))),
              // Diğer seçeneğini de ekleyebilirsiniz
              // DropdownMenuItem(value: 'Diğer', child: Text('Diğer')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedGender = value;
              });
            },
          ),
          const SizedBox(height: 16),
          // Kategori seçici
          DropdownButtonFormField<Categories>(
            value: _selectedCategories?.first,
            decoration: InputDecoration(
              labelText: context.tr('category'),
            ),
            items: [
              ...Categories.values.map((category) {
                return DropdownMenuItem<Categories>(
                  value: category,
                  child: Text(category.getText(context)),
                );
              }),
              DropdownMenuItem<Categories>(value: null, child: Text(context.tr('all'))),
            ],
            onChanged: (value) {
              setState(() {
                _selectedCategories = [value!];
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

  Widget _filteredList(
      {required List<Advert> adverts, required Customer currentCustomer, required Customer currentUser, required BuildContext context}) {
    return ListView.builder(
      itemCount: adverts.length,
      itemBuilder: (context, index) {
        return AdvertCard(
          advert: adverts[index],
        );
      },
    );
  }
}
