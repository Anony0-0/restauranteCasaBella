package controle;


import dao.ItensPedidoDao;
import dao.PedidosDao;
import dao.ProdutosDao;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.net.URLEncoder;
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
        } else if ("verPedido".equalsIgnoreCase(origem)) {   // NOVO
            verPedido(request, response);
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

    private void verPedido(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        try {
            int idPedido = Integer.parseInt(request.getParameter("id").trim());

            request.setAttribute("pedido", new PedidosDao().buscarPorId(idPedido));
            request.setAttribute("itens", new ItensPedidoDao().listarPorPedido(idPedido));
            request.setAttribute("produtos", new ProdutosDao().listarDisponiveis());

            request.getRequestDispatcher("/gerenciamentoAdmins/pedido.jsp").forward(request, response);

        } catch (NumberFormatException | NullPointerException e) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Pedido inválido.");
        } catch (ClassNotFoundException | SQLException e) {
            e.printStackTrace();
            throw new ServletException(e);
        }
    }



    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        String origem = request.getParameter("origem");

        if ("cadastrarPedido".equalsIgnoreCase(origem)) {
            cadastrarPedido(request, response);
        } else if ("adicionarItem".equalsIgnoreCase(origem)) {
            adicionarItem(request, response);
        } else if ("adicionarItemPainel".equalsIgnoreCase(origem)) {
            adicionarItemPainel(request, response);
        } else if ("removerItem".equalsIgnoreCase(origem)) {
            removerItem(request, response);
        } else if ("finalizar".equalsIgnoreCase(origem)) {
            mudarStatus(request, response, "concluido");
        } else if ("cancelar".equalsIgnoreCase(origem)) {
            mudarStatus(request, response, "cancelado");
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

            // Mobile pede JSON; o web agora abre a tela do pedido (antes voltava para a lista)
            if ("json".equalsIgnoreCase(request.getParameter("formato"))) {
                response.setContentType("application/json;charset=UTF-8");
                response.getWriter().write("{\"id_pedido\":" + idPedido + "}");
            } else {
                response.sendRedirect("ControlePedidos?origem=verPedido&id=" + idPedido);
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

    // NOVO: mesma regra do adicionarItem, mas volta para a tela do pedido com aviso
    private void adicionarItemPainel(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        try {
            int idPedido = Integer.parseInt(request.getParameter("id_pedido").trim());
            int idProduto = Integer.parseInt(request.getParameter("id_produto").trim());
            int quantidade = Integer.parseInt(request.getParameter("quantidade").trim());

            if (quantidade < 1) {
                voltarParaPedido(response, request, idPedido, "Quantidade inválida.");
                return;
            }

            int resultado = new ItensPedidoDao().adicionarItem(idPedido, idProduto, quantidade);

            if (resultado == ItensPedidoDao.PEDIDO_FECHADO) {
                voltarParaPedido(response, request, idPedido, "Pedido não está aberto.");
            } else if (resultado == ItensPedidoDao.PRODUTO_INDISPONIVEL) {
                voltarParaPedido(response, request, idPedido, "Produto indisponível.");
            } else {
                voltarParaPedido(response, request, idPedido, null);
            }

        } catch (NumberFormatException | NullPointerException e) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Valores inválidos.");
        } catch (ClassNotFoundException | SQLException e) {
            e.printStackTrace();
            throw new ServletException(e);
        }
    }

    // NOVO
    private void removerItem(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        try {
            int idPedido = Integer.parseInt(request.getParameter("id_pedido").trim());
            int idItem = Integer.parseInt(request.getParameter("id_itens").trim());

            boolean ok = new ItensPedidoDao().removerItem(idPedido, idItem);

            voltarParaPedido(response, request, idPedido, ok ? null : "Não foi possível remover o item.");

        } catch (NumberFormatException | NullPointerException e) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Valores inválidos.");
        } catch (ClassNotFoundException | SQLException e) {
            e.printStackTrace();
            throw new ServletException(e);
        }
    }

    // NOVO: finalizar ("concluido") e cancelar ("cancelado") usam o mesmo método
    private void mudarStatus(HttpServletRequest request, HttpServletResponse response, String novoStatus)
            throws ServletException, IOException {

        try {
            int idPedido = Integer.parseInt(request.getParameter("id_pedido").trim());

            int linhas = new PedidosDao().atualizarStatus(idPedido, novoStatus);

            // O gerenciamento.jsp lê o aviso da SESSÃO (e mostra uma vez só)
            if (linhas == 0) {
                request.getSession().setAttribute("aviso", "O pedido já estava fechado.");
            }
            response.sendRedirect(request.getContextPath() + "/PainelGerenciamento?aba=pedidos");

        } catch (NumberFormatException | NullPointerException e) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Valores inválidos.");
        } catch (ClassNotFoundException | SQLException e) {
            e.printStackTrace();
            throw new ServletException(e);
        }
    }

    private void voltarParaPedido(HttpServletResponse response, HttpServletRequest request, int idPedido, String aviso)
            throws IOException {

        String url = request.getContextPath() + "/ControlePedidos?origem=verPedido&id=" + idPedido;
        if (aviso != null) {
            url += "&aviso=" + URLEncoder.encode(aviso, "UTF-8");
        }
        response.sendRedirect(url);
    }

}
