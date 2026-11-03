class Mesa {
  final int? idMesa;
  final int capacidade;
  final bool reservado;

  const Mesa({this.idMesa, required this.capacidade, this.reservado = false});

  Map<String, Object?> toMap() => {
    'id_mesa': idMesa,
    'capacidade': capacidade,
    'reservado': reservado ? 1 : 0,
  };

  factory Mesa.fromMap(Map<String, Object?> map) => Mesa(
    idMesa: _asInt(map['id_mesa']),
    capacidade: _asInt(map['capacidade']) ?? 2,
    reservado: _asBool(map['reservado']),
  );

  static int? _asInt(Object? value) => value is num
      ? value.toInt()
      : int.tryParse(value?.toString() ?? '');

  static bool _asBool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    return const {'1', 'true', 'sim', 'yes'}.contains(
      value?.toString().trim().toLowerCase(),
    );
  }
}
