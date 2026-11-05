import '../repositories/local_repository.dart';

/// Regras do fluxo de autenticação e cadastro de colaboradores.
class AuthController {
  Future<bool> temColaboradores() => LocalRepository.temColaboradores();

  Future<({int? idUsuario, String? erro})> cadastrar({
    required String nome,
    required String senha,
  }) => LocalRepository.cadastrar(nome: nome, senha: senha);

  Future<Map<String, String>?> entrar({
    required String idUsuario,
    required String senha,
  }) => LocalRepository.entrar(idUsuario: idUsuario, senha: senha);

  bool podeGerenciarEquipe(String? cargo) =>
      LocalRepository.cargoPodeGerenciarEquipe(cargo);

  Future<List<Map<String, String>>> listarColaboradores() =>
      LocalRepository.listarColaboradores();

  Future<String?> removerColaborador({
    required String idResponsavel,
    required String idColaborador,
  }) => LocalRepository.removerColaborador(
    idResponsavel: idResponsavel,
    idColaborador: idColaborador,
  );
}
