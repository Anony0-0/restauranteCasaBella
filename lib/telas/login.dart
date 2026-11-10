import 'package:flutter/material.dart';

import '../servicos/api_service.dart';
import 'inicio.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usuarioController = TextEditingController();
  final _senhaController = TextEditingController();

  bool _senhaVisivel = false;
  bool _carregando = false;
  String? _mensagemErro;

  @override
  void dispose() {
    _usuarioController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _carregando = true;
      _mensagemErro = null;
    });

    try {
      final dados = await ApiService.login(
        email: _usuarioController.text.trim(),
        senha: _senhaController.text,
      );

      if (!mounted) return;

      final nome = dados['nome'] as String? ?? 'Atendente';
      final email = dados['email'] as String? ?? _usuarioController.text.trim();
      final perfil = dados['perfil'] as String? ?? 'funcionario';

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              InicioPage(nomeGarcom: nome, idUsuario: email, cargo: perfil),
        ),
      );
    } catch (erro) {
      if (!mounted) return;

      setState(() {
        _mensagemErro = erro.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5E8E8),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(
                      Icons.restaurant_menu,
                      color: Color(0xFF7B1E2B),
                      size: 34,
                    ),
                  ),

                  const Text(
                    'Casa Bella',
                    style: TextStyle(
                      color: Color(0xFF302B29),
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 4),

                  const Text(
                    'Acesso dos colaboradores',
                    style: TextStyle(color: Color(0xFF77716D), fontSize: 16),
                  ),

                  const SizedBox(height: 32),

                  TextFormField(
                    controller: _usuarioController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.username],
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (valor) => valor == null || valor.trim().isEmpty
                        ? 'Informe seu e-mail.'
                        : null,
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _senhaController,
                    obscureText: !_senhaVisivel,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    onFieldSubmitted: (_) => _entrar(),
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        tooltip: _senhaVisivel
                            ? 'Ocultar senha'
                            : 'Mostrar senha',
                        onPressed: () {
                          setState(() {
                            _senhaVisivel = !_senhaVisivel;
                          });
                        },
                        icon: Icon(
                          _senhaVisivel
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ),
                    validator: (valor) => valor == null || valor.isEmpty
                        ? 'Informe sua senha.'
                        : null,
                  ),

                  if (_mensagemErro != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _mensagemErro!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF9A4A16)),
                    ),
                  ],

                  const SizedBox(height: 24),

                  FilledButton(
                    onPressed: _carregando ? null : _entrar,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF7B1E2B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _carregando
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Entrar',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),

                  const SizedBox(height: 24),

                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Color(0xFF77716D),
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Seja bem-vindo, colaborador!',
                          style: TextStyle(
                            color: Color.fromARGB(255, 147, 95, 61),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
