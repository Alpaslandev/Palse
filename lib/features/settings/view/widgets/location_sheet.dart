import 'package:flutter/material.dart';
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
  List<LocationSuggestion> _suggestions = [];
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Arama Alanı
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Şehir Ara',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _isLoading
                  ? const CircularProgressIndicator()
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _suggestions.clear();
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
            child: ListView.separated(
              itemCount: _suggestions.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                return ListTile(
                  leading: const Icon(Icons.location_on),
                  title: Text(suggestion.displayName),
                  subtitle: Text('${suggestion.city} ${suggestion.district}'),
                  onTap: () => _selectLocation(suggestion),
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
      final results = await LocationService().searchLocation(query);
      setState(() => _suggestions = results);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _selectLocation(LocationSuggestion suggestion) {
    Navigator.pop(context, {
      'city': suggestion.city,
      'district': suggestion.district,
      'lat': suggestion.lat,
      'lon': suggestion.lon,
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
