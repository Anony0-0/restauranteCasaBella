package controle;

import dao.UsuariosDao;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.sql.ResultSet;
import java.sql.SQLException;

@WebServlet(name = "ControleUsuario", urlPatterns = {"/ControleUsuario"})
public class ControleUsuario extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        System.out.println("ENTROU NO CONTROLE USUARIO!");

        String origem = request.getParameter("origem");

        if ("listarFuncionarios".equalsIgnoreCase(origem)) {

            listarFuncionarios(request, response);

        } else {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST,
                    "Origem inválida.");
        }
    }

    private void listarFuncionarios(HttpServletRequest request,
                                    HttpServletResponse response)
            throws ServletException, IOException {

        try {

            System.out.println("ENTROU NO METODO LISTAR FUNCIONARIOS!");

            UsuariosDao dao = new UsuariosDao();

            ResultSet rs = dao.listarUsuarios();

            System.out.println("CONSULTA AO BANCO EXECUTADA!");

            request.setAttribute("funcionarios", rs);

            System.out.println("ATRIBUTO ENVIADO AO JSP!");

            request.getRequestDispatcher("/gerenciamento.jsp")
                    .forward(request, response);

        } catch (ClassNotFoundException | SQLException e) {

            e.printStackTrace();

            throw new ServletException(e);
        }
    }
}
