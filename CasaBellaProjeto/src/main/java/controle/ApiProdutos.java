//url api http://SEU_ID:8080/CasaBellaProjeto-1.0-SNAPSHOT/api/produtos


package controle;

import dao.ProdutosDao;
import jakarta.json.Json;
import jakarta.json.JsonArrayBuilder;
import jakarta.json.JsonObjectBuilder;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.sql.ResultSet;
import java.sql.SQLException;

@WebServlet(name = "ApiProdutos", urlPatterns = {"/api/produtos"})
public class ApiProdutos extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // Por padrão só os disponíveis (são os únicos que o pedido aceita).
        // /api/produtos?todos=true lista todos.
        boolean todos = "true".equalsIgnoreCase(request.getParameter("todos"));

        ResultSet rs = null;
        try {
            rs = new ProdutosDao().listarProdutos();
            JsonArrayBuilder lista = Json.createArrayBuilder();

            while (rs.next()) {
                String disponibilidade = rs.getString("disponibilidade");
                if (!todos && !"disponivel".equalsIgnoreCase(disponibilidade)) {
                    continue;
                }

                JsonObjectBuilder item = Json.createObjectBuilder();
                item.add("id_produto", rs.getInt("id_produto"));
                item.add("categoria", nuloSeVazio(rs.getString("categoria")));
                item.add("nome", nuloSeVazio(rs.getString("nome")));
                item.add("descricao", nuloSeVazio(rs.getString("descricao")));
                item.add("preco", rs.getBigDecimal("preco"));
                item.add("disponibilidade", nuloSeVazio(disponibilidade));
                lista.add(item);
            }

            response.setContentType("application/json;charset=UTF-8");
            response.getWriter().write(lista.build().toString());

        } catch (ClassNotFoundException | SQLException e) {
            e.printStackTrace();
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            response.setContentType("application/json;charset=UTF-8");
            response.getWriter().write(
                    Json.createObjectBuilder().add("erro", "Erro ao buscar produtos.").build().toString());
        } finally {
            // O listarProdutos() deixa a conexão aberta, então fechamos aqui
            try {
                if (rs != null) rs.getStatement().getConnection().close();
            } catch (SQLException ignorado) {
            }
        }
    }

    private String nuloSeVazio(String s) {
        return s == null ? "" : s;
    }
}
