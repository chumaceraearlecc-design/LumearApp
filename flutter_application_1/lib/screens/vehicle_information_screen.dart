import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/rider_profile.dart';

class VehicleInformationScreen extends StatefulWidget {
  const VehicleInformationScreen({super.key});

  @override
  State<VehicleInformationScreen> createState() =>
      _VehicleInformationScreenState();
}

class _VehicleInformationScreenState extends State<VehicleInformationScreen> {
  static const Color darkMaroon = Color(0xFF62191C);
  static const Color maroon = Color(0xFF873632);
  static const Color brownBeige = Color(0xFF9E7161);
  static const Color lightBeige = Color(0xFFCAAE9F);
  static const Color cream = Color(0xFFE0CFC2);

  static const String _baseUrl = 'http://10.102.177.127:8000';

  bool _isEditing = false;
  bool _isSaving = false;

  late final TextEditingController _vehicleTypeController;
  late final TextEditingController _licenseNumberController;
  late final TextEditingController _plateController;

  @override
  void initState() {
    super.initState();
    _vehicleTypeController = TextEditingController(
      text: RiderProfile.vehicleType,
    );
    _licenseNumberController = TextEditingController(
      text: RiderProfile.licenseNumber,
    );
    _plateController = TextEditingController(text: RiderProfile.plateNumber);
  }

  @override
  void dispose() {
    _vehicleTypeController.dispose();
    _licenseNumberController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final int? riderId = RiderProfile.id;
    if (riderId == null) {
      _showMessage('Rider information is unavailable. Please login again.');
      return;
    }

    if (_vehicleTypeController.text.trim().isEmpty ||
        _licenseNumberController.text.trim().isEmpty ||
        _plateController.text.trim().isEmpty) {
      _showMessage('Please complete all vehicle information fields.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final response = await http
          .patch(
            Uri.parse('$_baseUrl/api/riders/$riderId/vehicle-information'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'vehicle_type': _vehicleTypeController.text.trim(),
              'license_number': _licenseNumberController.text.trim(),
              'plate_number': _plateController.text.trim(),
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

        _showMessage('Vehicle information updated.', success: true);
        return;
      }

      setState(() => _isSaving = false);
      _showMessage(
        data['message']?.toString() ?? 'Unable to update vehicle information.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showMessage('Unable to connect to the server.');
    }
  }

  void _cancelEditing() {
    _vehicleTypeController.text = RiderProfile.vehicleType;
    _licenseNumberController.text = RiderProfile.licenseNumber;
    _plateController.text = RiderProfile.plateNumber;
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
          'Vehicle Information',
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
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: lightBeige,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35),
                        width: 3,
                      ),
                    ),
                    child: const Icon(
                      Icons.two_wheeler,
                      size: 45,
                      color: darkMaroon,
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          RiderProfile.vehicleType.isEmpty
                              ? 'Rider Vehicle'
                              : RiderProfile.vehicleType,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 7),
                        const Text(
                          'Manage your registered vehicle information.',
                          style: TextStyle(
                            fontSize: 12,
                            color: lightBeige,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(
                              Icons.verified_outlined,
                              color: lightBeige,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              RiderProfile.status == 'approved'
                                  ? 'Approved Rider Vehicle'
                                  : 'Registered Vehicle',
                              style: const TextStyle(
                                fontSize: 11,
                                color: lightBeige,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Vehicle Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: darkMaroon,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'These are the vehicle details submitted during registration.',
              style: TextStyle(color: brownBeige, fontSize: 12),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  _infoField(
                    label: 'Vehicle Type',
                    icon: Icons.two_wheeler_outlined,
                    controller: _vehicleTypeController,
                  ),
                  const SizedBox(height: 16),
                  _infoField(
                    label: 'Driver License Number',
                    icon: Icons.badge_outlined,
                    controller: _licenseNumberController,
                  ),
                  const SizedBox(height: 16),
                  _infoField(
                    label: 'Plate Number',
                    icon: Icons.confirmation_number_outlined,
                    controller: _plateController,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: lightBeige.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 19,
                    backgroundColor: darkMaroon,
                    child: Icon(
                      Icons.info_outline,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Important',
                          style: TextStyle(
                            color: darkMaroon,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Make sure your vehicle information matches your registration documents.',
                          style: TextStyle(
                            fontSize: 11,
                            color: maroon,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkMaroon,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
              ),
            ),
            if (_isEditing) ...[
              const SizedBox(height: 10),
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

  Widget _infoField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
  }) {
    return TextField(
      controller: controller,
      enabled: _isEditing,
      style: const TextStyle(
        color: darkMaroon,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
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
