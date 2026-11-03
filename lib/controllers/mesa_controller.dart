import '../models/mesa.dart';
import '../repositories/local_repository.dart';

class MesaController {
  Future<List<Mesa>> listar() async =>
      (await LocalRepository.listarMesas()).map(Mesa.fromMap).toList();
}
