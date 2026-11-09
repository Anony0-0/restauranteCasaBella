import 'package:flutter/material.dart';

import '../controllers/pedido_controller.dart';
import 'acompanhamento.dart';
import 'reservas.dart';

class InicioPage extends StatelessWidget {
  final String nomeGarcom;
  final String idUsuario;
  final String cargo;

  const InicioPage({
    super.key,
    this.nomeGarcom = 'Atendente',
    this.idUsuario = 'local',
    this.cargo = 'atendente',
  });

  Future<void> _abrirAcompanhamento(BuildContext context) async {
    final pedidos = await PedidoController().listar();
    if (!context.mounted) return;
    if (pedidos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ainda não há pedidos para acompanhar.')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AcompanhamentoPage(pedidos: pedidos)),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF5E8E8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.restaurant_menu, color: Color(0xFF7B1E2B)),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Casa Bella',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
              ),
              Text(
                'Cucina Italiana',
                style: TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    ),
    body: LayoutBuilder(
      builder: (context, constraints) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7B1E2B), Color(0xFF4E1420)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x247B1E2B),
                      blurRadius: 24,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -4,
                      bottom: -22,
                      child: Icon(
                        Icons.local_dining,
                        size: 126,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.13),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Text(
                            'PAINEL DE ATENDIMENTO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              letterSpacing: 1.1,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Bem-vindo, ${nomeGarcom.split(' ').first}!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 27,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 7),
                        const Text(
                          'Tudo pronto para oferecer uma experiência especial.',
                          style: TextStyle(
                            color: Color(0xFFEADADD),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 7,
                          runSpacing: 4,
                          children: [
                            const Icon(
                              Icons.storefront_outlined,
                              color: Color(0xFFEADADD),
                              size: 17,
                            ),
                            Text(
                              idUsuario == 'local'
                                  ? 'Modo operacional local · sem login obrigatório'
                                  : 'Operação local · ID $idUsuario',
                              style: const TextStyle(
                                color: Color(0xFFEADADD),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Acesso rápido',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF302B29),
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Escolha uma ação para continuar seu atendimento.',
                style: TextStyle(color: Color(0xFF77716D)),
              ),
              const SizedBox(height: 16),
              if (constraints.maxWidth >= 620)
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    SizedBox(
                      width: (constraints.maxWidth - 14) / 2,
                      child: _ActionCard(
                        icon: Icons.event_available_outlined,
                        title: 'Atender reservas',
                        subtitle:
                            'Selecione uma reserva e monte o pedido do cliente.',
                        tone: const Color(0xFFB17B36),
                        onTap: () => _abrirReservas(context),
                      ),
                    ),
                    SizedBox(
                      width: (constraints.maxWidth - 14) / 2,
                      child: _ActionCard(
                        icon: Icons.receipt_long_rounded,
                        title: 'Acompanhar pedidos',
                        subtitle: 'Consulte pedidos e status da cozinha.',
                        tone: const Color(0xFF47634A),
                        onTap: () => _abrirAcompanhamento(context),
                      ),
                    ),
                  ],
                )
              else ...[
                _ActionCard(
                  icon: Icons.event_available_outlined,
                  title: 'Atender reservas',
                  subtitle:
                      'Selecione uma reserva e monte o pedido do cliente.',
                  tone: const Color(0xFFB17B36),
                  onTap: () => _abrirReservas(context),
                ),
                const SizedBox(height: 12),
                _ActionCard(
                  icon: Icons.receipt_long_rounded,
                  title: 'Acompanhar pedidos',
                  subtitle: 'Consulte pedidos e status da cozinha.',
                  tone: const Color(0xFF47634A),
                  onTap: () => _abrirAcompanhamento(context),
                ),
              ],
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(17),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Color(0xFFF5E8E8),
                        child: Icon(
                          Icons.lightbulb_outline,
                          color: Color(0xFF7B1E2B),
                        ),
                      ),
                      const SizedBox(width: 13),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dica de atendimento',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Confira os itens antes de enviar o pedido à cozinha.',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Center(
                child: Text(
                  'CASA BELLA  •  CUCINA ITALIANA',
                  style: TextStyle(
                    color: Color(0xFF9A928E),
                    fontSize: 10,
                    letterSpacing: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  void _abrirReservas(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ReservasPage(atendente: nomeGarcom)),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color tone;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: tone.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: tone, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.black54,
                      height: 1.3,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: tone),
          ],
        ),
      ),
    ),
  );
}
