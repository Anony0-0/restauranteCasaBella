package controle;

import dao.ClientesDao;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.sql.SQLException;

@WebServlet(name = "ControleCliente", urlPatterns = {"/ControleCliente"})
public class ControleCliente extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8"); // antes de ler os parâmetros, para os acentos
        response.setContentType("text/html;charset=UTF-8");

        String origem = request.getParameter("origem");
        String mensagem;

        if ("cadastrar".equalsIgnoreCase(origem)) {
            String nome = request.getParameter("nome");
            String email = request.getParameter("email");
            String senha = request.getParameter("senha");
            String telefone = request.getParameter("telefone");

            try {
                int resultado = new ClientesDao().cadastrarCliente(nome, email, senha, telefone);
                mensagem = (resultado == 1) ? "Cliente cadastrado com sucesso" : "Cliente não cadastrado";
            } catch (ClassNotFoundException | SQLException erro) {
                if (erro.getMessage() != null && erro.getMessage().contains("Duplicate entry")) {
                    mensagem = "Este e-mail já está cadastrado";
                } else {
                    mensagem = erro.getMessage();
                }
            }
        }else if ("excluir".equalsIgnoreCase(origem)) {
            // Só cliente logado pode excluir. getSession(false) não cria sessão nova.
            HttpSession sessao = request.getSession(false);
            if (sessao == null || !"cliente".equals(sessao.getAttribute("perfil"))) {
                response.sendRedirect("login.html");
                return;
            }

            // O e-mail vem da sessão (do login), NUNCA do formulário
            String email = (String) sessao.getAttribute("email");
            String senha = request.getParameter("senha");

            try {
                ClientesDao dao = new ClientesDao();
                if (dao.logarCliente(email, senha) == null) {
                    mensagem = "Senha incorreta. Sua conta não foi excluída.";
                } else if (dao.excluirCliente(email) == 1) {
                    sessao.invalidate(); // encerra o login
                    mensagem = "Conta excluída com sucesso";
                } else {
                    mensagem = "Não foi possível excluir a conta.";
                }
            } catch (ClassNotFoundException | SQLException erro) {
                String texto = erro.getMessage();
                if (texto != null && texto.toLowerCase().contains("foreign key")) {
                    mensagem = "Não é possível excluir: existem reservas ou pedidos ligados à sua conta.";
                } else {
                    mensagem = texto;
                }
            }
        } else {
            mensagem = "Operação inválida.";
        }

        request.setAttribute("mens", mensagem);
        request.getRequestDispatcher("mensagens.jsp").forward(request, response);


    }
}
