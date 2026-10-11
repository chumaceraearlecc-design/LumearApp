import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_application_1/models/parcel_store.dart';
import 'package:flutter_application_1/screens/assignment_screen.dart';
import 'package:flutter_application_1/screens/delivery_details_screen.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class SellerPickupDetailsScreen extends StatefulWidget {
  final String requestId;

  const SellerPickupDetailsScreen({super.key, required this.requestId});

  @override
  State<SellerPickupDetailsScreen> createState() =>
      _SellerPickupDetailsScreenState();
}

class _SellerPickupDetailsScreenState extends State<SellerPickupDetailsScreen> {
  static const Color darkMaroon = Color(0xFF62191C);
  static const Color maroon = Color(0xFF873632);
  static const Color brownBeige = Color(0xFF9E7161);
  static const Color lightBeige = Color(0xFFCAAE9F);
  static const Color cream = Color(0xFFE0CFC2);
  static const Color success = Color(0xFF2E7D32);
  static const Color danger = Color(0xFFB3261E);

  final MapController _mapController = MapController();
  LatLng? _riderLocation;
  StreamSubscription<Position>? _positionSubscription;
  bool _didCenterOnRider = false;
  bool _isWorking = false;

  @override
  void initState() {
    super.initState();
    _startRiderLocationTracking();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startRiderLocationTracking() async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!mounted) return;
      if (!serviceEnabled) {
        _showMessage('Turn on location services to show your rider location.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (!mounted) return;
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showMessage(
          'Location permission is needed to show your rider location.',
        );
        return;
      }

      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      );
      _positionSubscription =
          Geolocator.getPositionStream(
            locationSettings: locationSettings,
          ).listen(
            (Position position) {
              if (!mounted) return;
              final LatLng location = LatLng(
                position.latitude,
                position.longitude,
              );
              setState(() => _riderLocation = location);
              if (!_didCenterOnRider) {
                _didCenterOnRider = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _mapController.move(location, 16);
                });
              }
            },
            onError: (Object error) {
              if (mounted) _showMessage('Unable to read the rider location.');
            },
          );
    } catch (error) {
      if (mounted) _showMessage('Unable to access rider location: $error');
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: isError ? danger : darkMaroon,
          content: Text(message),
        ),
      );
  }

  Future<void> _startPickup(SellerPickupRequest pickup) async {
    final SellerPickupStartResult result = ParcelStore.startSellerPickup(
      pickup.requestId,
    );
    if (result != SellerPickupStartResult.started) {
      _showMessage(
        'This pickup is not currently assigned to this rider.',
        isError: true,
      );
      return;
    }
    setState(() {});
  }

  Future<void> _confirmPickup(SellerPickupRequest pickup) async {
    final SellerPickupConfirmationResult result =
        ParcelStore.confirmSellerPickup(pickup.requestId);
    if (result != SellerPickupConfirmationResult.confirmed) {
      final String message = switch (result) {
        SellerPickupConfirmationResult.pickupNotFound =>
          'This pickup request could not be found.',
        SellerPickupConfirmationResult.pickupNotActive =>
          'Start the pickup before confirming collection.',
        SellerPickupConfirmationResult.parcelAssignedElsewhere =>
          'A parcel belongs to another pickup request.',
        SellerPickupConfirmationResult.parcelAlreadyCollected =>
          'A parcel has already been collected or processed elsewhere.',
        SellerPickupConfirmationResult.alreadyConfirmed =>
          'This pickup has already been confirmed.',
        SellerPickupConfirmationResult.confirmed => '',
      };
      _showMessage(message, isError: true);
      return;
    }

    if (!ParcelStore.beginSellerPickupHeadingToSortingCenter(
      pickup.requestId,
    )) {
      _showMessage(
        'Pickup was saved, but the sorting-center handoff failed.',
        isError: true,
      );
      return;
    }

    if (!mounted) return;
    await Navigator.pushReplacement<void, void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => DeliveryDetailsScreen(
          orderNumber: pickup.requestId,
          store: AssignmentScreen.assignedHub,
          customer: pickup.sellerName,
          address: pickup.pickupAddress,
          distance: '',
          fee: '',
          customerPhone: pickup.sellerPhone ?? '',
          sellerPickupHandoff: true,
          pickedUpParcelCount: pickup.expectedParcels.length,
        ),
      ),
    );
  }

  Widget _statusBadge(SellerPickupStatus status) {
    final bool done =
        status == SellerPickupStatus.pickedUp ||
        status == SellerPickupStatus.headingToSortingCenter;
    final Color color = done
        ? success
        : status == SellerPickupStatus.inProgress
        ? maroon
        : brownBeige;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _infoCard({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: const TextStyle(color: brownBeige, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: darkMaroon,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _callSeller(String? phone) async {
    final String dialable = (phone ?? '').trim().replaceAll(
      RegExp(r'[^0-9+]'),
      '',
    );
    if (dialable.isEmpty) {
      _showMessage('Seller phone number is unavailable.', isError: true);
      return;
    }

    try {
      final bool launched = await launchUrl(
        Uri(scheme: 'tel', path: dialable),
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        _showMessage('Unable to open the phone dialer.', isError: true);
      }
    } catch (error) {
      if (mounted) {
        _showMessage('Unable to call seller: $error', isError: true);
      }
    }
  }

  Widget _mapPreview(SellerPickupRequest pickup) {
    final LatLng? sellerLocation =
        pickup.pickupLatitude != null && pickup.pickupLongitude != null
        ? LatLng(pickup.pickupLatitude!, pickup.pickupLongitude!)
        : null;
    final LatLng initialCenter =
        sellerLocation ?? _riderLocation ?? const LatLng(14.0700, 121.3265);
    final String locationStatus = sellerLocation == null
        ? 'Seller coordinates unavailable'
        : _riderLocation == null
        ? 'Waiting for rider GPS'
        : 'Rider location updating';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: lightBeige.withValues(alpha: 0.7)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                const Icon(Icons.map_outlined, color: darkMaroon, size: 21),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Seller Location',
                    style: TextStyle(
                      color: darkMaroon,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: brownBeige.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'OPENSTREETMAP',
                    style: TextStyle(
                      color: brownBeige,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 180,
            width: double.infinity,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: initialCenter,
                initialZoom: sellerLocation != null ? 15 : 13,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.flutter_application_1',
                ),
                MarkerLayer(
                  markers: [
                    if (sellerLocation != null)
                      Marker(
                        point: sellerLocation,
                        width: 72,
                        height: 72,
                        child: _mapPin(
                          icon: Icons.storefront_rounded,
                          label: 'Seller',
                          color: darkMaroon,
                        ),
                      ),
                    if (_riderLocation != null)
                      Marker(
                        point: _riderLocation!,
                        width: 72,
                        height: 72,
                        child: _mapPin(
                          icon: Icons.delivery_dining_rounded,
                          label: 'Rider',
                          color: const Color(0xFF62191C),
                        ),
                      ),
                  ],
                ),
                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution('OpenStreetMap contributors'),
                  ],
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    elevation: 3,
                    child: IconButton(
                      tooltip: 'Center map on rider',
                      onPressed: () => _centerMap(sellerLocation),
                      icon: const Icon(Icons.my_location_rounded),
                      color: darkMaroon,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      locationStatus,
                      style: const TextStyle(
                        color: darkMaroon,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.place_outlined, color: brownBeige, size: 19),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    pickup.pickupAddress.trim().isEmpty
                        ? 'Seller address not provided'
                        : pickup.pickupAddress,
                    style: const TextStyle(
                      color: darkMaroon,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _centerMap(LatLng? sellerLocation) {
    final LatLng? location = _riderLocation ?? sellerLocation;
    if (location == null) {
      _showMessage('No map location is available yet.', isError: true);
      return;
    }
    _mapController.move(location, _riderLocation != null ? 16 : 15);
  }

  Widget _mapPin({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 7,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _sellerContactActions(SellerPickupRequest pickup) {
    final bool hasPhone =
        pickup.sellerPhone != null && pickup.sellerPhone!.trim().isNotEmpty;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: hasPhone ? () => _callSeller(pickup.sellerPhone) : null,
        icon: const Icon(Icons.call_outlined),
        label: const Text('Call Seller'),
        style: OutlinedButton.styleFrom(
          foregroundColor: darkMaroon,
          side: const BorderSide(color: darkMaroon),
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildPickup(SellerPickupRequest pickup) {
    final bool pickupInProgress =
        pickup.status == SellerPickupStatus.inProgress;
    final bool canConfirmPickup = pickupInProgress && !_isWorking;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: darkMaroon.withValues(alpha: 0.07)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'SELLER PICKUP',
                      style: TextStyle(
                        color: maroon,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _statusBadge(pickup.status),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                pickup.sellerName,
                style: const TextStyle(
                  color: darkMaroon,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              _infoCard(label: 'Pickup request', value: pickup.requestId),
              _infoCard(label: 'Pickup address', value: pickup.pickupAddress),
              _infoCard(
                label: 'Seller phone',
                value: pickup.sellerPhone ?? 'Not provided',
              ),
              _infoCard(
                label: 'Map location',
                value:
                    pickup.pickupLatitude != null &&
                        pickup.pickupLongitude != null
                    ? '${pickup.pickupLatitude}, ${pickup.pickupLongitude}'
                    : pickup.pickupAddress,
              ),
              _infoCard(
                label: 'Expected parcels',
                value: '${pickup.expectedParcels.length}',
              ),
              const SizedBox(height: 4),
              _mapPreview(pickup),
              const SizedBox(height: 12),
              _sellerContactActions(pickup),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Expected Parcels',
          style: TextStyle(
            color: darkMaroon,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        ...pickup.expectedParcels.map((parcel) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: lightBeige),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  color: darkMaroon,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        parcel.trackingNumber,
                        style: const TextStyle(
                          color: darkMaroon,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Text(
                  'Expected',
                  style: TextStyle(
                    color: brownBeige,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }),
        if (pickupInProgress) ...[
          const SizedBox(height: 6),
          Text(
            'Confirm Pickup will confirm all ${pickup.expectedParcels.length} parcels above.',
            style: const TextStyle(color: brownBeige, fontSize: 11),
          ),
        ],
        if (pickup.status == SellerPickupStatus.assigned) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isWorking ? null : () => _startPickup(pickup),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Start Pickup'),
              style: ElevatedButton.styleFrom(
                backgroundColor: darkMaroon,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ),
        ],
        if (pickupInProgress) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: canConfirmPickup ? () => _confirmPickup(pickup) : null,
              icon: const Icon(Icons.inventory_rounded),
              label: const Text('Confirm Pickup'),
              style: ElevatedButton.styleFrom(
                backgroundColor: darkMaroon,
                foregroundColor: Colors.white,
                disabledBackgroundColor: lightBeige,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ),
        ],
        if (pickup.status == SellerPickupStatus.headingToSortingCenter) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => _openSortingCenter(pickup),
              icon: const Icon(Icons.warehouse_outlined),
              label: const Text('Continue to Sorting Center'),
              style: ElevatedButton.styleFrom(
                backgroundColor: darkMaroon,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _openSortingCenter(SellerPickupRequest pickup) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => DeliveryDetailsScreen(
          orderNumber: pickup.requestId,
          store: AssignmentScreen.assignedHub,
          customer: pickup.sellerName,
          address: pickup.pickupAddress,
          distance: '',
          fee: '',
          customerPhone: pickup.sellerPhone ?? '',
          sellerPickupHandoff: true,
          pickedUpParcelCount: pickup.expectedParcels.length,
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
        title: const Text('Seller Pickup Details'),
      ),
      body: ValueListenableBuilder<List<SellerPickupRequest>>(
        valueListenable: ParcelStore.sellerPickups,
        builder: (context, pickups, _) {
          SellerPickupRequest? pickup;
          for (final item in pickups) {
            if (item.requestId == widget.requestId) {
              pickup = item;
              break;
            }
          }
          if (pickup == null) {
            return const Center(child: Text('Pickup request not found.'));
          }
          return _buildPickup(pickup);
        },
      ),
    );
  }
}
