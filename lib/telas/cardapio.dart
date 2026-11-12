import 'package:flutter/material.dart';

import '../controllers/catalogo_controller.dart';

class CardapioPage extends StatefulWidget {
  const CardapioPage({super.key});

  @override
  State<CardapioPage> createState() => _CardapioPageState();
}

class _CardapioPageState extends State<CardapioPage> {
  final _catalogoController = CatalogoController();
  String categoriaSelecionada = 'Todos';
  String busca = '';
  List<Map<String, dynamic>> produtos = [];
  final List<Map<String, dynamic>> itensPedido = [];
  bool _carregandoProdutos = true;
  String? _erroProdutos;

  @override
  void initState() {
    super.initState();
    _carregarProdutos();
  }

  Future<void> _carregarProdutos() async {
    setState(() {
      _carregandoProdutos = true;
      _erroProdutos = null;
    });

    try {
      final produtosCarregados = await _catalogoController.listar();
      if (!mounted) return;
      setState(() {
        produtos = produtosCarregados
            .map(
              (produto) => {
                ...produto.toMap(),
                'disponivel': produto.disponivel,
                'icone': _iconeDaCategoria(produto.categoria),
              },
            )
            .toList();
      });
    } catch (erro) {
      debugPrint('Não foi possível carregar os produtos: $erro');
      if (!mounted) return;
      setState(() {
        _erroProdutos = 'Não foi possível carregar o cardápio. Verifique a conexão e tente novamente.';
      });
    } finally {
      if (mounted) setState(() => _carregandoProdutos = false);
    }
  }

  void adicionarProduto(Map<String, dynamic> produto) {
    if (produto['disponivel'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este produto está indisponível.')),
      );
      return;
    }

    final idProduto = (produto['id_produto'] as num?)?.toInt();
    if (idProduto == null || idProduto <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O produto não possui um ID válido.')),
      );
      return;
    }

    setState(() {
      final indice = itensPedido.indexWhere(
        (item) => item['id_produto'] == idProduto,
      );

      if (indice >= 0) {
        itensPedido[indice]['quantidade']++;
      } else {
        itensPedido.add({
          'id_produto': idProduto,
          'nome': produto['nome'],
          'preco': produto['preco'],
          'preco_unitario': produto['preco'],
          'quantidade': 1,
        });
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${produto['nome']} adicionado ao pedido.'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  IconData _iconeDaCategoria(String categoria) {
    final valor = categoria.toLowerCase();
    if (valor.contains('pizza')) return Icons.local_pizza;
    if (valor.contains('bebida') || valor.contains('vinho')) {
      return Icons.local_drink;
    }
    if (valor.contains('sobremesa')) return Icons.cake;
    if (valor.contains('salada') || valor.contains('acompanhamento')) {
      return Icons.eco;
    }
    if (valor.contains('massa')) return Icons.ramen_dining;
    return Icons.restaurant;
  }

  int quantidadeTotal() {
    int total = 0;

    for (final item in itensPedido) {
      total += item['quantidade'] as int;
    }

    return total;
  }

  double valorTotal() {
    double total = 0;

    for (final item in itensPedido) {
      total += (item['preco'] as double) * (item['quantidade'] as int);
    }

    return total;
  }

  void _continuarComItens() {
    if (itensPedido.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adicione pelo menos um produto ao pedido.'),
        ),
      );
      return;
    }
    Navigator.pop(
      context,
      itensPedido.map((item) => Map<String, dynamic>.from(item)).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categorias =
        produtos
            .map((produto) => produto['categoria'] as String)
            .toSet()
            .toList()
          ..sort();
    categorias.insert(0, 'Todos');

    final produtosFiltrados = produtos.where((produto) {
      final categoriaOk =
          categoriaSelecionada == 'Todos' ||
          produto['categoria'] == categoriaSelecionada;
      final buscaOk =
          busca.isEmpty ||
          (produto['nome'] as String).toLowerCase().contains(busca) ||
          (produto['descricao'] as String).toLowerCase().contains(busca);
      return categoriaOk && buscaOk;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F3E8),

      appBar: AppBar(
        backgroundColor: const Color(0xFF7B1E2B),
        foregroundColor: Colors.white,
        title: const Text(
          'Cardápio',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,

        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.receipt_long, size: 28),
                onPressed: _continuarComItens,
              ),

              if (quantidadeTotal() > 0)
                Positioned(
                  right: 5,
                  top: 5,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${quantidadeTotal()}',
                      style: const TextStyle(
                        color: Color(0xFF7B1E2B),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),

      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 15),
            color: const Color(0xFFF8F3E8),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Casa Bella',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7B1E2B),
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  'Adicionar produtos ao pedido',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF555555),
                  ),
                ),

                const SizedBox(height: 5),

                const Text(
                  'Escolha os produtos para adicionar ao pedido.',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar no cardápio',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (valor) =>
                  setState(() => busca = valor.toLowerCase().trim()),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: categorias.map((categoria) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(categoria),
                    selected: categoriaSelecionada == categoria,
                    onSelected: (_) =>
                        setState(() => categoriaSelecionada = categoria),
                  ),
                );
              }).toList(),
            ),
          ),

          Expanded(
            child: _carregandoProdutos
                ? const Center(child: CircularProgressIndicator())
                : _erroProdutos != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_erroProdutos!, textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: _carregarProdutos,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Tentar novamente'),
                          ),
                        ],
                      ),
                    ),
                  )
                : produtosFiltrados.isEmpty
                ? const Center(child: Text('Nenhum produto encontrado.'))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 5, 16, 16),
                    itemCount: produtosFiltrados.length,
                    itemBuilder: (context, index) {
                      final produto = produtosFiltrados[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        color: Colors.white,
                        elevation: 3,

                        child: Padding(
                          padding: const EdgeInsets.all(16),

                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              Container(
                                width: 70,
                                height: 70,

                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3E2D8),
                                  borderRadius: BorderRadius.circular(12),
                                ),

                                child: Icon(
                                  produto['icone'] as IconData,
                                  size: 38,
                                  color: const Color(0xFF7B1E2B),
                                ),
                              ),

                              const SizedBox(width: 15),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,

                                  children: [
                                    Text(
                                      produto['nome'] as String,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF7B1E2B),
                                      ),
                                    ),

                                    const SizedBox(height: 5),

                                    Text(
                                      produto['descricao'] as String,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black54,
                                      ),
                                    ),

                                    const SizedBox(height: 8),

                                    Text(
                                      'R\$ ${(produto['preco'] as double).toStringAsFixed(2).replaceAll('.', ',')}',
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    const SizedBox(height: 10),

                                    SizedBox(
                                      width: double.infinity,

                                      child: ElevatedButton(
                                        onPressed: () {
                                          adicionarProduto(produto);
                                        },

                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF7B1E2B,
                                          ),
                                          foregroundColor: Colors.white,
                                        ),

                                        child: Text('Adicionar ao pedido'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: itensPedido.isEmpty ? null : _continuarComItens,
            icon: const Icon(Icons.playlist_add_check),
            label: const Text('Adicionar itens ao pedido'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: const Color(0xFF7B1E2B),
            ),
          ),
        ),
      ),
    );
  }
}
