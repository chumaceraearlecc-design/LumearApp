import 'dart:convert';

import 'package:flutter_application_1/data/hardcoded_rider.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/rider_profile.dart';

class PersonalInformationScreen extends StatefulWidget {
  const PersonalInformationScreen({super.key});

  @override
  State<PersonalInformationScreen> createState() =>
      _PersonalInformationScreenState();
}

class _PersonalInformationScreenState extends State<PersonalInformationScreen> {
  static const Color darkMaroon = Color(0xFF62191C);
  static const Color maroon = Color(0xFF873632);
  static const Color brownBeige = Color(0xFF9E7161);
  static const Color lightBeige = Color(0xFFCAAE9F);
  static const Color cream = Color(0xFFE0CFC2);

  static const String _baseUrl = 'http://10.102.177.127:8000';

  bool _isEditing = false;
  bool _isSaving = false;

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _birthdayController;
  late final TextEditingController _ageController;
  late final TextEditingController _regionController;
  late final TextEditingController _provinceController;
  late final TextEditingController _municipalityController;
  late final TextEditingController _barangayController;
  late final TextEditingController _streetController;
  late final TextEditingController _houseUnitController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: HardcodedRider.fullName);
    _phoneController = TextEditingController(text: HardcodedRider.phone);
    _emailController = TextEditingController(text: HardcodedRider.email);
    _birthdayController = TextEditingController(text: HardcodedRider.birthday);
    _ageController = TextEditingController(text: HardcodedRider.age.toString());
    _regionController = TextEditingController(text: HardcodedRider.region);
    _provinceController = TextEditingController(text: HardcodedRider.province);
    _municipalityController = TextEditingController(
      text: HardcodedRider.municipality,
    );
    _barangayController = TextEditingController(text: HardcodedRider.barangay);
    _streetController = TextEditingController(text: HardcodedRider.street);
    _houseUnitController = TextEditingController(
      text: HardcodedRider.houseUnit,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _birthdayController.dispose();
    _ageController.dispose();
    _regionController.dispose();
    _provinceController.dispose();
    _municipalityController.dispose();
    _barangayController.dispose();
    _streetController.dispose();
    _houseUnitController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final int? riderId = RiderProfile.id;
    if (riderId == null) {
      _showMessage('Rider information is unavailable. Please login again.');
      return;
    }

    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _birthdayController.text.trim().isEmpty ||
        _ageController.text.trim().isEmpty ||
        _regionController.text.trim().isEmpty ||
        _provinceController.text.trim().isEmpty ||
        _municipalityController.text.trim().isEmpty ||
        _barangayController.text.trim().isEmpty ||
        _streetController.text.trim().isEmpty ||
        _houseUnitController.text.trim().isEmpty) {
      _showMessage('Please complete all personal information fields.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final response = await http
          .patch(
            Uri.parse('$_baseUrl/api/riders/$riderId/personal-information'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'full_name': _nameController.text.trim(),
              'email': _emailController.text.trim(),
              'phone': _phoneController.text.trim(),
              'birthday': _birthdayController.text.trim(),
              'age': int.tryParse(_ageController.text.trim()),
              'region': _regionController.text.trim(),
              'province': _provinceController.text.trim(),
              'municipality': _municipalityController.text.trim(),
              'barangay': _barangayController.text.trim(),
              'street': _streetController.text.trim(),
              'house_unit': _houseUnitController.text.trim(),
            }),
          )
          .timeout(const Duration(seconds: 15));

      final dynamic decoded = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : <String, dynamic>{};
      final Map<String, dynamic> data = decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{};

      if (!mounted) return;

      if (response.statusCode == 200 && data['success'] == true) {
        final dynamic rider = data['rider'];
        if (rider is Map) {
          RiderProfile.setFromJson(Map<String, dynamic>.from(rider));
        }

        setState(() {
          _isEditing = false;
          _isSaving = false;
        });

        _showMessage('Personal information updated.', success: true);
        return;
      }

      setState(() => _isSaving = false);
      _showMessage(
        data['message']?.toString() ?? 'Unable to update information.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showMessage('Unable to connect to the server.');
    }
  }

  void _cancelEditing() {
    _nameController.text = RiderProfile.name;
    _phoneController.text = RiderProfile.phone;
    _emailController.text = RiderProfile.email;
    _birthdayController.text = RiderProfile.birthday;
    _ageController.text = RiderProfile.age?.toString() ?? '';
    _regionController.text = RiderProfile.region;
    _provinceController.text = RiderProfile.province;
    _municipalityController.text = RiderProfile.municipality;
    _barangayController.text = RiderProfile.barangay;
    _streetController.text = RiderProfile.street;
    _houseUnitController.text = RiderProfile.houseUnit;
    setState(() => _isEditing = false);
  }

  void _showMessage(String message, {bool success = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: darkMaroon,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Row(
            children: [
              Icon(
                success ? Icons.check_circle_outline : Icons.info_outline,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: cream,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: darkMaroon,
            size: 20,
          ),
        ),
        title: const Text(
          'Personal Information',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: darkMaroon,
            fontSize: 21,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 34),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
              decoration: BoxDecoration(
                color: darkMaroon,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: darkMaroon.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 41,
                    backgroundColor: lightBeige,
                    backgroundImage: RiderProfile.profileImage != null
                        ? FileImage(RiderProfile.profileImage!)
                        : null,
                    child: RiderProfile.profileImage == null
                        ? const Icon(Icons.person, size: 45, color: darkMaroon)
                        : null,
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          RiderProfile.name.isEmpty
                              ? 'Rider Information'
                              : RiderProfile.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          RiderProfile.riderId.isEmpty
                              ? 'Registered Rider'
                              : 'Rider ID: ${RiderProfile.riderId}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: lightBeige,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            _sectionTitle(
              'Personal Details',
              'Information from your rider account.',
            ),
            const SizedBox(height: 18),
            _card([
              _infoField('Full Name', Icons.person_outline, _nameController),
              _gap(),
              _infoField(
                'Phone Number',
                Icons.phone_outlined,
                _phoneController,
                keyboardType: TextInputType.phone,
              ),
              _gap(),
              _infoField(
                'Email Address',
                Icons.email_outlined,
                _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              _gap(),
              Row(
                children: [
                  Expanded(
                    child: _infoField(
                      'Birthday',
                      Icons.cake_outlined,
                      _birthdayController,
                      hintText: 'YYYY-MM-DD',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _infoField(
                      'Age',
                      Icons.numbers_outlined,
                      _ageController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ]),
            const SizedBox(height: 28),
            _sectionTitle(
              'Address',
              'Your registered delivery service address.',
            ),
            const SizedBox(height: 18),
            _card([
              _infoField('Region', Icons.map_outlined, _regionController),
              _gap(),
              _infoField(
                'Province',
                Icons.location_city_outlined,
                _provinceController,
              ),
              _gap(),
              _infoField(
                'Municipality / City',
                Icons.apartment_outlined,
                _municipalityController,
              ),
              _gap(),
              _infoField('Barangay', Icons.place_outlined, _barangayController),
              _gap(),
              _infoField('Street', Icons.route_outlined, _streetController),
              _gap(),
              _infoField(
                'House / Unit',
                Icons.home_outlined,
                _houseUnitController,
              ),
            ]),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isSaving
                    ? null
                    : () {
                        if (_isEditing) {
                          _saveChanges();
                        } else {
                          setState(() => _isEditing = true);
                        }
                      },
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        _isEditing ? Icons.save_outlined : Icons.edit_outlined,
                      ),
                label: Text(
                  _isSaving
                      ? 'Saving...'
                      : _isEditing
                      ? 'Save Changes'
                      : 'Edit Information',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkMaroon,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
              ),
            ),
            if (_isEditing) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _isSaving ? null : _cancelEditing,
                  child: const Text(
                    'Cancel Editing',
                    style: TextStyle(
                      color: maroon,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: darkMaroon,
          ),
        ),
        const SizedBox(height: 6),
        Text(subtitle, style: const TextStyle(color: brownBeige, fontSize: 12)),
      ],
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(children: children),
    );
  }

  Widget _gap() => const SizedBox(height: 16);

  Widget _infoField(
    String label,
    IconData icon,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    String? hintText,
  }) {
    return TextField(
      controller: controller,
      enabled: _isEditing,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: darkMaroon,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        labelStyle: const TextStyle(color: brownBeige, fontSize: 12),
        floatingLabelStyle: const TextStyle(
          color: darkMaroon,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Container(
          margin: const EdgeInsets.all(9),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: lightBeige.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: darkMaroon, size: 20),
        ),
        filled: true,
        fillColor: _isEditing ? Colors.white : cream.withValues(alpha: 0.45),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: lightBeige.withValues(alpha: 0.8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: darkMaroon, width: 1.6),
        ),
      ),
    );
  }
}
