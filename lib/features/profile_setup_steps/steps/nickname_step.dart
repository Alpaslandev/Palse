import 'package:flutter/material.dart';
import 'package:palseapp/features/profile_setup_steps/viewmodel/profile_setup_view_model.dart';
import 'package:provider/provider.dart';
import 'package:palseapp/core/localization/app_localizations.dart';

class NicknameStep extends StatelessWidget {
  final ProfileSetupViewModel viewModel;
  const NicknameStep({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    // Takma ad geçerli mi kontrol et
    final bool isNicknameValid = viewModel.isNicknameValid();

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
                    context.tr('nickname_almost_done'),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.tr('nickname_choose_cool'),
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      if (!isNicknameValid)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.red.shade900.withOpacity(0.3) : Colors.red.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            context.tr('nickname_required'),
                            style: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.red.shade300 : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Takma ad bilgi mesajı
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).primaryColor.withOpacity(0.2) : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.tr('nickname_profile_info'),
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Takma ad girişi
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: isNicknameValid ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextFormField(
                controller: viewModel.nicknameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: context.tr('nickname_label'),
                  hintText: context.tr('nickname_hint'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: !isNicknameValid
                          ? Colors.red
                          : Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey.shade700
                              : Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: !isNicknameValid
                          ? Colors.red
                          : Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey.shade700
                              : Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isNicknameValid ? Colors.green : Theme.of(context).primaryColor,
                      width: 2.0,
                    ),
                  ),
                  prefixIcon: Icon(
                    Icons.person,
                    color: isNicknameValid ? Colors.green : null,
                  ),
                  suffixIcon: isNicknameValid ? const Icon(Icons.check_circle, color: Colors.green) : null,
                  helperText: '',
                  errorText: !isNicknameValid ? context.tr('nickname_min_length_error') : null,
                  fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                  filled: true,
                ),
                onChanged: (value) => context.read<ProfileSetupViewModel>().updateNickname(value),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return context.tr('nickname_please_enter');
                  }
                  if (value.length < 3) {
                    return context.tr('nickname_min_length_error');
                  }
                  return null;
                },
                autovalidateMode: AutovalidateMode.onUserInteraction,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),

            // Takma ad geçerliyse onay mesajı göster
            if (isNicknameValid)
              Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: Container(
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
                              context.tr('nickname_great_choice'),
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${viewModel.customer.nickname}',
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
                ),
              ),

            const SizedBox(height: 32),

            // İpucu
            if (!isNicknameValid)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.amber.shade900.withOpacity(0.2) : Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.amber.shade700 : Colors.amber.shade200,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.amber.shade300 : Colors.amber.shade800,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        context.tr('nickname_tip'),
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Klavye açıldığında alt kısmın görünmesi için ekstra boşluk
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
