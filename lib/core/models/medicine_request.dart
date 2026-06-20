class MedicineRequest {
  const MedicineRequest({
    required this.id,
    required this.username,
    required this.contact,
    required this.medicineName,
    required this.avatarPath,
    this.useAsset = false,
  });

  final String id;
  final String username;
  final String contact;
  final String medicineName;
  final String avatarPath;
  final bool useAsset;
}
