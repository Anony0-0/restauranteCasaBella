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

            // PEDIDOS
            PedidosDao pedidosDao = new PedidosDao();
            ResultSet pedidos = pedidosDao.listarPedidos();

            request.setAttribute("pedidos", pedidos);


            // FUNCIONÁRIOS
            UsuariosDao usuariosDao = new UsuariosDao();
            ResultSet funcionarios = usuariosDao.listarUsuarios();

            request.setAttribute("funcionarios", funcionarios);


            // CLIENTES
            ClientesDao clientesDao = new ClientesDao();
            ResultSet clientes = clientesDao.listarClientes();

            request.setAttribute("clientes", clientes);


            // RESERVAS
            ReservasDao reservasDao = new ReservasDao();
            ResultSet reservas = reservasDao.listarReservas();

            request.setAttribute("reservas", reservas);


            // PRODUTOS
            ProdutosDao produtosDao = new ProdutosDao();
            ResultSet produtos = produtosDao.listarProdutos();

            request.setAttribute("produtos", produtos);


            // ENVIAR TODOS OS DADOS PARA A JSP
            request.getRequestDispatcher("/gerenciamento.jsp")
                    .forward(request, response);

        } catch (ClassNotFoundException | SQLException e) {

            e.printStackTrace();

            throw new ServletException(
                    "Erro ao carregar os dados do painel.",
                    e
            );
        }

    }
}
