import 'package:flutter/material.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/utils/app_theme.dart';
import 'package:palseapp/features/city_events/viewmodel/city_events_view_model.dart';
import 'package:palseapp/features/city_events/view/widgets/city_venue_view.dart';
import 'package:provider/provider.dart';

// Şehrimdeki etkinlikler ve mekanlar sayfası
class CityEventsView extends StatefulWidget {
  final Customer user;

  const CityEventsView({
    super.key,
    required this.user,
  });

  @override
  State<CityEventsView> createState() => _CityEventsViewState();
}

class _CityEventsViewState extends State<CityEventsView>
    with SingleTickerProviderStateMixin {
  late CityEventsViewModel _viewModel;
  late TabController _tabController;

  // Ön tanımlı türler ve seçim durumu
  final List<String> placeTypes = [
    'restaurant',
    'cafe',
    'bar',
    'park',
    'gym',
  ];

  String selectedType = 'restaurant';

  @override
  void initState() {
    super.initState();
    _viewModel = CityEventsViewModel();
    _tabController = TabController(length: 2, vsync: this);
    _loadCityEvents();
    _loadEventCategories();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCityEvents() async {
    await _viewModel.loadCityEvents(widget.user, type: selectedType);
  }

  Future<void> _loadEventCategories() async {
    await _viewModel.loadEventCategories(widget.user);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'Şehrimdeki mekanlar'),
            Tab(text: 'Şehrimdeki etkinlikler'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildVenuesTab(),
              _buildEventsTab(),
            ],
          ),
        ),
      ],
    );
  }

  // Ortak başlık ve dropdown widget'ı
  Widget _buildHeaderWithDropdown({
    required String title,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    String hintText = 'Seçiniz',
    Widget Function(String)? itemBuilder,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: value,
                  isExpanded: true,
                  hint: Text(hintText),
                  items: items.map((item) {
                    return DropdownMenuItem<String>(
                      value: item,
                      child: itemBuilder?.call(item) ??
                          Text(
                            item,
                            style: const TextStyle(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                    );
                  }).toList(),
                  onChanged: onChanged,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Şehrimdeki mekanları gösteren sekme
  Widget _buildVenuesTab() {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<CityEventsViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final events = viewModel.cityEvents;

          if (events.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderWithDropdown(
                title: "Şehrimde Gidilecek Yerler",
                value: selectedType,
                items: placeTypes
                    .map((type) => type)
                    .toList(), // Değerleri olduğu gibi bırakıyoruz
                onChanged: (String? newValue) async {
                  if (newValue != null) {
                    setState(() {
                      selectedType = newValue;
                    });
                    await _viewModel.loadCityEvents(widget.user,
                        type: selectedType);
                  }
                },
                itemBuilder: (String type) => Text(
                  type[0].toUpperCase() + type.substring(1),
                  style: const TextStyle(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: events.length,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    final place = events[index];
                    final name = place['name'] ?? 'İsimsiz';
                    final location = place['geometry']['location'];
                    final lat = location['lat'] as double;
                    final lng = location['lng'] as double;
                    final photoRef =
                        (place['photos'] as List?)?.first['photo_reference'];
                    final types = place['types'] != null &&
                            (place['types'] as List).isNotEmpty
                        ? (place['types'] as List).first.toString()
                        : 'Tür bilgisi yok';

                    final photoUrl = photoRef != null
                        ? viewModel.generatePhotoUrl(photoRef)
                        : null;

                    final iconUrl = place['icon'];

                    return CityVenueView(
                      name: name,
                      types: types,
                      photoUrl: photoUrl,
                      iconUrl: iconUrl,
                      lat: lat,
                      lng: lng,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Şehrimdeki etkinlikleri gösterecek sekme
  Widget _buildEventsTab() {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<CityEventsViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final categories = viewModel.eventCategories;

          if (categories.isEmpty) {
            return const Center(
              child: Text('Kategoriler yüklenemedi'),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderWithDropdown(
                title: "Şehrimde Ne Var?",
                value: viewModel.selectedEventCategory ?? categories.first.name,
                items: categories.map((category) => category.name).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    viewModel.updateSelectedEventCategory(newValue);
                  }
                },
                hintText: 'Kategori Seç',
              ),
              const Expanded(
                child: Center(
                  child: Text(
                    'Etkinlikler yakında burada listelenecek!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_city, size: 64, color: AppTheme.primaryColor),
          const SizedBox(height: 16),
          Text(
            "Aradığın Kriterde Mekan Bulunamadı",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Filtreni değiştirerek yeni mekanlar keşfet',
            textAlign: TextAlign.center,
            style:
                TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
          ),
        ],
      ),
    );
  }
}
