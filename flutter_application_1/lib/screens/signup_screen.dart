import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'login_screen.dart';
import 'terms_conditions_screen.dart';

class _PhLocalNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // Since +63 is already shown as a fixed prefix, remove the habitual
    // Philippine local-format leading 0 (e.g. 09171234567 -> 9171234567).
    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    // PH mobile numbers after +63 should contain 10 digits.
    if (digits.length > 10) {
      digits = digits.substring(0, 10);
    }

    return TextEditingValue(
      text: digits,
      selection: TextSelection.collapsed(offset: digits.length),
    );
  }
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  int _currentStep = 0;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _agreeToTerms = false;

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _houseUnitController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final TextEditingController _licenseNumberController =
      TextEditingController();
  final TextEditingController _plateNumberController = TextEditingController();

  DateTime? _selectedBirthday;

  String? _selectedRegion;
  String? _selectedProvince;
  String? _selectedMunicipality;
  String? _selectedBarangay;

  // PSGC codes are kept internally for API requests.
  String? _selectedRegionCode;
  String? _selectedProvinceCode;
  String? _selectedMunicipalityCode;

  List<Map<String, String>> _regionItems = [];
  List<Map<String, String>> _provinceItems = [];
  List<Map<String, String>> _municipalityItems = [];
  List<Map<String, String>> _barangayItems = [];

  bool _isLoadingRegions = false;
  bool _isLoadingProvinces = false;
  bool _isLoadingMunicipalities = false;
  bool _isLoadingBarangays = false;

  bool _regionLoadFailed = false;
  bool _provinceLoadFailed = false;
  bool _municipalityLoadFailed = false;
  bool _barangayLoadFailed = false;

  static const String _psgcBaseUrl = 'https://psgc.cloud/api/v2';

  String? _selectedVehicleType;

  final ImagePicker _picker = ImagePicker();

  XFile? _licenseImage;
  XFile? _orCrImage;

  OverlayEntry? _topNotificationEntry;

  static const Color darkMaroon = Color(0xFF62191C);
  static const Color maroon = Color(0xFF873632);
  static const Color brownBeige = Color(0xFF9E7161);
  static const Color lightBeige = Color(0xFFCAAE9F);
  static const Color cream = Color(0xFFE0CFC2);

  final List<Map<String, dynamic>> _vehicleTypes = const [
    {'label': 'Motorcycle', 'icon': Icons.two_wheeler_outlined},
    {'label': 'Tricycle', 'icon': Icons.electric_rickshaw_outlined},
    {'label': 'Van', 'icon': Icons.airport_shuttle_outlined},
    {'label': 'Truck', 'icon': Icons.local_shipping_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _fetchRegions();
  }

  List<String> get _regions =>
      _regionItems.map((item) => item['name']!).toList();

  List<String> get _provinces =>
      _provinceItems.map((item) => item['name']!).toList();

  List<String> get _municipalities =>
      _municipalityItems.map((item) => item['name']!).toList();

  List<String> get _barangays =>
      _barangayItems.map((item) => item['name']!).toList();

  String? _codeForName(List<Map<String, String>> items, String? name) {
    if (name == null) return null;

    for (final item in items) {
      if (item['name'] == name) {
        return item['code'];
      }
    }

    return null;
  }

  String _cleanPlaceName(String text) {
    String cleaned = text.trim();

    // Fix common mojibake such as "BiÃ±an" -> "Biñan".
    // Run at most twice in case the API text was encoded incorrectly more than once.
    for (int i = 0; i < 2; i++) {
      if (!(cleaned.contains('Ã') ||
          cleaned.contains('Â') ||
          cleaned.contains('â'))) {
        break;
      }

      try {
        final String repaired = utf8.decode(latin1.encode(cleaned));
        if (repaired == cleaned) break;
        cleaned = repaired;
      } catch (_) {
        break;
      }
    }

    // Final fallback for the characters commonly found in Philippine place names.
    return cleaned
        .replaceAll('Ã±', 'ñ')
        .replaceAll('Ã‘', 'Ñ')
        .replaceAll('Ã¡', 'á')
        .replaceAll('Ã©', 'é')
        .replaceAll('Ã­', 'í')
        .replaceAll('Ã³', 'ó')
        .replaceAll('Ãº', 'ú');
  }

  Future<List<Map<String, String>>> _fetchPsgcList(String url) async {
    debugPrint('PSGC GET: $url');

    final http.Response response = await http
        .get(Uri.parse(url), headers: const {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 15));

    debugPrint('PSGC STATUS: ${response.statusCode}');

    if (response.statusCode != 200) {
      throw HttpException(
        'PSGC request failed with status ${response.statusCode}.',
      );
    }

    final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));

    // The PSGC v2 API wraps list responses as {"data": [...]},
    // so unwrap that before validating it as a list.
    final dynamic items = decoded is Map && decoded['data'] is List
        ? decoded['data']
        : decoded;

    if (items is! List) {
      throw const FormatException('Unexpected PSGC response format.');
    }

    return items
        .whereType<Map>()
        .map<Map<String, String>>((dynamic item) {
          final Map<dynamic, dynamic> map = item as Map<dynamic, dynamic>;

          return {
            'code': map['code']?.toString() ?? '',
            'name': _cleanPlaceName(map['name']?.toString() ?? ''),
          };
        })
        .where(
          (item) =>
              item['code']!.trim().isNotEmpty &&
              item['name']!.trim().isNotEmpty,
        )
        .toList()
      ..sort((a, b) => a['name']!.compareTo(b['name']!));
  }

  Future<void> _fetchRegions() async {
    if (_isLoadingRegions) return;

    setState(() {
      _isLoadingRegions = true;
      _regionLoadFailed = false;
    });

    try {
      final items = await _fetchPsgcList('$_psgcBaseUrl/regions');

      if (!mounted) return;

      setState(() {
        _regionItems = items;
        _isLoadingRegions = false;
        _regionLoadFailed = items.isEmpty;
      });

      debugPrint('REGIONS LOADED: ${items.length}');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingRegions = false;
        _regionLoadFailed = true;
      });

      debugPrint('Unable to load PSGC regions: $e');
      _showMessage(
        'Unable to load regions. Check your internet connection.',
        icon: Icons.wifi_off_rounded,
      );
    }
  }

  Future<void> _fetchProvinces() async {
    final String? regionCode = _selectedRegionCode;

    if (regionCode == null || _isLoadingProvinces) return;

    setState(() {
      _isLoadingProvinces = true;
      _provinceLoadFailed = false;
      _municipalityLoadFailed = false;
      _barangayLoadFailed = false;
      _provinceItems = [];
      _municipalityItems = [];
      _barangayItems = [];
    });

    try {
      final items = await _fetchPsgcList(
        '$_psgcBaseUrl/regions/$regionCode/provinces',
      );

      if (!mounted || _selectedRegionCode != regionCode) return;

      if (items.isEmpty) {
        // Some PSGC regions, such as NCR, do not have provinces.
        // We keep a synthetic province entry so your existing backend field
        // remains complete while cities/municipalities are loaded by region.
        setState(() {
          _provinceItems = [
            {'code': regionCode, 'name': _selectedRegion ?? 'No Province'},
          ];
          _selectedProvince = _selectedRegion ?? 'No Province';
          _selectedProvinceCode = regionCode;
          _isLoadingProvinces = false;
        });

        await _fetchMunicipalities(loadByRegion: true);
        return;
      }

      setState(() {
        _provinceItems = items;
        _isLoadingProvinces = false;
        _provinceLoadFailed = false;
      });
    } catch (e) {
      if (!mounted || _selectedRegionCode != regionCode) return;

      setState(() {
        _isLoadingProvinces = false;
        _provinceLoadFailed = true;
      });

      debugPrint('Unable to load PSGC provinces: $e');
      _showMessage(
        'Unable to load provinces. Please try again.',
        icon: Icons.wifi_off_rounded,
      );
    }
  }

  Future<void> _fetchMunicipalities({bool loadByRegion = false}) async {
    final String? regionCode = _selectedRegionCode;
    final String? provinceCode = _selectedProvinceCode;

    if (regionCode == null || _isLoadingMunicipalities) return;

    if (!loadByRegion && provinceCode == null) return;

    setState(() {
      _isLoadingMunicipalities = true;
      _municipalityLoadFailed = false;
      _barangayLoadFailed = false;
      _municipalityItems = [];
      _barangayItems = [];
    });

    try {
      final String url = loadByRegion
          ? '$_psgcBaseUrl/regions/$regionCode/cities-municipalities'
          : '$_psgcBaseUrl/provinces/$provinceCode/cities-municipalities';

      final items = await _fetchPsgcList(url);

      if (!mounted || _selectedRegionCode != regionCode) return;

      if (!loadByRegion && _selectedProvinceCode != provinceCode) return;

      setState(() {
        _municipalityItems = items;
        _isLoadingMunicipalities = false;
        _municipalityLoadFailed = items.isEmpty;
      });
    } catch (e) {
      if (!mounted || _selectedRegionCode != regionCode) return;

      setState(() {
        _isLoadingMunicipalities = false;
        _municipalityLoadFailed = true;
      });

      debugPrint('Unable to load PSGC cities/municipalities: $e');
      _showMessage(
        'Unable to load cities or municipalities. Please try again.',
        icon: Icons.wifi_off_rounded,
      );
    }
  }

  Future<void> _fetchBarangays() async {
    final String? municipalityCode = _selectedMunicipalityCode;

    if (municipalityCode == null || _isLoadingBarangays) return;

    setState(() {
      _isLoadingBarangays = true;
      _barangayLoadFailed = false;
      _barangayItems = [];
    });

    try {
      final items = await _fetchPsgcList(
        '$_psgcBaseUrl/cities-municipalities/$municipalityCode/barangays',
      );

      if (!mounted || _selectedMunicipalityCode != municipalityCode) return;

      setState(() {
        _barangayItems = items;
        _isLoadingBarangays = false;
        _barangayLoadFailed = items.isEmpty;
      });
    } catch (e) {
      if (!mounted || _selectedMunicipalityCode != municipalityCode) return;

      setState(() {
        _isLoadingBarangays = false;
        _barangayLoadFailed = true;
      });

      debugPrint('Unable to load PSGC barangays: $e');
      _showMessage(
        'Unable to load barangays. Please try again.',
        icon: Icons.wifi_off_rounded,
      );
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _streetController.dispose();
    _houseUnitController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _licenseNumberController.dispose();
    _plateNumberController.dispose();

    _topNotificationEntry?.remove();

    super.dispose();
  }

  Future<void> _pickBirthday() async {
    final DateTime now = DateTime.now();

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate:
          _selectedBirthday ?? DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1940),
      lastDate: now,
      helpText: 'Select your birthday',
      cancelText: 'CANCEL',
      confirmText: 'SELECT',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: maroon,
              onPrimary: Colors.white,
              onSurface: darkMaroon,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) {
      return;
    }

    final int age = _calculateAge(pickedDate);

    setState(() {
      _selectedBirthday = pickedDate;
      _ageController.text = age.toString();
    });
  }

  int _calculateAge(DateTime birthday) {
    final DateTime today = DateTime.now();

    int age = today.year - birthday.year;

    if (today.month < birthday.month ||
        (today.month == birthday.month && today.day < birthday.day)) {
      age--;
    }

    return age;
  }

  String _formatBirthday(DateTime date) {
    final List<String> months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _nextStep() {
    FocusScope.of(context).unfocus();

    if (_currentStep == 0) {
      if (!_validatePersonal()) {
        return;
      }

      setState(() {
        _currentStep = 1;
      });

      return;
    }

    if (_currentStep == 1) {
      if (!_validateAddress()) {
        return;
      }

      setState(() {
        _currentStep = 2;
      });

      return;
    }

    if (_currentStep == 2) {
      if (!_validateSecurity()) {
        return;
      }

      setState(() {
        _currentStep = 3;
      });

      return;
    }

    if (_currentStep == 3) {
      if (!_validateRider()) {
        return;
      }

      setState(() {
        _currentStep = 4;
      });

      return;
    }

    if (_currentStep == 4) {
      _signUp();
    }
  }

  void _previousStep() {
    FocusScope.of(context).unfocus();

    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  bool _validatePersonal() {
    final String fullName = _fullNameController.text.trim();
    final String email = _emailController.text.trim();
    final String phone = _phoneController.text.trim();

    if (fullName.isEmpty) {
      _showMessage('Please enter your full name.', icon: Icons.person_outline);

      return false;
    }

    if (email.isEmpty) {
      _showMessage(
        'Please enter your email address.',
        icon: Icons.email_outlined,
      );

      return false;
    }

    if (!email.contains('@') || !email.contains('.')) {
      _showMessage(
        'Please enter a valid email address.',
        icon: Icons.email_outlined,
      );

      return false;
    }

    if (phone.isEmpty) {
      _showMessage(
        'Please enter your phone number.',
        icon: Icons.phone_outlined,
      );

      return false;
    }

    if (phone.length != 10 || !phone.startsWith('9')) {
      _showMessage(
        'Please enter a valid PH mobile number. It should start with 9 after +63.',
        icon: Icons.phone_outlined,
      );

      return false;
    }

    if (_selectedBirthday == null) {
      _showMessage('Please select your birthday.', icon: Icons.cake_outlined);

      return false;
    }

    return true;
  }

  bool _validateAddress() {
    if (_selectedRegion == null) {
      _showMessage('Please select your region.', icon: Icons.map_outlined);

      return false;
    }

    if (_selectedProvince == null) {
      _showMessage(
        'Please select your province.',
        icon: Icons.location_city_outlined,
      );

      return false;
    }

    if (_selectedMunicipality == null) {
      _showMessage(
        'Please select your municipality or city.',
        icon: Icons.apartment_outlined,
      );

      return false;
    }

    if (_selectedBarangay == null) {
      _showMessage('Please select your barangay.', icon: Icons.place_outlined);

      return false;
    }

    if (_streetController.text.trim().isEmpty) {
      _showMessage('Please enter your street.', icon: Icons.home_outlined);

      return false;
    }

    if (_houseUnitController.text.trim().isEmpty) {
      _showMessage(
        'Please enter your house or unit number.',
        icon: Icons.home_outlined,
      );

      return false;
    }

    return true;
  }

  bool _validateSecurity() {
    final String password = _passwordController.text;

    final String confirmPassword = _confirmPasswordController.text;

    if (password.isEmpty) {
      _showMessage('Please create a password.', icon: Icons.lock_outline);

      return false;
    }

    if (password.length < 6) {
      _showMessage(
        'Password must contain at least 6 characters.',
        icon: Icons.lock_outline,
      );

      return false;
    }

    if (confirmPassword.isEmpty) {
      _showMessage(
        'Please confirm your password.',
        icon: Icons.lock_reset_outlined,
      );

      return false;
    }

    if (password != confirmPassword) {
      _showMessage(
        'Passwords do not match.',
        icon: Icons.warning_amber_rounded,
      );

      return false;
    }

    return true;
  }

  bool _validateRider() {
    if (_selectedVehicleType == null) {
      _showMessage(
        'Please select your vehicle type.',
        icon: Icons.two_wheeler_outlined,
      );

      return false;
    }

    if (_licenseNumberController.text.trim().isEmpty) {
      _showMessage(
        "Please enter your driver's license number.",
        icon: Icons.badge_outlined,
      );

      return false;
    }

    if (_plateNumberController.text.trim().isEmpty) {
      _showMessage('Please enter your plate number.', icon: Icons.pin_outlined);

      return false;
    }

    return true;
  }

  bool _validateDocuments() {
    if (_licenseImage == null) {
      _showMessage(
        "Please upload your driver's license.",
        icon: Icons.badge_outlined,
      );

      return false;
    }

    if (_orCrImage == null) {
      _showMessage(
        'Please upload your OR/CR.',
        icon: Icons.description_outlined,
      );

      return false;
    }

    return true;
  }

  Future<void> _pickDocumentPhoto({required bool isLicense}) async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: lightBeige,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  'Upload Document',
                  style: TextStyle(
                    color: darkMaroon,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                ListTile(
                  leading: const Icon(
                    Icons.camera_alt_outlined,
                    color: darkMaroon,
                  ),
                  title: const Text(
                    'Take Photo',
                    style: TextStyle(
                      color: darkMaroon,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext, ImageSource.camera);
                  },
                ),

                ListTile(
                  leading: const Icon(
                    Icons.photo_library_outlined,
                    color: darkMaroon,
                  ),
                  title: const Text(
                    'Choose from Gallery',
                    style: TextStyle(
                      color: darkMaroon,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext, ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null) {
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (image == null || !mounted) {
        return;
      }

      setState(() {
        if (isLicense) {
          _licenseImage = image;
        } else {
          _orCrImage = image;
        }
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage('Unable to capture the document photo.');
    }
  }

  Future<void> _signUp() async {
    if (!_validateDocuments()) {
      return;
    }

    if (!_agreeToTerms) {
      _showMessage(
        'Please agree to the Terms & Conditions before submitting.',
        icon: Icons.gavel_rounded,
      );
      return;
    }

    if (_selectedBirthday == null ||
        _selectedRegion == null ||
        _selectedProvince == null ||
        _selectedMunicipality == null ||
        _selectedBarangay == null ||
        _selectedVehicleType == null ||
        _licenseImage == null ||
        _orCrImage == null) {
      _showMessage(
        'Please complete all registration information.',
        icon: Icons.warning_amber_rounded,
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    // Local/demo signup only.
    // No Laravel request is sent from this screen.
    await Future.delayed(const Duration(milliseconds: 350));

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
    });

    _showPendingVerificationDialog();
  }

  void _showMessage(String message, {IconData? icon}) {
    _topNotificationEntry?.remove();
    _topNotificationEntry = null;

    final OverlayState overlay = Overlay.of(context);

    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: darkMaroon,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    icon ?? Icons.info_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    _topNotificationEntry = entry;
    overlay.insert(entry);

    Future.delayed(const Duration(seconds: 2), () {
      if (_topNotificationEntry == entry) {
        entry.remove();
        _topNotificationEntry = null;
      }
    });
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: brownBeige, fontSize: 12),
      prefixIcon: Icon(icon, color: maroon, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.58),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: brownBeige.withValues(alpha: 0.35)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: maroon, width: 1.5),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool obscureText = false,
    Widget? suffixIcon,
    bool readOnly = false,
    String? fixedPrefix,
    List<TextInputFormatter>? inputFormatters,
  }) {
    if (fixedPrefix == null) {
      return SizedBox(
        height: 60,
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          obscureText: obscureText,
          readOnly: readOnly,
          inputFormatters: inputFormatters,
          style: const TextStyle(color: darkMaroon, fontSize: 13),
          decoration: _inputDecoration(
            hint: hint,
            icon: icon,
            suffixIcon: suffixIcon,
          ),
        ),
      );
    }

    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: brownBeige.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(icon, color: maroon, size: 20),
          const SizedBox(width: 10),
          Text(
            fixedPrefix,
            style: const TextStyle(
              color: darkMaroon,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 1,
            height: 24,
            color: brownBeige.withValues(alpha: 0.35),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              textCapitalization: textCapitalization,
              obscureText: obscureText,
              readOnly: readOnly,
              inputFormatters: inputFormatters,
              style: const TextStyle(color: darkMaroon, fontSize: 13),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: brownBeige, fontSize: 12),
                suffixIcon: suffixIcon,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 20),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  InputDecoration _flatDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: brownBeige, fontSize: 13),
      filled: true,
      fillColor: lightBeige.withValues(alpha: 0.30),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: maroon, width: 1.4),
      ),
    );
  }

  Widget _flatTextField({
    required TextEditingController controller,
    required String hint,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return SizedBox(
      height: 60,
      child: TextField(
        controller: controller,
        textCapitalization: textCapitalization,
        style: const TextStyle(color: darkMaroon, fontSize: 13),
        decoration: _flatDecoration(hint),
      ),
    );
  }

  // FIX: previously wrapped in a fixed SizedBox(height: 56), which was a few
  // pixels shorter than what DropdownButtonFormField's InputDecorator needs
  // once you factor in the icon + selected item text, causing the
  // "bottom overflowed by 16 pixels" error. Now it's only width-constrained
  // and sized naturally via isDense + tighter content padding, so it never
  // overflows its box while still visually matching the other fields.
  Widget _flatDropdownField({
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return SizedBox(
      width: double.infinity,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        isDense: true,
        menuMaxHeight: 360,
        borderRadius: BorderRadius.circular(18),
        alignment: AlignmentDirectional.centerStart,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        decoration: _flatDecoration(hint).copyWith(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        icon: const Padding(
          padding: EdgeInsets.only(right: 4),
          child: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: maroon,
            size: 24,
          ),
        ),
        dropdownColor: cream,
        style: const TextStyle(
          color: darkMaroon,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        selectedItemBuilder: (context) {
          return items.map((item) {
            return Align(
              alignment: Alignment.centerLeft,
              child: Text(
                item,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: darkMaroon,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList();
        },
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Text(
                item,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: darkMaroon,
                  fontSize: 13,
                  height: 1.25,
                ),
              ),
            ),
          );
        }).toList(),
        onChanged: items.isEmpty ? null : onChanged,
      ),
    );
  }

  Widget _buildHeader() {
    return const Text(
      'Create your account',
      style: TextStyle(
        color: darkMaroon,
        fontSize: 25,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return GestureDetector(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      },
      child: const Padding(
        padding: EdgeInsets.only(top: 3),
        child: Text.rich(
          TextSpan(
            style: TextStyle(color: brownBeige, fontSize: 13),
            children: [
              TextSpan(text: 'Already have an account? '),
              TextSpan(
                text: 'Login',
                style: TextStyle(
                  color: darkMaroon,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    final List<String> labels = [
      'Personal',
      'Address',
      'Security',
      'Rider',
      'Verify',
    ];

    return Row(
      children: List.generate(labels.length, (index) {
        return Expanded(
          child: Row(
            children: [
              Expanded(child: _stepCircle(index, labels[index])),
              if (index < labels.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 17),
                    color: _currentStep > index ? maroon : lightBeige,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _stepCircle(int index, String label) {
    final bool completed = _currentStep > index;
    final bool active = _currentStep == index;

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 29,
          height: 29,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: completed || active
                ? maroon
                : Colors.white.withValues(alpha: 0.45),
            border: Border.all(
              color: completed || active ? maroon : lightBeige,
            ),
          ),
          child: completed
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 17)
              : Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: active ? Colors.white : brownBeige,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          child: Text(
            label,
            style: TextStyle(
              color: active || completed ? maroon : brownBeige,
              fontSize: 9,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _stepTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: darkMaroon,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 3),
        Text(subtitle, style: const TextStyle(color: brownBeige, fontSize: 11)),
      ],
    );
  }

  Widget _buildPersonalStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepTitle('Personal Information', 'Tell us a little about yourself.'),
        const SizedBox(height: 14),
        _textField(
          controller: _fullNameController,
          hint: 'Full Name',
          icon: Icons.person_outline,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 10),
        _textField(
          controller: _emailController,
          hint: 'Email Address',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 10),
        _textField(
          controller: _phoneController,
          hint: '9123456789',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          fixedPrefix: '+63',
          inputFormatters: [_PhLocalNumberFormatter()],
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: _pickBirthday,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.58),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: brownBeige.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                const Icon(Icons.cake_outlined, color: maroon, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedBirthday == null
                        ? 'Birthday'
                        : _formatBirthday(_selectedBirthday!),
                    style: TextStyle(
                      color: _selectedBirthday == null
                          ? brownBeige
                          : darkMaroon,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Icon(
                  Icons.calendar_month_outlined,
                  color: maroon,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        _textField(
          controller: _ageController,
          hint: 'Age is calculated automatically',
          icon: Icons.person_search_outlined,
          readOnly: true,
        ),
        // Extra breathing room so the last field never sits flush against
        // the keyboard when this step scrolls.
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildAddressStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepTitle(
          'Residential Address',
          'Select your complete rider address.',
        ),
        const SizedBox(height: 14),

        if (_isLoadingRegions && _regionItems.isEmpty)
          _locationLoadingField('Loading regions...')
        else if (_regionLoadFailed && _regionItems.isEmpty)
          _locationRetryField(
            text: 'Unable to load regions. Tap to retry.',
            onTap: _fetchRegions,
          )
        else
          _flatDropdownField(
            hint: 'Region*',
            value: _selectedRegion,
            items: _regions,
            onChanged: (value) async {
              setState(() {
                _selectedRegion = value;
                _selectedRegionCode = _codeForName(_regionItems, value);

                _selectedProvince = null;
                _selectedProvinceCode = null;

                _selectedMunicipality = null;
                _selectedMunicipalityCode = null;

                _selectedBarangay = null;

                _provinceItems = [];
                _municipalityItems = [];
                _barangayItems = [];

                _provinceLoadFailed = false;
                _municipalityLoadFailed = false;
                _barangayLoadFailed = false;
              });

              if (value != null) {
                await _fetchProvinces();
              }
            },
          ),

        const SizedBox(height: 10),

        if (_isLoadingProvinces)
          _locationLoadingField('Loading provinces...')
        else if (_provinceLoadFailed)
          _locationRetryField(
            text: 'Unable to load provinces. Tap to retry.',
            onTap: _fetchProvinces,
          )
        else
          _flatDropdownField(
            hint: _selectedRegion == null ? 'Select region first' : 'Province*',
            value: _selectedProvince,
            items: _provinces,
            onChanged: (value) async {
              setState(() {
                _selectedProvince = value;
                _selectedProvinceCode = _codeForName(_provinceItems, value);

                _selectedMunicipality = null;
                _selectedMunicipalityCode = null;

                _selectedBarangay = null;

                _municipalityItems = [];
                _barangayItems = [];
              });

              if (value != null) {
                final bool provinceUsesRegionCode =
                    _selectedProvinceCode == _selectedRegionCode &&
                    _provinceItems.length == 1;

                await _fetchMunicipalities(
                  loadByRegion: provinceUsesRegionCode,
                );
              }
            },
          ),

        const SizedBox(height: 10),

        if (_isLoadingMunicipalities)
          _locationLoadingField('Loading cities / municipalities...')
        else if (_municipalityLoadFailed)
          _locationRetryField(
            text: 'Unable to load cities / municipalities. Tap to retry.',
            onTap: () async {
              final bool loadByRegion =
                  _selectedProvinceCode == _selectedRegionCode &&
                  _provinceItems.length == 1;
              await _fetchMunicipalities(loadByRegion: loadByRegion);
            },
          )
        else
          _flatDropdownField(
            hint: _selectedProvince == null
                ? 'Select province first'
                : 'City / Municipality*',
            value: _selectedMunicipality,
            items: _municipalities,
            onChanged: (value) async {
              setState(() {
                _selectedMunicipality = value;
                _selectedMunicipalityCode = _codeForName(
                  _municipalityItems,
                  value,
                );

                _selectedBarangay = null;
                _barangayItems = [];
              });

              if (value != null) {
                await _fetchBarangays();
              }
            },
          ),

        const SizedBox(height: 10),

        if (_isLoadingBarangays)
          _locationLoadingField('Loading barangays...')
        else if (_barangayLoadFailed)
          _locationRetryField(
            text: 'Unable to load barangays. Tap to retry.',
            onTap: _fetchBarangays,
          )
        else
          _flatDropdownField(
            hint: _selectedMunicipality == null
                ? 'Select city / municipality first'
                : 'Barangay*',
            value: _selectedBarangay,
            items: _barangays,
            onChanged: (value) {
              setState(() {
                _selectedBarangay = value;
              });
            },
          ),

        const SizedBox(height: 10),

        _flatTextField(
          controller: _streetController,
          hint: 'Street*',
          textCapitalization: TextCapitalization.words,
        ),

        const SizedBox(height: 10),

        _flatTextField(
          controller: _houseUnitController,
          hint: 'House / unit no.*',
          textCapitalization: TextCapitalization.words,
        ),

        const SizedBox(height: 8),
      ],
    );
  }

  Widget _locationLoadingField(String text) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: lightBeige.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: maroon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: brownBeige, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _locationRetryField({
    required String text,
    required Future<void> Function() onTap,
  }) {
    return InkWell(
      onTap: () {
        onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: maroon.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            const Icon(Icons.refresh_rounded, color: maroon, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: maroon,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepTitle(
          'Account Security',
          'Create a secure password for your rider account.',
        ),
        const SizedBox(height: 22),
        _textField(
          controller: _passwordController,
          hint: 'Create Password',
          icon: Icons.lock_outline,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: maroon,
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: 14),
        _textField(
          controller: _confirmPasswordController,
          hint: 'Confirm Password',
          icon: Icons.lock_reset_outlined,
          obscureText: _obscureConfirmPassword,
          suffixIcon: IconButton(
            onPressed: () {
              setState(() {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              });
            },
            icon: Icon(
              _obscureConfirmPassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: maroon,
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: lightBeige),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.shield_outlined, color: maroon, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Use at least 6 characters. Do not share your password with anyone.',
                  style: TextStyle(
                    color: brownBeige,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildRiderStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepTitle(
          'Rider & Vehicle',
          'Provide the vehicle you will use for deliveries.',
        ),
        const SizedBox(height: 14),
        _vehicleTypeSelector(),
        const SizedBox(height: 14),
        _textField(
          controller: _licenseNumberController,
          hint: "Driver's License Number",
          icon: Icons.badge_outlined,
          textCapitalization: TextCapitalization.characters,
        ),
        const SizedBox(height: 10),
        _textField(
          controller: _plateNumberController,
          hint: 'Vehicle Plate Number',
          icon: Icons.pin_outlined,
          textCapitalization: TextCapitalization.characters,
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _vehicleTypeSelector() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double spacing = 8;

        final double width = (constraints.maxWidth - spacing) / 2;

        return Wrap(
          spacing: spacing,
          runSpacing: 8,
          children: _vehicleTypes.map((vehicle) {
            final String label = vehicle['label'] as String;

            final IconData icon = vehicle['icon'] as IconData;

            final bool selected = _selectedVehicleType == label;

            return SizedBox(
              width: width,
              height: 48,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedVehicleType = label;
                  });
                },
                borderRadius: BorderRadius.circular(13),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? maroon
                        : Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: selected ? maroon : lightBeige),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        color: selected ? Colors.white : darkMaroon,
                        size: 19,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            color: selected ? Colors.white : darkMaroon,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildVerificationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepTitle(
          'Document Verification',
          'Upload clear photos for admin approval.',
        ),
        const SizedBox(height: 14),
        _compactDocumentCard(
          title: "Driver's License",
          subtitle: _licenseImage == null
              ? 'Upload front side'
              : 'Photo uploaded',
          image: _licenseImage,
          icon: Icons.badge_outlined,
          onTap: () {
            _pickDocumentPhoto(isLicense: true);
          },
        ),
        const SizedBox(height: 10),
        _compactDocumentCard(
          title: 'OR / CR',
          subtitle: _orCrImage == null
              ? 'Vehicle registration'
              : 'Photo uploaded',
          image: _orCrImage,
          icon: Icons.description_outlined,
          onTap: () {
            _pickDocumentPhoto(isLicense: false);
          },
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: lightBeige.withValues(alpha: 0.30),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.admin_panel_settings_outlined,
                color: maroon,
                size: 19,
              ),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Your account will be reviewed by the admin after submission.',
                  style: TextStyle(color: brownBeige, fontSize: 10),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: lightBeige),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: Checkbox(
                  value: _agreeToTerms,
                  activeColor: darkMaroon,
                  checkColor: Colors.white,
                  side: const BorderSide(color: brownBeige, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  onChanged: _isLoading
                      ? null
                      : (value) {
                          setState(() {
                            _agreeToTerms = value ?? false;
                          });
                        },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'I agree to the ',
                      style: TextStyle(color: brownBeige, fontSize: 11),
                    ),
                    GestureDetector(
                      onTap: _isLoading
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const TermsConditionsScreen(),
                                ),
                              );
                            },
                      child: const Text(
                        'Terms & Conditions',
                        style: TextStyle(
                          color: darkMaroon,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                          decorationColor: darkMaroon,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _compactDocumentCard({
    required String title,
    required String subtitle,
    required XFile? image,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final bool uploaded = image != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 92,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.50),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: uploaded ? Colors.green.withValues(alpha: 0.50) : lightBeige,
          ),
        ),
        child: Row(
          children: [
            if (uploaded)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  File(image.path),
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: lightBeige.withValues(alpha: 0.40),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: darkMaroon, size: 27),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: darkMaroon,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: brownBeige, fontSize: 10),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    uploaded ? 'Tap to change' : 'Tap to upload',
                    style: const TextStyle(
                      color: maroon,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              uploaded ? Icons.check_circle : Icons.add_a_photo_outlined,
              color: uploaded ? Colors.green : maroon,
              size: 21,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildPersonalStep();
      case 1:
        return _buildAddressStep();
      case 2:
        return _buildSecurityStep();
      case 3:
        return _buildRiderStep();
      case 4:
        return _buildVerificationStep();
      default:
        return _buildPersonalStep();
    }
  }

  Widget _buildBottomButtons() {
    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: SizedBox(
              height: 60,
              child: OutlinedButton(
                onPressed: _isLoading ? null : _previousStep,
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.55),
                  foregroundColor: darkMaroon,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: const Text(
                  'BACK',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 60,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: maroon,
                foregroundColor: Colors.white,
                disabledBackgroundColor: brownBeige,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 21,
                      height: 21,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _currentStep == 4 ? 'SUBMIT' : 'CONTINUE',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  void _showPendingVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: cream,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 75,
                height: 75,
                decoration: BoxDecoration(
                  color: lightBeige,
                  shape: BoxShape.circle,
                  border: Border.all(color: darkMaroon, width: 2),
                ),
                child: const Icon(
                  Icons.hourglass_top_rounded,
                  color: darkMaroon,
                  size: 38,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Registration Complete!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: darkMaroon,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your rider registration form is complete on this device.',
                textAlign: TextAlign.center,
                style: TextStyle(color: brownBeige, fontSize: 12, height: 1.5),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: lightBeige.withValues(alpha: 0.50),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.admin_panel_settings_outlined,
                      color: darkMaroon,
                      size: 27,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Local Demo Registration',
                            style: TextStyle(
                              color: darkMaroon,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Laravel submission is disabled for this screen. No rider data is being sent to the server.',
                            style: TextStyle(
                              color: maroon,
                              fontSize: 11,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkMaroon,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Back to Login',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Decorative waves/lines matching the Login screen.
          const Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _SignUpDecorPainter()),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 14),
              child: Column(
                children: [
                  SizedBox(
                    height: 42,
                    child: Row(
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          alignment: Alignment.centerLeft,
                          onPressed: () {
                            if (_currentStep > 0) {
                              _previousStep();
                            } else {
                              Navigator.pop(context);
                            }
                          },
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: darkMaroon,
                            size: 19,
                          ),
                        ),
                        const Spacer(),
                        Image.asset(
                          'assets/images/logo.png',
                          width: 42,
                          height: 42,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 6),

                  Align(alignment: Alignment.centerLeft, child: _buildHeader()),

                  const SizedBox(height: 18),

                  _buildStepIndicator(),

                  const SizedBox(height: 18),

                  // FIX: the step content is now wrapped in a SingleChildScrollView.
                  // Previously this Column of fields could be taller than the
                  // Expanded area (especially the Address step with 4 dropdowns,
                  // or the Personal step once the keyboard opens and shrinks the
                  // available height), which caused a RenderFlex overflow and made
                  // the layout jump/shift. Now it scrolls internally instead, and
                  // the CONTINUE / BACK buttons below stay fixed in place.
                  Expanded(
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      physics: const ClampingScrollPhysics(),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        child: Align(
                          key: ValueKey(_currentStep),
                          alignment: Alignment.topCenter,
                          child: _buildCurrentStep(),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  _buildBottomButtons(),

                  if (_currentStep == 0) ...[
                    const SizedBox(height: 8),
                    _buildLoginPrompt(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// SIGN UP DECORATIVE BACKGROUND
// Same visual language as the Login screen: soft bottom waves
// plus subtle curved accent lines along the left and right edges.
// ================================================================
class _SignUpDecorPainter extends CustomPainter {
  const _SignUpDecorPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final backWavePaint = Paint()
      ..color = const Color(0xFF9E7161).withValues(alpha: 0.16)
      ..style = PaintingStyle.fill;

    final frontWavePaint = Paint()
      ..color = const Color(0xFF873632).withValues(alpha: 0.10)
      ..style = PaintingStyle.fill;

    final sideLinePaint = Paint()
      ..color = const Color(0xFF873632).withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    // Bottom back wave
    final backWave = Path()
      ..moveTo(0, size.height * 0.88)
      ..cubicTo(
        size.width * 0.22,
        size.height * 0.84,
        size.width * 0.44,
        size.height * 0.94,
        size.width * 0.64,
        size.height * 0.90,
      )
      ..cubicTo(
        size.width * 0.80,
        size.height * 0.87,
        size.width * 0.91,
        size.height * 0.84,
        size.width,
        size.height * 0.86,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(backWave, backWavePaint);

    // Bottom front wave
    final frontWave = Path()
      ..moveTo(0, size.height * 0.92)
      ..cubicTo(
        size.width * 0.20,
        size.height * 0.89,
        size.width * 0.40,
        size.height * 0.97,
        size.width * 0.58,
        size.height * 0.94,
      )
      ..cubicTo(
        size.width * 0.76,
        size.height * 0.91,
        size.width * 0.88,
        size.height * 0.89,
        size.width,
        size.height * 0.91,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(frontWave, frontWavePaint);

    // Left decorative curves
    final leftTopCurve = Path()
      ..moveTo(0, size.height * 0.18)
      ..cubicTo(
        size.width * 0.07,
        size.height * 0.16,
        size.width * 0.11,
        size.height * 0.20,
        size.width * 0.16,
        size.height * 0.18,
      );
    canvas.drawPath(leftTopCurve, sideLinePaint);

    final leftMidCurve = Path()
      ..moveTo(0, size.height * 0.55)
      ..cubicTo(
        size.width * 0.05,
        size.height * 0.53,
        size.width * 0.10,
        size.height * 0.57,
        size.width * 0.14,
        size.height * 0.55,
      );
    canvas.drawPath(leftMidCurve, sideLinePaint);

    // Right decorative curves
    final rightTopCurve = Path()
      ..moveTo(size.width, size.height * 0.27)
      ..cubicTo(
        size.width * 0.93,
        size.height * 0.25,
        size.width * 0.89,
        size.height * 0.29,
        size.width * 0.84,
        size.height * 0.27,
      );
    canvas.drawPath(rightTopCurve, sideLinePaint);

    final rightMidCurve = Path()
      ..moveTo(size.width, size.height * 0.68)
      ..cubicTo(
        size.width * 0.95,
        size.height * 0.66,
        size.width * 0.90,
        size.height * 0.70,
        size.width * 0.86,
        size.height * 0.68,
      );
    canvas.drawPath(rightMidCurve, sideLinePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
