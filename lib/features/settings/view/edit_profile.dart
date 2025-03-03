import 'package:flutter/material.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/models/location_model.dart';
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
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => EditProfileViewModel(user: widget.user, customerService: CustomerService()),
      child: Consumer<EditProfileViewModel>(
        builder: (context, viewModel, child) => Scaffold(
          appBar: AppBar(
            title: const Text('Profili Düzenle'),
            actions: [
              TextButton(
                onPressed: viewModel.isLoading
                    ? null
                    : () async {
                        await viewModel.updateProfil();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Profil başarıyla güncellendi'),
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
                    : const Text('Kaydet', style: TextStyle(color: Colors.blue)),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleProfilePicture(imageUrl: viewModel.user.profilePictureUrl),
                TextButton(
                  onPressed: () {
                    // TODO: Profil fotoğrafı değiştirme
                  },
                  child: const Text('Fotoğrafı Değiştir', style: TextStyle(color: Colors.blue)),
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 16,
                  children: [
                    _buildTextField(
                      controller: viewModel.nicknameController,
                      label: 'Kullanıcı Adı',
                      keyboardType: TextInputType.name,
                      readOnly: viewModel.user.nickname!.length > 4,
                      suffixIcon: viewModel.user.nickname!.length > 4 ? Icons.check : Icons.edit,
                    ),
                    _buildTextField(
                      controller: viewModel.nameController,
                      label: 'Ad',
                      keyboardType: TextInputType.name,
                      prefixIcon: Icons.person,
                      suffixIcon: Icons.edit,
                    ),
                    _buildTextField(
                      controller: viewModel.lastNameController,
                      label: 'Soyad',
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
                              const SnackBar(content: Text('Telefon numarası başarıyla doğrulandı')),
                            );
                          }
                        });
                      },
                      controller: viewModel.phoneController,
                      label: 'Telefon',
                      keyboardType: TextInputType.phone,
                      readOnly: viewModel.user.verification == true,
                      prefixIcon: Icons.phone,
                      suffixIcon: viewModel.user.verification == false ? Icons.edit : Icons.check,
                    ),
                    if (viewModel.user.verification == false) const Text('Telefon Doğrulanmamıştır.', style: TextStyle(color: Colors.red)),
                    if (viewModel.user.verification == true) const Text('Telefon Doğrulanmıştır.', style: TextStyle(color: Colors.green)),
                    _buildTextField(
                      controller: viewModel.addressController,
                      label: 'Konum',
                      prefixIcon: Icons.location_on,
                      suffixIcon: Icons.edit,
                      onTap: () async {
                        final result = await showModalBottomSheet<LocationModel>(
                          context: context,
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
                      label: 'Doğum Tarihi',
                      keyboardType: TextInputType.datetime,
                      readOnly: true,
                      prefixIcon: Icons.calendar_month,
                    ),
                    _buildTextField(
                      controller: viewModel.genderController,
                      label: 'Cinsiyet',
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
  }) {
    return TextField(
      controller: controller,
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
