import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

// ============================================================
// DELIVERY STAGE (enum instead of raw strings)
//
// Replaces the previous free-form `String _status` with a type-safe
// enum. This removes an entire class of bugs where a typo'd string
// literal (e.g. 'Heading to sorting center' vs 'Heading to Sorting
// Center') would silently fail every == comparison with no warning
// from the compiler.
// ============================================================

enum DeliveryStage {
  headingToSortingCenter,
  parcelPickedUp,
  outForDelivery,
  arrivedAtDestination,
  delivered,
  deliveryFailed,
}

extension DeliveryStageX on DeliveryStage {
  /// Long label used in status text throughout the screen.
  String get label {
    switch (this) {
      case DeliveryStage.headingToSortingCenter:
        return 'Heading to Sorting Center';
      case DeliveryStage.parcelPickedUp:
        return 'Parcel Picked Up';
      case DeliveryStage.outForDelivery:
        return 'Out for Delivery';
      case DeliveryStage.arrivedAtDestination:
        return 'Arrived at Destination';
      case DeliveryStage.delivered:
        return 'Delivered';
      case DeliveryStage.deliveryFailed:
        return 'Delivery Failed';
    }
  }

  /// Short label used in the horizontal stage indicator.
  String get shortLabel {
    switch (this) {
      case DeliveryStage.headingToSortingCenter:
        return 'Sorting';
      case DeliveryStage.parcelPickedUp:
        return 'Picked Up';
      case DeliveryStage.outForDelivery:
        return 'Transit';
      case DeliveryStage.arrivedAtDestination:
        return 'Drop-off';
      case DeliveryStage.delivered:
        return 'Delivered';
      case DeliveryStage.deliveryFailed:
        return 'Failed';
    }
  }
}

class DeliveryDetailsScreen extends StatefulWidget {
  final String orderNumber;
  final String store;
  final String customer;
  final String address;
  final String distance;
  final String fee;
  final String customerPhone;
  final bool sellerPickupHandoff;
  final int? pickedUpParcelCount;

  const DeliveryDetailsScreen({
    super.key,
    required this.orderNumber,
    required this.store,
    required this.customer,
    required this.address,
    required this.distance,
    required this.fee,
    this.customerPhone = '',
    this.sellerPickupHandoff = false,
    this.pickedUpParcelCount,
  });

  @override
  State<DeliveryDetailsScreen> createState() => _DeliveryDetailsScreenState();
}

class _DeliveryDetailsScreenState extends State<DeliveryDetailsScreen> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color darkMaroon = Color(0xFF62191C);
  static const Color maroon = Color(0xFF873632);
  static const Color brownBeige = Color(0xFF9E7161);
  static const Color lightBeige = Color(0xFFCAAE9F);
  static const Color cream = Color(0xFFE0CFC2);

  // ============================================================
  // DELIVERY STATUS
  // ============================================================

  DeliveryStage _status = DeliveryStage.headingToSortingCenter;

  // Successful path shown by the compact stage indicator.
  static const List<DeliveryStage> _progressStages = [
    DeliveryStage.headingToSortingCenter,
    DeliveryStage.parcelPickedUp,
    DeliveryStage.outForDelivery,
    DeliveryStage.arrivedAtDestination,
    DeliveryStage.delivered,
  ];

  final Map<DeliveryStage, DateTime> _stageTimes = {};
  String? _failedReason;
  String _failedNote = '';
  DateTime? _failedAt;
  DeliveryStage? _stageBeforeFailure;

  // ============================================================
  // PROOF OF DELIVERY
  // ============================================================

  final ImagePicker _picker = ImagePicker();

  XFile? _proofImage;

  final TextEditingController _receivedByController = TextEditingController();

  // ============================================================
  // CASH ON DELIVERY (COD)
  // Demo/hardcoded collection state for the current prototype.
  // ============================================================
  static const String _paymentMethod = 'Cash on Delivery';
  static const String _codAmount = '₱450.00';
  bool _codCollected = false;
  bool _isShowingConfirmation = false;
  bool _completionSubmitted = false;

  // ============================================================
  // SAMPLE LOCATIONS
  // ============================================================

  final LatLng _pickupLocation = const LatLng(14.0700, 121.3265);

  final LatLng _customerLocation = const LatLng(14.0648, 121.3310);

  // ============================================================
  // RIDER LIVE GPS LOCATION
  // ============================================================

  final MapController _mapController = MapController();

  LatLng? _riderLocation;
  StreamSubscription<Position>? _positionSubscription;
  bool _didCenterOnRider = false;

  @override
  void initState() {
    super.initState();
    _stageTimes[DeliveryStage.headingToSortingCenter] = DateTime.now();
    _startRiderLocationTracking();
  }

  Future<void> _startRiderLocationTracking() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!mounted) return;

    if (!serviceEnabled) {
      _showTopNotification(
        'Please turn on your phone location.',
        icon: Icons.location_off_outlined,
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (!mounted) return;

    if (permission == LocationPermission.denied) {
      _showTopNotification(
        'Location permission is required to show the rider location.',
        icon: Icons.location_off_outlined,
      );
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      _showTopNotification(
        'Location permission is permanently denied. Enable it in app settings.',
        icon: Icons.location_off_outlined,
      );
      return;
    }

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    await _positionSubscription?.cancel();

    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            if (!mounted) return;

            final LatLng newRiderLocation = LatLng(
              position.latitude,
              position.longitude,
            );

            setState(() {
              _riderLocation = newRiderLocation;
            });

            // Center the map on the rider only on the first GPS fix.
            // The rider marker will keep updating afterward without
            // constantly pulling the map away from manual panning.
            if (!_didCenterOnRider) {
              _didCenterOnRider = true;

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted || _riderLocation == null) return;
                _mapController.move(_riderLocation!, 16);
              });
            }
          },
          onError: (Object error) {
            if (!mounted) return;

            _showTopNotification(
              'Unable to read the rider location.',
              icon: Icons.location_off_outlined,
            );
          },
        );
  }

  // ============================================================
  // TOP NOTIFICATION OVERLAY STATE
  // ============================================================

  OverlayEntry? _topNotificationEntry;

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _receivedByController.dispose();
    // Previously this only called .remove() without clearing the
    // reference. If a pending 2-second auto-dismiss Future.delayed
    // callback (see _showTopNotification) fired after dispose, it would
    // see the same OverlayEntry reference and call .remove() on it a
    // second time, throwing an assertion error. Nulling it out here
    // makes that later check a safe no-op.
    _topNotificationEntry?.remove();
    _topNotificationEntry = null;
    super.dispose();
  }

  // ============================================================
  // CURRENT STEP
  // ============================================================

  int get _currentStepIndex {
    final DeliveryStage effectiveStage = _status == DeliveryStage.deliveryFailed
        ? (_stageBeforeFailure ?? DeliveryStage.outForDelivery)
        : _status;

    final int index = _progressStages.indexOf(effectiveStage);

    return index < 0 ? 0 : index;
  }

  // ============================================================
  // CUSTOMER STATUS
  // ============================================================

  String _customerStatusMessage() {
    switch (_status) {
      case DeliveryStage.headingToSortingCenter:
        return 'Your rider is heading to the sorting center to collect your parcel.';

      case DeliveryStage.parcelPickedUp:
        return 'Your parcel is now with the rider.';

      case DeliveryStage.outForDelivery:
        return 'Your parcel is on the way to you.';

      case DeliveryStage.arrivedAtDestination:
        return 'Rider has arrived at your delivery location.';

      case DeliveryStage.delivered:
        return 'Your parcel has been delivered successfully.';
      case DeliveryStage.deliveryFailed:
        return 'The delivery attempt was unsuccessful. The parcel is waiting to be returned.';
    }
  }

  // ============================================================
  // RIDER DESCRIPTION
  // ============================================================

  String _riderDescription() {
    switch (_status) {
      case DeliveryStage.headingToSortingCenter:
        return 'Proceed to the assigned sorting center to collect the parcel.';

      case DeliveryStage.parcelPickedUp:
        return 'Parcel verified and collected. The customer has been notified that the parcel is now with you.';

      case DeliveryStage.outForDelivery:
        return 'Proceed to the customer delivery address.';

      case DeliveryStage.arrivedAtDestination:
        return 'You have arrived. Collect the COD payment, then complete the Proof of Delivery before confirming.';

      case DeliveryStage.delivered:
        return 'The parcel has been successfully delivered.';
      case DeliveryStage.deliveryFailed:
        return 'This delivery attempt was marked as failed. Tap Return Parcel to begin the return process.';
    }
  }

  // ============================================================
  // BUTTON TEXT
  // ============================================================

  String _buttonText() {
    switch (_status) {
      case DeliveryStage.headingToSortingCenter:
        return 'Confirm Parcel Pickup';

      case DeliveryStage.parcelPickedUp:
        return 'Start Delivery';

      case DeliveryStage.outForDelivery:
        return 'Arrived at Destination';

      case DeliveryStage.arrivedAtDestination:
        return 'Confirm Delivery';

      case DeliveryStage.delivered:
        return 'Delivery Completed';
      case DeliveryStage.deliveryFailed:
        return 'Return Parcel';
    }
  }

  // ============================================================
  // BUTTON ICON
  // ============================================================

  IconData _buttonIcon() {
    switch (_status) {
      case DeliveryStage.headingToSortingCenter:
        return Icons.inventory_2_outlined;

      case DeliveryStage.parcelPickedUp:
        return Icons.delivery_dining;

      case DeliveryStage.outForDelivery:
        return Icons.location_on_outlined;

      case DeliveryStage.arrivedAtDestination:
        return Icons.verified_outlined;

      case DeliveryStage.delivered:
        return Icons.task_alt;
      case DeliveryStage.deliveryFailed:
        return Icons.assignment_return_outlined;
    }
  }

  // ============================================================
  // TAKE PROOF PHOTO
  // ============================================================

  Future<void> _takeProofPhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image == null) {
        return;
      }

      if (!mounted) return;

      setState(() {
        _proofImage = image;
      });
    } catch (e) {
      if (!mounted) return;

      _showTopNotification('Unable to open the camera.');
    }
  }

  // ============================================================
  // UPDATE STATUS
  // ============================================================

  Future<void> _updateStatus() async {
    // ==========================================================
    // FAILED -> START RETURN
    // ==========================================================
    if (_status == DeliveryStage.deliveryFailed) {
      final bool confirm = await _showConfirmation(
        title: 'Return Parcel',
        message:
            'Move Order ${widget.orderNumber} to the Returns section? The failed delivery reason and details will be saved.',
        confirmText: 'Return Parcel',
        icon: Icons.assignment_return_outlined,
      );

      if (!confirm) return;

      final DateTime returnedAt = DateTime.now();

      if (!mounted) return;

      // Remove this parcel from the active delivery flow and send it
      // back to the previous screen so it can be stored in Returns.
      Navigator.pop(context, {
        'status': 'returned',
        'returnedAt': returnedAt,
        'returnReason': _failedReason ?? 'Delivery attempt failed',
        'returnNote': _failedNote,
        'failedAt': _failedAt,
        'orderNumber': widget.orderNumber,
        'store': widget.store,
        'customer': widget.customer,
        'address': widget.address,
        'distance': widget.distance,
        'fee': widget.fee,
      });

      return;
    }

    // ==========================================================
    // SORTING CENTER -> CONFIRM PARCEL PICKUP
    // ==========================================================

    if (_status == DeliveryStage.headingToSortingCenter) {
      final bool confirm = await _showConfirmation(
        title: 'Confirm Parcel Pickup',
        message:
            'Have you collected order ${widget.orderNumber} from ${widget.store}?',
        confirmText: 'Confirm Pickup',
        icon: Icons.inventory_2_outlined,
      );

      if (!confirm) return;

      setState(() {
        _status = DeliveryStage.parcelPickedUp;
        _stageTimes[DeliveryStage.parcelPickedUp] = DateTime.now();
      });

      _showTopNotification(
        'Parcel pickup confirmed. The parcel is now with the rider.',
        icon: Icons.inventory_2_outlined,
      );
      return;
    }

    // ==========================================================
    // ARRIVED AT DESTINATION -> CHECK POD
    // ==========================================================

    if (_status == DeliveryStage.arrivedAtDestination) {
      if (!_codCollected) {
        _showErrorMessage(
          'Please confirm the COD payment before completing the delivery.',
        );
        return;
      }

      if (_proofImage == null) {
        _showErrorMessage('Please take a Proof of Delivery photo first.');
        return;
      }

      if (_receivedByController.text.trim().isEmpty) {
        _showErrorMessage(
          'Please enter the name of the person who received the parcel.',
        );
        return;
      }

      final bool confirm = await _showConfirmation(
        title: 'Confirm Delivery',
        message: 'The COD payment has been collected and proof of delivery is complete. Confirm that the parcel was handed to the recipient.',
        confirmText: 'Confirm Delivered',
        icon: Icons.verified_outlined,
      );

      if (!confirm) {
        return;
      }
    }

    // ==========================================================
    // CHANGE STATUS
    // ==========================================================

    setState(() {
      switch (_status) {
        case DeliveryStage.parcelPickedUp:
          _status = DeliveryStage.outForDelivery;
          _stageTimes[DeliveryStage.outForDelivery] = DateTime.now();
          break;

        case DeliveryStage.outForDelivery:
          _status = DeliveryStage.arrivedAtDestination;
          _stageTimes[DeliveryStage.arrivedAtDestination] = DateTime.now();
          break;

        case DeliveryStage.arrivedAtDestination:
          _status = DeliveryStage.delivered;
          _stageTimes[DeliveryStage.delivered] = DateTime.now();
          break;

        default:
          break;
      }
    });

    if (_status != DeliveryStage.delivered) {
      if (!mounted) return;
      _showTopNotification('Delivery updated: ${_status.label}');
    }

    if (_status == DeliveryStage.delivered) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _showCompletedDialog();
        }
      });
    }
  }

  // ============================================================
  // DELIVERY ATTEMPT FAILED
  // ============================================================

  bool get _canMarkFailed =>
      _status == DeliveryStage.outForDelivery ||
      _status == DeliveryStage.arrivedAtDestination;

  Future<void> _showFailedDeliveryDialog() async {
    const List<String> reasons = [
      'Customer cancelled the order',
      'Customer unavailable',
      'Unable to contact customer',
      'Customer refused parcel',
      'Wrong / incomplete address',
      'Customer requested reschedule',
      'Parcel damaged',
      'Other',
    ];

    String selectedReason = reasons.first;
    final TextEditingController noteController = TextEditingController();

    final bool? save = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: cream,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              title: const Row(
                children: [
                  Icon(Icons.error_outline, color: maroon),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Delivery Attempt Failed',
                      style: TextStyle(
                        color: darkMaroon,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Why was the delivery unsuccessful?',
                      style: TextStyle(color: brownBeige, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: lightBeige),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedReason,
                          isExpanded: true,
                          dropdownColor: cream,
                          iconEnabledColor: darkMaroon,
                          style: const TextStyle(
                            color: darkMaroon,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          items: reasons
                              .map(
                                (reason) => DropdownMenuItem<String>(
                                  value: reason,
                                  child: Text(reason),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setDialogState(() {
                              selectedReason = value;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: noteController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Add a note (optional)',
                        hintStyle: const TextStyle(color: brownBeige),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.72),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: lightBeige),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: maroon),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: brownBeige),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: maroon,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Confirm Failed Attempt'),
                ),
              ],
            );
          },
        );
      },
    );

    if (save != true || !mounted) {
      noteController.dispose();
      return;
    }

    final DateTime now = DateTime.now();

    setState(() {
      _stageBeforeFailure = _status;
      _status = DeliveryStage.deliveryFailed;
      _failedReason = selectedReason;
      _failedNote = noteController.text.trim();
      _failedAt = now;
      _stageTimes[DeliveryStage.deliveryFailed] = now;
    });

    noteController.dispose();

    _showTopNotification(
      'Delivery attempt recorded as failed. Tap Return Parcel to move it to Returns.',
      color: maroon,
      icon: Icons.error_outline,
    );
  }

  String _formatTime(DateTime time) {
    int hour = time.hour;
    final String period = hour >= 12 ? 'PM' : 'AM';

    if (hour == 0) {
      hour = 12;
    } else if (hour > 12) {
      hour -= 12;
    }

    final String minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  String _formatDate(DateTime time) {
    const List<String> months = [
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

    return '${months[time.month - 1]} ${time.day}, ${time.year}';
  }

  // ============================================================
  // DETAILED DELIVERY TIMELINE
  // ============================================================

  Widget _buildDeliveryTimeline() {
    final List<DeliveryStage> timelineStages = [
      DeliveryStage.headingToSortingCenter,
      DeliveryStage.parcelPickedUp,
      DeliveryStage.outForDelivery,
      DeliveryStage.arrivedAtDestination,
      DeliveryStage.delivered,
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: lightBeige),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.timeline_rounded, color: darkMaroon, size: 21),
              SizedBox(width: 8),
              Text(
                'Delivery Timeline',
                style: TextStyle(
                  color: darkMaroon,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...List.generate(timelineStages.length, (index) {
            final DeliveryStage stage = timelineStages[index];
            final DateTime? recordedAt = _stageTimes[stage];

            // If delivery failed, do not show later successful stages as active.
            final bool reached = recordedAt != null;
            final bool showConnector =
                index < timelineStages.length - 1 || _failedAt != null;

            return _timelineEntry(
              title: stage.label,
              time: recordedAt,
              isReached: reached,
              showConnector: showConnector,
              isFailed: false,
            );
          }),
          if (_failedAt != null)
            _timelineEntry(
              title: 'Delivery Attempt Failed',
              time: _failedAt,
              isReached: true,
              showConnector: false,
              isFailed: true,
              subtitle: _failedReason,
            ),
        ],
      ),
    );
  }

  Widget _timelineEntry({
    required String title,
    required DateTime? time,
    required bool isReached,
    required bool showConnector,
    required bool isFailed,
    String? subtitle,
  }) {
    final Color accent = isFailed ? maroon : darkMaroon;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 26,
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 21,
                  height: 21,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isReached ? accent : Colors.transparent,
                    border: Border.all(
                      color: isReached ? accent : lightBeige,
                      width: 2,
                    ),
                  ),
                  child: isReached
                      ? Icon(
                          isFailed ? Icons.close_rounded : Icons.check_rounded,
                          color: Colors.white,
                          size: 13,
                        )
                      : null,
                ),
                if (showConnector)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      color: lightBeige,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isReached ? accent : brownBeige,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (time != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${_formatTime(time)} • ${_formatDate(time)}',
                      style: const TextStyle(color: brownBeige, fontSize: 10.5),
                    ),
                  ],
                  if (subtitle != null && subtitle.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: isFailed ? maroon : brownBeige,
                        fontSize: 10.5,
                        fontWeight: isFailed
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFailedAttemptCard() {
    final DateTime? failedAt = _failedAt;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: maroon.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: maroon.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.error_outline, color: maroon),
              SizedBox(width: 8),
              Text(
                'Failed Delivery Details',
                style: TextStyle(
                  color: darkMaroon,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _failedReason ?? 'Delivery attempt failed',
            style: const TextStyle(
              color: darkMaroon,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          if (_failedNote.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              _failedNote,
              style: const TextStyle(
                color: brownBeige,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ],
          if (failedAt != null) ...[
            const SizedBox(height: 8),
            Text(
              '${_formatTime(failedAt)} • ${_formatDate(failedAt)}',
              style: const TextStyle(
                color: brownBeige,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // ERROR MESSAGE
  // ============================================================

  void _showErrorMessage(String message) {
    _showTopNotification(message);
  }

  // ============================================================
  // TOP NOTIFICATION
  // ============================================================

  void _showTopNotification(String message, {Color? color, IconData? icon}) {
    // Remove any notification that's currently showing so they don't stack.
    _topNotificationEntry?.remove();
    _topNotificationEntry = null;

    final overlay = Overlay.of(context);

    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: MediaQuery.of(context).padding.top + 2,
          left: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, -30 * (1 - value)),
                  child: Opacity(opacity: value, child: child),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: color ?? darkMaroon,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      icon ?? Icons.local_shipping_outlined,
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
                        ),
                      ),
                    ),
                  ],
                ),
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

  // ============================================================
  // CONFIRMATION DIALOG
  // ============================================================

  Future<bool> _showConfirmation({
    required String title,
    required String message,
    required String confirmText,
    required IconData icon,
  }) async {
    if (_isShowingConfirmation) return false;

    _isShowingConfirmation = true;
    bool confirmationSubmitted = false;

    try {
      final bool? result = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: cream,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: lightBeige,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: darkMaroon),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: darkMaroon,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              message,
              style: const TextStyle(color: brownBeige, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext, false);
                },
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: brownBeige),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (confirmationSubmitted) return;
                  confirmationSubmitted = true;
                  Navigator.pop(dialogContext, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkMaroon,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(confirmText),
              ),
            ],
          );
        },
      );

      return result ?? false;
    } finally {
      _isShowingConfirmation = false;
    }
  }

  // ============================================================
  // COMPLETED DIALOG
  // ============================================================

  void _showCompletedDialog() {
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
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: darkMaroon,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 45,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Delivery Completed!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: darkMaroon,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: darkMaroon.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded, color: darkMaroon, size: 17),
                    SizedBox(width: 6),
                    Text(
                      'COD Payment Collected',
                      style: TextStyle(
                        color: darkMaroon,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              Text(
                'Order ${widget.orderNumber} has been successfully delivered.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: brownBeige, height: 1.5),
              ),

              const SizedBox(height: 18),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: lightBeige.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Received By',
                      style: TextStyle(color: brownBeige, fontSize: 11),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      _receivedByController.text.trim(),
                      style: const TextStyle(
                        color: darkMaroon,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'COD Collected',
                      style: TextStyle(color: brownBeige, fontSize: 11),
                    ),

                    const SizedBox(height: 4),

                    const Text(
                      _codAmount,
                      style: TextStyle(
                        color: darkMaroon,
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'Payment Method',
                      style: TextStyle(color: brownBeige, fontSize: 11),
                    ),

                    const SizedBox(height: 4),

                    const Text(
                      _paymentMethod,
                      style: TextStyle(
                        color: darkMaroon,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (_completionSubmitted) return;
                    _completionSubmitted = true;
                    final DateTime deliveredAt =
                        _stageTimes[DeliveryStage.delivered] ?? DateTime.now();

                    final Map<String, dynamic> result = {
                      'status': 'completed',
                      'deliveredAt': deliveredAt,
                      'receivedBy': _receivedByController.text.trim(),
                      'proofImagePath': _proofImage?.path,
                      'codCollected': _codCollected,
                    };

                    Navigator.pop(dialogContext);
                    Navigator.pop(context, result);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkMaroon,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'Done',
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

  // ============================================================
  // CALL CUSTOMER
  // Opens the phone dialer with the customer's number pre-filled.
  // The rider still presses the Call button in the phone app.
  //
  // FIX: previously this went straight to launchUrl() and relied on
  // the catch block to report failure. On Android 11+ (API 30+),
  // launchUrl can silently return false instead of throwing when the
  // app hasn't declared that it queries the "tel" scheme in the
  // manifest — so the error message shown didn't reflect the real
  // cause. This now checks canLaunchUrl() first, which distinguishes
  // "no dialer app / not permitted to query it" from "actually failed
  // to launch," making the message shown to the rider accurate.
  //
  // NOTE: this code change alone will not fix a "can't open dialer"
  // issue caused by missing platform configuration. You also need:
  //
  // Android — add to android/app/src/main/AndroidManifest.xml,
  // as a sibling of <application>, not inside it:
  //   <queries>
  //       <intent>
  //           <action android:name="android.intent.action.DIAL" />
  //           <data android:scheme="tel" />
  //       </intent>
  //   </queries>
  //
  // iOS — add to ios/Runner/Info.plist, inside the top-level <dict>:
  //   <key>LSApplicationQueriesSchemes</key>
  //   <array>
  //       <string>tel</string>
  //   </array>
  // ============================================================

  String? _normalizePhilippinePhone(String rawPhone) {
    String phone = rawPhone.trim();

    if (phone.isEmpty) {
      return null;
    }

    phone = phone.replaceAll(RegExp(r'[^0-9+]'), '');

    if (RegExp(r'^\+639\d{9}$').hasMatch(phone)) {
      return phone;
    }

    if (RegExp(r'^639\d{9}$').hasMatch(phone)) {
      return '+$phone';
    }

    if (RegExp(r'^09\d{9}$').hasMatch(phone)) {
      return '+63${phone.substring(1)}';
    }

    if (RegExp(r'^9\d{9}$').hasMatch(phone)) {
      return '+63$phone';
    }

    return null;
  }

  Future<void> _callCustomer() async {
    final String? phoneNumber = _customerPhoneForDialer;

    if (phoneNumber == null) {
      _showTopNotification(
        'Customer phone number is invalid or unavailable.',
        icon: Icons.phone_disabled_outlined,
      );
      return;
    }

    final Uri phoneUri = Uri.parse('tel:$phoneNumber');

    debugPrint('CALLING NUMBER: $phoneNumber');
    debugPrint('PHONE URI: $phoneUri');

    try {
      final bool launched = await launchUrl(
        phoneUri,
        mode: LaunchMode.externalApplication,
      );

      debugPrint('DIALER LAUNCHED: $launched');

      if (!launched && mounted) {
        _showTopNotification(
          'Unable to open phone dialer.',
          icon: Icons.phone_disabled_outlined,
        );
      }
    } catch (e) {
      debugPrint('CALL ERROR: $e');

      if (!mounted) return;

      _showTopNotification(
        'Unable to open phone dialer.',
        icon: Icons.phone_disabled_outlined,
      );
    }
  }

  String? get _customerPhoneForDialer =>
      _normalizePhilippinePhone(widget.customerPhone);

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (widget.sellerPickupHandoff) {
      return _buildSellerPickupHandoff();
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: cream,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back, color: darkMaroon),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Delivery Details',
              style: TextStyle(
                color: darkMaroon,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),

            Text(
              'Order ${widget.orderNumber}',
              style: const TextStyle(color: brownBeige, fontSize: 11),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // ==================================================
            // MAP (fixed — always visible, never scrolls away)
            // Fits both the pickup and customer markers in view
            // with padding, instead of centering only on pickup at
            // a fixed zoom.
            // ==================================================

            SizedBox(
              height: 200,
              width: double.infinity,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCameraFit: CameraFit.bounds(
                    bounds: LatLngBounds.fromPoints([
                      _pickupLocation,
                      _customerLocation,
                    ]),
                    padding: const EdgeInsets.all(48),
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.flutter_application_1',
                  ),

                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _pickupLocation,
                        width: 55,
                        height: 55,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.warehouse_outlined,
                            color: darkMaroon,
                            size: 32,
                          ),
                        ),
                      ),

                      Marker(
                        point: _customerLocation,
                        width: 55,
                        height: 55,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 37,
                          ),
                        ),
                      ),

                      if (_riderLocation != null)
                        Marker(
                          point: _riderLocation!,
                          width: 62,
                          height: 62,
                          child: Container(
                            decoration: BoxDecoration(
                              color: darkMaroon,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.delivery_dining,
                              color: Colors.white,
                              size: 34,
                            ),
                          ),
                        ),
                    ],
                  ),

                  RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution('OpenStreetMap contributors'),
                    ],
                  ),
                ],
              ),
            ),

            // ==================================================
            // STAGE INDICATOR (compact, like the sign-up steps)
            // ==================================================
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
              child: _buildStageIndicator(),
            ),

            // ==================================================
            // CURRENT STAGE CONTENT (only this stage's info shows;
            // switches with an animation as the status changes)
            // ==================================================
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: SingleChildScrollView(
                  key: ValueKey(_status),
                  padding: const EdgeInsets.fromLTRB(18, 6, 18, 12),
                  child: _buildStageBody(),
                ),
              ),
            ),

            // ==================================================
            // PINNED BOTTOM ACTION BAR (never needs scrolling to)
            // ==================================================
            Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
              decoration: BoxDecoration(
                color: cream,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _callCustomer,
                          icon: const Icon(Icons.phone_outlined, size: 18),
                          label: const Text('Call'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: darkMaroon,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.55,
                            ),
                            side: BorderSide.none,
                            minimumSize: const Size(double.infinity, 46),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            if (_riderLocation == null) {
                              _showTopNotification(
                                'Waiting for the rider GPS location.',
                                icon: Icons.location_searching,
                              );
                              return;
                            }

                            _mapController.move(_riderLocation!, 16);

                            _showTopNotification(
                              'Map centered on your current location.',
                              icon: Icons.my_location,
                            );
                          },
                          icon: const Icon(Icons.navigation_outlined, size: 18),
                          label: const Text('My Location'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: darkMaroon,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.55,
                            ),
                            side: BorderSide.none,
                            minimumSize: const Size(double.infinity, 46),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _status == DeliveryStage.delivered
                          ? null
                          : _updateStatus,
                      icon: Icon(_buttonIcon()),
                      label: Text(
                        _buttonText(),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: darkMaroon,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: brownBeige,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ),

                  if (_canMarkFailed) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _showFailedDeliveryDialog,
                        icon: const Icon(Icons.error_outline),
                        label: const Text(
                          'Delivery Attempt Failed',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: maroon,
                          side: const BorderSide(color: maroon),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSellerPickupHandoff() {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: cream,
        title: const Text(
          'Heading to Sorting Center',
          style: TextStyle(color: darkMaroon, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 230,
              width: double.infinity,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _pickupLocation,
                  initialZoom: 14,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.flutter_application_1',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _pickupLocation,
                        width: 54,
                        height: 54,
                        child: const Icon(
                          Icons.warehouse_rounded,
                          color: darkMaroon,
                          size: 40,
                        ),
                      ),
                      if (_riderLocation != null)
                        Marker(
                          point: _riderLocation!,
                          width: 54,
                          height: 54,
                          child: const Icon(
                            Icons.delivery_dining_rounded,
                            color: maroon,
                            size: 38,
                          ),
                        ),
                    ],
                  ),
                  RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution('OpenStreetMap contributors'),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: lightBeige,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.warehouse_outlined,
                          color: darkMaroon,
                          size: 34,
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Seller pickup confirmed',
                            style: TextStyle(
                              color: darkMaroon,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _handoffInfo('Pickup request', widget.orderNumber),
                  _handoffInfo(
                    'Parcels collected',
                    '${widget.pickedUpParcelCount ?? 0}',
                  ),
                  _handoffInfo('Sorting center', widget.store),
                  _handoffInfo(
                    'Seller phone',
                    widget.customerPhone.trim().isEmpty
                        ? 'Not provided'
                        : widget.customerPhone,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Proceed to the assigned sorting center with the confirmed parcels.',
                    style: TextStyle(
                      color: brownBeige,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _handoffInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
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
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STAGE INDICATOR (horizontal, sign-up style)
  // ============================================================

  Widget _buildStageIndicator() {
    return Row(
      children: List.generate(_progressStages.length, (index) {
        final bool completed = index < _currentStepIndex;
        final bool current =
            index == _currentStepIndex &&
            _status != DeliveryStage.deliveryFailed;

        return Expanded(
          child: Row(
            children: [
              Expanded(child: _stageCircle(index, completed, current)),
              if (index < _progressStages.length - 1)
                Expanded(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: completed ? 1 : 0),
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Container(
                        height: 2,
                        margin: const EdgeInsets.only(bottom: 15),
                        decoration: BoxDecoration(
                          color: lightBeige,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: value,
                            child: Container(
                              decoration: BoxDecoration(
                                color: darkMaroon,
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _stageCircle(int index, bool completed, bool current) {
    final bool active = completed || current;

    return Column(
      children: [
        AnimatedScale(
          scale: current ? 1.13 : 1.0,
          duration: const Duration(milliseconds: 300),
          curve: current ? Curves.easeOutBack : Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? darkMaroon : Colors.white.withValues(alpha: 0.5),
              border: Border.all(color: active ? darkMaroon : lightBeige),
            ),
            child: completed
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                : Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: current ? Colors.white : brownBeige,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 3),

        FittedBox(
          child: Text(
            _progressStages[index].shortLabel,
            style: TextStyle(
              color: current || completed ? darkMaroon : brownBeige,
              fontSize: 8,
              fontWeight: current ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STAGE BODY — only the info relevant to the current status
  // ============================================================

  Widget _buildStageBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCurrentStatus(),

        const SizedBox(height: 14),

        _buildCustomerStatus(),

        const SizedBox(height: 18),

        _buildDeliveryTimeline(),

        if (_status == DeliveryStage.deliveryFailed) ...[
          const SizedBox(height: 14),
          _buildFailedAttemptCard(),
        ],

        const SizedBox(height: 18),

        const Text(
          'Delivery Information',
          style: TextStyle(
            color: darkMaroon,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 10),

        _buildActiveLocationCard(),

        const SizedBox(height: 14),

        _buildOrderDetails(),

        if (_status == DeliveryStage.outForDelivery ||
            _status == DeliveryStage.arrivedAtDestination ||
            _status == DeliveryStage.delivered) ...[
          const SizedBox(height: 18),
          const Text(
            'Payment Information',
            style: TextStyle(
              color: darkMaroon,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          _buildCodPaymentCard(),
        ],

        if (_status == DeliveryStage.arrivedAtDestination ||
            _status == DeliveryStage.delivered) ...[
          const SizedBox(height: 18),
          _buildProofOfDelivery(),
        ],
      ],
    );
  }

  // Shows only the location relevant to what the rider is doing right
  // now — the pickup card before the parcel is collected, then the
  // customer card afterwards — instead of always showing both.
  Widget _buildActiveLocationCard() {
    final bool atSortingCenter =
        _status == DeliveryStage.headingToSortingCenter;

    if (atSortingCenter) {
      return _locationCard(
        icon: Icons.warehouse_outlined,
        label: 'SORTING CENTER',
        title: widget.store,
        subtitle: 'Assigned parcel collection hub',
      );
    }

    return _locationCard(
      icon: Icons.person_pin_circle_outlined,
      label: 'CUSTOMER',
      title: widget.customer,
      subtitle: widget.address,
    );
  }

  // ============================================================
  // CURRENT STATUS
  // ============================================================

  Widget _buildCurrentStatus() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: lightBeige,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              color: darkMaroon,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _status == DeliveryStage.delivered
                  ? Icons.check
                  : _status == DeliveryStage.deliveryFailed
                  ? Icons.close_rounded
                  : Icons.delivery_dining,
              color: Colors.white,
              size: 28,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CURRENT DELIVERY STATUS',
                  style: TextStyle(
                    color: maroon,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.7,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  _status.label,
                  style: const TextStyle(
                    color: darkMaroon,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  _riderDescription(),
                  style: const TextStyle(
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
    );
  }

  // ============================================================
  // CUSTOMER STATUS
  // ============================================================

  Widget _buildCustomerStatus() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: lightBeige),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: lightBeige,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              color: darkMaroon,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Customer Status Update',
                  style: TextStyle(color: brownBeige, fontSize: 11),
                ),

                const SizedBox(height: 3),

                Text(
                  _customerStatusMessage(),
                  style: const TextStyle(
                    color: darkMaroon,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COD PAYMENT CARD
  // ============================================================

  Widget _buildCodPaymentCard() {
    final bool canCollect =
        _status == DeliveryStage.arrivedAtDestination && !_codCollected;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _codCollected
              ? darkMaroon.withValues(alpha: 0.35)
              : lightBeige,
        ),
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
                  color: _codCollected ? darkMaroon : lightBeige,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _codCollected ? Icons.check_rounded : Icons.payments_outlined,
                  color: _codCollected ? Colors.white : darkMaroon,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cash on Delivery',
                      style: TextStyle(
                        color: darkMaroon,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Collect payment from the customer.',
                      style: TextStyle(color: brownBeige, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const Text(
                _codAmount,
                style: TextStyle(
                  color: darkMaroon,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(
              color: _codCollected
                  ? darkMaroon.withValues(alpha: 0.08)
                  : cream.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              children: [
                Icon(
                  _codCollected
                      ? Icons.verified_rounded
                      : Icons.schedule_rounded,
                  color: darkMaroon,
                  size: 19,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    _codCollected
                        ? 'Payment Status: Collected'
                        : 'Payment Status: To Collect',
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
          if (canCollect) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _confirmCodCollection,
                icon: const Icon(Icons.payments_outlined),
                label: const Text(
                  'Confirm COD Collected',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkMaroon,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmCodCollection() async {
    if (_codCollected) return;

    final bool confirm = await _showConfirmation(
      title: 'Confirm COD Payment',
      message:
          'Confirm that you received $_codAmount in cash from ${widget.customer}.',
      confirmText: 'Payment Collected',
      icon: Icons.payments_outlined,
    );

    if (!confirm || !mounted) return;

    setState(() {
      _codCollected = true;
    });

    _showTopNotification(
      'COD payment of $_codAmount collected.',
      icon: Icons.verified_rounded,
    );
  }

  // ============================================================
  // PROOF OF DELIVERY UI
  // ============================================================

  Widget _buildProofOfDelivery() {
    final bool delivered = _status == DeliveryStage.delivered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Proof of Delivery',
          style: TextStyle(
            color: darkMaroon,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 5),

        const Text(
          'Complete the information below before confirming delivery.',
          style: TextStyle(color: brownBeige, fontSize: 12),
        ),

        const SizedBox(height: 12),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================================================
              // PHOTO
              // ==================================================

              const Text(
                'Delivery Photo',
                style: TextStyle(
                  color: darkMaroon,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 10),

              if (_proofImage == null)
                Container(
                  width: double.infinity,
                  height: 170,
                  decoration: BoxDecoration(
                    color: lightBeige.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: lightBeige),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt_outlined,
                        color: darkMaroon,
                        size: 42,
                      ),

                      SizedBox(height: 10),

                      Text(
                        'No proof photo yet',
                        style: TextStyle(
                          color: darkMaroon,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 4),

                      Text(
                        'Take a clear delivery photo.',
                        style: TextStyle(color: brownBeige, fontSize: 11),
                      ),
                    ],
                  ),
                )
              else
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.file(
                    File(_proofImage!.path),
                    width: double.infinity,
                    height: 210,
                    fit: BoxFit.cover,
                  ),
                ),

              const SizedBox(height: 12),

              if (!delivered)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _takeProofPhoto,
                    icon: Icon(
                      _proofImage == null
                          ? Icons.camera_alt_outlined
                          : Icons.refresh,
                    ),
                    label: Text(
                      _proofImage == null ? 'Take Proof Photo' : 'Retake Photo',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: darkMaroon,
                      side: const BorderSide(color: darkMaroon),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),

              if (_proofImage != null) ...[
                const SizedBox(height: 10),

                const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Proof photo added',
                      style: TextStyle(
                        color: darkMaroon,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 20),

              // ==================================================
              // RECEIVED BY
              // ==================================================
              const Text(
                'Received By',
                style: TextStyle(
                  color: darkMaroon,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: _receivedByController,
                enabled: !delivered,
                decoration: InputDecoration(
                  hintText: 'Enter receiver name',
                  hintStyle: const TextStyle(color: brownBeige, fontSize: 12),
                  prefixIcon: const Icon(
                    Icons.person_outline,
                    color: darkMaroon,
                  ),
                  filled: true,
                  fillColor: cream,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ORDER DETAILS
  // ============================================================

  Widget _buildOrderDetails() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Details',
            style: TextStyle(
              color: darkMaroon,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          _detailRow(
            Icons.receipt_long_outlined,
            'Order Number',
            widget.orderNumber,
          ),

          const Divider(height: 26, color: lightBeige),

          _detailRow(Icons.route_outlined, 'Distance', widget.distance),

          const Divider(height: 26, color: lightBeige),

          _detailRow(
            Icons.phone_outlined,
            'Customer Number',
            _customerPhoneForDialer ?? 'Not provided',
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DETAIL ROW
  // ============================================================

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: lightBeige,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: darkMaroon, size: 20),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: brownBeige, fontSize: 12),
          ),
        ),

        Text(
          value,
          style: const TextStyle(
            color: darkMaroon,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // LOCATION CARD
  // ============================================================

  Widget _locationCard({
    required IconData icon,
    required String label,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: lightBeige,
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
                  label,
                  style: const TextStyle(color: brownBeige, fontSize: 10),
                ),

                const SizedBox(height: 3),

                Text(
                  title,
                  style: const TextStyle(
                    color: darkMaroon,
                    fontSize: 15,
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
    );
  }
}
