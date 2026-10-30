package controle;

import dao.ClientesDao;
import dao.UsuariosDao;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.sql.SQLException;

@WebServlet(name = "ControleLogin", urlPatterns = {"/ControleLogin"})
public class ControleLogin extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setContentType("text/html;charset=UTF-8");

        String email = request.getParameter("email");
        String senha = request.getParameter("senha");
        String mensagem;

        try {
            // 1) Procura primeiro na tabela de funcionários
            String nome = new UsuariosDao().logar(email, senha);
            if (nome != null) {
                guardarLogin(request, "funcionario", nome, email);
                request.getRequestDispatcher("gerenciamento.jsp").forward(request, response);
                return;
            }

            // 2) Se não achou, procura na tabela de clientes
            nome = new ClientesDao().logarCliente(email, senha);
            if (nome != null) {
                guardarLogin(request, "cliente", nome, email);
                request.getRequestDispatcher("areaCliente.jsp").forward(request, response);
                return;
            }

            // 3) Não achou em nenhuma das duas
            mensagem = "E-mail ou senha inválidos.";
        } catch (ClassNotFoundException | SQLException erro) {
            mensagem = erro.getMessage();
        }

        request.setAttribute("mens", mensagem);
        request.getRequestDispatcher("mensagens.jsp").forward(request, response);
    }

    // Quem tenta entrar por link (GET) volta para o login
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.sendRedirect("login.html");
    }

    // request: usado pela tela que aparece agora. sessão: usada pelas próximas.
    private void guardarLogin(HttpServletRequest request, String perfil, String nome, String email) {
        request.setAttribute("nome", nome);
        request.setAttribute("email", email);

        HttpSession sessao = request.getSession();
        sessao.setAttribute("perfil", perfil);
        sessao.setAttribute("nome", nome);
        sessao.setAttribute("email", email);
    }
}
