import 'package:flutter/material.dart';

import 'pedido.dart';
import '../controllers/catalogo_controller.dart';

class CardapioPage extends StatefulWidget {
  final String mesa;
  final int? mesaId;
  final String garcom;
  final bool modoSelecao;

  const CardapioPage({
    super.key,
    required this.mesa,
    this.mesaId,
    required this.garcom,
    this.modoSelecao = false,
  });

  @override
  State<CardapioPage> createState() => _CardapioPageState();
}

class _CardapioPageState extends State<CardapioPage> {
  final _catalogoController = CatalogoController();
  String categoriaSelecionada = 'Todos';
  String busca = '';

  final List<Map<String, dynamic>> produtos = [
    {
      'nome': 'Bruschetta al Pomodoro',
      'categoria': 'Entradas',
      'descricao': 'Pão italiano, tomate, alho e manjericão.',
      'preco': 18.90,
      'icone': Icons.bakery_dining,
    },
    {
      'nome': 'Arancini di Ragù',
      'categoria': 'Entradas',
      'descricao': 'Bolinhos de risoto recheados com carne.',
      'preco': 24.90,
      'icone': Icons.circle,
    },
    {
      'nome': 'Caprese',
      'categoria': 'Entradas',
      'descricao': 'Tomate fresco, muçarela de búfala, manjericão e azeite.',
      'preco': 61.90,
      'icone': Icons.restaurant,
    },
    {
      'nome': 'Carpaccio alla Italiana',
      'categoria': 'Entradas',
      'descricao':
          'Fatias finas de carne, rúcula, parmesão e molho de mostarda.',
      'preco': 85.20,
      'icone': Icons.dinner_dining,
    },
    {
      'nome': 'Polenta Frita com Parmesão',
      'categoria': 'Entradas',
      'descricao': 'Palitos de polenta crocantes com parmesão ralado.',
      'preco': 45.90,
      'icone': Icons.restaurant,
    },
    {
      'nome': 'Focaccia da Casa',
      'categoria': 'Entradas',
      'descricao': 'Pão italiano assado com alecrim, azeite e flor de sal.',
      'preco': 19.90,
      'icone': Icons.bakery_dining,
    },
    {
      'nome': 'Spaghetti à Bolonhesa',
      'categoria': 'Massas',
      'descricao': 'Spaghetti com molho de tomate e carne moída.',
      'preco': 32.90,
      'icone': Icons.ramen_dining,
    },
    {
      'nome': 'Spaghetti alla Carbonara',
      'categoria': 'Massas',
      'descricao': 'Massa, guanciale, queijo pecorino e gema de ovo.',
      'preco': 42.90,
      'icone': Icons.ramen_dining,
    },
    {
      'nome': 'Fettuccine Alfredo',
      'categoria': 'Massas',
      'descricao': 'Fettuccine ao molho cremoso de parmesão.',
      'preco': 35.90,
      'icone': Icons.ramen_dining,
    },
    {
      'nome': 'Penne alla Vodka',
      'categoria': 'Massas',
      'descricao': 'Penne ao molho cremoso de tomate e parmesão.',
      'preco': 37.90,
      'icone': Icons.ramen_dining,
    },
    {
      'nome': 'Ravioli de ricota',
      'categoria': 'Massas',
      'descricao': 'Massa recheada com ricota, molho de manteiga e sálvia.',
      'preco': 41.90,
      'icone': Icons.ramen_dining,
    },
    {
      'nome': 'Gnocchi al Pomodoro',
      'categoria': 'Massas',
      'descricao': 'Nhoque de batata com molho de tomate e manjericão.',
      'preco': 50.89,
      'icone': Icons.ramen_dining,
    },
    {
      'nome': 'Pappardelle al Pesto',
      'categoria': 'Massas',
      'descricao': 'Massa larga ao pesto de manjericão, parmesão e castanhas.',
      'preco': 50.90,
      'icone': Icons.ramen_dining,
    },
    {
      'nome': 'Penne alla Puttanesca',
      'categoria': 'Massas',
      'descricao': 'Penne com tomate, azeitonas, alcaparras e alho.',
      'preco': 70.90,
      'icone': Icons.ramen_dining,
    },
    {
      'nome': 'Tortellini ai Quattro Formaggi',
      'categoria': 'Massas',
      'descricao': 'Tortellini recheado servido com molho de quatro queijos.',
      'preco': 60.50,
      'icone': Icons.ramen_dining,
    },
    {
      'nome': 'Lasagna Vegetariana',
      'categoria': 'Massas',
      'descricao': 'Lasanha de legumes grelhados, molho de tomate e queijo.',
      'preco': 39.90,
      'icone': Icons.restaurant,
    },
    {
      'nome': 'Linguine al Limone',
      'categoria': 'Massas',
      'descricao': 'Linguine ao limão siciliano, manteiga e parmesão.',
      'preco': 59.90,
      'icone': Icons.ramen_dining,
    },
    {
      'nome': 'Tagliatelle al Ragù',
      'categoria': 'Massas',
      'descricao': 'Tagliatelle com molho de carne cozido lentamente.',
      'preco': 55.90,
      'icone': Icons.ramen_dining,
    },
    {
      'nome': 'Pasta alla Norma',
      'categoria': 'Massas',
      'descricao': 'Massa com berinjela, tomate, manjericão e ricota salgada.',
      'preco': 89.90,
      'icone': Icons.ramen_dining,
    },
    {
      'nome': 'Ravioli de Carne ao Sugo',
      'categoria': 'Massas',
      'descricao': 'Ravioli recheado com carne e molho de tomate artesanal.',
      'preco': 88.90,
      'icone': Icons.ramen_dining,
    },
    {
      'nome': 'Fettuccine ai Funghi',
      'categoria': 'Massas',
      'descricao': 'Fettuccine com cogumelos salteados, creme e parmesão.',
      'preco': 79.90,
      'icone': Icons.ramen_dining,
    },
    {
      'nome': 'Rigatoni al Forno',
      'categoria': 'Massas',
      'descricao':
          'Rigatoni ao tomate, queijo e manjericão, gratinado no forno.',
      'preco': 88.90,
      'icone': Icons.ramen_dining,
    },
    {
      'nome': 'Spaghetti Aglio e Olio',
      'categoria': 'Massas',
      'descricao': 'Spaghetti com alho dourado, azeite, salsinha e pimenta.',
      'preco': 31.90,
      'icone': Icons.ramen_dining,
    },
    {
      'nome': 'Caneloni de Ricota e Espinafre',
      'categoria': 'Massas',
      'descricao':
          'Massa recheada com ricota e espinafre, gratinada com queijo.',
      'preco': 41.90,
      'icone': Icons.restaurant,
    },
    {
      'nome': 'Pizza Margherita',
      'categoria': 'Pizzas Individuais',
      'descricao': 'Pizza individual com molho de tomate, muçarela de búfala e manjericão.',
      'preco': 29.90,
      'icone': Icons.local_pizza,
    },
    {
      'nome': 'Pizza Diavola',
      'categoria': 'Pizzas Individuais',
      'descricao':
          'Pizza individual com molho de tomate, muçarela e salame picante.',
      'preco': 32.90,
      'icone': Icons.local_pizza,
    },
    {
      'nome': 'Pizza Individual de Funghi',
      'categoria': 'Pizzas Individuais',
      'descricao': 'Pizza individual com cogumelos, muçarela e ervas.',
      'preco': 33.90,
      'icone': Icons.local_pizza,
    },
    {
      'nome': 'Pizza Individual de Calabresa',
      'categoria': 'Pizzas Individuais',
      'descricao': 'Pizza individual com calabresa, cebola e muçarela.',
      'preco': 28.90,
      'icone': Icons.local_pizza,
    },
    {
      'nome': 'Pizza Individual Quatro Queijos',
      'categoria': 'Pizzas Individuais',
      'descricao':
          'Pizza individual com muçarela, parmesão, provolone e gorgonzola.',
      'preco': 31.90,
      'icone': Icons.local_pizza,
    },
    {
      'nome': 'Pizza Individual de Presunto e Cogumelos',
      'categoria': 'Pizzas Individuais',
      'descricao': 'Pizza individual com presunto, cogumelos e muçarela.',
      'preco': 30.90,
      'icone': Icons.local_pizza,
    },
    {
      'nome': 'Pizza Quatro Queijos',
      'categoria': 'Pizzas',
      'descricao': 'Mussarela, parmesão, provolone e gorgonzola.',
      'preco': 48.90,
      'icone': Icons.local_pizza,
    },
    {
      'nome': 'Pizza Calabresa',
      'categoria': 'Pizzas',
      'descricao': 'Calabresa artesanal, cebola roxa e mozzarella.',
      'preco': 46.90,
      'icone': Icons.local_pizza,
    },
    {
      'nome': 'Pizza Portuguesa',
      'categoria': 'Pizzas',
      'descricao': 'Presunto, ovos, cebola, azeitonas e mozzarella.',
      'preco': 49.90,
      'icone': Icons.local_pizza,
    },
    {
      'nome': 'Pizza Pepperoni',
      'categoria': 'Pizzas',
      'descricao': 'Pepperoni, mozzarella e molho da casa.',
      'preco': 51.90,
      'icone': Icons.local_pizza,
    },
    {
      'nome': 'Pizza Napolitana',
      'categoria': 'Pizzas',
      'descricao': 'Molho de tomate, muçarela, parmesão, tomate e alho.',
      'preco': 90.90,
      'icone': Icons.local_pizza,
    },
    {
      'nome': 'Pizza de Presunto de Parma e Rúcula',
      'categoria': 'Pizzas',
      'descricao': 'Muçarela, presunto de Parma, rúcula fresca e parmesão.',
      'preco': 74.90,
      'icone': Icons.local_pizza,
    },
    {
      'nome': 'Pizza Vegetariana',
      'categoria': 'Pizzas',
      'descricao': 'Abobrinha, berinjela, pimentão, tomate e muçarela.',
      'preco': 99.90,
      'icone': Icons.local_pizza,
    },
    {
      'nome': 'Pizza Marinara',
      'categoria': 'Pizzas',
      'descricao': 'Molho de tomate, alho, orégano e azeite, sem queijo.',
      'preco': 42.90,
      'icone': Icons.local_pizza,
    },
    {
      'nome': 'Pizza Prosciutto e Funghi',
      'categoria': 'Pizzas',
      'descricao': 'Muçarela, presunto cozido e cogumelos frescos.',
      'preco': 49.90,
      'icone': Icons.local_pizza,
    },
    {
      'nome': 'Pizza Caprese',
      'categoria': 'Pizzas',
      'descricao': 'Tomate-cereja, muçarela de búfala, manjericão e pesto.',
      'preco': 51.90,
      'icone': Icons.local_pizza,
    },
    {
      'nome': 'Pizza Toscana',
      'categoria': 'Pizzas',
      'descricao': 'Linguiça toscana artesanal, cebola roxa e muçarela.',
      'preco': 48.90,
      'icone': Icons.local_pizza,
    },
    {
      'nome': 'Pizza de Frango com Catupiry',
      'categoria': 'Pizzas',
      'descricao': 'Frango desfiado temperado, requeijão cremoso e muçarela.',
      'preco': 47.90,
      'icone': Icons.local_pizza,
    },
    {
      'nome': 'Pizza de Alcachofra',
      'categoria': 'Pizzas',
      'descricao': 'Alcachofra, tomate, muçarela e ervas italianas.',
      'preco': 52.90,
      'icone': Icons.local_pizza,
    },
    {
      'nome': 'Pizza Bianca ai Quattro Formaggi',
      'categoria': 'Pizzas',
      'descricao':
          'Pizza branca com mozzarella, gorgonzola, parmesão e provolone.',
      'preco': 52.90,
      'icone': Icons.local_pizza,
    },
    {
      'nome': 'Pizza de Abobrinha e Parmesão',
      'categoria': 'Pizzas',
      'descricao': 'Abobrinha grelhada, parmesão, muçarela e azeite de ervas.',
      'preco': 46.90,
      'icone': Icons.local_pizza,
    },
    {
      'nome': 'Pizza Boscaiola',
      'categoria': 'Pizzas',
      'descricao': 'Cogumelos, linguiça italiana, muçarela e salsa fresca.',
      'preco': 51.90,
      'icone': Icons.local_pizza,
    },
    {
      'nome': 'Lasagna al Forno',
      'categoria': 'Massas',
      'descricao': 'Lasanha clássica à bolonhesa, assada com queijo.',
      'preco': 42.90,
      'icone': Icons.restaurant,
    },
    {
      'nome': 'Ossobuco alla Milanese',
      'categoria': 'Carnes',
      'descricao': 'Ossobuco cozido lentamente, servido com risoto de açafrão.',
      'preco': 74.90,
      'icone': Icons.dinner_dining,
    },
    {
      'nome': 'Pollo alla Parmigiana',
      'categoria': 'Carnes',
      'descricao': 'Frango empanado com molho de tomate e queijo gratinado.',
      'preco': 49.90,
      'icone': Icons.dinner_dining,
    },
    {
      'nome': 'Saltimbocca alla Romana',
      'categoria': 'Carnes',
      'descricao': 'Filé de vitela com presunto e sálvia, ao molho suave.',
      'preco': 68.90,
      'icone': Icons.dinner_dining,
    },
    {
      'nome': 'Filetto al Pepe Verde',
      'categoria': 'Carnes',
      'descricao': 'Medalhão de filé-mignon ao molho de pimenta verde.',
      'preco': 79.90,
      'icone': Icons.dinner_dining,
    },
    {
      'nome': 'Risotto ai Funghi',
      'categoria': 'Risotos',
      'descricao': 'Arroz arbóreo cremoso com cogumelos e parmesão.',
      'preco': 46.90,
      'icone': Icons.rice_bowl,
    },
    {
      'nome': 'Risotto alla Milanese',
      'categoria': 'Risotos',
      'descricao': 'Risoto tradicional com açafrão e parmesão.',
      'preco': 42.90,
      'icone': Icons.rice_bowl,
    },
    {
      'nome': 'Risotto al Limone e Gamberi',
      'categoria': 'Risotos',
      'descricao': 'Risoto de limão siciliano com camarões salteados.',
      'preco': 57.90,
      'icone': Icons.rice_bowl,
    },
    {
      'nome': 'Salmone al Limone',
      'categoria': 'Peixes e Frutos do Mar',
      'descricao': 'Filé de salmão grelhado com limão siciliano e ervas.',
      'preco': 69.90,
      'icone': Icons.set_meal,
    },
    {
      'nome': 'Linguine ai Frutti di Mare',
      'categoria': 'Peixes e Frutos do Mar',
      'descricao': 'Linguine com camarões, lula, mexilhões e molho de tomate.',
      'preco': 64.90,
      'icone': Icons.set_meal,
    },
    {
      'nome': 'Gamberi all’Aglio',
      'categoria': 'Peixes e Frutos do Mar',
      'descricao': 'Camarões salteados no alho, azeite e salsinha.',
      'preco': 59.90,
      'icone': Icons.set_meal,
    },
    {
      'nome': 'Insalata Caprese',
      'categoria': 'Saladas',
      'descricao': 'Tomate, muçarela de búfala, manjericão e azeite.',
      'preco': 29.90,
      'icone': Icons.eco,
    },
    {
      'nome': 'Insalata di Rucola e Parma',
      'categoria': 'Saladas',
      'descricao': 'Rúcula, presunto de Parma, parmesão e tomate-cereja.',
      'preco': 34.90,
      'icone': Icons.eco,
    },
    {
      'nome': 'Legumes Grigliati',
      'categoria': 'Acompanhamentos',
      'descricao': 'Abobrinha, berinjela e pimentão grelhados com ervas.',
      'preco': 18.90,
      'icone': Icons.eco,
    },
    {
      'nome': 'Purê de Batata com Parmesão',
      'categoria': 'Acompanhamentos',
      'descricao': 'Purê cremoso finalizado com parmesão.',
      'preco': 16.90,
      'icone': Icons.restaurant,
    },
    {
      'nome': 'Tiramisù',
      'categoria': 'Sobremesas',
      'descricao': 'Biscoito champanhe, café e creme de mascarpone.',
      'preco': 19.90,
      'icone': Icons.cake,
    },
    {
      'nome': 'Panna cotta',
      'categoria': 'Sobremesas',
      'descricao': 'Creme italiano delicado com calda de frutas vermelhas.',
      'preco': 17.90,
      'icone': Icons.icecream,
    },
    {
      'nome': 'Cannoli Siciliani',
      'categoria': 'Sobremesas',
      'descricao': 'Massa crocante com creme de ricota.',
      'preco': 18.90,
      'icone': Icons.bakery_dining,
    },
    {
      'nome': 'Gelato italiano',
      'categoria': 'Sobremesas',
      'descricao': 'Duas bolas de gelato artesanal (consulte sabores).',
      'preco': 16.90,
      'icone': Icons.icecream,
    },
    {
      'nome': 'Affogato al Caffè',
      'categoria': 'Sobremesas',
      'descricao': 'Gelato de baunilha servido com café espresso quente.',
      'preco': 15.90,
      'icone': Icons.icecream,
    },
    {
      'nome': 'Torta della Nonna',
      'categoria': 'Sobremesas',
      'descricao': 'Torta italiana de creme com toque de limão e pinoli.',
      'preco': 19.90,
      'icone': Icons.cake,
    },
    {
      'nome': 'Semifreddo al Cioccolato',
      'categoria': 'Sobremesas',
      'descricao': 'Sobremesa gelada de chocolate meio amargo.',
      'preco': 21.90,
      'icone': Icons.icecream,
    },
    {
      'nome': 'Soda Italiana',
      'categoria': 'Bebidas Não Alcoólicas',
      'descricao': 'Escolha entre limão siciliano ou maçã verde.',
      'preco': 14.90,
      'icone': Icons.local_drink,
    },
    {
      'nome': 'Limonata',
      'categoria': 'Bebidas Não Alcoólicas',
      'descricao': 'Limonada clássica italiana.',
      'preco': 12.90,
      'icone': Icons.local_drink,
    },
    {
      'nome': 'Suco de laranja',
      'categoria': 'Bebidas Não Alcoólicas',
      'descricao': 'Suco natural preparado na hora.',
      'preco': 10.90,
      'icone': Icons.local_drink,
    },
    {
      'nome': 'Água mineral',
      'categoria': 'Bebidas Não Alcoólicas',
      'descricao': 'Com ou sem gás, 500 ml.',
      'preco': 6.00,
      'icone': Icons.water_drop,
    },
    {
      'nome': 'Refrigerante',
      'categoria': 'Bebidas Não Alcoólicas',
      'descricao': 'Lata 350 ml. Consulte as opções disponíveis.',
      'preco': 7.50,
      'icone': Icons.local_drink,
    },
    {
      'nome': 'Chá gelado de pêssego',
      'categoria': 'Bebidas Não Alcoólicas',
      'descricao': 'Chá preto gelado com pêssego e gelo.',
      'preco': 9.90,
      'icone': Icons.local_cafe,
    },
    {
      'nome': 'Suco de uva integral',
      'categoria': 'Bebidas Não Alcoólicas',
      'descricao': 'Suco de uva integral servido gelado.',
      'preco': 12.90,
      'icone': Icons.local_drink,
    },
    {
      'nome': 'Suco de limão siciliano',
      'categoria': 'Bebidas Não Alcoólicas',
      'descricao': 'Suco cítrico preparado na hora.',
      'preco': 11.90,
      'icone': Icons.local_drink,
    },
    {
      'nome': 'Aranciata',
      'categoria': 'Bebidas Não Alcoólicas',
      'descricao': 'Refrigerante italiano de laranja, lata 330 ml.',
      'preco': 12.90,
      'icone': Icons.local_drink,
    },
    {
      'nome': 'Água aromatizada da casa',
      'categoria': 'Bebidas Não Alcoólicas',
      'descricao': 'Água com limão siciliano, hortelã e rodelas de laranja.',
      'preco': 8.90,
      'icone': Icons.water_drop,
    },
    {
      'nome': 'Espresso italiano',
      'categoria': 'Bebidas Não Alcoólicas',
      'descricao': 'Café espresso curto, preparado na hora.',
      'preco': 6.90,
      'icone': Icons.coffee,
    },
    {
      'nome': 'Cappuccino italiano',
      'categoria': 'Bebidas Não Alcoólicas',
      'descricao': 'Espresso com leite vaporizado e espuma cremosa.',
      'preco': 10.90,
      'icone': Icons.coffee,
    },
    {
      'nome': 'Mocktail Bella',
      'categoria': 'Bebidas Não Alcoólicas',
      'descricao': 'Bebida sem álcool com laranja, limão e água com gás.',
      'preco': 16.90,
      'icone': Icons.local_bar,
    },
    {
      'nome': 'Vinho tinto Chianti',
      'categoria': 'Vinhos',
      'descricao': 'Chianti DOCG italiano, servido em taça de 150 ml.',
      'preco': 34.90,
      'icone': Icons.wine_bar,
    },
    {
      'nome': 'Chianti DOCG — garrafa',
      'categoria': 'Vinhos',
      'descricao': 'Tinto seco da Toscana, garrafa de 750 ml.',
      'preco': 159.90,
      'icone': Icons.wine_bar,
    },
    {
      'nome': 'Montepulciano d’Abruzzo',
      'categoria': 'Vinhos',
      'descricao': 'Tinto italiano frutado, garrafa de 750 ml.',
      'preco': 129.90,
      'icone': Icons.wine_bar,
    },
    {
      'nome': 'Pinot Grigio delle Venezie',
      'categoria': 'Vinhos',
      'descricao': 'Branco italiano leve e cítrico, garrafa de 750 ml.',
      'preco': 139.90,
      'icone': Icons.wine_bar,
    },
    {
      'nome': 'Primitivo di Manduria',
      'categoria': 'Vinhos',
      'descricao': 'Tinto encorpado da Puglia, garrafa de 750 ml.',
      'preco': 189.90,
      'icone': Icons.wine_bar,
    },
    {
      'nome': 'Prosecco DOC',
      'categoria': 'Vinhos',
      'descricao': 'Espumante brut italiano, garrafa de 750 ml.',
      'preco': 149.90,
      'icone': Icons.wine_bar,
    },
    {
      'nome': 'Prosecco',
      'categoria': 'Bebidas Alcoólicas',
      'descricao': 'Espumante italiano servido em taça de 150 ml.',
      'preco': 32.90,
      'icone': Icons.wine_bar,
    },
    {
      'nome': 'Cerveja Peroni',
      'categoria': 'Bebidas Alcoólicas',
      'descricao': 'Cerveja lager italiana, long neck 330 ml.',
      'preco': 16.90,
      'icone': Icons.sports_bar,
    },
    {
      'nome': 'Aperol Spritz',
      'categoria': 'Bebidas Alcoólicas',
      'descricao':
          'Coquetel italiano com Aperol, prosecco, água com gás e laranja.',
      'preco': 34.90,
      'icone': Icons.local_bar,
    },
    {
      'nome': 'Mini pizza Margherita',
      'categoria': 'Infantil',
      'descricao': 'Porção individual com mozzarella e manjericão.',
      'preco': 24.90,
      'icone': Icons.local_pizza,
    },
    {
      'nome': 'Penne ao sugo',
      'categoria': 'Infantil',
      'descricao': 'Porção infantil de penne com molho de tomate suave.',
      'preco': 22.90,
      'icone': Icons.ramen_dining,
    },
    {
      'nome': 'Polpettine com purê',
      'categoria': 'Infantil',
      'descricao': 'Almôndegas caseiras com purê de batata.',
      'preco': 25.90,
      'icone': Icons.restaurant,
    },
    {
      'nome': 'Mini Lasanha Infantil',
      'categoria': 'Infantil',
      'descricao':
          'Porção pequena de lasanha à bolonhesa com queijo gratinado.',
      'preco': 26.90,
      'icone': Icons.restaurant,
    },
    {
      'nome': 'Frango Grelhado com Penne',
      'categoria': 'Infantil',
      'descricao': 'Frango grelhado com penne ao molho de tomate suave.',
      'preco': 27.90,
      'icone': Icons.dinner_dining,
    },
  ];

  final List<Map<String, dynamic>> itensPedido = [];

  void adicionarProduto(Map<String, dynamic> produto) {
    final idProduto = _catalogoController.idDoProduto(
      produto['nome'] as String,
    );
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
    if (widget.modoSelecao) {
      Navigator.pop(
        context,
        itensPedido.map((item) => Map<String, dynamic>.from(item)).toList(),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PedidoPage(
          mesa: widget.mesa,
          mesaId: widget.mesaId,
          garcom: widget.garcom,
          itens: itensPedido,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  'Pedido - ${widget.mesa}',
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
              children:
                  [
                    'Todos',
                    'Entradas',
                    'Saladas',
                    'Massas',
                    'Risotos',
                    'Pizzas',
                    'Pizzas Individuais',
                    'Carnes',
                    'Peixes e Frutos do Mar',
                    'Acompanhamentos',
                    'Bebidas Não Alcoólicas',
                    'Vinhos',
                    'Bebidas Alcoólicas',
                    'Infantil',
                    'Sobremesas',
                  ].map((categoria) {
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
          if (categoriaSelecionada == 'Vinhos')
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 2, 18, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Preços em R\$ — referência de cardápio 2026; sujeitos à safra e ao fornecedor.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
            ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 5, 16, 16),
              itemCount: produtos.where((produto) {
                final categoriaOk =
                    categoriaSelecionada == 'Todos' ||
                    produto['categoria'] == categoriaSelecionada;
                final buscaOk =
                    busca.isEmpty ||
                    (produto['nome'] as String).toLowerCase().contains(busca) ||
                    (produto['descricao'] as String).toLowerCase().contains(
                      busca,
                    );
                return categoriaOk && buscaOk;
              }).length,

              itemBuilder: (context, index) {
                final filtrados = produtos.where((produto) {
                  final categoriaOk =
                      categoriaSelecionada == 'Todos' ||
                      produto['categoria'] == categoriaSelecionada;
                  final buscaOk =
                      busca.isEmpty ||
                      (produto['nome'] as String).toLowerCase().contains(
                        busca,
                      ) ||
                      (produto['descricao'] as String).toLowerCase().contains(
                        busca,
                      );
                  return categoriaOk && buscaOk;
                }).toList();
                final produto = filtrados[index];

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
                                    backgroundColor: const Color(0xFF7B1E2B),
                                    foregroundColor: Colors.white,
                                  ),

                                  child: Text(
                                    widget.modoSelecao
                                        ? 'Adicionar nesta rodada'
                                        : 'Adicionar ao pedido',
                                  ),
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
      bottomNavigationBar: widget.modoSelecao
          ? SafeArea(
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
            )
          : null,
    );
  }
}
