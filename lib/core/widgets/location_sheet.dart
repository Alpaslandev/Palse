import 'package:flutter/material.dart';
import 'package:palseapp/core/models/location_model.dart';
import 'package:palseapp/core/services/location_service.dart';
import 'package:palseapp/core/utils/debouncer.dart';

class LocationSheet extends StatefulWidget {
  const LocationSheet({super.key});

  @override
  State<LocationSheet> createState() => _LocationSheetState();
}

class _LocationSheetState extends State<LocationSheet> {
  final Debouncer _debouncer = Debouncer(milliseconds: 300);
  final TextEditingController _searchController = TextEditingController();
  List<LocationModel> _suggestions = [];
  bool _isLoading = false;
  final LocationService _locationService = LocationService();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Mevcut Konumu Kullan Butonu
          ElevatedButton.icon(
            onPressed: () async {
              final locationModel = await _locationService.getCurrentLocationModel();
              if (context.mounted && locationModel != null) {
                _returnLocationModel(locationModel);
              }
            },
            icon: const Icon(Icons.my_location),
            label: const Text('Mevcut Konumumu Kullan'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
          ),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),

          // Arama Alanı
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Şehir, İlçe Ara',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _suggestions.clear();
                        });
                      },
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onChanged: (value) => _debouncer.run(() => _searchLocation(value)),
          ),
          const SizedBox(height: 16),

          // Öneri Listesi
          Expanded(
            child: _isLoading && _suggestions.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    itemCount: _suggestions.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final suggestion = _suggestions[index];
                      return ListTile(
                        leading: const Icon(Icons.location_on),
                        title: Text(suggestion.displayName ?? ''),
                        onTap: () => _returnLocationModel(suggestion),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _searchLocation(String query) async {
    if (query.length < 3) return;

    setState(() => _isLoading = true);
    try {
      final results = await _locationService.searchLocation(query);
      setState(() => _suggestions = results);
    } catch (e) {
      _showErrorMessage('Hata: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // LocationModel'i döndür
  void _returnLocationModel(LocationModel locationModel) {
    Navigator.pop(context, locationModel);
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
