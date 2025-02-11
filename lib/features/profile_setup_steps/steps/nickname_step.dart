import 'package:flutter/material.dart';
import 'package:palseapp/features/profile_setup_steps/steps/location_step.dart';
import 'package:palseapp/features/profile_setup_steps/viewmodel/profile_setup_view_model.dart';
import 'package:provider/provider.dart';

class NicknameStep extends StatelessWidget {
  final ProfileSetupViewModel viewModel;
  const NicknameStep({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Merhaba, ${context.read<ProfileSetupViewModel>().customer.firstName}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Takma Ad',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
            ),
            onChanged: (value) => context.read<ProfileSetupViewModel>().updateNickname(value),
          ),
          const SizedBox(height: 16),
          Text(
            'Bu isim profilinizde görünecektir',
            style: Theme.of(context).textTheme.bodySmall,
          )
        ],
      ),
    );
  }
}
