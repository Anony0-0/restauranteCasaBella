package controle;

import dao.ItensPedidoDao;
import dao.PedidosDao;
import jakarta.json.Json;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.sql.SQLException;

@WebServlet(name = "ApiPedidos", urlPatterns = {"/api/pedidos", "/api/pedidos/itens"})
public class ApiPedidos extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        if (request.getServletPath().endsWith("/itens")) {
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
}
