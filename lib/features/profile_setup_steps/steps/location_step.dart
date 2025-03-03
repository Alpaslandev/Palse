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
            Text(
              'Şehir, ilçe adı yazın veya mevcut konumunuzu kullanın',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            _buildSearchField(),
            const SizedBox(height: 16),
            _buildCurrentLocationButton(),
            const SizedBox(height: 16),
            _buildSuggestionsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextFormField(
      controller: widget.viewModel.cityController,
      decoration: InputDecoration(
        labelText: 'Konum Ara',
        border: const OutlineInputBorder(),
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

  Widget _buildCurrentLocationButton() {
    return OutlinedButton.icon(
      icon: const Icon(Icons.my_location),
      label: const Text('Mevcut Konumu Kullan'),
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
              suggestion.toString(),
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
    // viewModel.updateLocation(suggestion);

    widget.viewModel.cityController.text = suggestion.toString();
    _suggestions.clear();
    FocusManager.instance.primaryFocus?.unfocus();
  }
}
