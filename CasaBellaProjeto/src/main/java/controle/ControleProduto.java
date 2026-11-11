package controle;

import dao.ClientesDao;
import dao.ProdutosDao;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.math.BigDecimal;
import java.sql.SQLException;

@WebServlet(name = "ControleProduto", urlPatterns = {"/ControleProduto"})
public class ControleProduto extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        String origem = request.getParameter("origem");

        if ("editar".equalsIgnoreCase(origem)) {
            try {
                int id_produto = Integer.parseInt(request.getParameter("id_produto"));
                String[] produto = new ProdutosDao().buscarPorID(id_produto);

                if (produto == null) {
                    request.setAttribute("mens", "Produto não encontrado.");
                    request.getRequestDispatcher("mensagens.jsp").forward(request, response);
                    return;
                }

                request.setAttribute("produto", produto);
                request.getRequestDispatcher("/gerenciamentoAdmins/alterarProdutos.jsp").forward(request, response);
                return;

            } catch (NumberFormatException | NullPointerException erro) {
                request.setAttribute("mens", "ID do produto inválido.");
            } catch (ClassNotFoundException | SQLException erro) {
                erro.printStackTrace();
                request.setAttribute("mens", "Não foi possível carregar o produto agora.");
            }
            request.getRequestDispatcher("mensagens.jsp").forward(request, response);
            return;
        }

        response.sendRedirect("PainelGerenciamento?aba=produtos");
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        response.setContentType("text/html;charset=UTF-8");

        String origem = request.getParameter("origem");
        String mensagem;

        if ("cadastrar".equalsIgnoreCase(origem)) {

            String categoria = request.getParameter("categoria");
            String nome = request.getParameter("nome");
            String descricao = request.getParameter("descricao");
            boolean disponivel = "disponivel".equals(request.getParameter("disponibilidade"));

            try {
                int id_produto = Integer.parseInt(request.getParameter("id_produto"));

                // Aceita "32,90", "32.90" e "R$ 32,90"
                String textoPreco = request.getParameter("preco")
                        .replace("R$", "").replace(" ", "").replace(",", ".");
                BigDecimal preco = new BigDecimal(textoPreco);

                if (id_produto < 1) {
                    mensagem = "O ID deve ser um número maior que zero.";
                } else if (preco.compareTo(BigDecimal.ZERO) <= 0) {
                    mensagem = "O preço deve ser maior que zero.";
                } else {
                    int resultado = new ProdutosDao()
                            .cadastrarProduto(id_produto, categoria, nome, descricao, preco, disponivel);

                    if (resultado == 1) {
                        request.getSession().setAttribute("aviso", "Produto cadastrado com sucesso.");
                        response.sendRedirect("PainelGerenciamento?aba=produtos");
                        return;
                    }
                    mensagem = "Produto não cadastrado.";
                }
            } catch (NumberFormatException | NullPointerException erro) {
                mensagem = "ID ou preço inválido.";
            } catch (ClassNotFoundException | SQLException erro) {
                if (erro.getMessage() != null && erro.getMessage().contains("Duplicate entry")) {
                    mensagem = "Já existe um produto com esse ID.";
                } else {
                    erro.printStackTrace();
                    mensagem = "Não foi possível cadastrar o produto agora.";
                }
            }

        }   else if ("atualizar".equalsIgnoreCase(origem)) {
        atualizar(request, response);
        return;

    } else {
        mensagem = "Operação inválida.";
    }

        request.setAttribute("mens", mensagem);
        request.getRequestDispatcher("mensagens.jsp").forward(request, response);


    }

    private void atualizar(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String idOriginalTexto = request.getParameter("id_original");
        String idTexto = request.getParameter("id_produto");
        String categoria = request.getParameter("categoria");
        String nome = request.getParameter("nome");
        String descricao = request.getParameter("descricao");
        String precoTexto = request.getParameter("preco");
        String disponibilidade = request.getParameter("disponibilidade");

        boolean disponivel = "disponivel".equals(disponibilidade);

        String[] produto = {
                idTexto, categoria, nome, descricao, precoTexto, disponibilidade
        };

        String erroMsg;

        try {
            int id_original = Integer.parseInt(idOriginalTexto);
            int id_produto = Integer.parseInt(idTexto);

            String textoPreco = precoTexto
                    .replace("R$", "")
                    .replace(" ", "")
                    .replace(",", ".");

            BigDecimal preco = new BigDecimal(textoPreco);

            if (id_produto < 1) {
                erroMsg = "O ID deve ser um número maior que zero.";

            } else if (nome == null || nome.trim().isEmpty()) {
                erroMsg = "Informe o nome do produto.";

            } else if (preco.compareTo(BigDecimal.ZERO) <= 0) {
                erroMsg = "O preço deve ser maior que zero.";

            } else {
                int resultado = new ProdutosDao().atualizarProduto(
                        id_original, id_produto, categoria,
                        nome.trim(), descricao, preco, disponivel);

                if (resultado == 1) {
                    request.getSession().setAttribute(
                            "aviso", "Produto atualizado com sucesso.");

                    response.sendRedirect("PainelGerenciamento?aba=produtos");
                    return;
                }

                erroMsg = "Produto não encontrado ou nenhuma alteração feita.";
            }

        } catch (NumberFormatException | NullPointerException erro) {
            erroMsg = "ID ou preço inválido.";

        } catch (ClassNotFoundException | SQLException erro) {
            erro.printStackTrace();
            erroMsg = "Não foi possível atualizar o produto agora.";
        }

        request.setAttribute("produto", produto);
        request.setAttribute("idOriginal", idOriginalTexto);
        request.setAttribute("erro", erroMsg);

        request.getRequestDispatcher(
                        "/gerenciamentoAdmins/alterarProdutos.jsp")
                .forward(request, response);
    }


    private void excluirPeloPainel(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

    }

}
