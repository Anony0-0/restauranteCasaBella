class Usuario {
  final int? idUsuario;
  final String cpf;
  final String? email;
  final String nome;
  final String senhaHash;
  final String cargo;
  final DateTime? admissao;

  const Usuario({
    this.idUsuario,
    required this.cpf,
    this.email,
    required this.nome,
    required this.senhaHash,
    required this.cargo,
    this.admissao,
  });

  Map<String, Object?> toMap() => {
    'id_usuario': idUsuario,
    'cpf': cpf,
    'email': email,
    'nome': nome,
    'senha': senhaHash,
    'cargo': cargo,
    'admissao': admissao?.toIso8601String(),
  };

  factory Usuario.fromMap(Map<String, Object?> map) => Usuario(
    idUsuario: map['id_usuario'] as int?,
    cpf: map['cpf'] as String? ?? '',
    email: map['email'] as String?,
    nome: map['nome'] as String? ?? '',
    senhaHash: map['senha'] as String? ?? '',
    cargo: map['cargo'] as String? ?? 'Atendente',
    admissao: DateTime.tryParse(map['admissao'] as String? ?? ''),
  );
}
