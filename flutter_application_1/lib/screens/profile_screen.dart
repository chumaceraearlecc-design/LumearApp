import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_application_1/models/rider_profile.dart';
import 'package:flutter_application_1/data/hardcoded_rider.dart';

import 'personal_information_screen.dart';
import 'vehicle_information_screen.dart';
import 'documents_screen.dart';
import 'app_settings_screen.dart';
import 'help_support_screen.dart';
import 'rider_performance_screen.dart';
import 'login_screen.dart';
import 'assignment_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ============================================================
  // DESIGN SYSTEM — COLORS
  // Matches the dashboard and parcels screens' palette and tokens.
  // ============================================================

  static const Color darkMaroon = Color(0xFF62191C);
  static const Color maroon = Color(0xFF873632);
  static const Color brownBeige = Color(0xFF9E7161);
  static const Color lightBeige = Color(0xFFCAAE9F);
  static const Color cream = Color(0xFFF3E9E1);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF8B6F63);

  static const Color success = Color(0xFF2E7D32);
  static const Color danger = Color(0xFFB3261E);

  static const double radiusSm = 14;
  static const double radiusMd = 18;
  static const double radiusLg = 22;
  static const double radiusXl = 26;

  static List<BoxShadow> get shadowSoft => [
    BoxShadow(
      color: darkMaroon.withValues(alpha: 0.06),
      blurRadius: 18,
      offset: const Offset(0, 6),
    ),
  ];

  static BoxDecoration get cardDecoration => BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(radiusLg),
    border: Border.all(color: darkMaroon.withValues(alpha: 0.06)),
    boxShadow: shadowSoft,
  );

  final ImagePicker _picker = ImagePicker();

  bool _isUpdatingPhoto = false;

  OverlayEntry? _topNotificationEntry;

  @override
  void dispose() {
    _topNotificationEntry?.remove();
    super.dispose();
  }

  // ============================================
  // PROFILE PHOTO — OPTIONS SHEET
  // ============================================

  Future<void> _showProfilePhotoOptions() async {
    final String? action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: cream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: brownBeige.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: darkMaroon,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.photo_camera_rounded,
                          color: Colors.white,
                          size: 19,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Update Profile Picture',
                        style: TextStyle(
                          color: darkMaroon,
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  _sheetOption(
                    icon: Icons.camera_alt_rounded,
                    label: 'Take Photo',
                    onTap: () => Navigator.pop(sheetContext, 'camera'),
                  ),

                  const SizedBox(height: 10),

                  _sheetOption(
                    icon: Icons.photo_library_rounded,
                    label: 'Choose from Gallery',
                    onTap: () => Navigator.pop(sheetContext, 'gallery'),
                  ),

                  if (RiderProfile.profileImage != null) ...[
                    const SizedBox(height: 10),
                    _sheetOption(
                      icon: Icons.delete_outline_rounded,
                      label: 'Remove Photo',
                      color: danger,
                      onTap: () => Navigator.pop(sheetContext, 'remove'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );

    if (action == null) {
      return;
    }

    if (action == 'remove') {
      setState(() {
        RiderProfile.profileImage = null;
      });

      _showTopNotification(
        'Profile picture removed.',
        icon: Icons.check_circle_outline,
      );

      return;
    }

    final ImageSource source = action == 'camera'
        ? ImageSource.camera
        : ImageSource.gallery;

    await _pickProfileImage(source);
  }

  Widget _sheetOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = darkMaroon,
  }) {
    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(radiusMd),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: color, size: 19),
              ),
              const SizedBox(width: 13),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================
  // PROFILE PHOTO — PICK
  // ============================================

  Future<void> _pickProfileImage(ImageSource source) async {
    setState(() {
      _isUpdatingPhoto = true;
    });

    try {
      final XFile? pickedImage = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (pickedImage == null) {
        if (mounted) {
          setState(() {
            _isUpdatingPhoto = false;
          });
        }

        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        RiderProfile.profileImage = File(pickedImage.path);

        _isUpdatingPhoto = false;
      });

      _showTopNotification(
        'Profile picture updated.',
        icon: Icons.check_circle_outline,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isUpdatingPhoto = false;
      });

      _showTopNotification('Unable to update profile picture.');
    }
  }

  // ============================================
  // TOP NOTIFICATION
  // ============================================

  void _showTopNotification(String message, {IconData? icon}) {
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
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.22),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon ?? Icons.info_outline,
                      color: Colors.white,
                      size: 17,
                    ),
                  ),

                  const SizedBox(width: 12),

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

  // ============================================
  // LOG OUT
  // ============================================

  void _showLogoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: cream,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
          contentPadding: const EdgeInsets.fromLTRB(22, 14, 22, 10),
          actionsPadding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: danger.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: danger,
                  size: 19,
                ),
              ),

              const SizedBox(width: 12),

              const Text(
                'Log Out',
                style: TextStyle(
                  color: darkMaroon,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to log out of your rider account?',
            style: TextStyle(color: textMuted, fontSize: 13.5, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(color: textMuted, fontWeight: FontWeight.w700),
              ),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: darkMaroon,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(radiusSm),
                ),
              ),
              child: const Text(
                'Yes, Log Out',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================
  // BUILD
  // ============================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: SingleChildScrollView(
          // EXTRA SPACE FOR FLOATING NAVBAR
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 125),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ============================================
              // HEADER
              // ============================================

              _EntranceAnimation(
                delay: 30,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Profile',
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        color: darkMaroon,
                        letterSpacing: -0.4,
                      ),
                    ),

                    Container(
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: shadowSoft,
                      ),
                      child: IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AppSettingsScreen(),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.settings_outlined,
                          color: darkMaroon,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ============================================
              // PROFILE CARD
              // ============================================
              _EntranceAnimation(
                delay: 80,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [darkMaroon, maroon],
                    ),
                    borderRadius: BorderRadius.circular(radiusXl),
                    boxShadow: [
                      BoxShadow(
                        color: darkMaroon.withValues(alpha: 0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _isUpdatingPhoto
                            ? null
                            : _showProfilePhotoOptions,
                        child: Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  width: 2,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 46,
                                backgroundColor: lightBeige,
                                backgroundImage:
                                    RiderProfile.profileImage != null
                                    ? FileImage(RiderProfile.profileImage!)
                                    : null,
                                child: RiderProfile.profileImage == null
                                    ? const Icon(
                                        Icons.person,
                                        size: 50,
                                        color: darkMaroon,
                                      )
                                    : null,
                              ),
                            ),

                            if (_isUpdatingPhoto)
                              Positioned.fill(
                                child: Container(
                                  margin: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black.withValues(alpha: 0.4),
                                  ),
                                  child: const Center(
                                    child: SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                            Positioned(
                              bottom: 2,
                              right: 2,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: cream,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: darkMaroon,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  color: darkMaroon,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      TextButton.icon(
                        onPressed: _isUpdatingPhoto
                            ? null
                            : _showProfilePhotoOptions,
                        icon: const Icon(
                          Icons.photo_library_outlined,
                          size: 16,
                        ),
                        label: const Text(
                          'Change Profile Picture',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white.withValues(alpha: 0.85),
                          disabledForegroundColor: Colors.white.withValues(
                            alpha: 0.4,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                        ),
                      ),

                      const SizedBox(height: 2),

                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const PersonalInformationScreen(),
                            ),
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              HardcodedRider.fullName,
                              style: const TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),

                            const SizedBox(width: 6),

                            Icon(
                              Icons.edit_rounded,
                              size: 14,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        'Rider ID: ${HardcodedRider.riderId}',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),

                      const SizedBox(height: 14),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.circle,
                              size: 8,
                              color: Colors.greenAccent,
                            ),

                            SizedBox(width: 7),

                            Text(
                              'Online',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ============================================
              // STATS
              // ============================================
              _EntranceAnimation(
                delay: 140,
                child: Row(
                  children: [
                    Expanded(
                      child: _statCard(
                        icon: Icons.star_rounded,
                        iconColor: const Color(0xFFC77700),
                        value: '4.8',
                        label: 'Rating',
                      ),
                    ),

                    const SizedBox(width: 11),

                    Expanded(
                      child: _statCard(
                        icon: Icons.delivery_dining_rounded,
                        iconColor: darkMaroon,
                        value: '256',
                        label: 'Deliveries',
                      ),
                    ),

                    const SizedBox(width: 11),

                    Expanded(
                      child: _statCard(
                        icon: Icons.calendar_month_rounded,
                        iconColor: maroon,
                        value: '3 Mos.',
                        label: 'Member',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ============================================
              // VERIFIED RIDER
              // ============================================
              _EntranceAnimation(
                delay: 190,
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(radiusLg),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(radiusLg),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DocumentsScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: success.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(radiusLg),
                        border: Border.all(
                          color: success.withValues(alpha: 0.22),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: success,
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: const Icon(
                              Icons.verified_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),

                          const SizedBox(width: 14),

                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Verified Rider',
                                  style: TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w800,
                                    color: darkMaroon,
                                  ),
                                ),

                                SizedBox(height: 3),

                                Text(
                                  'Your rider account has been verified.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Icon(
                            Icons.chevron_right_rounded,
                            color: success,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 26),

              _EntranceAnimation(delay: 220, child: _sectionLabel('Work')),

              const SizedBox(height: 12),

              _EntranceAnimation(
                delay: 240,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: cardDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: darkMaroon.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.assignment_rounded,
                              color: darkMaroon,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Current Assignment',
                              style: TextStyle(
                                color: darkMaroon,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: success.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Active',
                              style: TextStyle(
                                color: success,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _AssignmentInfoItem(
                              icon: Icons.warehouse_outlined,
                              label: 'Assigned hub',
                              value: AssignmentScreen.assignedHub,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _AssignmentInfoItem(
                              icon: Icons.location_on_outlined,
                              label: 'Delivery area',
                              value: AssignmentScreen.assignedArea,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _AssignmentInfoItem(
                              icon: Icons.schedule_rounded,
                              label: 'Shift',
                              value: AssignmentScreen.assignedShift,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _AssignmentInfoItem(
                              icon: Icons.inventory_2_outlined,
                              label: 'Assigned parcels',
                              value: '${AssignmentScreen.assignedParcels}',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AssignmentScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                        label: const Text('View assignment details'),
                        style: TextButton.styleFrom(
                          foregroundColor: darkMaroon,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ============================================
              // ACCOUNT
              // ============================================
              _EntranceAnimation(delay: 240, child: _sectionLabel('Account')),

              const SizedBox(height: 12),

              _EntranceAnimation(
                delay: 280,
                child: _profileMenu(
                  icon: Icons.person_rounded,
                  title: 'Personal Information',
                  subtitle: 'Name, contact number, and address',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PersonalInformationScreen(),
                      ),
                    );
                  },
                ),
              ),

              _EntranceAnimation(
                delay: 320,
                child: _profileMenu(
                  icon: Icons.two_wheeler_rounded,
                  title: 'Vehicle Information',
                  subtitle: 'Motorcycle and plate details',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VehicleInformationScreen(),
                      ),
                    );
                  },
                ),
              ),

              _EntranceAnimation(
                delay: 360,
                child: _profileMenu(
                  icon: Icons.description_rounded,
                  title: 'Documents',
                  subtitle: 'License and verification documents',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DocumentsScreen(),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // ============================================
              // SETTINGS & SUPPORT
              // ============================================
              _EntranceAnimation(
                delay: 440,
                child: _sectionLabel('Settings & Support'),
              ),

              const SizedBox(height: 12),

              _EntranceAnimation(
                delay: 480,
                child: _profileMenu(
                  icon: Icons.settings_rounded,
                  title: 'App Settings',
                  subtitle: 'Notifications and preferences',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AppSettingsScreen(),
                      ),
                    );
                  },
                ),
              ),

              _EntranceAnimation(
                delay: 520,
                child: _profileMenu(
                  icon: Icons.support_agent_rounded,
                  title: 'Help & Support',
                  subtitle: 'Chat with Customer Service',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HelpSupportScreen(),
                      ),
                    );
                  },
                ),
              ),

              _EntranceAnimation(
                delay: 560,
                child: _profileMenu(
                  icon: Icons.bar_chart_rounded,
                  title: 'Rider Performance',
                  subtitle: 'Ratings and delivery performance',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RiderPerformanceScreen(),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // ============================================
              // LOG OUT
              // ============================================
              _EntranceAnimation(
                delay: 600,
                child: _profileMenu(
                  icon: Icons.logout_rounded,
                  title: 'Log Out',
                  subtitle: 'Sign out of your rider account',
                  onTap: _showLogoutDialog,
                  isDanger: true,
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================
  // SECTION LABEL
  // ============================================

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 18.5,
        fontWeight: FontWeight.w800,
        color: darkMaroon,
        letterSpacing: -0.3,
      ),
    );
  }

  // ============================================
  // STAT CARD
  // ============================================

  Widget _statCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      decoration: cardDecoration,
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 19),
          ),

          const SizedBox(height: 10),

          Text(
            value,
            style: const TextStyle(
              fontSize: 17.5,
              fontWeight: FontWeight.w800,
              color: darkMaroon,
              letterSpacing: -0.3,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // PROFILE MENU
  // ============================================

  Widget _profileMenu({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    final Color accent = isDanger ? danger : darkMaroon;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: surface,
        borderRadius: BorderRadius.circular(radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radiusMd),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radiusMd),
              border: Border.all(color: darkMaroon.withValues(alpha: 0.05)),
              boxShadow: shadowSoft,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: accent, size: 20),
                ),

                const SizedBox(width: 13),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: isDanger ? danger : darkMaroon,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 11, color: textMuted),
                      ),
                    ],
                  ),
                ),

                Icon(
                  Icons.chevron_right_rounded,
                  color: accent.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// CURRENT ASSIGNMENT INFO ITEM
// ============================================================

class _AssignmentInfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _AssignmentInfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    const darkMaroon = Color(0xFF62191C);
    const cream = Color(0xFFF3E9E1);
    const textMuted = Color(0xFF8B6F63);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cream,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: darkMaroon.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: darkMaroon, size: 17),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textMuted,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: darkMaroon,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SUBTLE ENTRANCE ANIMATION
// Fade + small rise + tiny pop
// ============================================================

class _EntranceAnimation extends StatefulWidget {
  final Widget child;
  final int delay;

  const _EntranceAnimation({required this.child, required this.delay});

  @override
  State<_EntranceAnimation> createState() => _EntranceAnimationState();
}

class _EntranceAnimationState extends State<_EntranceAnimation> {
  bool _show = false;

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (!mounted) {
        return;
      }

      setState(() {
        _show = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _show ? 1 : 0,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,

      child: AnimatedSlide(
        offset: _show ? Offset.zero : const Offset(0, 0.025),
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,

        child: AnimatedScale(
          scale: _show ? 1 : 0.985,
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutCubic,
          child: widget.child,
        ),
      ),
    );
  }
}
