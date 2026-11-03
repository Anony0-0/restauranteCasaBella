import 'package:flutter/material.dart';

import 'telas/inicio.dart';
import 'controllers/auth_controller.dart';

void main() {
  runApp(const CasaBellaApp());
}

class CasaBellaApp extends StatelessWidget {
  const CasaBellaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Casa Bella',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7B1E2B),
          surface: const Color(0xFFFCFAF7),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF6F4F0),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFCFAF7),
          foregroundColor: Color(0xFF272322),
          centerTitle: false,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE8E1DC)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE8E1DC)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF7B1E2B), width: 1.5),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFEFEAE5)),
          ),
        ),
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _authController = AuthController();
  final TextEditingController usuarioController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();

  bool mostrarSenha = false;
  bool carregando = false;

  Future<void> entrar() async {
    if (usuarioController.text.trim().isEmpty || senhaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe seu CPF e sua senha.')),
      );
      return;
    }

    setState(() => carregando = true);

    final usuario = await _authController.entrar(
      cpf: usuarioController.text,
      senha: senhaController.text,
    );

    if (!mounted) return;

    setState(() => carregando = false);

    if (usuario == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('CPF ou senha incorretos.')));
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => InicioPage(
          nomeGarcom: usuario['nome']!,
          cpf: usuario['cpf']!,
          cargo: usuario['cargo']!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F3E8),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.restaurant,
                  size: 80,
                  color: Color(0xFF7B1E2B),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Casa Bella',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7B1E2B),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Cucina Italiana',
                  style: TextStyle(
                    fontSize: 18,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF555555),
                  ),
                ),
                const SizedBox(height: 40),
                FutureBuilder<bool>(
                  future: _authController.temColaboradores(),
                  builder: (context, snapshot) {
                    if (snapshot.data == true) {
                      return const SizedBox.shrink();
                    }

                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 18),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0D8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Primeiro acesso? Cadastre o colaborador para começar.',
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
                TextField(
                  controller: usuarioController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'CPF',
                    hintText: 'Somente números ou com pontuação',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: senhaController,
                  obscureText: !mostrarSenha,
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        mostrarSenha ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          mostrarSenha = !mostrarSenha;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: carregando ? null : entrar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7B1E2B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: carregando
                        ? const SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'ENTRAR',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CadastroPage()),
                  ),
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Cadastrar colaborador'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF7B1E2B),
                  ),
                ),
                const Text(
                  'Sistema de registro e acompanhamento de pedidos',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF666666), fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    usuarioController.dispose();
    senhaController.dispose();
    super.dispose();
  }
}

class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final _authController = AuthController();
  final _formKey = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _cpf = TextEditingController();
  final _senha = TextEditingController();
  final _confirmacao = TextEditingController();

  bool _salvando = false;
  bool _mostrarSenha = false;

  Future<void> _cadastrar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _salvando = true);

    final erro = await _authController.cadastrar(
      nome: _nome.text,
      cpf: _cpf.text,
      senha: _senha.text,
    );

    if (!mounted) return;

    setState(() => _salvando = false);

    if (erro != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(erro)));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cadastro salvo. Entre com seu CPF e senha.'),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Cadastro de colaborador'),
      backgroundColor: const Color(0xFF7B1E2B),
      foregroundColor: Colors.white,
    ),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.badge_outlined,
                  size: 58,
                  color: Color.fromARGB(255, 148, 42, 56),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Crie seu acesso',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nome,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nome completo',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      (value == null || value.trim().length < 3)
                      ? 'Informe seu nome completo.'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _cpf,
                  keyboardType: TextInputType.number,
                  maxLength: 14,
                  decoration: const InputDecoration(
                    labelText: 'CPF do colaborador',
                    hintText: '000.000.000-00',
                    prefixIcon: Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      (value == null || !_authController.cpfValido(value))
                      ? 'Informe um CPF válido.'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _senha,
                  obscureText: !_mostrarSenha,
                  decoration: InputDecoration(
                    labelText: 'Senha (mínimo 6 caracteres)',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _mostrarSenha ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => _mostrarSenha = !_mostrarSenha),
                    ),
                  ),
                  validator: (value) => (value == null || value.length < 6)
                      ? 'A senha deve ter ao menos 6 caracteres.'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _confirmacao,
                  obscureText: !_mostrarSenha,
                  decoration: const InputDecoration(
                    labelText: 'Confirme a senha',
                    prefixIcon: Icon(Icons.lock_reset),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value != _senha.text ? 'As senhas não coincidem.' : null,
                ),
                const SizedBox(height: 22),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _salvando ? null : _cadastrar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7B1E2B),
                      foregroundColor: Colors.white,
                    ),
                    child: _salvando
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('SALVAR CADASTRO'),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'O primeiro cadastro recebe perfil gerente; os próximos, perfil atendente. Os dados ficam neste dispositivo e não são sincronizados.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  @override
  void dispose() {
    _nome.dispose();
    _cpf.dispose();
    _senha.dispose();
    _confirmacao.dispose();
    super.dispose();
  }
}
