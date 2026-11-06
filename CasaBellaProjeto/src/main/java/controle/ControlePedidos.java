package controle;


import dao.ItensPedidoDao;
import dao.PedidosDao;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.sql.ResultSet;
import java.sql.SQLException;

@WebServlet(name = "ControlePedidos", urlPatterns = {"/ControlePedidos"})
public class ControlePedidos extends HttpServlet {

    @Override

    protected void doGet(HttpServletRequest request, HttpServletResponse response)
        throws ServletException, IOException{

        String origem = request.getParameter("origem");

        if ("listarPedidos".equalsIgnoreCase(origem)){
            listarPedidos(request,response);
        }else {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST,"Origem Inválida.");
        }
    }

    private void listarPedidos(HttpServletRequest request, HttpServletResponse response)
        throws ServletException, IOException{

        try {
            PedidosDao dao = new PedidosDao();

            ResultSet rs = dao.listarPedidos();

            request.setAttribute("pedidos",rs);

            request.getRequestDispatcher("/gerenciamento.jsp").forward(request,response);

        }catch (ClassNotFoundException | SQLException e){
            e.printStackTrace();

            throw new ServletException(e);
        }

    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String origem = request.getParameter("origem");

        if ("cadastrarPedido".equalsIgnoreCase(origem)) {
            cadastrarPedido(request, response);
        } else if ("adicionarItem".equalsIgnoreCase(origem)) {
            adicionarItem(request, response);
        } else {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Origem Inválida.");
        }
    }

    private void cadastrarPedido(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        try {
            String sReserva = request.getParameter("id_reserva");
            String sMesa = request.getParameter("id_mesa");

            Integer idReserva = (sReserva == null || sReserva.trim().isEmpty()) ? null : Integer.valueOf(sReserva.trim());
            Integer idMesa = (sMesa == null || sMesa.trim().isEmpty()) ? null : Integer.valueOf(sMesa.trim());

            if (idReserva == null && idMesa == null) {
                response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Informe a reserva ou a mesa.");
                return;
            }

            int idPedido = new PedidosDao().cadastrarPedido(idReserva, idMesa);

            if (idPedido == 0) {
                response.sendError(HttpServletResponse.SC_CONFLICT, "Não há reserva confirmada para essa mesa/reserva.");
                return;
            }

            // Mobile pede JSON; o web redireciona para a lista
            if ("json".equalsIgnoreCase(request.getParameter("formato"))) {
                response.setContentType("application/json;charset=UTF-8");
                response.getWriter().write("{\"id_pedido\":" + idPedido + "}");
            } else {
                response.sendRedirect("PainelGerenciamento");
            }

        } catch (NumberFormatException e) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Valores inválidos.");
        } catch (ClassNotFoundException | SQLException e) {
            e.printStackTrace();
            throw new ServletException(e);
        }
    }

    private void adicionarItem(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        try {
            int idPedido = Integer.parseInt(request.getParameter("id_pedido").trim());
            int idProduto = Integer.parseInt(request.getParameter("id_produto").trim());
            int quantidade = Integer.parseInt(request.getParameter("quantidade").trim());

            if (quantidade < 1) {
                response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Quantidade inválida.");
                return;
            }

            int resultado = new ItensPedidoDao().adicionarItem(idPedido, idProduto, quantidade);

            if (resultado == ItensPedidoDao.PEDIDO_FECHADO) {
                response.sendError(HttpServletResponse.SC_CONFLICT, "Pedido não está aberto.");
            } else if (resultado == ItensPedidoDao.PRODUTO_INDISPONIVEL) {
                response.sendError(HttpServletResponse.SC_CONFLICT, "Produto indisponível.");
            } else {
                response.setContentType("application/json;charset=UTF-8");
                response.getWriter().write("{\"ok\":true}");
            }

        } catch (NumberFormatException | NullPointerException e) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Valores inválidos.");
        } catch (ClassNotFoundException | SQLException e) {
            e.printStackTrace();
            throw new ServletException(e);
        }
    }

}
