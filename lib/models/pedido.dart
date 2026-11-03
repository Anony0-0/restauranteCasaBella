import 'item_pedido.dart';

class Pedido {
  final int idPedido;
  final int? clienteId;
  final int? mesaId;
  final String? mesaDescricao;
  final DateTime dataPedido;
  final String status;
  final double valorTotal;
  final String? atendente;
  final List<ItemPedido> itens;

  const Pedido({
    required this.idPedido,
    this.clienteId,
    this.mesaId,
    this.mesaDescricao,
    required this.dataPedido,
    required this.status,
    required this.valorTotal,
    this.atendente,
    this.itens = const [],
  });

  Map<String, Object?> toMap() => {
    'id_pedido': idPedido,
    'id_cliente': clienteId,
    'id_mesa': mesaId,
    'data_pedido': dataPedido.toIso8601String(),
    'status': status,
    'valor_total': valorTotal,
    'atendente': atendente,
    'mesa': mesaDescricao,
    'itens': itens.map((item) => item.toMap()).toList(),
  };

  factory Pedido.fromMap(Map<String, Object?> map) => Pedido(
    idPedido:
        (map['id_pedido'] as num?)?.toInt() ??
        int.tryParse(map['id']?.toString() ?? '') ??
        0,
    clienteId: _asInt(map['id_cliente']),
    mesaId: _asInt(map['id_mesa']),
    mesaDescricao: map['mesa'] as String?,
    dataPedido:
        DateTime.tryParse(
          map['data_pedido']?.toString() ?? map['criadoEm']?.toString() ?? '',
        ) ??
        DateTime.now(),
    status: map['status'] as String? ?? 'pendente',
    valorTotal: _asDouble(map['valor_total']),
    atendente: map['atendente'] as String? ?? map['garcom'] as String?,
    itens: ((map['itens'] as List<dynamic>?) ?? const [])
      .whereType<Map>()
      .map((item) => ItemPedido.fromMap(Map<String, Object?>.from(item)))
      .toList(),
  );

    static int? _asInt(Object? value) => value is num
      ? value.toInt()
      : int.tryParse(value?.toString() ?? '');

    static double _asDouble(Object? value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '') ?? 0;
}
