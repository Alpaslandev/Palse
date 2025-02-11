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
              title: Image.asset('assets/images/dostum_olsana.png', width: 50, height: 50),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: LinearProgressIndicator(
                  value: (viewModel.currentStep + 1) / 6,
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
                LocationStep(viewModel: viewModel),
                NicknameStep(viewModel: viewModel),
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
            onPressed: () => viewModel.isLastStep ? viewModel.completeProfileSetup() : viewModel.nextStep(),
            icon: const Icon(Icons.arrow_forward),
            label: Text(viewModel.isLastStep ? 'Tamamla' : 'İleri'),
            backgroundColor: Theme.of(context).primaryColor,
          ),
        ],
      ),
    );
  }
}
