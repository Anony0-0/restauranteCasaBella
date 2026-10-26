package controle;

import java.io.IOException;
import java.io.PrintWriter;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import dao.UsuariosDao;
import java.sql.SQLException;

@WebServlet(name = "ControleUsuario", urlPatterns = {"/ControleUsuario"})
public class ControleUsuario extends HttpServlet {

    protected void processRequest(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setContentType("text/html;charset=UTF-8");
        // Receber os dados enviados pelo formulário de cadastro
        String origem, email, nome, senha, cargo, admissao;
        int resultado;
        String mensagem="";
        origem = request.getParameter("origem");
        if (origem.equalsIgnoreCase("cadastrar")) {

            email = request.getParameter("email");
            nome = request.getParameter("nome");
            senha = request.getParameter("senha");
            cargo = request.getParameter("cargo");
            admissao = request.getParameter("admissao");
            // Chamar o método cadastrarUsuario da classe UsuarioDao
            UsuariosDao dao = new UsuariosDao();
            try {
                resultado = dao.cadastrarUsuario(email, nome, senha,cargo,admissao);
                if (resultado == 1) {
                    mensagem = "Usuário cadastrado com sucesso";
                } else {
                    mensagem = "Usuário não cadastrado";
                }
            } catch (ClassNotFoundException | SQLException erro) {
                if (erro.getMessage().contains("Duplicate entry")) {
                    mensagem = "Este e-mail já está cadastrado";
                } else {
                    mensagem = erro.getMessage();
                }
            }
            // Envia a mensagem para o arquivo mensagens.jsp
            request.setAttribute("mens", mensagem);
            request.getRequestDispatcher("mensagens.jsp").forward(request, response);
        } else if (origem.equalsIgnoreCase("logar")) {
            //Receber o email e a senha digitados
            email = request.getParameter("email");
            senha = request.getParameter("senha");
            // fazer o login
            UsuariosDao dao = new UsuariosDao();
            try {
                nome = dao.logar(email, senha);
                if (nome == null) { //Se não encontrou o usuário
                    mensagem = "Usuário e/ou senha inválidos";
                } else { //Se encontrou o usuário
                    // Envia o nome para o arquivo restrito.jsp
                    request.setAttribute("nome", nome);
                    request.getRequestDispatcher("restrito.jsp").forward(request, response);
                }
            } catch (ClassNotFoundException | SQLException erro) {
                mensagem = erro.getMessage();
            }
            // Envia a mensagem para o arquivo mensagens.jsp
            request.setAttribute("mens", mensagem);
            request.getRequestDispatcher("mensagens.jsp").forward(request, response);
        }
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processRequest(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processRequest(request, response);
    }

    @Override
    public String getServletInfo() {
        return "Short description";
    }

}
