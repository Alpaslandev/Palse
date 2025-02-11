import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:palseapp/core/constant/categories.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/core/services/location_service.dart';
import 'package:palseapp/features/create_advert/viewmodel/create_advert_view_model.dart';
import 'package:provider/provider.dart';

class CreateAdvertView extends StatelessWidget {
  const CreateAdvertView({super.key});

  // Tarih ve saat seçimi için yardımcı metod
  Future<void> _selectDateTime(BuildContext context, bool isStartDate, CreateAdvertViewModel viewModel) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: isStartDate ? DateTime.now() : (viewModel.startDate ?? DateTime.now()),
      firstDate: isStartDate ? DateTime.now() : (viewModel.startDate ?? DateTime.now()),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      // ignore: use_build_context_synchronously
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        final DateTime combinedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        if (isStartDate) {
          viewModel.setStartDate(combinedDateTime);
        } else {
          viewModel.setEndDate(combinedDateTime);
        }
      }
    }
  }

  List<Step> _buildSteps(CreateAdvertViewModel viewModel, BuildContext context) {
    return [
      Step(
        isActive: viewModel.currentStep >= 0,
        title: const Icon(Icons.description),
        label: const Text('Bilgiler'),
        content: Form(
          key: viewModel.formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'İlan Adı'),
                onChanged: (value) => viewModel.advertName = value,
                validator: (value) => value?.isEmpty ?? true ? 'İlan adı gerekli' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'İlan Açıklaması'),
                maxLines: 3,
                onChanged: (value) => viewModel.advertDescription = value,
                validator: (value) => value?.isEmpty ?? true ? 'İlan açıklaması gerekli' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Etkinlik Tipi'),
                value: viewModel.eventType,
                items: categories.map((String category) => DropdownMenuItem(value: category, child: Text(category))).toList(),
                onChanged: (value) => viewModel.setEventType(value),
                validator: (value) => value == null ? 'Etkinlik tipi seçiniz' : null,
              ),
            ],
          ),
        ),
      ),
      Step(
        isActive: viewModel.currentStep >= 1,
        title: const Icon(Icons.photo_camera),
        label: const Text('Görsel'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (viewModel.advertImage != null)
              Image.file(
                File(viewModel.advertImage!.path),
                height: 200,
                fit: BoxFit.cover,
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: viewModel.pickImage,
              icon: const Icon(Icons.photo_camera),
              label: const Text('Fotoğraf Seç'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: viewModel.getCurrentLocation,
              icon: const Icon(Icons.location_on),
              label: const Text('Konum Seç'),
            ),
            if (viewModel.city.isNotEmpty && viewModel.district.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.location_city),
                title: Text('${viewModel.city} / ${viewModel.district}'),
                subtitle: Text(viewModel.address),
              ),
          ],
        ),
      ),
      Step(
        isActive: viewModel.currentStep >= 2,
        title: const Icon(Icons.calendar_month),
        label: const Text('Tarih'),
        content: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Başlangıç Tarihi ve Saati'),
              subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(viewModel.startDate ?? DateTime.now())),
              onTap: () => _selectDateTime(context, true, viewModel),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Bitiş Tarihi ve Saati'),
              subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(viewModel.endDate ?? DateTime.now())),
              onTap: () => _selectDateTime(context, false, viewModel),
            ),
          ],
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CreateAdvertViewModel>(
      create: (context) => CreateAdvertViewModel(authProvider: context.read<AuthProvider>(), locationService: LocationService()),
      child: Consumer<CreateAdvertViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('İlan Oluştur'),
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Expanded(
                    child: Stepper(
                      type: StepperType.horizontal,
                      currentStep: viewModel.currentStep,
                      onStepContinue: viewModel.onStepContinue,
                      onStepCancel: viewModel.onStepCancel,
                      steps: _buildSteps(viewModel, context),
                      controlsBuilder: (context, details) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Row(
                            children: [
                              ElevatedButton(
                                onPressed: details.onStepContinue,
                                child: Text(viewModel.currentStep == 2 ? 'Tamamla' : 'Devam Et'),
                              ),
                              if (viewModel.currentStep > 0) ...[
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: details.onStepCancel,
                                  child: const Text('Geri'),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
