package controle;

import dao.*;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.sql.ResultSet;
import java.sql.SQLException;

@WebServlet(name = "PainelGerenciamento",urlPatterns = {"/PainelGerenciamento"})

public class PainelGerenciamento extends HttpServlet {


    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        try {
            // 1. Recebe os parâmetros enviados pelos formulários
            String aba = request.getParameter("aba");
            String busca = request.getParameter("busca");
            String mesa = request.getParameter("mesa");

            // Trata parâmetros que não foram enviados
            if (aba == null || aba.isEmpty()) {
                aba = "pedidos";
            }

            if (busca == null) {
                busca = "";
            }

            if (mesa == null) {
                mesa = "";
            }

            busca = busca.trim();

            // 2. Guarda os valores para a JSP
            request.setAttribute("aba", aba);
            request.setAttribute("busca", busca);
            request.setAttribute("mesa", mesa);

            // 3. Carrega os pedidos
            PedidosDao pedidosDao = new PedidosDao();

            // Filtro das abinhas (Em preparo / Concluídos / Cancelados)
            String statusParam = request.getParameter("status");
            String statusFiltro = null;
            if ("preparo".equals(statusParam)) {
                statusFiltro = "em preparo";
            } else if ("concluido".equals(statusParam)) {
                statusFiltro = "concluido";
            } else if ("cancelado".equals(statusParam)) {
                statusFiltro = "cancelado";
            }

            if ("pedidos".equals(aba) && (!busca.isEmpty() || !mesa.isEmpty())) {
                request.setAttribute("pedidos", pedidosDao.buscarPedidos(busca, mesa));
            } else if ("pedidos".equals(aba) && statusFiltro != null) {
                request.setAttribute("pedidos", pedidosDao.listarPedidosPorStatus(statusFiltro));
            } else {
                request.setAttribute("pedidos", pedidosDao.listarPedidos());
            }

            // Mesas para o filtro da aba Pedidos
            request.setAttribute("mesas", pedidosDao.listarMesas());

            // 4. Carrega os funcionários
            FuncionariosDao funcionariosDao = new FuncionariosDao();

            if ("funcionarios".equals(aba) && !busca.isEmpty()) {
                request.setAttribute("funcionarios", funcionariosDao.buscarFuncionarios(busca));
            } else {
                request.setAttribute("funcionarios", funcionariosDao.listarFuncionarios());
            }

            // 5. Carrega os clientes
            ClientesDao clientesDao = new ClientesDao();

            if ("clientes".equals(aba) && !busca.isEmpty()) {
                request.setAttribute("clientes", clientesDao.buscarClientes(busca));
            } else {
                request.setAttribute("clientes", clientesDao.listarClientes());
            }

            // 6. Carrega as reservas
            ReservasDao reservasDao = new ReservasDao();

            if ("reservas".equals(aba) && !busca.isEmpty()) {
                request.setAttribute("reservas", reservasDao.buscarReservas(busca));
            } else {
                request.setAttribute("reservas", reservasDao.listarReservas());
            }

            // 7. Carrega os produtos
            ProdutosDao produtosDao = new ProdutosDao();

            if ("produtos".equals(aba) && !busca.isEmpty()) {
                request.setAttribute("produtos", produtosDao.buscarProdutos(busca));
            } else {
                request.setAttribute("produtos", produtosDao.listarProdutos());
            }

            // 8. Encaminha para a página
            request.getRequestDispatcher("/gerenciamento.jsp").forward(request, response);

        } catch (ClassNotFoundException | SQLException e) {
            throw new ServletException("Erro ao carregar o painel de gerenciamento.", e);
        }
    }
}

