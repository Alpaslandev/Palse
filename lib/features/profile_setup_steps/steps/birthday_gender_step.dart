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
            'Biraz Daha Bilgi',
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
          RadioListTile<String>(
            title: const Text('Erkek'),
            value: 'Erkek',
            groupValue: viewModel.customer.gender?.name,
            onChanged: (value) => viewModel.updateGender(Gender.values.firstWhere((e) => e.name == value)),
          ),
          RadioListTile<String>(
            title: const Text('Kadın'),
            value: 'Kadın',
            groupValue: viewModel.customer.gender?.name,
            onChanged: (value) => viewModel.updateGender(Gender.values.firstWhere((e) => e.name == value)),
          ),
        ],
      ),
    );
  }

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      context.read<ProfileSetupViewModel>().updateBirthDate(picked);
    }
  }
}
