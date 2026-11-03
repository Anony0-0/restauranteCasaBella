import '../repositories/local_repository.dart';

/// Orquestra o ciclo de vida dos pedidos sem acoplar as telas à persistência.
class PedidoController {
  Future<List<Map<String, dynamic>>> listar() =>
      LocalRepository.listarPedidos();

  Future<Map<String, dynamic>> enviar({
    required String mesa,
    int? mesaId,
    required String atendente,
    required List<Map<String, dynamic>> itens,
  }) => LocalRepository.enviarPedido(
    mesa: mesa,
    mesaId: mesaId,
    garcom: atendente,
    itens: itens,
  );

  Future<Map<String, dynamic>> atualizarStatus(Map<String, dynamic> pedido) =>
      LocalRepository.atualizarStatus(pedido);

  bool podeAlterar(Map<String, dynamic> pedido) =>
      LocalRepository.podeAlterarPedido(pedido);

  Future<Map<String, dynamic>> alterar(
    Map<String, dynamic> pedido, {
    required List<Map<String, dynamic>> itens,
  }) => LocalRepository.alterarPedido(pedido, itens: itens);

  Future<Map<String, dynamic>> cancelar(
    Map<String, dynamic> pedido, {
    String? motivo,
  }) => LocalRepository.cancelarPedido(pedido, motivo: motivo);
}
