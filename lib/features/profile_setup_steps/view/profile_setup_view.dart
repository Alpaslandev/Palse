import 'package:flutter/material.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/features/profile_setup_steps/steps/birthday_gender_step.dart';
import 'package:palseapp/features/profile_setup_steps/steps/favorite_category_step.dart';
import 'package:palseapp/features/profile_setup_steps/steps/location_step.dart';
import 'package:palseapp/features/profile_setup_steps/steps/nickname_step.dart';
import 'package:palseapp/features/profile_setup_steps/steps/profile_picture_step.dart';
import 'package:palseapp/features/profile_setup_steps/steps/user_info_step.dart';
import 'package:palseapp/features/profile_setup_steps/viewmodel/profile_setup_view_model.dart';
import 'package:provider/provider.dart';

class ProfileSetupView extends StatelessWidget {
  const ProfileSetupView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileSetupViewModel(authProvider: Provider.of<AuthProvider>(context, listen: false)),
      child: Consumer<ProfileSetupViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              title: Row(
                children: [
                  Image.asset('assets/images/dostum_olsana.png', width: 40, height: 40),
                  const SizedBox(width: 8),
                  Text(
                    'Profil Oluştur',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(50),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            'Adım ${viewModel.currentStep + 1}/6',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${((viewModel.currentStep + 1) / 6 * 100).toInt()}%',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: (viewModel.currentStep + 1) / 6,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white,
                    Colors.grey.shade50,
                  ],
                ),
              ),
              child: PageView(
                controller: viewModel.pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  UserInfoStep(viewModel: viewModel),
                  BirthdayGenderStep(viewModel: viewModel),
                  LocationStep(viewModel: viewModel),
                  NicknameStep(viewModel: viewModel),
                  ProfilePictureStep(viewModel: viewModel),
                  FavoriteCategoryStep(viewModel: viewModel),
                ],
              ),
            ),
            bottomNavigationBar: _buildNavigationBar(context, viewModel),
          );
        },
      ),
    );
  }

  Widget _buildNavigationBar(BuildContext context, ProfileSetupViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Geri butonu
            if (viewModel.currentStep > 0)
              ElevatedButton.icon(
                onPressed: viewModel.previousStep,
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Geri'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Theme.of(context).primaryColor,
                  elevation: 0,
                  side: BorderSide(color: Theme.of(context).primaryColor),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              )
            else
              const SizedBox.shrink(),

            // İleri/Tamamla butonu
            ElevatedButton.icon(
              onPressed: () => _handleNavigation(context, viewModel),
              label: Text(
                viewModel.isLastStep ? 'Tamamla' : 'İleri',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              icon: Icon(viewModel.isLastStep ? Icons.check_circle : Icons.arrow_forward_rounded),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNavigation(BuildContext context, ProfileSetupViewModel viewModel) {
    // İlk adımda ad ve soyad validasyonu yap
    if (viewModel.currentStep == 0 && !viewModel.isUserInfoStepValid()) {
      _showErrorSnackBar(context, 'Lütfen ad ve soyadınızı doğru şekilde girin (en az 3 karakter)');
      return;
    }

    // İkinci adımda doğum tarihi ve cinsiyet validasyonu yap
    if (viewModel.currentStep == 1 && !viewModel.isBirthdayGenderStepValid()) {
      _showErrorSnackBar(context, 'Lütfen doğum tarihinizi ve cinsiyetinizi seçin');
      return;
    }

    // Üçüncü adımda konum validasyonu yap
    if (viewModel.currentStep == 2 && !viewModel.isLocationStepValid()) {
      _showErrorSnackBar(context, 'Lütfen bir konum seçin veya mevcut konumunuzu kullanın');
      return;
    }

    // Dördüncü adımda takma ad validasyonu yap
    if (viewModel.currentStep == 3 && !viewModel.isNicknameStepValid()) {
      _showErrorSnackBar(context, 'Lütfen geçerli bir takma ad girin (en az 3 karakter)');
      return;
    }

    // Son adımda favori kategoriler validasyonu yap
    if (viewModel.currentStep == 5 && !viewModel.isFavoriteCategoryStepValid()) {
      _showErrorSnackBar(context, 'Lütfen en az 3 kategori seçin');
      return;
    }

    // Validasyon başarılıysa veya başka bir adımdaysa devam et
    viewModel.isLastStep ? viewModel.completeProfileSetup() : viewModel.nextStep();
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }
}
