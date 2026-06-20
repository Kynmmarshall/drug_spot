class UserProfile {
  const UserProfile({
    required this.username,
    required this.email,
    required this.phone,
    required this.bio,
    required this.avatarPath,
    this.useAsset = false,
  });

  final String username;
  final String email;
  final String phone;
  final String bio;
  final String avatarPath;
  final bool useAsset;

  UserProfile copyWith({
    String? username,
    String? email,
    String? phone,
    String? bio,
    String? avatarPath,
    bool? useAsset,
  }) {
    return UserProfile(
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      bio: bio ?? this.bio,
      avatarPath: avatarPath ?? this.avatarPath,
      useAsset: useAsset ?? this.useAsset,
    );
  }
}
