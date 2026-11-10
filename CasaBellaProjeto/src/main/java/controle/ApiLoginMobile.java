package controle;

import dao.FuncionariosDao;
import jakarta.json.Json;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.sql.SQLException;

@WebServlet(name = "ApiLogin", urlPatterns = {"/api/login"})
public class ApiLoginMobile extends HttpServlet {

    // POST /api/login  (email, senha)
    // 200 -> {"nome":"...","cargo":"...","email":"..."}
    // 401 -> {"erro":"E-mail ou senha inválidos."}
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        String email = request.getParameter("email");
        String senha = request.getParameter("senha");

        if (email == null || email.trim().isEmpty() || senha == null || senha.isEmpty()) {
            responder(response, HttpServletResponse.SC_BAD_REQUEST,
                    Json.createObjectBuilder().add("erro", "Informe e-mail e senha.").build().toString());
            return;
        }

        try {
            String[] func = new FuncionariosDao().logarMobile(email.trim(), senha);

            if (func == null) {
                responder(response, HttpServletResponse.SC_UNAUTHORIZED,
                        Json.createObjectBuilder().add("erro", "E-mail ou senha inválidos.").build().toString());
                return;
            }

            responder(response, HttpServletResponse.SC_OK,
                    Json.createObjectBuilder()
                            .add("nome", func[0] == null ? "" : func[0])
                            .add("cargo", func[1] == null ? "" : func[1])
                            .add("email", email.trim())
                            .build().toString());

        } catch (ClassNotFoundException | SQLException e) {
            e.printStackTrace();
            responder(response, HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    Json.createObjectBuilder().add("erro", "Erro ao fazer login.").build().toString());
        }
    }

    private void responder(HttpServletResponse response, int status, String json) throws IOException {
        response.setStatus(status);
        response.setContentType("application/json;charset=UTF-8");
        response.getWriter().write(json);
    }
}
