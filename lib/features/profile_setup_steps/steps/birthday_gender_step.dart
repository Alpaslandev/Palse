import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/features/profile_setup_steps/viewmodel/profile_setup_view_model.dart';

class BirthdayGenderStep extends StatelessWidget {
  final ProfileSetupViewModel viewModel;

  const BirthdayGenderStep({Key? key, required this.viewModel}) : super(key: key);

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
                    color: Colors.grey.shade200,
                    width: 1.0,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sizi tanıyalım',
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
                      'Doğum Tarihiniz',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(width: 8),
                    if (!isBirthdayValid)
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
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _showDatePicker(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: !isBirthdayValid
                            ? Colors.red
                            : isBirthdayValid
                                ? Colors.green
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
                          color: isBirthdayValid ? Colors.green : Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          viewModel.customer.birthday != null
                              ? DateFormat('dd MMMM yyyy', 'tr').format(
                                  viewModel.customer.birthday!,
                                )
                              : 'Doğum tarihinizi seçin',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: viewModel.customer.birthday != null ? Colors.black87 : Colors.grey.shade600,
                          ),
                        ),
                        const Spacer(),
                        if (isBirthdayValid)
                          const Icon(Icons.check_circle, color: Colors.green)
                        else
                          Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade600),
                      ],
                    ),
                  ),
                ),
                if (!isBirthdayValid)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, left: 16),
                    child: Text(
                      'Lütfen doğum tarihinizi seçin',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 12,
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
                      'Cinsiyetiniz',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(width: 8),
                    if (!isGenderValid)
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
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: !isGenderValid ? Border.all(color: Colors.red) : null,
                  ),
                  padding: !isGenderValid ? const EdgeInsets.all(8) : EdgeInsets.zero,
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildGenderCard(
                          context,
                          Gender.male,
                          Icons.male,
                          'Erkek',
                          Colors.blue.shade50,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildGenderCard(
                          context,
                          Gender.female,
                          Icons.female,
                          'Kadın',
                          Colors.pink.shade50,
                          Colors.pink,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildGenderCard(
                          context,
                          Gender.others,
                          Icons.transgender,
                          'Diğer',
                          Colors.purple.shade50,
                          Colors.purple,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isGenderValid)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, left: 16),
                    child: Text(
                      'Lütfen cinsiyetinizi seçin',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 32),

            // Her iki alan da geçerliyse onay mesajı göster
            if (isBirthdayValid && isGenderValid)
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
                            'Harika!',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Temel bilgileriniz tamamlandı, şimdi diğer adımlara geçebilirsiniz.',
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
                            'Doğum tarihiniz ve cinsiyetiniz size uygun etkinlikleri önerirken kullanılacaktır.',
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
          color: isSelected ? backgroundColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? iconColor : Colors.grey.shade300,
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
              color: isSelected ? iconColor : Colors.grey.shade600,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? iconColor : Colors.grey.shade800,
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
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 13)), // En az 13 yaş
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
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
