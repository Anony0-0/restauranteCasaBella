//urls pedidos:
// criar pedido:       POST http://SEU_IP:8080/CasaBellaProjeto-1.0-SNAPSHOT/api/pedidos
// adicionar produto:  POST http://SEU_IP:8080/CasaBellaProjeto-1.0-SNAPSHOT/api/pedidos/itens
// remover item:       POST http://SEU_IP:8080/CasaBellaProjeto-1.0-SNAPSHOT/api/pedidos/itens/remover
// listar pedidos:     GET  http://SEU_IP:8080/CasaBellaProjeto-1.0-SNAPSHOT/api/pedidos
// ver um pedido:      GET  http://SEU_IP:8080/CasaBellaProjeto-1.0-SNAPSHOT/api/pedidos?id=

//final url = Uri.parse('http://SEU_IP:8080/CasaBellaProjeto-1.0-SNAPSHOT/api/pedidos?id=$idPedido');  //exemplo que como ficaria o link de ver pedido no flutter


package controle;

import dao.ItensPedidoDao;
import dao.PedidosDao;
import jakarta.json.Json;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.json.JsonArray;
import jakarta.json.JsonArrayBuilder;
import jakarta.json.JsonObjectBuilder;
import java.math.BigDecimal;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;

import java.io.IOException;
import java.sql.SQLException;

@WebServlet(name = "ApiPedidos", urlPatterns = {"/api/pedidos", "/api/pedidos/itens"})
public class ApiPedidos extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        String caminho = request.getServletPath();

        if (caminho.endsWith("/itens/remover")) {
            removerItem(request, response);
        } else if (caminho.endsWith("/itens")) {
            adicionarItem(request, response);
        } else {
            cadastrarPedido(request, response);
        }
    }

    // POST /api/pedidos  (id_reserva OU id_mesa)  ->  {"id_pedido": 12}
    private void cadastrarPedido(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        try {
            Integer idReserva = lerInteiroOpcional(request.getParameter("id_reserva"));
            Integer idMesa = lerInteiroOpcional(request.getParameter("id_mesa"));

            if (idReserva == null && idMesa == null) {
                responderErro(response, HttpServletResponse.SC_BAD_REQUEST, "Informe a reserva ou a mesa.");
                return;
            }

            int idPedido = new PedidosDao().cadastrarPedido(idReserva, idMesa);

            if (idPedido == 0) {
                responderErro(response, HttpServletResponse.SC_CONFLICT,
                        "Não há reserva confirmada para essa mesa/reserva.");
                return;
            }

            responderJson(response, HttpServletResponse.SC_OK,
                    Json.createObjectBuilder().add("id_pedido", idPedido).build().toString());

        } catch (NumberFormatException e) {
            responderErro(response, HttpServletResponse.SC_BAD_REQUEST, "Valores inválidos.");
        } catch (ClassNotFoundException | SQLException e) {
            e.printStackTrace();
            responderErro(response, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Erro ao cadastrar pedido.");
        }
    }

    // POST /api/pedidos/itens  (id_pedido, id_produto, quantidade)  ->  {"ok": true}
    private void adicionarItem(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        try {
            Integer idPedido = lerInteiroOpcional(request.getParameter("id_pedido"));
            Integer idProduto = lerInteiroOpcional(request.getParameter("id_produto"));
            Integer quantidade = lerInteiroOpcional(request.getParameter("quantidade"));

            if (idPedido == null || idProduto == null || quantidade == null || quantidade < 1) {
                responderErro(response, HttpServletResponse.SC_BAD_REQUEST, "Valores inválidos.");
                return;
            }

            int resultado = new ItensPedidoDao().adicionarItem(idPedido, idProduto, quantidade);

            if (resultado == ItensPedidoDao.PEDIDO_FECHADO) {
                responderErro(response, HttpServletResponse.SC_CONFLICT, "Pedido não está aberto.");
            } else if (resultado == ItensPedidoDao.PRODUTO_INDISPONIVEL) {
                responderErro(response, HttpServletResponse.SC_CONFLICT, "Produto indisponível.");
            } else {
                responderJson(response, HttpServletResponse.SC_OK,
                        Json.createObjectBuilder().add("ok", true).build().toString());
            }

        } catch (NumberFormatException e) {
            responderErro(response, HttpServletResponse.SC_BAD_REQUEST, "Valores inválidos.");
        } catch (ClassNotFoundException | SQLException e) {
            e.printStackTrace();
            responderErro(response, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Erro ao adicionar item.");
        }
    }

    // Vazio/null -> null; senão converte (lança NumberFormatException se não for número)
    private Integer lerInteiroOpcional(String s) {
        return (s == null || s.trim().isEmpty()) ? null : Integer.valueOf(s.trim());
    }

    private void responderJson(HttpServletResponse response, int status, String json) throws IOException {
        response.setStatus(status);
        response.setContentType("application/json;charset=UTF-8");
        response.getWriter().write(json);
    }

    private void responderErro(HttpServletResponse response, int status, String mensagem) throws IOException {
        responderJson(response, status,
                Json.createObjectBuilder().add("erro", mensagem).build().toString());
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        if (request.getParameter("id") != null) {
            verPedido(request, response);
        } else {
            listarPedidos(response);
        }
    }

    // GET /api/pedidos  ->  [ {...}, {...} ]
    private void listarPedidos(HttpServletResponse response) throws IOException {
        try {
            ResultSet rs = new PedidosDao().listarPedidos();
            responderJson(response, HttpServletResponse.SC_OK, resultSetParaJson(rs).toString());

        } catch (ClassNotFoundException | SQLException e) {
            e.printStackTrace();
            responderErro(response, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Erro ao listar pedidos.");
        }
    }

    // GET /api/pedidos?id=12  ->  {"pedido": {...}, "itens": [...]}
    private void verPedido(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        try {
            Integer idPedido = lerInteiroOpcional(request.getParameter("id"));
            if (idPedido == null) {
                responderErro(response, HttpServletResponse.SC_BAD_REQUEST, "Pedido inválido.");
                return;
            }

            JsonArray pedido = resultSetParaJson(new PedidosDao().buscarPorId(idPedido));
            if (pedido.isEmpty()) {
                responderErro(response, HttpServletResponse.SC_NOT_FOUND, "Pedido não encontrado.");
                return;
            }

            JsonArray itens = resultSetParaJson(new ItensPedidoDao().listarPorPedido(idPedido));

            responderJson(response, HttpServletResponse.SC_OK,
                    Json.createObjectBuilder()
                            .add("pedido", pedido.get(0))
                            .add("itens", itens)
                            .build().toString());

        } catch (NumberFormatException e) {
            responderErro(response, HttpServletResponse.SC_BAD_REQUEST, "Pedido inválido.");
        } catch (ClassNotFoundException | SQLException e) {
            e.printStackTrace();
            responderErro(response, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Erro ao buscar pedido.");
        }
    }

    // POST /api/pedidos/itens/remover  (id_pedido, id_itens)  ->  {"ok": true}
    private void removerItem(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        try {
            Integer idPedido = lerInteiroOpcional(request.getParameter("id_pedido"));
            Integer idItem = lerInteiroOpcional(request.getParameter("id_itens"));

            if (idPedido == null || idItem == null) {
                responderErro(response, HttpServletResponse.SC_BAD_REQUEST, "Valores inválidos.");
                return;
            }

            boolean ok = new ItensPedidoDao().removerItem(idPedido, idItem);

            if (!ok) {
                responderErro(response, HttpServletResponse.SC_CONFLICT, "Não foi possível remover o item.");
                return;
            }

            responderJson(response, HttpServletResponse.SC_OK,
                    Json.createObjectBuilder().add("ok", true).build().toString());

        } catch (NumberFormatException e) {
            responderErro(response, HttpServletResponse.SC_BAD_REQUEST, "Valores inválidos.");
        } catch (ClassNotFoundException | SQLException e) {
            e.printStackTrace();
            responderErro(response, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Erro ao remover item.");
        }
    }
    private JsonArray resultSetParaJson(ResultSet rs) throws SQLException {
        JsonArrayBuilder lista = Json.createArrayBuilder();
        ResultSetMetaData md = rs.getMetaData();
        int colunas = md.getColumnCount();

        while (rs.next()) {
            JsonObjectBuilder obj = Json.createObjectBuilder();
            for (int i = 1; i <= colunas; i++) {
                String nome = md.getColumnLabel(i);
                Object v = rs.getObject(i);

                if (v == null) {
                    obj.addNull(nome);
                } else if (v instanceof Integer) {
                    obj.add(nome, (Integer) v);
                } else if (v instanceof Long) {
                    obj.add(nome, (Long) v);
                } else if (v instanceof BigDecimal) {
                    obj.add(nome, (BigDecimal) v);
                } else if (v instanceof Double) {
                    obj.add(nome, (Double) v);
                } else if (v instanceof Boolean) {
                    obj.add(nome, (Boolean) v);
                } else {
                    obj.add(nome, v.toString()); // datas, textos, enums...
                }
            }
            lista.add(obj);
        }
        return lista.build();
    }
}
