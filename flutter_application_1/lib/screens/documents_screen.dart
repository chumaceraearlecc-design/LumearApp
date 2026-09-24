import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../models/rider_profile.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  static const Color darkMaroon = Color(0xFF62191C);
  static const Color brownBeige = Color(0xFF9E7161);
  static const Color lightBeige = Color(0xFFCAAE9F);
  static const Color cream = Color(0xFFE0CFC2);

  static const String _baseUrl = 'http://10.102.177.127:8000';

  final ImagePicker _picker = ImagePicker();

  XFile? _newLicenseImage;
  XFile? _newOrCrImage;
  bool _isUploading = false;

  String? get _licenseUrl {
    if (RiderProfile.licenseImage.trim().isEmpty) return null;
    return '$_baseUrl/storage/${RiderProfile.licenseImage}';
  }

  String? get _orCrUrl {
    if (RiderProfile.orCrImage.trim().isEmpty) return null;
    return '$_baseUrl/storage/${RiderProfile.orCrImage}';
  }

  Future<void> _pickLicense() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1800,
    );
    if (image == null || !mounted) return;
    setState(() => _newLicenseImage = image);
  }

  Future<void> _pickOrCr() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1800,
    );
    if (image == null || !mounted) return;
    setState(() => _newOrCrImage = image);
  }

  Future<void> _uploadDocuments() async {
    final int? riderId = RiderProfile.id;
    if (riderId == null) {
      _showMessage('Rider information is unavailable. Please login again.');
      return;
    }

    if (_newLicenseImage == null && _newOrCrImage == null) {
      _showMessage('Select at least one new document first.');
      return;
    }

    setState(() => _isUploading = true);

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/api/riders/$riderId/documents'),
      );
      request.headers['Accept'] = 'application/json';

      if (_newLicenseImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'license_image',
            _newLicenseImage!.path,
          ),
        );
      }

      if (_newOrCrImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath('or_cr_image', _newOrCrImage!.path),
        );
      }

      final streamed = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamed);

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
          _newLicenseImage = null;
          _newOrCrImage = null;
          _isUploading = false;
        });

        _showMessage('Documents updated.', success: true);
        return;
      }

      setState(() => _isUploading = false);
      _showMessage(
        data['message']?.toString() ?? 'Unable to update documents.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploading = false);
      _showMessage('Unable to connect to the server.');
    }
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
          'Documents',
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
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: darkMaroon,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Row(
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: lightBeige,
                    child: Icon(
                      Icons.description_outlined,
                      color: darkMaroon,
                      size: 38,
                    ),
                  ),
                  SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rider Documents',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'View or replace your submitted verification documents.',
                          style: TextStyle(
                            color: lightBeige,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            _documentCard(
              title: "Driver's License",
              subtitle: RiderProfile.licenseNumber.isEmpty
                  ? 'License document'
                  : 'License No. ${RiderProfile.licenseNumber}',
              currentUrl: _licenseUrl,
              selectedFile: _newLicenseImage,
              onSelect: _pickLicense,
              icon: Icons.badge_outlined,
            ),
            const SizedBox(height: 18),
            _documentCard(
              title: 'OR / CR',
              subtitle: RiderProfile.plateNumber.isEmpty
                  ? 'Vehicle registration document'
                  : 'Plate No. ${RiderProfile.plateNumber}',
              currentUrl: _orCrUrl,
              selectedFile: _newOrCrImage,
              onSelect: _pickOrCr,
              icon: Icons.directions_car_filled_outlined,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _uploadDocuments,
                icon: _isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.cloud_upload_outlined),
                label: Text(
                  _isUploading ? 'Uploading...' : 'Save New Documents',
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
          ],
        ),
      ),
    );
  }

  Widget _documentCard({
    required String title,
    required String subtitle,
    required String? currentUrl,
    required XFile? selectedFile,
    required VoidCallback onSelect,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: lightBeige.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: darkMaroon),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: darkMaroon,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(color: brownBeige, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: double.infinity,
              height: 210,
              color: cream.withValues(alpha: 0.6),
              child: selectedFile != null
                  ? Image.file(File(selectedFile.path), fit: BoxFit.cover)
                  : currentUrl != null
                  ? Image.network(
                      currentUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _emptyDocumentPreview(),
                    )
                  : _emptyDocumentPreview(),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isUploading ? null : onSelect,
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(
                selectedFile == null
                    ? 'Choose New Image'
                    : 'Change Selected Image',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: darkMaroon,
                side: const BorderSide(color: darkMaroon),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyDocumentPreview() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.image_not_supported_outlined, color: brownBeige, size: 42),
          SizedBox(height: 8),
          Text(
            'No document preview available',
            style: TextStyle(color: brownBeige, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
