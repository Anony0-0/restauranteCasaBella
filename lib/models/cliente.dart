class Cliente {
  final int? idCliente;
  final String nome;
  final String email;
  final String telefone;
  final String? senhaHash;

  const Cliente({
    this.idCliente,
    required this.nome,
    required this.email,
    required this.telefone,
    this.senhaHash,
  });

  Map<String, Object?> toMap() => {
    'id_cliente': idCliente,
    'nome': nome,
    'email': email,
    'senha': senhaHash,
    'telefone': telefone,
  };

  factory Cliente.fromMap(Map<String, Object?> map) => Cliente(
    idCliente: map['id_cliente'] as int?,
    nome: map['nome'] as String? ?? '',
    email: map['email'] as String? ?? '',
    telefone: map['telefone'] as String? ?? '',
    senhaHash: map['senha'] as String?,
  );
}
