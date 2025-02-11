import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:palseapp/core/models/customer.dart';

// Profil düzenleme sayfası
class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key, required this.user});
  final Customer user;

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  late final TextEditingController _nameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _cityController;
  late final TextEditingController _districtController;
  late final TextEditingController _birthDateController;
  late final TextEditingController _genderController;

  @override
  void initState() {
    super.initState();
    // Mevcut kullanıcı bilgilerini form alanlarına yerleştir
    _nameController = TextEditingController(text: widget.user.firstName);
    _lastNameController = TextEditingController(text: widget.user.lastName);
    _phoneController = TextEditingController(text: widget.user.phoneNumber);
    _cityController = TextEditingController(text: widget.user.city);
    _districtController = TextEditingController(text: widget.user.district);
    _birthDateController = TextEditingController(text: DateFormat('dd/MM/yyyy').format(widget.user.birthday!));
    _genderController = TextEditingController(text: widget.user.gender?.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _birthDateController.dispose();
    _genderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profili Düzenle'),
        actions: [
          TextButton(
            onPressed: () {
              // TODO: Profil güncelleme işlemi
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          spacing: 16,
          children: [
            if (widget.user.profilePictureUrl != null) ...[
              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(widget.user.profilePictureUrl!),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Profil fotoğrafı değiştirme
                },
                child: const Text('Fotoğrafı Değiştir'),
              ),
              const SizedBox(height: 16),
            ],
            _buildTextField(
              controller: _nameController,
              label: 'Ad',
              keyboardType: TextInputType.name,
            ),
            _buildTextField(
              controller: _lastNameController,
              label: 'Soyad',
              keyboardType: TextInputType.name,
            ),
            _buildTextField(
              controller: _phoneController,
              label: 'Telefon',
              keyboardType: TextInputType.phone,
            ),
            _buildTextField(
              controller: _cityController,
              label: 'Şehir',
            ),
            _buildTextField(
              controller: _districtController,
              label: 'İlçe',
            ),
            _buildTextField(
              controller: _birthDateController,
              label: 'Doğum Tarihi',
              keyboardType: TextInputType.datetime,
              isEditable: false,
            ),
            _buildTextField(
              controller: _genderController,
              label: 'Cinsiyet',
              keyboardType: TextInputType.name,
              isEditable: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    bool isEditable = true,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      keyboardType: keyboardType,
      enabled: isEditable,
    );
  }
}
