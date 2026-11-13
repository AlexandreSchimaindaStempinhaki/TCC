class AddressModel {
  final String city;
  final String neighborhood;
  final String street;
  final String number;
  final String complement;

  AddressModel({
    required this.city,
    required this.neighborhood,
    required this.street,
    required this.number,
    required this.complement,
  });

  Map<String, dynamic> toMap() {
    return {
      'city': city,
      'neighborhood': neighborhood,
      'street': street,
      'number': number,
      'complement': complement,
    };
  }

  factory AddressModel.fromMap(Map<String, dynamic> map) {
    return AddressModel(
      city: map['city'] ?? '',
      neighborhood: map['neighborhood'] ?? '',
      street: map['street'] ?? '',
      number: map['number'] ?? '',
      complement: map['complement'] ?? '',
    );
  }

  AddressModel copyWith({
    String? city,
    String? neighborhood,
    String? street,
    String? number,
    String? complement,
  }) {
    return AddressModel(
      city: city ?? this.city,
      neighborhood: neighborhood ?? this.neighborhood,
      street: street ?? this.street,
      number: number ?? this.number,
      complement: complement ?? this.complement,
    );
  }
}