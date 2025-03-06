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
          // Başlık kısmı
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1.0,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Çok az kaldı...',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Havalı bir kullanıcı adına ne dersin?',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    if (!isNicknameValid)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Zorunlu',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Takma ad bilgi mesajı
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Bu isim profilinizde görünecektir',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Takma ad girişi
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: isNicknameValid ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextFormField(
              controller: viewModel.nicknameController,
              decoration: InputDecoration(
                labelText: 'Takma Ad',
                hintText: 'En az 3 karakter giriniz',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: !isNicknameValid ? Colors.red : Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: !isNicknameValid ? Colors.red : Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isNicknameValid ? Colors.green : Theme.of(context).primaryColor,
                    width: 2.0,
                  ),
                ),
                prefixIcon: Icon(
                  Icons.person,
                  color: isNicknameValid ? Colors.green : null,
                ),
                suffixIcon: isNicknameValid ? const Icon(Icons.check_circle, color: Colors.green) : null,
                helperText: '',
                errorText: !isNicknameValid ? 'Takma ad en az 3 karakter olmalıdır' : null,
                fillColor: Colors.white,
                filled: true,
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
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isNicknameValid ? Colors.black87 : Colors.black54,
              ),
            ),
          ),

          // Takma ad geçerliyse onay mesajı göster
          if (isNicknameValid)
            Padding(
              padding: const EdgeInsets.only(top: 24.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Harika bir seçim!',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${viewModel.customer.nickname}',
                            style: TextStyle(
                              color: Colors.green.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const Spacer(),

          // İpucu
          if (!isNicknameValid)
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.amber.shade800),
                    const SizedBox(width: 8),
                    const Text(
                      'Eğlenceli ve özgün bir isim seçin!',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
