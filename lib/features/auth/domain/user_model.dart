class UserModel {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String country;
  final String currency;
  final String language;
  final bool emailVerified;
  final bool kycVerified;
  final String? kycType;
  final bool isVendor;
  final String? vendorStatus;
  final String referralCode;
  final bool telegramLinked;
  final String? avatarUrl;
  final AddressModel? defaultAddress;
  final String? createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.country,
    required this.currency,
    required this.language,
    required this.emailVerified,
    required this.kycVerified,
    this.kycType,
    required this.isVendor,
    this.vendorStatus,
    required this.referralCode,
    required this.telegramLinked,
    this.avatarUrl,
    this.defaultAddress,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as int,
        name: json['name'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String? ?? '',
        country: json['country'] as String? ?? 'NG',
        currency: json['currency'] as String? ?? 'NGN',
        language: json['language'] as String? ?? 'en',
        emailVerified: json['email_verified'] as bool? ?? false,
        kycVerified: json['kyc_verified'] as bool? ?? false,
        kycType: json['kyc_type'] as String?,
        isVendor: json['is_vendor'] as bool? ?? false,
        vendorStatus: json['vendor_status'] as String?,
        referralCode: json['referral_code'] as String? ?? '',
        telegramLinked: json['telegram_linked'] as bool? ?? false,
        avatarUrl: json['avatar_url'] as String?,
        defaultAddress: json['default_address'] != null
            ? AddressModel.fromJson(json['default_address'] as Map<String, dynamic>)
            : null,
        createdAt: json['created_at'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'country': country,
        'currency': currency,
        'language': language,
        'email_verified': emailVerified,
        'kyc_verified': kycVerified,
        'kyc_type': kycType,
        'is_vendor': isVendor,
        'vendor_status': vendorStatus,
        'referral_code': referralCode,
        'telegram_linked': telegramLinked,
        'avatar_url': avatarUrl,
        'default_address': defaultAddress?.toJson(),
        'created_at': createdAt,
      };
}

class AddressModel {
  final String? address;
  final String? city;
  final String? state;
  final String? lga;
  final String? landmark;

  const AddressModel({
    this.address,
    this.city,
    this.state,
    this.lga,
    this.landmark,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) => AddressModel(
        address: json['address'] as String?,
        city: json['city'] as String?,
        state: json['state'] as String?,
        lga: json['lga'] as String?,
        landmark: json['landmark'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'address': address,
        'city': city,
        'state': state,
        'lga': lga,
        'landmark': landmark,
      };

  bool get isEmpty =>
      (address == null || address!.isEmpty) &&
      (city == null || city!.isEmpty) &&
      (state == null || state!.isEmpty);
}
