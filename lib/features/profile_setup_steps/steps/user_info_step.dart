import 'package:flutter/material.dart';
import 'package:palseapp/core/localization/app_localizations.dart';
import 'package:palseapp/features/profile_setup_steps/viewmodel/profile_setup_view_model.dart';
import 'package:provider/provider.dart';
import 'package:palseapp/core/provider/auth_provider.dart';

class UserInfoStep extends StatefulWidget {
  const UserInfoStep({super.key, required this.viewModel});
  final ProfileSetupViewModel viewModel;

  @override
  State<UserInfoStep> createState() => _UserInfoStepState();
}

class _UserInfoStepState extends State<UserInfoStep> {
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Fill Apple User Info If Available
    if (!_isInitialized) {
      _fillAppleUserInfoIfAvailable();
      _isInitialized = true;
    }
  }

  // Fill Apple User Info If Available
  void _fillAppleUserInfoIfAvailable() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final appleDisplayName = authProvider.firebaseUser?.displayName;
    debugPrint('Apple Display Name: $appleDisplayName');

    if (appleDisplayName != null && appleDisplayName.isNotEmpty) {
      final nameParts = appleDisplayName.split(' ');

      final firstName = nameParts.first;
      final lastName = nameParts.length > 1 ? nameParts.last : '';

      if (firstName.isNotEmpty && widget.viewModel.firstNameController.text.isEmpty) {
        widget.viewModel.firstNameController.text = firstName;
        widget.viewModel.updateFirstName(firstName);
      }

      if (lastName.isNotEmpty && widget.viewModel.lastNameController.text.isEmpty) {
        widget.viewModel.lastNameController.text = lastName;
        widget.viewModel.updateLastName(lastName);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Validasyon durumunu kontrol et
    final bool isFirstNameValid = widget.viewModel.firstNameController.text.length >= 3;
    final bool isLastNameValid = widget.viewModel.lastNameController.text.length >= 3;
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
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade700 : Colors.grey.shade200,
                    width: 1.0,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('user_info_welcome'),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.tr('user_info_description'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // İsim giriş alanı
            _buildTextFieldWithValidation(
              context,
              controller: widget.viewModel.firstNameController,
              labelText: context.tr('user_info_first_name'),
              hintText: context.tr('user_info_first_name_hint'),
              isValid: isFirstNameValid,
              onChanged: widget.viewModel.updateFirstName,
            ),

            const SizedBox(height: 16),

            // Soyisim giriş alanı
            _buildTextFieldWithValidation(
              context,
              controller: widget.viewModel.lastNameController,
              labelText: context.tr('user_info_last_name'),
              hintText: context.tr('user_info_last_name_hint'),
              isValid: isLastNameValid,
              onChanged: widget.viewModel.updateLastName,
            ),

            const SizedBox(height: 32),

            // Bilgi ve onay mesajı
            if (isAllValid)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.green.shade900.withOpacity(0.2) : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.green.shade700 : Colors.green.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('user_info_perfect'),
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context
                                .tr('user_info_hello')
                                .replaceAll('{firstName}', widget.viewModel.firstNameController.text)
                                .replaceAll('{lastName}', widget.viewModel.lastNameController.text),
                            style: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.green.shade300 : Colors.green.shade800,
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
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.blue.shade900.withOpacity(0.2) : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.blue.shade700 : Colors.blue.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.blue.shade300 : Colors.blue.shade700,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('user_info_info'),
                            style: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.blue.shade300 : Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.tr('user_info_please_enter'),
                            style: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.blue.shade200 : Colors.blue.shade800,
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

  Widget _buildTextFieldWithValidation(
    BuildContext context, {
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required bool isValid,
    required Function(String) onChanged,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? errorText,
  }) {
    // TextField'ı bir InputDecoration ile döndür
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Etiket
        Text(
          labelText,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        // TextField
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: Theme.of(context).inputDecorationTheme.fillColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: controller.text.isNotEmpty
                    ? (isValid ? Colors.green : Colors.red)
                    : Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade700
                        : Colors.grey.shade300,
                width: 1.0,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: controller.text.isNotEmpty
                    ? (isValid ? Colors.green : Colors.red)
                    : Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade700
                        : Colors.grey.shade300,
                width: 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: controller.text.isNotEmpty ? (isValid ? Colors.green : Colors.red) : Theme.of(context).primaryColor,
                width: 2.0,
              ),
            ),
            errorText: controller.text.isNotEmpty && !isValid ? errorText : null,
            suffixIcon: controller.text.isNotEmpty
                ? Icon(
                    isValid ? Icons.check_circle : Icons.cancel,
                    color: isValid ? Colors.green : Colors.red,
                  )
                : null,
          ),
          onChanged: onChanged,
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ],
    );
  }
}
