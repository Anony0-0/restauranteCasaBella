import '../models/produto.dart';

/// Mantém IDs locais determinísticos para que itens do pedido guardem a FK.
class CatalogoController {
  int idDoProduto(String nome) {
    var hash = 17;
    for (final codePoint in nome.trim().toLowerCase().runes) {
      hash = (hash * 31 + codePoint) & 0x7fffffff;
    }
    return hash == 0 ? 1 : hash;
  }

  Produto converter(Map<String, Object?> dados) {
    final produto = Produto.fromMap(dados);
    return Produto(
      idProduto:
          produto.idProduto ?? idDoProduto(dados['nome']?.toString() ?? ''),
      categoria: produto.categoria,
      nome: produto.nome,
      descricao: produto.descricao,
      preco: produto.preco,
      imagem: produto.imagem,
      disponivel: produto.disponivel,
    );
  }
}
