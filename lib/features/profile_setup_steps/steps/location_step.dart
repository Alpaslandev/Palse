import 'package:flutter/material.dart';
import 'package:palseapp/core/models/location_model.dart';
import 'package:palseapp/features/profile_setup_steps/viewmodel/profile_setup_view_model.dart';
import 'package:provider/provider.dart';
import 'package:palseapp/core/services/location_service.dart';
import 'package:palseapp/core/utils/debouncer.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationStep extends StatefulWidget {
  const LocationStep({super.key, required this.viewModel});
  final ProfileSetupViewModel viewModel;
  @override
  State<LocationStep> createState() => _LocationStepState();
}

class _LocationStepState extends State<LocationStep> {
  final Debouncer _debouncer = Debouncer(milliseconds: 300);
  List<LocationModel> _suggestions = [];
  bool _isLoading = false;
  Position? _currentPosition;

  @override
  Widget build(BuildContext context) {
    // Konum seçilip seçilmediğini kontrol et
    final bool isLocationSelected = widget.viewModel.isLocationValid();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Konumunuzu Belirtin',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Şehir, ilçe adı yazın veya mevcut konumunuzu kullanın',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                if (!isLocationSelected)
                  const Text(
                    '(Zorunlu)',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
            const SizedBox(height: 32),
            _buildSearchField(isLocationSelected),
            const SizedBox(height: 16),
            _buildCurrentLocationButton(isLocationSelected),

            // Konum seçilmediğinde uyarı mesajı göster
            if (!isLocationSelected)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Lütfen bir konum seçin veya mevcut konumunuzu kullanın',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),

            const SizedBox(height: 16),
            _buildSuggestionsList(),

            // Seçilen konum bilgisi
            if (isLocationSelected)
              Card(
                margin: const EdgeInsets.only(top: 16),
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Seçilen Konum:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(widget.viewModel.cityController.text),
                      const SizedBox(height: 4),
                      Text(
                        'Koordinatlar: ${widget.viewModel.customer.location?.geoPoint?.latitude.toStringAsFixed(4) ?? ''}, ${widget.viewModel.customer.location?.geoPoint?.longitude.toStringAsFixed(4) ?? ''}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(bool isLocationSelected) {
    return TextFormField(
      controller: widget.viewModel.cityController,
      decoration: InputDecoration(
        labelText: 'Konum Ara',
        border: OutlineInputBorder(
          borderSide: BorderSide(
            color: !isLocationSelected ? Colors.red : Colors.grey.shade300,
            width: 1.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: !isLocationSelected ? Colors.red : Colors.grey.shade300,
            width: 1.0,
          ),
        ),
        prefixIcon: const Icon(Icons.location_on),
        suffixIcon: _isLoading
            ? const CircularProgressIndicator()
            : IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  widget.viewModel.cityController.clear();
                  widget.viewModel.districtController.clear();
                  _suggestions.clear();
                },
              ),
      ),
      onChanged: (value) => _debouncer.run(() => _searchLocation(value)),
    );
  }

  Widget _buildCurrentLocationButton(bool isLocationSelected) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.my_location),
      label: const Text('Mevcut Konumu Kullan'),
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: !isLocationSelected ? Colors.red : Colors.grey.shade300,
          width: 1.0,
        ),
      ),
      onPressed: _getCurrentLocation,
    );
  }

  Widget _buildSuggestionsList() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 300),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _suggestions.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final suggestion = _suggestions[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            leading: const Icon(Icons.location_pin, size: 28),
            title: Text(
              suggestion.displayName ?? '',
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
            subtitle: Text(
              '${suggestion.city} ${suggestion.district}',
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => _selectLocation(suggestion),
          );
        },
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      _currentPosition = await Geolocator.getCurrentPosition();
      final places = await GeocodingPlatform.instance
          ?.placemarkFromCoordinates(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          )
          .then((value) => value.first);

      _updateViewModel(places!, _currentPosition!);
      widget.viewModel.cityController.text = '${places.isoCountryCode}, ${places.administrativeArea}, ${places.locality}';
      setState(() => _suggestions.clear());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Konum alınamadı: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _updateViewModel(Placemark place, Position position) {
    final viewModel = context.read<ProfileSetupViewModel>();
    viewModel.updateCoordinates(position.latitude, position.longitude);
  }

  Future<void> _searchLocation(String query) async {
    if (query.length < 3) return;

    setState(() => _isLoading = true);
    try {
      final results = await LocationService().searchLocation(query);
      setState(() => _suggestions = results);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _selectLocation(LocationModel suggestion) {
    final viewModel = context.read<ProfileSetupViewModel>();
    viewModel.updateLocation(suggestion);

    widget.viewModel.cityController.text = suggestion.displayName ?? '';
    _suggestions.clear();
    FocusManager.instance.primaryFocus?.unfocus();
  }
}
