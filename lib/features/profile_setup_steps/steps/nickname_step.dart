import 'package:flutter/material.dart';
import 'package:palseapp/features/profile_setup_steps/viewmodel/profile_setup_view_model.dart';
import 'package:provider/provider.dart';

class NicknameStep extends StatelessWidget {
  final ProfileSetupViewModel viewModel;
  const NicknameStep({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    // Takma ad geçerli mi kontrol et
    final bool isNicknameValid = viewModel.isNicknameValid();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Çok az kaldı...',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Havalı bir kullanıcı adına ne dersin?',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              if (!isNicknameValid)
                const Text(
                  '(Zorunlu)',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: viewModel.nicknameController,
            decoration: InputDecoration(
              labelText: 'Takma Ad',
              border: OutlineInputBorder(
                borderSide: BorderSide(
                  color: !isNicknameValid ? Colors.red : Colors.grey.shade300,
                  width: 1.0,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: !isNicknameValid ? Colors.red : Colors.grey.shade300,
                  width: 1.0,
                ),
              ),
              prefixIcon: const Icon(Icons.person),
              helperText: '',
              errorText: !isNicknameValid ? 'Takma ad en az 3 karakter olmalıdır' : null,
            ),
            onChanged: (value) => context.read<ProfileSetupViewModel>().updateNickname(value),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Lütfen bir takma ad girin';
              }
              if (value.length < 3) {
                return 'Takma ad en az 3 karakter olmalıdır';
              }
              return null;
            },
            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),
          const SizedBox(height: 16),
          Text(
            'Bu isim profilinizde görünecektir',
            style: Theme.of(context).textTheme.bodySmall,
          ),

          // Takma ad geçerliyse onay mesajı göster
          if (isNicknameValid)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        'Harika bir seçim: ${viewModel.customer.nickname}',
                        style: const TextStyle(color: Colors.green),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
