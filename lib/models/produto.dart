class Produto {
  final int? idProduto;
  final String categoria;
  final String nome;
  final String descricao;
  final double preco;
  final String? imagem;
  final bool disponivel;

  const Produto({
    this.idProduto,
    required this.categoria,
    required this.nome,
    required this.descricao,
    required this.preco,
    this.imagem,
    this.disponivel = true,
  });

  Map<String, Object?> toMap() => {
    'id_produto': idProduto,
    'categoria': categoria,
    'nome': nome,
    'descricao': descricao,
    'preco': preco,
    'imagem': imagem,
    'disponibilidade': disponivel ? 1 : 0,
  };

  /// Serialização para a coluna ENUM do esquema MySQL anexado.
  Map<String, Object?> toMySqlMap() => {
    ...toMap(),
    'disponibilidade': disponivel ? 'disponivel' : 'indisponivel',
  };

  factory Produto.fromMap(Map<String, Object?> map) => Produto(
    idProduto: _asInt(map['id_produto']),
    categoria: map['categoria'] as String? ?? '',
    nome: map['nome'] as String? ?? '',
    descricao: map['descricao'] as String? ?? '',
    preco: _asDouble(map['preco']),
    imagem: map['imagem'] as String?,
    disponivel: _isDisponivel(map['disponibilidade']),
  );

  static int? _asInt(Object? value) => value is num
      ? value.toInt()
      : int.tryParse(value?.toString() ?? '');

    static double _asDouble(Object? value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '') ?? 0;

  static bool _isDisponivel(Object? value) {
    if (value == null) return true;
    if (value is bool) return value;
    if (value is num) return value != 0;
    return const {'1', 'true', 'disponivel', 'available', 'ativo'}.contains(
      value.toString().trim().toLowerCase(),
    );
  }
}
