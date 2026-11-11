package controle;

import dao.FuncionariosDao;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.sql.ResultSet;
import java.sql.SQLException;

@WebServlet(name = "ControleFuncionario", urlPatterns = {"/ControleFuncionario"})
public class ControleFuncionario extends HttpServlet {

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

            FuncionariosDao dao = new FuncionariosDao();

            ResultSet rs = dao.listarFuncionarios();

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
            String id_func= request.getParameter("id_func");
            String nome = request.getParameter("nome");
            String usermobi = request.getParameter("usermobi");
            String email = request.getParameter("email");
            String senha = request.getParameter("senha");
            String cargo = request.getParameter("cargo");
            String admissao = request.getParameter("admissao");

            try {
                int resultado = new FuncionariosDao().cadastrarFuncionarios(id_func, nome, usermobi, email, senha, cargo, admissao);
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

