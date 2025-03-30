import 'package:flutter/material.dart';
import 'package:palseapp/core/localization/app_localizations.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/core/provider/locale_provider.dart';
import 'package:palseapp/features/profile_setup_steps/steps/birthday_gender_step.dart';
import 'package:palseapp/features/profile_setup_steps/steps/favorite_category_step.dart';
import 'package:palseapp/features/profile_setup_steps/steps/location_step.dart';
import 'package:palseapp/features/profile_setup_steps/steps/nickname_step.dart';
import 'package:palseapp/features/profile_setup_steps/steps/profile_picture_step.dart';
import 'package:palseapp/features/profile_setup_steps/steps/user_info_step.dart';
import 'package:palseapp/features/profile_setup_steps/viewmodel/profile_setup_view_model.dart';
import 'package:provider/provider.dart';

// Profil kurulum ekranı
class ProfileSetupView extends StatelessWidget {
  const ProfileSetupView({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: true);
    return ChangeNotifierProvider(
      create: (_) => ProfileSetupViewModel(authProvider: authProvider),
      child: Consumer<ProfileSetupViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: AppBar(
              // Dark mode uyumlu AppBar
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              elevation: 0,
              title: Row(
                children: [
                  Image.asset('assets/images/dostum_olsana.png', width: 40, height: 40),
                  const SizedBox(width: 8),
                  Text(
                    context.tr('profile_setup'),
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
                            context.tr('profile_setup_step').replaceAll('{step}', '${viewModel.currentStep + 1}'),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
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
                          backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            body: authProvider.isLoading
                ? Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor))
                : Container(
                    // Dark mode uyumlu gradient
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Theme.of(context).scaffoldBackgroundColor,
                          Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.surface : Colors.grey.shade50,
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

  // Alt navigasyon çubuğunu oluşturur
  Widget _buildNavigationBar(BuildContext context, ProfileSetupViewModel viewModel) {
    // Dark mode uyumlu bottom navigation bar
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Geri butonu - Dark mode uyumlu
            if (viewModel.currentStep > 0)
              ElevatedButton.icon(
                onPressed: viewModel.previousStep,
                icon: const Icon(Icons.arrow_back_rounded),
                label: Text(context.tr('profile_setup_back')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.surface : Colors.white,
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
                viewModel.isLastStep ? context.tr('profile_setup_finish') : context.tr('profile_setup_next'),
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

  // Navigasyon işlemlerini yönetir
  void _handleNavigation(BuildContext context, ProfileSetupViewModel viewModel) {
    final locale = Provider.of<LocaleProvider>(context, listen: false).locale;
    // İlk adımda ad ve soyad validasyonu yap
    if (viewModel.currentStep == 0 && !viewModel.isUserInfoStepValid()) {
      _showErrorSnackBar(context, context.tr('profile_setup_error_name'));
      return;
    }

    // İkinci adımda doğum tarihi ve cinsiyet validasyonu yap
    if (viewModel.currentStep == 1 && !viewModel.isBirthdayGenderStepValid()) {
      _showErrorSnackBar(context, context.tr('profile_setup_error_birthday_gender'));
      return;
    }

    // Üçüncü adımda konum validasyonu yap
    if (viewModel.currentStep == 2 && !viewModel.isLocationStepValid()) {
      _showErrorSnackBar(context, context.tr('profile_setup_error_location'));
      return;
    }

    // Dördüncü adımda takma ad validasyonu yap
    if (viewModel.currentStep == 3 && !viewModel.isNicknameStepValid()) {
      _showErrorSnackBar(context, context.tr('profile_setup_error_nickname'));
      return;
    }

    // Son adımda favori kategoriler validasyonu yap
    if (viewModel.currentStep == 5 && !viewModel.isFavoriteCategoryStepValid()) {
      _showErrorSnackBar(context, context.tr('profile_setup_error_categories'));
      return;
    }

    // Validasyon başarılıysa veya başka bir adımdaysa devam et
    viewModel.isLastStep ? viewModel.completeProfileSetup(locale.languageCode) : viewModel.nextStep();
  }

  // Hata mesajı gösterir
  void _showErrorSnackBar(BuildContext context, String message) {
    // Dark mode uyumlu SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }
}
