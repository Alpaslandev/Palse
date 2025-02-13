import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/services/firestore/customer_service.dart';
import 'package:palseapp/features/settings/view/widgets/location_sheet.dart';
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
  late final TextEditingController _nicknameController;
  late final TextEditingController _nameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _birthDateController;
  late final TextEditingController _genderController;

  @override
  void initState() {
    super.initState();
    // Mevcut kullanıcı bilgilerini form alanlarına yerleştir
    _nicknameController = TextEditingController(text: '@${widget.user.nickname}');
    _nameController = TextEditingController(text: widget.user.firstName);
    _lastNameController = TextEditingController(text: widget.user.lastName);
    _phoneController = TextEditingController(text: widget.user.phoneNumber);
    _addressController = TextEditingController(text: '${widget.user.district}, ${widget.user.city}');
    _birthDateController = TextEditingController(text: DateFormat('dd/MM/yyyy').format(widget.user.birthday!));
    _genderController = TextEditingController(text: widget.user.gender?.name);
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _nameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _birthDateController.dispose();
    _genderController.dispose();
    super.dispose();
  }

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
                onPressed: () async {
                  await viewModel.updateProfil();
                },
                child: const Text('Kaydet', style: TextStyle(color: Colors.blue)),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: widget.user.profilePictureUrl != null
                      ? NetworkImage(widget.user.profilePictureUrl!)
                      : const AssetImage('assets/images/dostum_olsana.png'),
                ),
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
                      controller: _nicknameController,
                      label: 'Kullanıcı Adı',
                      keyboardType: TextInputType.name,
                      readOnly: widget.user.nickname!.length > 4,
                    ),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Ad',
                      keyboardType: TextInputType.name,
                      prefixIcon: Icons.person,
                    ),
                    _buildTextField(
                      controller: _lastNameController,
                      label: 'Soyad',
                      keyboardType: TextInputType.name,
                      prefixIcon: Icons.person,
                    ),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Telefon',
                      keyboardType: TextInputType.phone,
                      readOnly: widget.user.verification == true,
                      prefixIcon: Icons.phone,
                    ),
                    if (widget.user.verification == false) const Text('Telefon Doğrulanmamıştır.', style: TextStyle(color: Colors.red)),
                    if (widget.user.verification == true) const Text('Telefon Doğrulanmıştır.', style: TextStyle(color: Colors.green)),
                    _buildTextField(
                      controller: _addressController,
                      label: 'Konum',
                      prefixIcon: Icons.location_on,
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (context) => const LocationSheet(),
                        );
                      },
                      readOnly: true,
                    ),
                    _buildTextField(
                      controller: _birthDateController,
                      label: 'Doğum Tarihi',
                      keyboardType: TextInputType.datetime,
                      readOnly: true,
                      prefixIcon: Icons.calendar_month,
                    ),
                    _buildTextField(
                      controller: _genderController,
                      label: 'Cinsiyet',
                      keyboardType: TextInputType.name,
                      readOnly: true,
                      prefixIcon: widget.user.gender?.name == 'Male' ? Icons.male : Icons.female,
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
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      ),
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
    );
  }
}
