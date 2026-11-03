import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';

class EquipePage extends StatefulWidget {
  final String cpfGerente;

  const EquipePage({super.key, required this.cpfGerente});

  @override
  State<EquipePage> createState() => _EquipePageState();
}

class _EquipePageState extends State<EquipePage> {
  final _authController = AuthController();
  late Future<List<Map<String, String>>> _colaboradores;
  final Set<String> _removendo = {};

  @override
  void initState() {
    super.initState();
    _carregarColaboradores();
  }

  void _carregarColaboradores() {
    _colaboradores = _authController.listarColaboradores();
  }

  Future<void> _remover(Map<String, String> colaborador) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover atendente?'),
        content: Text(
          'O acesso de ${colaborador['nome']} será removido deste dispositivo. '
          'Essa ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Voltar'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remover acesso'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    final cpf = colaborador['cpf']!;
    setState(() => _removendo.add(cpf));
    final erro = await _authController.removerColaborador(
      cpfResponsavel: widget.cpfGerente,
      cpfColaborador: cpf,
    );
    if (!mounted) return;
    setState(() {
      _removendo.remove(cpf);
      _carregarColaboradores();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(erro ?? 'Acesso de ${colaborador['nome']} removido.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Equipe de atendimento'),
      backgroundColor: const Color(0xFF7B1E2B),
      foregroundColor: Colors.white,
    ),
    body: FutureBuilder<List<Map<String, String>>>(
      future: _colaboradores,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(
            child: Text('Não foi possível carregar a equipe.'),
          );
        }
        final colaboradores = snapshot.data ?? [];
        if (colaboradores.isEmpty) {
          return const Center(child: Text('Nenhum colaborador cadastrado.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: colaboradores.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final colaborador = colaboradores[index];
            final cpf = colaborador['cpf']!;
            final eGerente = _authController.podeGerenciarEquipe(
              colaborador['cargo'],
            );
            final eProprioUsuario = cpf == widget.cpfGerente;
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFF5E8E8),
                  child: Icon(
                    eGerente ? Icons.admin_panel_settings : Icons.person,
                    color: const Color(0xFF7B1E2B),
                  ),
                ),
                title: Text(colaborador['nome'] ?? 'Colaborador'),
                subtitle: Text(colaborador['cargo'] ?? 'Atendente'),
                trailing: eProprioUsuario
                    ? const Chip(label: Text('Você'))
                    : IconButton(
                        tooltip: 'Remover acesso',
                        onPressed: _removendo.contains(cpf)
                            ? null
                            : () => _remover(colaborador),
                        icon: _removendo.contains(cpf)
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.person_remove_alt_1,
                                color: Colors.red,
                              ),
                      ),
              ),
            );
          },
        );
      },
    ),
  );
}
