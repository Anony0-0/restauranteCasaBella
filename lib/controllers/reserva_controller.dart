import '../models/mesa.dart';
import '../repositories/local_repository.dart';
import '../servicos/api_service.dart';

class ReservaController {
  Future<List<Map<String, dynamic>>> pesquisar(String nome) async {
    final reservas = await ApiService.listarReservas();

    return reservas
        .map((item) {
          final reserva = Map<String, dynamic>.from(item);
          reserva['nome_cliente'] = reserva['cliente'];
          return reserva;
        })
        .where((reserva) {
          final cliente =
              reserva['nome_cliente']?.toString().toLowerCase() ?? '';
          return cliente.contains(nome.toLowerCase());
        })
        .toList();
  }

  Future<List<Mesa>> listarMesas() async =>
      (await LocalRepository.listarMesas()).map(Mesa.fromMap).toList();

  Future<Map<String, dynamic>> abrirPedido({
    required Map<String, dynamic> reserva,
    required String atendente,
  }) => LocalRepository.abrirPedidoParaReserva(
    reserva: reserva,
    atendente: atendente,
  );

  Future<void> confirmar(int reservaId) =>
      ApiService.confirmarReserva(reservaId);

  Future<Map<String, dynamic>> confirmarComMesa({
    required int reservaId,
    required int mesaId,
  }) => LocalRepository.confirmarReserva(reservaId: reservaId, mesaId: mesaId);

  Future<void> alterar({
    required int reservaId,
    required DateTime horario,
    required int quantidadePessoas,
  }) => ApiService.alterarReserva(
    reservaId: reservaId,
    horario: horario,
    quantidadePessoas: quantidadePessoas,
  );

  Future<void> cancelar(int reservaId) => ApiService.cancelarReserva(reservaId);

  String formatarHorario(dynamic valor) {
    final data = DateTime.tryParse(valor?.toString() ?? '');
    if (data == null) return 'Horário não informado';

    final local = data.toLocal();
    final dia = local.day.toString().padLeft(2, '0');
    final mes = local.month.toString().padLeft(2, '0');
    final hora = local.hour.toString().padLeft(2, '0');
    final minuto = local.minute.toString().padLeft(2, '0');

    return '$dia/$mes/${local.year} • $hora:$minuto';
  }

  String rotuloStatus(String status) => switch (status.toLowerCase()) {
    'pendente' => 'Pendente',
    'confirmada' => 'Confirmada',
    'em_andamento' || 'aberto' => 'Em atendimento',
    'concluida' => 'Concluída',
    'cancelada' => 'Cancelada',
    _ => status.isEmpty ? 'Sem status' : status,
  };
}
