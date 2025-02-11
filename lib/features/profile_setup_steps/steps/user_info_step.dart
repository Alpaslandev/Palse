import 'package:flutter/material.dart';
import 'package:palseapp/features/profile_setup_steps/viewmodel/profile_setup_view_model.dart';

class UserInfoStep extends StatelessWidget {
  const UserInfoStep({super.key, required this.viewModel});
  final ProfileSetupViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hoşgeldin! Deneyimini hazırlamak için birkaç bilgi girmeni rica ediyoruz.',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 32),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Adınız',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person_outline),
            ),
            onChanged: viewModel.updateFirstName,
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Soyadınız',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.people_outline),
            ),
            onChanged: viewModel.updateLastName,
          ),
        ],
      ),
    );
  }
}
