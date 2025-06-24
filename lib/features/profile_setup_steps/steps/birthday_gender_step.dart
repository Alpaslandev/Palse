import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:palseapp/core/localization/app_localizations.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/features/profile_setup_steps/viewmodel/profile_setup_view_model.dart';

// Doğum tarihi ve cinsiyet adımı
class BirthdayGenderStep extends StatelessWidget {
  final ProfileSetupViewModel viewModel;

  const BirthdayGenderStep({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    // Geçerlilik durumlarını kontrol et
    final bool isBirthdayValid = viewModel.isBirthdayValid();
    final bool isGenderValid = viewModel.isGenderValid();

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
                    context.tr('birthday_gender_title'),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Doğum tarihi seçimi
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      context.tr('birthday_gender_birthday'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.blue.shade900.withOpacity(0.3) : Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        context.tr('birthday_gender_optional'),
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.blue.shade300 : Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _showDatePicker(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).inputDecorationTheme.fillColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: viewModel.customer.birthday != null
                            ? Colors.green
                            : Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade700
                                : Colors.grey.shade300,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: viewModel.customer.birthday != null ? Colors.green : Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          viewModel.customer.birthday != null
                              ? DateFormat('dd MMMM yyyy', 'tr').format(
                                  viewModel.customer.birthday!,
                                )
                              : context.tr('birthday_gender_select_date'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: viewModel.customer.birthday != null ? Theme.of(context).textTheme.bodyLarge?.color : Theme.of(context).hintColor,
                          ),
                        ),
                        const Spacer(),
                        if (viewModel.customer.birthday != null)
                          const Icon(Icons.check_circle, color: Colors.green)
                        else
                          Icon(Icons.arrow_forward_ios, size: 16, color: Theme.of(context).hintColor),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Cinsiyet seçimi
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      context.tr('birthday_gender_gender'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.blue.shade900.withOpacity(0.3) : Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        context.tr('birthday_gender_optional'),
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.blue.shade300 : Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.zero,
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildGenderCard(
                          context,
                          Gender.male,
                          Icons.male,
                          context.tr('birthday_gender_male'),
                          Theme.of(context).brightness == Brightness.dark ? Colors.blue.shade900.withOpacity(0.3) : Colors.blue.shade50,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildGenderCard(
                          context,
                          Gender.female,
                          Icons.female,
                          context.tr('birthday_gender_female'),
                          Theme.of(context).brightness == Brightness.dark ? Colors.pink.shade900.withOpacity(0.3) : Colors.pink.shade50,
                          Colors.pink,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildGenderCard(
                          context,
                          Gender.others,
                          Icons.transgender,
                          context.tr('birthday_gender_other'),
                          Theme.of(context).brightness == Brightness.dark ? Colors.purple.shade900.withOpacity(0.3) : Colors.purple.shade50,
                          Colors.purple,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Bilgi mesajı - her durumda gösteriliyor
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
                          context.tr('birthday_gender_info'),
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.blue.shade300 : Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.tr('birthday_gender_optional_info'),
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

  Widget _buildGenderCard(
    BuildContext context,
    Gender gender,
    IconData icon,
    String label,
    Color backgroundColor,
    Color iconColor,
  ) {
    final bool isSelected = viewModel.customer.gender == gender;

    return GestureDetector(
      onTap: () {
        viewModel.updateGender(gender);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? backgroundColor : Theme.of(context).inputDecorationTheme.fillColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? iconColor
                : Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade700
                    : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? iconColor.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? iconColor
                  : Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade400
                      : Colors.grey.shade600,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? iconColor
                    : Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade300
                        : Colors.grey.shade800,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 8),
              Icon(
                Icons.check_circle,
                color: iconColor,
                size: 16,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showDatePicker(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: viewModel.customer.birthday ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1940),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)), // En az 18 yaş
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              onSurface: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      viewModel.updateBirthDate(picked);
    }
  }
}
