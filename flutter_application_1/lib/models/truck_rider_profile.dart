class TruckRiderProfile {
  final String riderId;

  // Personal information
  final String fullName;
  final String email;
  final String phone;
  final DateTime birthday;
  final String age;

  // Address
  final String region;
  final String province;
  final String municipality;
  final String barangay;
  final String street;
  final String houseUnit;

  // Account and vehicle
  final String vehicleType;
  final String licenseNumber;
  final String plateNumber;
  final String accountStatus;

  // Local document file paths for the prototype
  final String? licenseImagePath;
  final String? orImagePath;
  final String? crImagePath;

  const TruckRiderProfile({
    required this.riderId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.birthday,
    required this.age,
    required this.region,
    required this.province,
    required this.municipality,
    required this.barangay,
    required this.street,
    required this.houseUnit,
    required this.vehicleType,
    required this.licenseNumber,
    required this.plateNumber,
    required this.accountStatus,
    this.licenseImagePath,
    this.orImagePath,
    this.crImagePath,
  });

  String get completeAddress =>
      '$houseUnit $street, $barangay, $municipality, '
      '$province, $region';

  bool get isTruckOrVan {
    final type = vehicleType.trim().toLowerCase();
    return type == 'truck' || type == 'van';
  }
}
