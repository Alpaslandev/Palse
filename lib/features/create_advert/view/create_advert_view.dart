import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:palseapp/core/constant/categories.dart';
import 'package:palseapp/core/localization/app_localizations.dart';
import 'package:palseapp/core/models/location_model.dart';
import 'package:palseapp/core/provider/ads_provider.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/core/routes/routes.dart';
import 'package:palseapp/core/services/location_service.dart';
import 'package:palseapp/core/widgets/scaffold_mess.dart';
import 'package:palseapp/features/create_advert/viewmodel/create_advert_view_model.dart';
import 'package:palseapp/core/widgets/location_sheet.dart';
import 'package:provider/provider.dart';

class CreateAdvertView extends StatefulWidget {
  const CreateAdvertView({super.key});

  @override
  State<CreateAdvertView> createState() => _CreateAdvertViewState();
}

class _CreateAdvertViewState extends State<CreateAdvertView> {
  // Form alanları için FocusNode'lar
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _descriptionFocusNode = FocusNode();
  final FocusNode _eventTypeFocusNode = FocusNode();
  final FocusNode _locationFocusNode = FocusNode();

  @override
  void dispose() {
    // FocusNode'ları temizle
    _titleFocusNode.dispose();
    _descriptionFocusNode.dispose();
    _eventTypeFocusNode.dispose();
    _locationFocusNode.dispose();
    super.dispose();
  }

  // Tarih ve saat seçimi için basitleştirilmiş yardımcı metod
  Future<void> _selectDateTime(BuildContext context, bool isStartDate, CreateAdvertViewModel viewModel) async {
    // Önce tarih seçimi
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null && context.mounted) {
      // Sonra saat seçimi
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        // Seçilen tarih ve saati birleştir ve viewModel'e aktar
        final DateTime selectedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        viewModel.setStartDate(selectedDateTime);
      }
    }
  }

  List<Step> _buildSteps(CreateAdvertViewModel viewModel, BuildContext context) {
    return [
      Step(
        isActive: viewModel.currentStep >= 0,
        title: const Icon(Icons.description),
        content: Form(
          key: viewModel.formKey,
          child: Column(
            children: [
              TextFormField(
                focusNode: _titleFocusNode,
                decoration: InputDecoration(labelText: context.tr('event_title')),
                maxLength: 40,
                onChanged: (value) => viewModel.advertName = value,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return context.tr('event_title_required');
                  }
                  if (value.length < 15) {
                    return context.tr('event_title_min_length');
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) {
                  FocusScope.of(context).requestFocus(_descriptionFocusNode);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                focusNode: _descriptionFocusNode,
                decoration: InputDecoration(labelText: context.tr('event_description')),
                maxLines: 5,
                maxLength: 300,
                onChanged: (value) => viewModel.advertDescription = value,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return context.tr('event_description_required');
                  }
                  if (value.length < 15) {
                    return context.tr('event_description_min_length');
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) {
                  FocusScope.of(context).requestFocus(_eventTypeFocusNode);
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Categories>(
                focusNode: _eventTypeFocusNode,
                decoration: InputDecoration(labelText: context.tr('event_type')),
                value: viewModel.eventType,
                items: Categories.values
                    .map((Categories category) =>
                        DropdownMenuItem(value: category, child: Text(category.getText(context), style: const TextStyle(fontSize: 12))))
                    .toList(),
                onChanged: (value) => viewModel.setEventType(value),
                validator: (value) => value == null ? context.tr('event_type_required') : null,
              ),
            ],
          ),
        ),
      ),
      Step(
        isActive: viewModel.currentStep >= 1,
        title: const Icon(Icons.photo_camera),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (viewModel.advertImage != null)
              Image.asset(
                viewModel.advertImage!.path,
                height: 200,
                fit: BoxFit.cover,
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: viewModel.authProvider.user?.isPremium == true
                  ? viewModel.pickImage
                  : () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(context.tr('only_premium_users_can_select_photo')),
                        action: SnackBarAction(
                            label: context.tr('premium_subscription'),
                            textColor: Colors.blue,
                            onPressed: () {
                              context.pushNamed(paywall);
                            }),
                      )),
              icon: const Icon(Icons.photo_camera),
              label: Text(context.tr('select_photo')),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _showGallery(context, viewModel),
              icon: const Icon(Icons.photo_outlined),
              label: Text(context.tr('use_ready_photo')),
            ),
          ],
        ),
      ),
      Step(
        isActive: viewModel.currentStep >= 2,
        title: const Icon(Icons.calendar_month),
        content: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(context.tr('event_date')),
              subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(viewModel.startDate ?? DateTime.now())),
              onTap: () => _selectDateTime(context, true, viewModel),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: viewModel.locationController,
              focusNode: _locationFocusNode,
              readOnly: true,
              decoration: InputDecoration(labelText: context.tr('event_location')),
              onTap: () async {
                if (!mounted) return;
                final result = await showModalBottomSheet<LocationModel>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  isDismissible: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  builder: (context) {
                    return FractionallySizedBox(
                      heightFactor: 0.95,
                      child: const LocationSheet(),
                    );
                  },
                );

                if (!mounted) return;
                if (result != null) {
                  viewModel.updateLocation(result);
                }
              },
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
    ];
  }

  void _showGallery(BuildContext context, CreateAdvertViewModel viewModel) {
    final List<String> images = [
      'assets/images/aakategori1.png',
      'assets/images/aakategori2.png',
      'assets/images/aakategori3.png',
      'assets/images/aakategori4.png',
      'assets/images/aakategori5.png',
      'assets/images/aakategori6.png',
      'assets/images/aakategori7.png',
      'assets/images/aakategori8.png',
      'assets/images/aakategori9.png',
      'assets/images/aakategori10.png',
      'assets/images/aakategori11.png',
      'assets/images/aakategori12.png',
      'assets/images/aakategori13.png',
      'assets/images/aakategori14.png',
      'assets/images/aakategori15.png',
      'assets/images/aakategori16.png',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Başlık ve Kapat butonu - Sabit kalacak
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(context.tr('use_ready_photo'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const Divider(),
                // Kaydırılabilir liste
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          // File yerine String path kullanıyoruz
                          viewModel.setAdvertImage(File(images[index]));
                          Navigator.pop(context);
                        },
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              images[index],
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Alt kısımda padding ekleyelim
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CreateAdvertViewModel>(
      create: (context) => CreateAdvertViewModel(authProvider: context.read<AuthProvider>(), locationService: LocationService()),
      child: Consumer<CreateAdvertViewModel>(
        builder: (context, viewModel, child) {
          return GestureDetector(
            // Ekranda boş bir alana tıklandığında klavyeyi kapat
            onTap: () {
              FocusScope.of(context).unfocus();
            },
            child: Scaffold(
              appBar: AppBar(
                title: Text(context.tr('create_advert')),
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
                        connectorColor: WidgetStateProperty.fromMap({
                          WidgetState.selected: Colors.blue,
                          WidgetState.disabled: Colors.grey.shade400,
                        }),
                        controlsBuilder: (context, details) {
                          // Boş bir widget döndürerek Stepper içindeki kontrolleri gizliyoruz
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ],
                ),
              ),
              // Butonları Scaffold'un en altına taşıyoruz
              bottomNavigationBar: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (viewModel.currentStep > 0)
                        TextButton.icon(
                          onPressed: viewModel.onStepCancel,
                          icon: const Icon(Icons.arrow_back),
                          label: Text(context.tr('back'), style: const TextStyle(color: Colors.blue)),
                        )
                      else
                        const SizedBox.shrink(),
                      ElevatedButton(
                        onPressed: () async {
                          if (viewModel.currentStep == 0) {
                            // İlk adımda form validasyonu yap
                            if (viewModel.formKey.currentState?.validate() ?? false) {
                              viewModel.onStepContinue();
                            }
                          } else if (viewModel.currentStep == 1) {
                            // İkinci adımda fotoğraf seçilmiş mi kontrol et
                            if (viewModel.advertImage == null) {
                              ScaffoldMess.showErrorSnackBar(context.tr('please_select_photo'));
                            } else {
                              viewModel.onStepContinue();
                            }
                          } else if (viewModel.currentStep == 2) {
                            // Son adımda tarih ve konum seçilmiş mi kontrol et
                            if (viewModel.startDate == null) {
                              ScaffoldMess.showErrorSnackBar(context.tr('please_select_event_date'));
                            } else if (viewModel.city.isEmpty || viewModel.district.isEmpty) {
                              ScaffoldMess.showErrorSnackBar(context.tr('please_select_event_location'));
                            } else {
                              // Premium kullanıcı ise direkt ilan oluştur
                              if (viewModel.authProvider.user?.isPremium == true) {
                                await viewModel.createAdvert();
                                if (!context.mounted) return;

                                // context.go yerine pushReplacement kullan
                                context.pushReplacement(myAdverts);

                                // Sonra başarı mesajını göster
                                ScaffoldMess.showSuccessSnackBar(
                                  context.tr('advert_created_successfully_premium'),
                                );
                              } else {
                                // Premium değilse, reklam göster ve sonrasında ilan oluştur
                                try {
                                  await context.read<AdsProvider>().showRewardedAd(onRewarded: (reward) async {
                                    await viewModel.createAdvert();
                                    if (!context.mounted) return;

                                    // Önce ilanlarım sayfasına git (navigasyon stack'ini değiştirmek için)
                                    // go yerine pushReplacement kullanarak stack'i boşaltmadan değiştiriyoruz
                                    context.pushReplacement(myAdverts);

                                    // Sonra premium olmayı öneren snackbar göster (premium sayfası stack'e eklenecek)
                                    ScaffoldMess.showGotoSnackBar(
                                      context.tr('advert_created_successfully_non_premium'),
                                      context.tr('get_premium'),
                                      paywall, // Paywall sayfasına yönlendirir
                                      shouldReplaceCurrentScreen: false, // Stack'e ekler
                                    );
                                  });
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMess.showErrorSnackBar(
                                    e.toString(),
                                  );
                                }
                              }
                            }
                          }
                        },
                        child: Text(viewModel.currentStep == 2 ? context.tr('finish') : context.tr('continue')),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
