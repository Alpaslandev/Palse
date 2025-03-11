import 'package:flutter/material.dart';
import 'package:palseapp/features/profile_setup_steps/viewmodel/profile_setup_view_model.dart';

class UserInfoStep extends StatelessWidget {
  const UserInfoStep({super.key, required this.viewModel});
  final ProfileSetupViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    // Validasyon durumunu kontrol et
    final bool isFirstNameValid = viewModel.firstNameController.text.length >= 3;
    final bool isLastNameValid = viewModel.lastNameController.text.length >= 3;
    final bool isAllValid = isFirstNameValid && isLastNameValid;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
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
                    'Hoşgeldin!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Deneyimini hazırlamak için birkaç bilgi girmeni rica ediyoruz.',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // İsim giriş alanı
            Text(
              'Adınız',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: isFirstNameValid ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextFormField(
                controller: viewModel.firstNameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'Adınızı girin',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: !isFirstNameValid && viewModel.firstNameController.text.isNotEmpty ? Colors.red : Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: !isFirstNameValid && viewModel.firstNameController.text.isNotEmpty ? Colors.red : Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isFirstNameValid ? Colors.green : Theme.of(context).primaryColor,
                      width: 2.0,
                    ),
                  ),
                  prefixIcon: Icon(
                    Icons.person_outline,
                    color: isFirstNameValid && viewModel.firstNameController.text.isNotEmpty ? Colors.green : null,
                  ),
                  suffixIcon:
                      isFirstNameValid && viewModel.firstNameController.text.isNotEmpty ? const Icon(Icons.check_circle, color: Colors.green) : null,
                  helperText: '',
                  errorText: !isFirstNameValid && viewModel.firstNameController.text.isNotEmpty ? 'Ad en az 3 karakter olmalıdır' : null,
                  fillColor: Colors.white,
                  filled: true,
                ),
                onChanged: viewModel.updateFirstName,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen adınızı girin';
                  }
                  if (value.length < 3) {
                    return 'Ad en az 3 karakter olmalıdır';
                  }
                  return null;
                },
                autovalidateMode: AutovalidateMode.onUserInteraction,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: isFirstNameValid ? Colors.black87 : Colors.black54,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Soyad giriş alanı
            Text(
              'Soyadınız',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: isLastNameValid ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextFormField(
                controller: viewModel.lastNameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'Soyadınızı girin',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: !isLastNameValid && viewModel.lastNameController.text.isNotEmpty ? Colors.red : Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: !isLastNameValid && viewModel.lastNameController.text.isNotEmpty ? Colors.red : Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isLastNameValid ? Colors.green : Theme.of(context).primaryColor,
                      width: 2.0,
                    ),
                  ),
                  prefixIcon: Icon(
                    Icons.people_outline,
                    color: isLastNameValid && viewModel.lastNameController.text.isNotEmpty ? Colors.green : null,
                  ),
                  suffixIcon:
                      isLastNameValid && viewModel.lastNameController.text.isNotEmpty ? const Icon(Icons.check_circle, color: Colors.green) : null,
                  helperText: '',
                  errorText: !isLastNameValid && viewModel.lastNameController.text.isNotEmpty ? 'Soyad en az 3 karakter olmalıdır' : null,
                  fillColor: Colors.white,
                  filled: true,
                ),
                onChanged: viewModel.updateLastName,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen soyadınızı girin';
                  }
                  if (value.length < 3) {
                    return 'Soyad en az 3 karakter olmalıdır';
                  }
                  return null;
                },
                autovalidateMode: AutovalidateMode.onUserInteraction,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: isLastNameValid ? Colors.black87 : Colors.black54,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Bilgi ve onay mesajı
            if (isAllValid)
              Container(
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
                            'Mükemmel!',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Merhaba ${viewModel.firstNameController.text} ${viewModel.lastNameController.text}, şimdi diğer adımlara geçebilirsin.',
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
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bilgi',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Lütfen adınızı ve soyadınızı girin. Bu bilgiler profilinizde görünecektir.',
                            style: TextStyle(
                              color: Colors.blue.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Klavye açıldığında alt kısmın görünmesi için ekstra boşluk
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
