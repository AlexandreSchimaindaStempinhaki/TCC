class VehicleModel {
  final int id;
  final String cnpjEmpresa;
  final String placa;
  final String modelo;
  final String marca;
  final int capacidade;
  final bool ativo;

  const VehicleModel({
    required this.id,
    required this.cnpjEmpresa,
    required this.placa,
    required this.modelo,
    required this.marca,
    required this.capacidade,
    this.ativo = true,
  });

  VehicleModel copyWith({
    int? id,
    String? cnpjEmpresa,
    String? placa,
    String? modelo,
    String? marca,
    int? capacidade,
    bool? ativo,
  }) {
    return VehicleModel(
      id: id ?? this.id,
      cnpjEmpresa: cnpjEmpresa ?? this.cnpjEmpresa,
      placa: placa ?? this.placa,
      modelo: modelo ?? this.modelo,
      marca: marca ?? this.marca,
      capacidade: capacidade ?? this.capacidade,
      ativo: ativo ?? this.ativo,
    );
  }

  factory VehicleModel.fromMap(Map<String, dynamic> map) {
    return VehicleModel(
      id: (map['id'] as num?)?.toInt() ?? 0,
      cnpjEmpresa: map['cnpj_empresa'] as String? ?? '',
      placa: map['placa'] as String? ?? '',
      modelo: map['modelo'] as String? ?? '',
      marca: map['marca'] as String? ?? '',
      capacidade: (map['capacidade'] as num?)?.toInt() ?? 0,
      ativo: map['ativo'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cnpj_empresa': cnpjEmpresa,
      'placa': placa,
      'modelo': modelo,
      'marca': marca,
      'capacidade': capacidade,
      'ativo': ativo,
    };
  }
}