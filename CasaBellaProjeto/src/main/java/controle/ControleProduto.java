package controle;

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

        } else {
            mensagem = "Operação inválida.";
        }

        request.setAttribute("mens", mensagem);
        request.getRequestDispatcher("mensagens.jsp").forward(request, response);
    }
}
