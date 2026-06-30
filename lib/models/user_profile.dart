class UserProfile {
  const UserProfile({
    required this.username,
    required this.email,
    required this.phone,
    required this.bio,
    required this.avatarPath,
    this.useAsset = false,
    this.userType = 'patient',
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final avatarPath = (json['avatar_path'] as String?) ?? '';
    return UserProfile(
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      avatarPath: avatarPath,
      useAsset: avatarPath.startsWith('assets/'),
      userType: json['user_type'] as String? ?? 'patient',
    );
  }

  final String username;
  final String email;
  final String phone;
  final String bio;
  final String avatarPath;
  final bool useAsset;
  final String userType;

  Map<String, dynamic> toJson() => {
        'username': username,
        'email': email,
        'phone': phone,
        'bio': bio,
        'avatar_path': avatarPath,
      };

  UserProfile copyWith({
    String? username,
    String? email,
    String? phone,
    String? bio,
    String? avatarPath,
    bool? useAsset,
    String? userType,
  }) {
    return UserProfile(
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      bio: bio ?? this.bio,
      avatarPath: avatarPath ?? this.avatarPath,
      useAsset: useAsset ?? this.useAsset,
      userType: userType ?? this.userType,
    );
  }
}
