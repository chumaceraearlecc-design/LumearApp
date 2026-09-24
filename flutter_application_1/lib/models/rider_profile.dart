import 'dart:io';

class RiderProfile {
  static File? profileImage;

  static int? id;
  static String name = '';
  static String riderId = '';
  static String email = '';
  static String phone = '';
  static String birthday = '';
  static int? age;

  static String region = '';
  static String province = '';
  static String municipality = '';
  static String barangay = '';
  static String street = '';
  static String houseUnit = '';

  static String vehicleType = '';
  static String licenseNumber = '';
  static String plateNumber = '';

  static String licenseImage = '';
  static String orCrImage = '';
  static String status = '';

  static String get completeAddress {
    return [
      houseUnit,
      street,
      barangay,
      municipality,
      province,
      region,
    ].where((part) => part.trim().isNotEmpty).join(', ');
  }

  static void setFromJson(Map<String, dynamic> json) {
    id = _toInt(json['id']);
    name = json['full_name']?.toString() ?? '';
    riderId = id != null ? '#R${id.toString().padLeft(5, '0')}' : '';
    email = json['email']?.toString() ?? '';
    phone = json['phone']?.toString() ?? '';
    birthday = json['birthday']?.toString() ?? '';
    age = _toInt(json['age']);

    region = json['region']?.toString() ?? '';
    province = json['province']?.toString() ?? '';
    municipality = json['municipality']?.toString() ?? '';
    barangay = json['barangay']?.toString() ?? '';
    street = json['street']?.toString() ?? '';
    houseUnit = json['house_unit']?.toString() ?? '';

    vehicleType = json['vehicle_type']?.toString() ?? '';
    licenseNumber = json['license_number']?.toString() ?? '';
    plateNumber = json['plate_number']?.toString() ?? '';

    licenseImage = json['license_image']?.toString() ?? '';
    orCrImage = json['or_cr_image']?.toString() ?? '';
    status = json['status']?.toString() ?? '';
  }

  static void clear() {
    profileImage = null;
    id = null;
    name = '';
    riderId = '';
    email = '';
    phone = '';
    birthday = '';
    age = null;
    region = '';
    province = '';
    municipality = '';
    barangay = '';
    street = '';
    houseUnit = '';
    vehicleType = '';
    licenseNumber = '';
    plateNumber = '';
    licenseImage = '';
    orCrImage = '';
    status = '';
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
