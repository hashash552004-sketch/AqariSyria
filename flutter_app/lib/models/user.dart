class AppUser {
  final String uid;
  final String? uniqueUserId;
  final String fullName;
  final String email;
  final String phone;
  final String? profileImage;
  final List<String> favorites;
  final String role;
  final String username;

  AppUser({
    required this.uid,
    this.uniqueUserId,
    required this.fullName,
    required this.email,
    required this.phone,
    this.profileImage,
    this.favorites = const [],
    this.role = 'user',
    this.username = '',
  });

  factory AppUser.fromFirestore(Map<String, dynamic> data, String uid) {
    return AppUser(
      uid: uid,
      uniqueUserId: data['uniqueUserId']?.toString(),
      fullName: data['fullName']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      phone: data['phone']?.toString() ?? '',
      profileImage: data['profileImage']?.toString(),
      favorites:
          (data['favorites'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      role: data['role']?.toString() ?? 'user',
      username: data['username']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uniqueUserId': uniqueUserId,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'profileImage': profileImage,
      'favorites': favorites,
      'role': role,
      'username': username,
    };
  }
}
