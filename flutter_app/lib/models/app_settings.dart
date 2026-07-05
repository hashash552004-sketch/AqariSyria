class AppSettings {
  final String whatsapp;
  final String phone;
  final String email;
  final String instagram;
  final String telegram;
  final String facebook;
  final String tiktok;

  AppSettings({
    this.whatsapp = '+963 900 000 000',
    this.phone = '+963 900 000 000',
    this.email = 'info@baitalomar.com',
    this.instagram = '',
    this.telegram = '',
    this.facebook = '',
    this.tiktok = '',
  });

  factory AppSettings.fromFirestore(Map<String, dynamic> data) {
    return AppSettings(
      whatsapp: data['whatsapp']?.toString() ?? '+963 900 000 000',
      phone: data['phone']?.toString() ?? '+963 900 000 000',
      email: data['email']?.toString() ?? 'info@baitalomar.com',
      instagram: data['instagram']?.toString() ?? '',
      telegram: data['telegram']?.toString() ?? '',
      facebook: data['facebook']?.toString() ?? '',
      tiktok: data['tiktok']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
    'whatsapp': whatsapp,
    'phone': phone,
    'email': email,
    'instagram': instagram,
    'telegram': telegram,
    'facebook': facebook,
    'tiktok': tiktok,
  };
}
