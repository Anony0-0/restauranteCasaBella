import '../models/produto.dart';
import '../servicos/api_service.dart';

class CatalogoController {
  Future<List<Produto>> listar() async {
    final dados = await ApiService.listarProdutos();
    return dados.map((item) {
      final produto = converter(Map<String, Object?>.from(item));
      if (produto.idProduto == null || produto.idProduto! <= 0) {
        throw const FormatException('Produto sem identificador válido.');
      }
      if (produto.nome.trim().isEmpty || produto.categoria.trim().isEmpty) {
        throw const FormatException('Produto com nome ou categoria inválidos.');
      }
      final preco = item['preco'] is num
          ? (item['preco'] as num).toDouble()
          : double.tryParse(item['preco']?.toString() ?? '');
      if (preco == null || !preco.isFinite || preco < 0) {
        throw const FormatException('Produto com preço inválido.');
      }
      if (item['disponibilidade'] == null) {
        throw const FormatException('Produto sem disponibilidade válida.');
      }
      return produto;
    }).toList();
  }

  Produto converter(Map<String, Object?> dados) {
    return Produto.fromMap(dados);
  }
}
