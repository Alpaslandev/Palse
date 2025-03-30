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
import 'package:palseapp/core/helper/calculate_distance.dart';
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
  Gender? _selectedGender;
  Categories? _selectedCategory;
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

    // Tüm ilanları çek (filtrelerimizi backendde uygulayarak)
    final advertService = AdvertService();
    List<Advert> allAdverts = await advertService.fetchAdvertsByFiltering(gender: _selectedGender?.name, category: _selectedCategory?.name);

    // Orijinal listeyi kaydet (sıralamanın bozulmaması için)
    List<Advert> resultAdverts = List.from(allAdverts);

    debugPrint('Toplam çekilen ilan sayısı: ${allAdverts.length}');

    // Mesafe filtresi uygula (eğer belirtilmişse)
    if (_distance != null && _distance! > 0 && _currentUser?.location != null) {
      // Kullanıcının konumu
      final userLat = _currentUser?.location?.lat;
      final userLng = _currentUser?.location?.lon;

      if (userLat != null && userLng != null) {
        debugPrint('Kullanıcı konumu: $userLat, $userLng');
        debugPrint('Mesafe filtresi uygulanıyor: $_distance km');

        // Orijinal listeden filtreye uymayanları çıkar
        resultAdverts = resultAdverts.where((advert) {
          // İlanın konumu
          final advertLat = advert.location?.lat;
          final advertLng = advert.location?.lon;

          // Eğer ilanın konumu yoksa filtre dışında bırakılır
          if (advertLat == null || advertLng == null) {
            return false;
          }

          // Mesafeyi hesapla
          final distance = calculateDistance(latitude1: userLat, longitude1: userLng, latitude2: advertLat, longitude2: advertLng);

          // Debug mesajı
          debugPrint('İlan ID: ${advert.advertID}, Mesafe: $distance km, Filtreleniyor mu: ${distance <= _distance!}');

          // Mesafe filtresine göre kontrol
          return distance <= _distance!;
        }).toList();

        debugPrint('Mesafe filtrelemesi sonucu kalan ilan sayısı: ${resultAdverts.length}');
      } else {
        debugPrint('Kullanıcı konumu bulunamadı, mesafe filtresi uygulanamadı');
      }
    } else {
      debugPrint('Mesafe filtresi uygulanmadı: $_distance');
    }

    setState(() {
      _filteredAdverts = resultAdverts;
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
            value: _selectedCategory,
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
                _selectedCategory = value;
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
