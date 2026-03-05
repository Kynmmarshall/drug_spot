class UserProfile {
  const UserProfile({
    required this.username,
    required this.email,
    required this.phone,
    required this.bio,
    required this.avatarUrl,
  });

  final String username;
  final String email;
  final String phone;
  final String bio;
  final String avatarUrl;

  UserProfile copyWith({
    String? username,
    String? email,
    String? phone,
    String? bio,
    String? avatarUrl,
  }) {
    return UserProfile(
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
