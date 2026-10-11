import 'package:flutter/foundation.dart';

class ParcelData {
  final String parcelNumber;
  final String trackingNumber;
  final String hub;
  final String recipient;
  final String phone;
  final String address;
  final String parcelType;
  final String paymentMethod;
  final double codAmount;
  final double riderFee;
  final String distance;
  final double customerLatitude;
  final double customerLongitude;
  final String qrValue;
  final String status;

  const ParcelData({
    required this.parcelNumber,
    required this.trackingNumber,
    required this.hub,
    required this.recipient,
    required this.phone,
    required this.address,
    required this.parcelType,
    required this.paymentMethod,
    required this.codAmount,
    required this.riderFee,
    required this.distance,
    required this.customerLatitude,
    required this.customerLongitude,
    required this.qrValue,
    required this.status,
  });

  ParcelData copyWith({String? status}) {
    return ParcelData(
      parcelNumber: parcelNumber,
      trackingNumber: trackingNumber,
      hub: hub,
      recipient: recipient,
      phone: phone,
      address: address,
      parcelType: parcelType,
      paymentMethod: paymentMethod,
      codAmount: codAmount,
      riderFee: riderFee,
      distance: distance,
      customerLatitude: customerLatitude,
      customerLongitude: customerLongitude,
      qrValue: qrValue,
      status: status ?? this.status,
    );
  }
}

enum SellerPickupStatus {
  pendingAssignment,
  assigned,
  inProgress,
  pickedUp,
  headingToSortingCenter,
}

extension SellerPickupStatusLabel on SellerPickupStatus {
  String get label => switch (this) {
    SellerPickupStatus.pendingAssignment => 'Pending Assignment',
    SellerPickupStatus.assigned => 'Assigned',
    SellerPickupStatus.inProgress => 'Seller Pickup In Progress',
    SellerPickupStatus.pickedUp => 'Picked Up',
    SellerPickupStatus.headingToSortingCenter => 'Heading to Sorting Center',
  };
}

enum SellerPickupConfirmationResult {
  confirmed,
  pickupNotFound,
  pickupNotActive,
  parcelAssignedElsewhere,
  parcelAlreadyCollected,
  alreadyConfirmed,
}

class SellerPickupRequest {
  final String requestId;
  final String sellerName;
  final String pickupAddress;
  final String? sellerPhone;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final List<ParcelData> expectedParcels;
  final SellerPickupStatus status;
  SellerPickupRequest({
    required this.requestId,
    required this.sellerName,
    required this.pickupAddress,
    this.sellerPhone,
    this.pickupLatitude,
    this.pickupLongitude,
    required List<ParcelData> expectedParcels,
    this.status = SellerPickupStatus.assigned,
  }) : expectedParcels = List.unmodifiable(expectedParcels);

  SellerPickupRequest copyWith({
    SellerPickupStatus? status,
    List<ParcelData>? expectedParcels,
  }) {
    return SellerPickupRequest(
      requestId: requestId,
      sellerName: sellerName,
      pickupAddress: pickupAddress,
      sellerPhone: sellerPhone,
      pickupLatitude: pickupLatitude,
      pickupLongitude: pickupLongitude,
      expectedParcels: expectedParcels ?? this.expectedParcels,
      status: status ?? this.status,
    );
  }
}

enum SellerPickupStartResult { started, pickupNotFound, pickupNotAssignable }

class ParcelStore {
  // ============================================================
  // ALL SCANNED PARCELS
  // ============================================================

  static final ValueNotifier<List<ParcelData>> parcels =
      ValueNotifier<List<ParcelData>>([]);

  static final SellerPickupRequest demoSellerPickup = SellerPickupRequest(
    requestId: 'PU-0001',
    sellerName: 'Victoria Home Supplies',
    pickupAddress: 'Lumear Seller Hub, Victoria, Laguna',
    sellerPhone: '0912 345 6789',
    pickupLatitude: 14.2277,
    pickupLongitude: 121.3284,
    expectedParcels: const [
      ParcelData(
        parcelNumber: '#SPX1234',
        trackingNumber: 'SPX1234',
        hub: 'Victoria Hub',
        recipient: 'Awaiting sorting',
        phone: '',
        address: 'Lumear Seller Hub, Victoria, Laguna',
        parcelType: 'Seller pickup parcel',
        paymentMethod: 'Paid',
        codAmount: 0,
        riderFee: 0,
        distance: '',
        customerLatitude: 0,
        customerLongitude: 0,
        qrValue: 'SPX1234',
        status: 'To Pick Up',
      ),
      ParcelData(
        parcelNumber: '#SPX1235',
        trackingNumber: 'SPX1235',
        hub: 'Victoria Hub',
        recipient: 'Awaiting sorting',
        phone: '',
        address: 'Lumear Seller Hub, Victoria, Laguna',
        parcelType: 'Seller pickup parcel',
        paymentMethod: 'Paid',
        codAmount: 0,
        riderFee: 0,
        distance: '',
        customerLatitude: 0,
        customerLongitude: 0,
        qrValue: 'SPX1235',
        status: 'To Pick Up',
      ),
    ],
  );

  static final ValueNotifier<List<SellerPickupRequest>> sellerPickups =
      ValueNotifier<List<SellerPickupRequest>>([demoSellerPickup]);

  // Keep this for compatibility with your existing code.
  static final ValueNotifier<ParcelData?> currentParcel =
      ValueNotifier<ParcelData?>(null);

  static const double earningPerDelivery = 50;

  static final ValueNotifier<double> totalEarnings = ValueNotifier<double>(0);

  static final ValueNotifier<List<ParcelData>> earnedParcels =
      ValueNotifier<List<ParcelData>>([]);

  static SellerPickupRequest? findSellerPickup(String requestId) {
    for (final pickup in sellerPickups.value) {
      if (pickup.requestId == requestId) return pickup;
    }
    return null;
  }

  static void addSellerPickup(SellerPickupRequest pickup) {
    if (sellerPickups.value.any((item) => item.requestId == pickup.requestId)) {
      throw ArgumentError.value(
        pickup.requestId,
        'requestId',
        'Already exists',
      );
    }
    sellerPickups.value = [...sellerPickups.value, pickup];
  }

  static SellerPickupStartResult startSellerPickup(String requestId) {
    final SellerPickupRequest? pickup = findSellerPickup(requestId);
    if (pickup == null) return SellerPickupStartResult.pickupNotFound;
    if (pickup.status == SellerPickupStatus.inProgress) {
      return SellerPickupStartResult.started;
    }
    if (pickup.status != SellerPickupStatus.assigned) {
      return SellerPickupStartResult.pickupNotAssignable;
    }

    _replaceSellerPickup(
      pickup.copyWith(status: SellerPickupStatus.inProgress),
    );
    return SellerPickupStartResult.started;
  }

  static SellerPickupConfirmationResult confirmSellerPickup(String requestId) {
    final SellerPickupRequest? pickup = findSellerPickup(requestId);
    if (pickup == null) {
      return SellerPickupConfirmationResult.pickupNotFound;
    }
    if (pickup.status == SellerPickupStatus.pickedUp ||
        pickup.status == SellerPickupStatus.headingToSortingCenter) {
      return SellerPickupConfirmationResult.alreadyConfirmed;
    }
    if (pickup.status != SellerPickupStatus.inProgress) {
      return SellerPickupConfirmationResult.pickupNotActive;
    }
    if (pickup.expectedParcels.any(
      (expectedParcel) => sellerPickups.value.any(
        (other) =>
            other.requestId != requestId &&
            other.expectedParcels.any(
              (parcel) =>
                  parcel.trackingNumber == expectedParcel.trackingNumber,
            ),
      ),
    )) {
      return SellerPickupConfirmationResult.parcelAssignedElsewhere;
    }
    if (pickup.expectedParcels.any((expectedParcel) {
      final ParcelData? storedParcel = _findParcel(
        expectedParcel.trackingNumber,
      );
      return storedParcel != null && !_isCollectable(storedParcel);
    })) {
      return SellerPickupConfirmationResult.parcelAlreadyCollected;
    }

    for (final expectedParcel in pickup.expectedParcels) {
      _upsertParcel(expectedParcel.copyWith(status: 'Picked Up'));
    }
    _replaceSellerPickup(pickup.copyWith(status: SellerPickupStatus.pickedUp));
    return SellerPickupConfirmationResult.confirmed;
  }

  static bool beginSellerPickupHeadingToSortingCenter(String requestId) {
    final SellerPickupRequest? pickup = findSellerPickup(requestId);
    if (pickup == null || pickup.status != SellerPickupStatus.pickedUp) {
      return false;
    }

    for (final parcel in pickup.expectedParcels) {
      _upsertParcel(parcel.copyWith(status: 'Heading to Sorting Center'));
    }
    _replaceSellerPickup(
      pickup.copyWith(status: SellerPickupStatus.headingToSortingCenter),
    );
    return true;
  }

  static void _replaceSellerPickup(SellerPickupRequest updated) {
    sellerPickups.value = sellerPickups.value
        .map(
          (pickup) => pickup.requestId == updated.requestId ? updated : pickup,
        )
        .toList(growable: false);
  }

  static ParcelData? _findParcel(String trackingNumber) {
    for (final parcel in parcels.value) {
      if (parcel.trackingNumber == trackingNumber) return parcel;
    }
    return null;
  }

  static bool _isCollectable(ParcelData parcel) =>
      parcel.status == 'To Pick Up' ||
      parcel.status == 'Assigned' ||
      parcel.status == 'Seller Pickup In Progress';

  static void _upsertParcel(ParcelData updated) {
    final bool exists = parcels.value.any(
      (parcel) => parcel.trackingNumber == updated.trackingNumber,
    );
    parcels.value = exists
        ? parcels.value
              .map(
                (parcel) => parcel.trackingNumber == updated.trackingNumber
                    ? updated
                    : parcel,
              )
              .toList(growable: false)
        : [updated, ...parcels.value];

    if (currentParcel.value?.trackingNumber == updated.trackingNumber) {
      currentParcel.value = updated;
    }
  }

  // ============================================================
  // CREATE PARCEL
  // ============================================================

  static ParcelData createParcelFromQr(String qrValue) {
    final String cleanQr = qrValue.trim();

    if (cleanQr.isEmpty) {
      throw Exception('QR code is empty.');
    }

    // ----------------------------------------------------------
    // Check if QR already exists
    // ----------------------------------------------------------

    for (final parcel in parcels.value) {
      if (parcel.qrValue == cleanQr) {
        currentParcel.value = parcel;

        debugPrint('PARCEL ALREADY EXISTS: ${parcel.trackingNumber}');

        return parcel;
      }
    }

    // ----------------------------------------------------------
    // Generate unique parcel ID
    // ----------------------------------------------------------

    final int number = DateTime.now().microsecondsSinceEpoch;

    final String shortId = number.toString().substring(
      number.toString().length - 7,
    );

    final ParcelData newParcel = ParcelData(
      parcelNumber: '#LUM$shortId',
      trackingNumber: 'LUMEAR-$shortId',

      hub: 'Lumear Seller Hub - Victoria',

      recipient: 'Maricko Sheiy Villacorta',

      phone: '0912 345 6789',

      address: 'Masapang, Victoria, Laguna',

      parcelType: 'Medium Parcel',

      paymentMethod: 'Cash on Delivery',

      codAmount: 150.00,

      riderFee: 45.00,

      distance: '3.2 km',

      customerLatitude: 14.2277,

      customerLongitude: 121.3284,

      qrValue: cleanQr,

      status: 'To Pick Up',
    );

    // ==========================================================
    // IMPORTANT
    // Create NEW LIST so ValueNotifier definitely notifies.
    // ==========================================================

    parcels.value = [newParcel, ...parcels.value];

    currentParcel.value = newParcel;

    debugPrint('');
    debugPrint('======================================');
    debugPrint('PARCEL CREATED');
    debugPrint('Parcel: ${newParcel.parcelNumber}');
    debugPrint('Tracking: ${newParcel.trackingNumber}');
    debugPrint('QR: ${newParcel.qrValue}');
    debugPrint('Total parcels: ${parcels.value.length}');
    debugPrint('======================================');
    debugPrint('');

    return newParcel;
  }

  // ============================================================
  // UPDATE STATUS
  // ============================================================

  static void updateStatus(String status) {
    final ParcelData? current = currentParcel.value;

    if (current == null) {
      return;
    }

    final ParcelData updated = current.copyWith(status: status);

    currentParcel.value = updated;

    parcels.value = parcels.value.map((parcel) {
      if (parcel.trackingNumber == updated.trackingNumber) {
        return updated;
      }

      return parcel;
    }).toList();
  }

  static bool awardSuccessfulDelivery(ParcelData completedParcel) {
    if (completedParcel.status != 'Delivered') return false;

    ParcelData? storedParcel;
    for (final parcel in parcels.value) {
      if (parcel.trackingNumber == completedParcel.trackingNumber) {
        storedParcel = parcel;
        break;
      }
    }

    if (storedParcel != null && storedParcel.status != 'Delivered')
      return false;

    if (earnedParcels.value.any(
      (parcel) => parcel.trackingNumber == completedParcel.trackingNumber,
    )) {
      return false;
    }

    final ParcelData earnedParcel = storedParcel ?? completedParcel;
    if (storedParcel == null) {
      parcels.value = [earnedParcel, ...parcels.value];
    }

    earnedParcels.value = [earnedParcel, ...earnedParcels.value];
    totalEarnings.value += earningPerDelivery;
    return true;
  }

  // ============================================================
  // REMOVE CURRENT
  // ============================================================

  static void removeParcel() {
    currentParcel.value = null;
  }

  // ============================================================
  // CLEAR
  // ============================================================

  static void clearAll() {
    parcels.value = [];
    sellerPickups.value = [];
    currentParcel.value = null;
    earnedParcels.value = [];
    totalEarnings.value = 0;
  }
}
