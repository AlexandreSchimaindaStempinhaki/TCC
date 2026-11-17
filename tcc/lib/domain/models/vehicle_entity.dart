class VehicleModel {
  final String id;
  final String companyCnpj;
  final String plate;
  final String model;
  final String brand;
  final int capacity;
  final String? color;
  final String? photoUrl;
  final String? defaultDriverId;
  final bool isActive;

  const VehicleModel({
    required this.id,
    required this.companyCnpj,
    required this.plate,
    required this.model,
    required this.brand,
    required this.capacity,
    this.color,
    this.photoUrl,
    this.defaultDriverId,
    this.isActive = true,
  });

  String get displayTitle => '$brand $model ($plate)';

  VehicleModel copyWith({
    String? id,
    String? companyCnpj,
    String? plate,
    String? model,
    String? brand,
    int? capacity,
    String? color,
    String? photoUrl,
    String? defaultDriverId,
    bool? isActive,
  }) {
    return VehicleModel(
      id: id ?? this.id,
      companyCnpj: companyCnpj ?? this.companyCnpj,
      plate: plate ?? this.plate,
      model: model ?? this.model,
      brand: brand ?? this.brand,
      capacity: capacity ?? this.capacity,
      color: color ?? this.color,
      photoUrl: photoUrl ?? this.photoUrl,
      defaultDriverId: defaultDriverId ?? this.defaultDriverId,
      isActive: isActive ?? this.isActive,
    );
  }
}