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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCityEvents() async {
    await _viewModel.loadCityEvents(widget.user, type: selectedType);
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
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    const Text(
                      "Şehrimde Gidilecek Yerler",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<String>(
                        value: selectedType,
                        underline: const SizedBox(),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        items: placeTypes.map((type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(
                              type[0].toUpperCase() + type.substring(1),
                              style: const TextStyle(fontSize: 14),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) async {
                          if (newValue != null) {
                            setState(() {
                              selectedType = newValue;
                            });
                            await _viewModel.loadCityEvents(widget.user,
                                type: selectedType);
                          }
                        },
                      ),
                    ),
                  ],
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

  // Şehrimdeki etkinlikleri gösterecek boş sekme
  Widget _buildEventsTab() {
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
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: const Text(
                  "Şehrimde Ne Var?",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
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
