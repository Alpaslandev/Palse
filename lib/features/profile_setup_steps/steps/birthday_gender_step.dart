import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/features/profile_setup_steps/viewmodel/profile_setup_view_model.dart';
import 'package:provider/provider.dart';

class BirthdayGenderStep extends StatelessWidget {
  const BirthdayGenderStep({super.key, required this.viewModel});
  final ProfileSetupViewModel viewModel;
  @override
  Widget build(BuildContext context) {
    // Validasyon durumlarını kontrol et
    final bool isBirthdaySelected = viewModel.isBirthdayValid();
    final bool isGenderSelected = viewModel.isGenderValid();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Merhaba, ${viewModel.customer.firstName}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 32),

          // Doğum tarihi seçimi
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: !isBirthdaySelected ? Colors.red : Colors.grey.shade300,
                width: 1.0,
              ),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: ListTile(
              title: const Text('Doğum Tarihiniz'),
              subtitle: Text(
                viewModel.customer.birthday != null ? DateFormat('dd/MM/yyyy').format(viewModel.customer.birthday!) : 'Tarih seçiniz',
                style: TextStyle(
                  color: !isBirthdaySelected ? Colors.red : null,
                ),
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(context),
            ),
          ),

          // Doğum tarihi hata mesajı
          if (!isBirthdaySelected)
            const Padding(
              padding: EdgeInsets.only(left: 12.0, top: 4.0),
              child: Text(
                'Doğum tarihi seçmelisiniz',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),

          const SizedBox(height: 16),

          // Cinsiyet seçimi başlığı
          Row(
            children: [
              const Text('Cinsiyetiniz'),
              if (!isGenderSelected)
                const Text(
                  ' (Seçim yapmalısınız)',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
            ],
          ),

          // Cinsiyet seçenekleri
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: !isGenderSelected ? Colors.red : Colors.transparent,
                width: 1.0,
              ),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Column(
              children: [
                RadioListTile<Gender>(
                  title: const Text('Erkek'),
                  value: Gender.male,
                  groupValue: viewModel.customer.gender,
                  onChanged: (value) => viewModel.updateGender(value!),
                ),
                RadioListTile<Gender>(
                  title: const Text('Kadın'),
                  value: Gender.female,
                  groupValue: viewModel.customer.gender,
                  onChanged: (value) => viewModel.updateGender(value!),
                ),
                RadioListTile<Gender>(
                  title: const Text('Diğer'),
                  value: Gender.others,
                  groupValue: viewModel.customer.gender,
                  onChanged: (value) => viewModel.updateGender(value!),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          ListTile(
            title: const Text('Bu bilgilerini daha sonra değiştiremeyeceksin. O yüzden lütfen dikkatli ol'),
            trailing: const Icon(Icons.info),
          ),
        ],
      ),
    );
  }

  void _selectDate(BuildContext context) async {
    debugPrint('Locale: ${Intl.getCurrentLocale()}');
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)), // 18 yıl öncesine kadar
    );
    if (picked != null && picked.isBefore(DateTime.now().subtract(const Duration(days: 365 * 18))) && context.mounted) {
      context.read<ProfileSetupViewModel>().updateBirthDate(picked);
    }
  }
}
