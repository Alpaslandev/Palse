import 'package:flutter/material.dart';
import 'package:palseapp/features/profile_setup_steps/viewmodel/profile_setup_view_model.dart';
import 'package:provider/provider.dart';
import 'package:palseapp/core/services/location_service.dart';
import 'package:palseapp/core/utils/debouncer.dart';

class LocationStep extends StatefulWidget {
  const LocationStep({super.key, required this.viewModel});
  final ProfileSetupViewModel viewModel;

  @override
  State<LocationStep> createState() => _LocationStepState();
}

class _LocationStepState extends State<LocationStep> {
  final TextEditingController _locationController = TextEditingController();
  final Debouncer _debouncer = Debouncer(milliseconds: 300);
  List<LocationSuggestion> _suggestions = [];
  bool _isLoading = false;

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
              'Şehir, ilçe adı veya posta kodu yazın (Örnek: İstanbul, Kadıköy veya 34340)',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: 'Konum Ara',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.location_on),
                suffixIcon: _isLoading
                    ? const CircularProgressIndicator()
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _locationController.clear();
                          _suggestions.clear();
                        },
                      ),
              ),
              onChanged: (value) => _debouncer.run(() => _searchLocation(value)),
            ),
            const SizedBox(height: 16),
            _buildSuggestionsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _suggestions.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final suggestion = _suggestions[index];
        return ListTile(
          leading: const Icon(Icons.location_pin),
          title: Text(suggestion.displayName),
          subtitle: Text('${suggestion.city} ${suggestion.district}'),
          onTap: () => _selectLocation(suggestion),
        );
      },
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
    final viewModel = context.read<ProfileSetupViewModel>();
    viewModel.updateCity(suggestion.city);
    viewModel.updateDistrict(suggestion.district);
    // viewModel.updateCoordinates(suggestion.lat, suggestion.lon);

    _locationController.text = suggestion.displayName;
    _suggestions.clear();
    FocusManager.instance.primaryFocus?.unfocus();
  }
}
