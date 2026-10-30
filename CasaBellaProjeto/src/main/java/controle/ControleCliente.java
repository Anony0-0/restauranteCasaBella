package controle;

import dao.ClientesDao;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

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
        } else {
            mensagem = "Operação inválida.";
        }

        request.setAttribute("mens", mensagem);
        request.getRequestDispatcher("mensagens.jsp").forward(request, response);
    }
}
