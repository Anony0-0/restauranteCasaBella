class Reserva {
  final int? idReserva;
  final int clienteId;
  final String telefone;
  final String email;
  final DateTime horario;
  final int quantidadePessoas;
  final int mesaId;
  final String status;

  const Reserva({
    this.idReserva,
    required this.clienteId,
    required this.telefone,
    required this.email,
    required this.horario,
    required this.quantidadePessoas,
    required this.mesaId,
    this.status = 'pendente',
  });

  Map<String, Object?> toMap() => {
    'id_reserva': idReserva,
    'id_cliente': clienteId,
    'telefone': telefone,
    'email': email,
    'horario': horario.toIso8601String(),
    'qtd_pessoas': quantidadePessoas,
    'id_mesa': mesaId,
    'status': status,
  };

  factory Reserva.fromMap(Map<String, Object?> map) => Reserva(
    idReserva: map['id_reserva'] as int?,
    clienteId: map['id_cliente'] as int? ?? 0,
    telefone: map['telefone'] as String? ?? '',
    email: map['email'] as String? ?? '',
    horario:
        DateTime.tryParse(map['horario'] as String? ?? '') ?? DateTime.now(),
    quantidadePessoas: map['qtd_pessoas'] as int? ?? 1,
    mesaId: map['id_mesa'] as int? ?? 0,
    status: map['status'] as String? ?? 'pendente',
  );
}
