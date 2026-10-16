import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/rider_profile.dart';
import 'package:flutter_application_1/models/hub_transfer_model.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../widgets/hub_assignment_card.dart';
import '../widgets/parcel_loading_card.dart';
import '../widgets/transfer_progress_card.dart';
import '../widgets/transfer_history_card.dart';

import 'app_settings_screen.dart';
import 'login_screen.dart';

class HubTransferDashboardScreen extends StatefulWidget {
  const HubTransferDashboardScreen({super.key});

  @override
  State<HubTransferDashboardScreen> createState() =>
      _HubTransferDashboardScreenState();
}

class _HubTransferDashboardScreenState
    extends State<HubTransferDashboardScreen> {
  static const darkMaroon = Color(0xFF62191C);
  static const maroon = Color(0xFF873632);
  static const brownBeige = Color(0xFF9E7161);
  static const cream = Color(0xFFE0CFC2);
  static const background = Color(0xFFF8F2ED);

  int _selectedTab = 0;
  late int _loadedParcels;

  bool _loadingComplete = false;
  bool _hasDeparted = false;
  bool _hasArrived = false;
  bool _unloadingComplete = false;

  final List<TransferHistoryItem> _history = [...demoTransferHistory];

  static const LatLng _originPoint = LatLng(14.6763, 121.0437);
  static const LatLng _destinationPoint = LatLng(14.4081, 121.0415);
  static const List<LatLng> _routePoints = [
    _originPoint,
    LatLng(14.6250, 121.0520),
    LatLng(14.5700, 121.0470),
    LatLng(14.5150, 121.0450),
    _destinationPoint,
  ];

  @override
  void initState() {
    super.initState();
    _loadedParcels = demoHubTransfer.initialLoadedParcels;
  }

  String get _name {
    final name = RiderProfile.name.trim();
    return name.isEmpty ? 'Demo Rider' : name;
  }

  String get _vehicle {
    final vehicle = RiderProfile.vehicleType.trim();
    return vehicle.isEmpty ? 'Truck' : vehicle;
  }

  String get _status {
    if (_unloadingComplete) return 'Completed';
    if (_hasArrived) return 'Arrived';
    if (_hasDeparted) return 'In Transit';
    if (_loadingComplete) return 'Ready to Depart';
    return 'Loading';
  }

  IconData get _vehicleIcon {
    if (_vehicle.toLowerCase().contains('van')) {
      return Icons.airport_shuttle;
    }
    return Icons.local_shipping;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: darkMaroon,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openProfile() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          height: MediaQuery.sizeOf(sheetContext).height * 0.9,
          decoration: const BoxDecoration(
            color: background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cream,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 10, 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Rider information',
                          style: TextStyle(
                            color: darkMaroon,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close rider information',
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close, color: darkMaroon),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                    children: [
                      _profileDetail('Full name', RiderProfile.name),
                      _profileDetail('Email', RiderProfile.email),
                      _profileDetail('Phone', RiderProfile.phone),
                      _profileDetail(
                        'Birthday',
                        RiderProfile.age == null
                            ? RiderProfile.birthday
                            : '${RiderProfile.birthday} · ${RiderProfile.age} years old',
                      ),
                      _profileDetail(
                        'Residential address',
                        RiderProfile.completeAddress,
                      ),
                      _profileDetail('Vehicle', RiderProfile.vehicleType),
                      _profileDetail('Plate number', RiderProfile.plateNumber),
                      _profileDetail(
                        "Driver's license number",
                        RiderProfile.licenseNumber,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Documents',
                        style: TextStyle(
                          color: darkMaroon,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _documentPreview(
                        "Driver's License",
                        RiderProfile.localDriverLicenseFile,
                      ),
                      const SizedBox(height: 10),
                      _documentPreview(
                        'Official Receipt (OR)',
                        RiderProfile.localOrFile,
                      ),
                      const SizedBox(height: 10),
                      _documentPreview(
                        'Certificate of Registration (CR)',
                        RiderProfile.localCrFile,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Profile details and document previews are stored locally for this prototype.',
                        style: TextStyle(color: brownBeige, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _profileDetail(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: brownBeige,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value.trim().isEmpty ? 'Not provided' : value,
            style: const TextStyle(
              color: darkMaroon,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _documentPreview(String title, File? file) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: darkMaroon,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: file == null
                ? Container(
                    height: 130,
                    width: double.infinity,
                    color: cream.withValues(alpha: 0.45),
                    alignment: Alignment.center,
                    child: const Text(
                      'No local document uploaded',
                      style: TextStyle(color: brownBeige, fontSize: 12),
                    ),
                  )
                : Image.file(
                    file,
                    height: 170,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      height: 130,
                      alignment: Alignment.center,
                      color: cream.withValues(alpha: 0.45),
                      child: const Text(
                        'Document preview unavailable',
                        style: TextStyle(color: brownBeige, fontSize: 12),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AppSettingsScreen()),
    );
  }

  Future<void> _confirmLogout() async {
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: cream,
          title: const Text(
            'Log out?',
            style: TextStyle(color: darkMaroon, fontWeight: FontWeight.w800),
          ),
          content: const Text(
            'You will return to the login screen. Your local demo rider information will remain on this device.',
            style: TextStyle(color: brownBeige, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Log out'),
              style: FilledButton.styleFrom(
                backgroundColor: darkMaroon,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true || !mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _confirmDeparture() {
    setState(() => _hasDeparted = true);
    _showMessage('Departure confirmed locally.');
  }

  void _confirmArrival() {
    setState(() => _hasArrived = true);
    _showMessage('Arrival confirmed locally.');
  }

  void _confirmUnloading() {
    setState(() {
      _unloadingComplete = true;
      _history.insert(
        0,
        TransferHistoryItem(
          id: 'HT-2048',
          origin: 'Lumear North Sorting Center',
          destination: 'Lumear South Distribution Hub',
          status: 'Completed',
          completedAt: _historyDate(DateTime.now()),
          parcelCount: _loadedParcels,
        ),
      );
    });

    _showMessage('Transfer completed locally.');
  }

  String _historyDate(DateTime date) {
    const List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Widget _sectionHeading(String title, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: darkMaroon,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: brownBeige, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final plate = RiderProfile.plateNumber.trim();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [darkMaroon, maroon, brownBeige],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(_vehicleIcon, color: Colors.white, size: 29),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LUMEAR RIDER',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Hub Transfer Dashboard',
                      style: TextStyle(color: cream, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _openProfile,
                icon: const Icon(Icons.person_outline, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'Welcome back,',
            style: TextStyle(color: cream, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            _name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _headerChip(_vehicleIcon, _vehicle),
              if (plate.isNotEmpty)
                _headerChip(Icons.confirmation_number_outlined, plate),
              _headerChip(
                Icons.circle,
                _unloadingComplete ? 'Transfer Complete' : 'On Duty',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: cream),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _resetDemo() {
    setState(() {
      _loadedParcels = demoHubTransfer.initialLoadedParcels;
      _loadingComplete = false;
      _hasDeparted = false;
      _hasArrived = false;
      _unloadingComplete = false;

      _history.removeWhere((item) => item.id == demoHubTransfer.id);
    });

    _showMessage('Demo transfer has been reset.');
  }

  Widget _buildRouteMap() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 270,
        child: FlutterMap(
          options: MapOptions(
            initialCameraFit: CameraFit.bounds(
              bounds: LatLngBounds.fromPoints(_routePoints),
              padding: const EdgeInsets.all(36),
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.flutter_application_1',
            ),
            PolylineLayer(
              polylines: [
                Polyline(points: _routePoints, color: maroon, strokeWidth: 4),
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: _originPoint,
                  width: 44,
                  height: 44,
                  child: _mapMarker(Icons.warehouse_outlined),
                ),
                Marker(
                  point: _destinationPoint,
                  width: 44,
                  height: 44,
                  child: _mapMarker(Icons.flag_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _mapMarker(IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: maroon, width: 2),
        boxShadow: [
          BoxShadow(
            color: darkMaroon.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(icon, color: darkMaroon, size: 23),
    );
  }

  Widget _buildHomeTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 22),
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: darkMaroon,
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'TEST MODE · Local sample data only.',
                  style: TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _buildHeader(),
        const SizedBox(height: 18),
        _sectionHeading(
          'Current transfer',
          subtitle: 'Your assigned hub-to-hub route',
        ),
        HubAssignmentCard(
          transfer: demoHubTransfer,
          hasDeparted: _hasDeparted,
          hasArrived: _hasArrived,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cream),
          ),
          child: Row(
            children: [
              const Icon(Icons.inventory_2_outlined, color: maroon),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  '$_loadedParcels of ${demoHubTransfer.assignedParcels} parcels loaded',
                  style: const TextStyle(
                    color: darkMaroon,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                _status,
                style: const TextStyle(
                  color: brownBeige,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => setState(() => _selectedTab = 1),
            icon: const Icon(Icons.map_outlined),
            label: const Text('Open transfer route'),
            style: FilledButton.styleFrom(
              backgroundColor: darkMaroon,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransferTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _sectionHeading(
          'Transfer route',
          subtitle: 'Sample route preview between logistics hubs',
        ),
        _buildRouteMap(),
        const Padding(
          padding: EdgeInsets.only(top: 5, bottom: 13),
          child: Text(
            'Map data © OpenStreetMap contributors · Sample route, not turn-by-turn navigation',
            style: TextStyle(color: brownBeige, fontSize: 10),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cream),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${demoHubTransfer.originName}  →  ${demoHubTransfer.destinationName}',
                style: const TextStyle(
                  color: darkMaroon,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${demoHubTransfer.originAddress} to ${demoHubTransfer.destinationAddress} · ${demoHubTransfer.estimatedRoute}',
                style: const TextStyle(color: brownBeige, fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _sectionHeading(
          'Parcel loading',
          subtitle: 'Load every assigned parcel before departure',
        ),
        ParcelLoadingCard(
          assignedParcels: demoHubTransfer.assignedParcels,
          loadedParcels: _loadedParcels,
          loadingComplete: _loadingComplete,
          onAdd: () {
            if (_loadedParcels < demoHubTransfer.assignedParcels) {
              setState(() => _loadedParcels++);
            }
          },
          onRemove: () {
            if (_loadedParcels > 0) setState(() => _loadedParcels--);
          },
          onConfirm: () {
            setState(() => _loadingComplete = true);
            _showMessage('Loading confirmed locally.');
          },
        ),
        const SizedBox(height: 18),
        _sectionHeading('Transfer confirmations'),
        TransferProgressCard(
          loadingComplete: _loadingComplete,
          hasDeparted: _hasDeparted,
          hasArrived: _hasArrived,
          unloadingComplete: _unloadingComplete,
          onConfirmDeparture: _confirmDeparture,
          onConfirmArrival: _confirmArrival,
          onConfirmUnloading: _confirmUnloading,
        ),
        if (_unloadingComplete) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _resetDemo,
              icon: const Icon(Icons.restart_alt),
              label: const Text('Reset demo transfer'),
              style: OutlinedButton.styleFrom(foregroundColor: maroon),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHistoryTab() {
    final int parcelTotal = _history.fold<int>(
      0,
      (total, item) => total + item.parcelCount,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _sectionHeading(
          'Transfer history',
          subtitle: 'Completed hub-to-hub handovers',
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cream),
          ),
          child: Row(
            children: [
              const Icon(Icons.fact_check_outlined, color: maroon, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${_history.length} completed transfers',
                  style: const TextStyle(
                    color: darkMaroon,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                '$parcelTotal parcels',
                style: const TextStyle(
                  color: brownBeige,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        TransferHistoryCard(items: _history),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    return BottomNavigationBar(
      currentIndex: _selectedTab,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: darkMaroon,
      unselectedItemColor: brownBeige,
      backgroundColor: Colors.white,
      selectedLabelStyle: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
      ),
      unselectedLabelStyle: const TextStyle(fontSize: 10),
      onTap: (index) => setState(() => _selectedTab = index),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.local_shipping_outlined),
          activeIcon: Icon(Icons.local_shipping),
          label: 'Transfer',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: darkMaroon,
        elevation: 0,
        title: const Text(
          'Hub Transfer',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: 'Rider information and documents',
            onPressed: _openProfile,
            icon: const Icon(Icons.person_outline),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: _openSettings,
            icon: const Icon(Icons.settings_outlined),
          ),
          IconButton(
            tooltip: 'Log out',
            onPressed: _confirmLogout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: switch (_selectedTab) {
          0 => _buildHomeTab(),
          1 => _buildTransferTab(),
          _ => _buildHistoryTab(),
        },
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }
}
