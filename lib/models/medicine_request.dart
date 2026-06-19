class MedicineRequest {
  const MedicineRequest({
    required this.id,
    required this.username,
    required this.contact,
    required this.medicineName,
    required this.avatarPath,
    this.useAsset = false,
  });

  factory MedicineRequest.fromJson(Map<String, dynamic> json) {
    final avatarPath = (json['avatar_path'] as String?) ?? '';
    return MedicineRequest(
      id: json['id'].toString(),
      username: json['username'] as String,
      contact: json['contact'] as String,
      medicineName: json['medicine_name'] as String,
      avatarPath: avatarPath,
      useAsset: json['use_asset'] as bool? ?? avatarPath.startsWith('assets/'),
    );
  }

  final String id;
  final String username;
  final String contact;
  final String medicineName;
  final String avatarPath;
  final bool useAsset;
}
