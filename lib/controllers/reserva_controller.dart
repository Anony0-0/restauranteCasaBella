import '../models/mesa.dart';
import '../repositories/local_repository.dart';

/// Encaminha as operações de reserva da interface para o repositório local.
class ReservaController {
  Future<List<Map<String, dynamic>>> pesquisar(String nome) =>
      LocalRepository.pesquisarReservasPorNome(nome);

  Future<List<Mesa>> listarMesas() async =>
      (await LocalRepository.listarMesas()).map(Mesa.fromMap).toList();

  Future<Map<String, dynamic>> confirmar({
    required int reservaId,
    required int mesaId,
  }) => LocalRepository.confirmarReserva(reservaId: reservaId, mesaId: mesaId);

  Future<Map<String, dynamic>> abrirPedido({
    required int reservaId,
    required int mesaId,
    required String atendente,
  }) => LocalRepository.abrirPedidoParaReserva(
    reservaId: reservaId,
    mesaId: mesaId,
    atendente: atendente,
  );
}
