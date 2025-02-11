import 'package:flutter/material.dart';
import 'package:palseapp/features/profile_setup_steps/steps/user_info_step.dart';
import 'package:palseapp/features/profile_setup_steps/viewmodel/profile_setup_view_model.dart';
import 'package:provider/provider.dart';

class LocationStep extends StatelessWidget {
  final ProfileSetupViewModel viewModel;
  const LocationStep({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final cityController = TextEditingController();
    final districtController = TextEditingController();
    return Padding(
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
            'Çevrenizdeki etkinlikleri keşfedebilmek için lütfen konum bilgilerinizi giriniz',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 32),
          DropdownButtonFormField<String>(
            value: cityController.text.isEmpty ? null : cityController.text,
            items: ['İstanbul', 'Ankara', 'İzmir'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (value) {
              cityController.text = value!;
              context.read<ProfileSetupViewModel>().updateCity(value);
            },
            decoration: const InputDecoration(
              labelText: 'İl',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_city),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: districtController.text.isEmpty ? null : districtController.text,
            items: _getDistricts(cityController.text).map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (value) {
              districtController.text = value!;
              context.read<ProfileSetupViewModel>().updateDistrict(value);
            },
            decoration: const InputDecoration(
              labelText: 'İlçe',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.map_outlined),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getDistricts(String city) {
    // İllere göre ilçe listesi döndür
    return const [];
  }
}
