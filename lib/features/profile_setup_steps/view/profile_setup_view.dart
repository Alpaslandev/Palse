import 'package:flutter/material.dart';
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
      create: (_) => ProfileSetupViewModel(),
      child: Consumer<ProfileSetupViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            appBar: AppBar(
              title: Image.asset('assets/images/dostum_olsana.png', width: 50, height: 50),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: LinearProgressIndicator(
                  value: (viewModel.currentStep + 1) / 5,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                ),
              ),
            ),
            body: PageView(
              controller: viewModel.pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                UserInfoStep(viewModel: viewModel),
                BirthdayGenderStep(viewModel: viewModel),
                NicknameStep(viewModel: viewModel),
                LocationStep(viewModel: viewModel),
                ProfilePictureStep(viewModel: viewModel),
                FavoriteCategoryStep(viewModel: viewModel),
              ],
            ),
            floatingActionButton: _buildNavigationButtons(context, viewModel),
          );
        },
      ),
    );
  }

  Widget _buildNavigationButtons(BuildContext context, ProfileSetupViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (viewModel.currentStep > 0)
            FloatingActionButton.extended(
              onPressed: viewModel.previousStep,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Geri'),
              backgroundColor: Theme.of(context).primaryColor,
            ),
          FloatingActionButton.extended(
            onPressed: () => _handleNextStep(context, viewModel),
            icon: const Icon(Icons.arrow_forward),
            label: Text(viewModel.currentStep == 4 ? 'Tamamla' : 'İleri'),
            backgroundColor: Theme.of(context).primaryColor,
          ),
        ],
      ),
    );
  }

  void _handleNextStep(BuildContext context, ProfileSetupViewModel viewModel) {
    if (viewModel.currentStep == 4) {
      _completeProfileSetup(context);
    } else {
      viewModel.nextStep();
    }
  }

  void _completeProfileSetup(BuildContext context) {
    // Profil tamamlama işlemleri
    Navigator.of(context).pushReplacementNamed('/home');
  }
}
