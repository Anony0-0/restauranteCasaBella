import '../repositories/local_repository.dart';

/// Regras do fluxo de autenticação e cadastro de colaboradores.
class AuthController {
  Future<bool> temColaboradores() => LocalRepository.temColaboradores();

  Future<String?> cadastrar({
    required String nome,
    required String cpf,
    required String senha,
  }) => LocalRepository.cadastrar(nome: nome, cpf: cpf, senha: senha);

  Future<Map<String, String>?> entrar({
    required String cpf,
    required String senha,
  }) => LocalRepository.entrar(cpf: cpf, senha: senha);

  bool cpfValido(String cpf) => LocalRepository.cpfValido(cpf);

  bool podeGerenciarEquipe(String? cargo) =>
      LocalRepository.cargoPodeGerenciarEquipe(cargo);

  Future<List<Map<String, String>>> listarColaboradores() =>
      LocalRepository.listarColaboradores();

  Future<String?> removerColaborador({
    required String cpfResponsavel,
    required String cpfColaborador,
  }) => LocalRepository.removerColaborador(
    cpfResponsavel: cpfResponsavel,
    cpfColaborador: cpfColaborador,
  );
}
