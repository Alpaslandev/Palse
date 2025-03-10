import 'dart:io';

import 'package:flutter/material.dart';
import 'package:palseapp/core/localization/app_localizations.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/models/location_model.dart';
import 'package:palseapp/core/services/cloud_storage.dart';
import 'package:palseapp/core/services/firestore/customer_service.dart';
import 'package:palseapp/core/widgets/circle_profile_picture.dart';
import 'package:palseapp/core/widgets/location_sheet.dart';
import 'package:palseapp/features/settings/view/widgets/phone_number_sheet.dart';
import 'package:palseapp/features/settings/viewmodel/edit_profile_view_model.dart';
import 'package:provider/provider.dart';

// Profil düzenleme sayfası
class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key, required this.user});
  final Customer user;

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final CloudStorageService _cloudStorageService = CloudStorageService();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => EditProfileViewModel(user: widget.user, customerService: CustomerService()),
      child: Consumer<EditProfileViewModel>(
        builder: (context, viewModel, child) => GestureDetector(
          // Ekranda boş bir alana tıklandığında klavyeyi kapat
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(context.tr('edit_profile')),
              actions: [
                TextButton(
                  onPressed: viewModel.isLoading
                      ? null
                      : () async {
                          // Eğer fotoğraf seçildiyse önce fotoğrafı yükleyelim
                          if (viewModel.selectedImage != null) {
                            viewModel.setLoading(true);
                            try {
                              // Eski fotoğrafı silme işlemi
                              if (viewModel.user.profilePictureUrl != null && viewModel.user.profilePictureUrl!.isNotEmpty) {
                                await _cloudStorageService.deleteFile(viewModel.user.profilePictureUrl!);
                              }

                              // Yeni fotoğrafı yükleme
                              final url = await _cloudStorageService.uploadUserFile(
                                userId: viewModel.user.userID!,
                                fileType: FileType.profile,
                                fileName: viewModel.user.userID!,
                                file: File(viewModel.selectedImage!.path),
                              );

                              // Profil fotoğrafı URL'ini güncelleme
                              viewModel.updateProfilePictureUrl(url);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${context.tr('photo_upload_error')}: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } finally {
                              viewModel.setLoading(false);
                            }
                          }

                          // Profili güncelleme
                          await viewModel.updateProfil();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(context.tr('profile_updated_successfully')),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                  child: viewModel.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                          ),
                        )
                      : Text(context.tr('save')),
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Seçilen fotoğraf varsa onu, yoksa mevcut profil fotoğrafını göster
                  viewModel.selectedImage != null
                      ? CircleAvatar(
                          radius: 50,
                          backgroundImage: FileImage(File(viewModel.selectedImage!.path)),
                        )
                      : CircleProfilePicture(imageUrl: viewModel.user.profilePictureUrl, radius: 50),
                  TextButton(
                    onPressed: () async {
                      await viewModel.pickImage();
                      // Fotoğrafı seçtikten sonra direkt yüklemiyoruz, sadece ui'da gösteriyoruz.
                      // Yükleme işlemi Kaydet butonuna basıldığında gerçekleşecek
                    },
                    child: Text(context.tr('change_photo')),
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 16,
                    children: [
                      _buildTextField(
                        controller: viewModel.nicknameController,
                        label: context.tr('username'),
                        keyboardType: TextInputType.name,
                        readOnly: viewModel.user.nickname!.length > 4,
                        suffixIcon: viewModel.user.nickname!.length > 4 ? Icons.check : Icons.edit,
                      ),
                      _buildTextField(
                        controller: viewModel.nameController,
                        label: context.tr('first_name'),
                        keyboardType: TextInputType.name,
                        prefixIcon: Icons.person,
                        suffixIcon: Icons.edit,
                      ),
                      _buildTextField(
                        controller: viewModel.lastNameController,
                        label: context.tr('last_name'),
                        keyboardType: TextInputType.name,
                        prefixIcon: Icons.person,
                        suffixIcon: Icons.edit,
                      ),
                      _buildTextField(
                        onTap: () async {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                            ),
                            builder: (context) => const PhoneNumberSheet(),
                          ).then((result) {
                            if (result == true) {
                              // Telefon doğrulama başarılı
                              viewModel.updatePhone(viewModel.phoneController.text, true);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(context.tr('phone_verification_success'))),
                              );
                            }
                          });
                        },
                        controller: viewModel.phoneController,
                        label: context.tr('phone'),
                        keyboardType: TextInputType.phone,
                        readOnly: viewModel.user.verification == true,
                        prefixIcon: Icons.phone,
                        suffixIcon: viewModel.user.verification == false ? Icons.edit : Icons.check,
                      ),
                      if (viewModel.user.verification == false) Text(context.tr('phone_not_verified'), style: const TextStyle(color: Colors.red)),
                      if (viewModel.user.verification == true) Text(context.tr('phone_verified'), style: const TextStyle(color: Colors.green)),
                      _buildTextField(
                        controller: viewModel.addressController,
                        label: context.tr('location'),
                        prefixIcon: Icons.location_on,
                        suffixIcon: Icons.edit,
                        onTap: () async {
                          final result = await showModalBottomSheet<LocationModel>(
                            context: context,
                            isScrollControlled: true,
                            constraints: BoxConstraints(
                              maxHeight: MediaQuery.of(context).size.height * 0.85,
                            ),
                            builder: (context) => const LocationSheet(),
                          );

                          if (result != null) {
                            viewModel.updateLocation(result);
                          }
                        },
                        readOnly: true,
                      ),
                      _buildTextField(
                        controller: viewModel.birthDateController,
                        label: context.tr('birth_date'),
                        keyboardType: TextInputType.datetime,
                        readOnly: true,
                        prefixIcon: Icons.calendar_month,
                      ),
                      _buildTextField(
                        controller: viewModel.genderController,
                        label: context.tr('gender'),
                        textKey: viewModel.user.gender?.textKey,
                        keyboardType: TextInputType.name,
                        readOnly: true,
                        prefixIcon: Icons.female,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    bool readOnly = false,
    IconData? prefixIcon,
    VoidCallback? onTap,
    IconData? suffixIcon,
    String? textKey,
  }) {
    return TextField(
      controller: textKey != null ? TextEditingController(text: context.tr(textKey)) : controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: suffixIcon != null ? Icon(suffixIcon) : null,
      ),
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
    );
  }
}
