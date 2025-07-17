import 'package:flutter/material.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/utils/app_theme.dart';
import 'package:palseapp/features/city_events/view/widgets/city_event_view.dart';
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
    _tabController.addListener(() {
      setState(() {}); // Tab değiştiğinde widget'ı yeniden build et
    });
    _loadCityEvents();
    _loadEventCategories();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCityEvents() async {
    await _viewModel.loadCityVenues(widget.user, type: selectedType);
  }

  Future<void> _loadEventCategories() async {
    await _viewModel.loadEventCategories(widget.user);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.grey[50],
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: SizedBox(
            height: 40,
            child: TabBar(
              controller: _tabController,
              // Özel stil için varsayılan indicator'ı kaldır.
              indicator: const BoxDecoration(),
              dividerColor: Colors.transparent,
              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
              tabs: [
                _buildTab('Şehrimdeki mekanlar', 0),
                _buildTab('Şehrimdeki etkinlikler', 1),
              ],
            ),
          ),
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
                    await _viewModel.loadCityVenues(widget.user,
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
              Expanded(
                child: viewModel.events.isEmpty
                    ? _buildEmptyEventsState()
                    : ListView.builder(
                        itemCount: viewModel.events.length,
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          final event = viewModel.events[index];
                          return CityEventView(event: event);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTab(String text, int index) {
    final isSelected = _tabController.index == index;

    return Tab(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? null
              : Border.all(color: Colors.grey.shade300, width: 1.5),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: isSelected ? Colors.white : Colors.grey[700],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
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

  // Etkinlik bulunamadığında gösterilecek widget
  Widget _buildEmptyEventsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 64, color: AppTheme.primaryColor),
          const SizedBox(height: 16),
          const Text(
            "Bu Kategoride Etkinlik Bulunamadı",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Farklı bir kategori seçerek yeni etkinlikler keşfet',
            textAlign: TextAlign.center,
            style:
                TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
          ),
        ],
      ),
    );
  }
}
