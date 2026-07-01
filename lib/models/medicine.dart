class Medicine {
  const Medicine({
    required this.id,
    required this.name,
    required this.price,
    required this.pharmacyId,
    required this.distanceKm,
    this.description = '',
    this.imageUrl,
  });

  factory Medicine.fromJson(Map<String, dynamic> json, {double distanceKm = 0}) {
    return Medicine(
      id: json['id'].toString(),
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      pharmacyId: json['pharmacy_id'].toString(),
      distanceKm: distanceKm,
      description: json['description']?.toString() ?? '',
      imageUrl: json['image_url']?.toString(),
    );
  }

  final String id;
  final String name;
  final double price;
  final String pharmacyId;
  final double distanceKm;
  final String description;
  final String? imageUrl;

  Medicine copyWith({
    String? name,
    double? price,
    String? pharmacyId,
    double? distanceKm,
    String? description,
    String? imageUrl,
  }) {
    return Medicine(
      id: id,
      name: name ?? this.name,
      price: price ?? this.price,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      distanceKm: distanceKm ?? this.distanceKm,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
