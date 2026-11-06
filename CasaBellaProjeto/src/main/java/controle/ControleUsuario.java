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

    //LISTAR FUNCIONARIOS

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)

            throws ServletException, IOException {

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

            UsuariosDao dao = new UsuariosDao();

            ResultSet rs = dao.listarUsuarios();

            request.setAttribute("funcionarios", rs);

            request.getRequestDispatcher("/gerenciamento.jsp")
                    .forward(request, response);

        } catch (ClassNotFoundException | SQLException e) {

            e.printStackTrace();

            throw new ServletException(e);
        }
    }


    //CADASTRAR FUNCINARIOS
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
        throws ServletException, IOException{

        request.setCharacterEncoding("UTF-8");
        response.setContentType("text/html;charset=UTF8");

        String origem =  request.getParameter("origem");
        String mensagem;

        if ("cadastrar".equalsIgnoreCase(origem)) {
            String id_usuario = request.getParameter("id_usuario");
            String email = request.getParameter("email");
            String nome = request.getParameter("nome");
            String senha = request.getParameter("senha");
            String cargo = request.getParameter("cargo");
            String admissao = request.getParameter("admissao");

            try {
                int resultado = new UsuariosDao().cadastrarUsuario(id_usuario, email, nome, senha, cargo, admissao);
                if (resultado == 1) {
                    mensagem = "Funcionário cadastrado com sucesso!";
                } else {
                    mensagem = "Funcionário não cadastrado.";
                }

            } catch (ClassNotFoundException | SQLException erro) {

                erro.printStackTrace();

                if (erro.getMessage() != null &&
                        erro.getMessage().contains("Duplicate entry")) {

                    mensagem = "Este e-mail já está cadastrado.";

                } else {

                    mensagem = "Erro ao cadastrar funcionário: "
                            + erro.getMessage();
                }
            }




            request.setAttribute("mens", mensagem);

            request.getRequestDispatcher("/mensagens.jsp")
                    .forward(request, response);

        } else {

            response.sendError(
                    HttpServletResponse.SC_BAD_REQUEST,
                    "Origem inválida."
            );
        }
    }
}

