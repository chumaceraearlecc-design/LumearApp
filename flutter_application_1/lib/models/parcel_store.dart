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

class ParcelStore {
  // ============================================================
  // ALL SCANNED PARCELS
  // ============================================================

  static final ValueNotifier<List<ParcelData>> parcels =
      ValueNotifier<List<ParcelData>>([]);

  // Keep this for compatibility with your existing code.
  static final ValueNotifier<ParcelData?> currentParcel =
      ValueNotifier<ParcelData?>(null);

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
    currentParcel.value = null;
  }
}
