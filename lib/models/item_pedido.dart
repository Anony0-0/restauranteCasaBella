class ItemPedido {
  final int? idItem;
  final int pedidoId;
  final int produtoId;
  final int quantidade;
  final double precoUnitario;
  final String? nomeProduto;

  const ItemPedido({
    this.idItem,
    required this.pedidoId,
    required this.produtoId,
    required this.quantidade,
    required this.precoUnitario,
    this.nomeProduto,
  });

  double get subtotal => quantidade * precoUnitario;

  Map<String, Object?> toMap() => {
    'id_itens': idItem,
    'id_pedido': pedidoId,
    'id_produto': produtoId,
    'quantidade': quantidade,
    'preco_unitario': precoUnitario,
    'nome_produto': nomeProduto,
  };

  /// Serialização para `preco_uni` usado no schema MySQL anexado.
  Map<String, Object?> toMySqlMap() => {
    ...toMap()..remove('preco_unitario'),
    'preco_uni': precoUnitario,
  };

  factory ItemPedido.fromMap(Map<String, Object?> map) => ItemPedido(
    idItem: _asInt(map['id_itens']),
    pedidoId: _asInt(map['id_pedido']) ?? 0,
    produtoId: _asInt(map['id_produto']) ?? 0,
    quantidade: _asInt(map['quantidade']) ?? 1,
    precoUnitario: _asDouble(map['preco_unitario'] ?? map['preco_uni']),
    nomeProduto: map['nome_produto'] as String?,
  );

  static int? _asInt(Object? value) => value is num
      ? value.toInt()
      : int.tryParse(value?.toString() ?? '');

  static double _asDouble(Object? value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '') ?? 0;
}
