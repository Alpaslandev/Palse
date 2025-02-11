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
          ListTile(
            title: const Text('Doğum Tarihiniz'),
            subtitle: Text(
              viewModel.customer.birthday != null ? DateFormat('dd/MM/yyyy').format(viewModel.customer.birthday!) : 'Tarih seçiniz',
            ),
            trailing: const Icon(Icons.calendar_today),
            onTap: () => _selectDate(context),
          ),
          const SizedBox(height: 16),
          const Text('Cinsiyetiniz'),
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
          ListTile(
            title: const Text('Bu bilgilerini daha sonra değiştiremeyeceksin. O yüzden lütfen dikkatli ol'),
            trailing: const Icon(Icons.info),
          ),
        ],
      ),
    );
  }

  void _selectDate(BuildContext context) async {
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
