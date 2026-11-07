package controle;

import dao.ReservasDao;
import jakarta.json.Json;
import jakarta.json.JsonArrayBuilder;
import jakarta.json.JsonObjectBuilder;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;

@WebServlet(name = "ApiReservas", urlPatterns = {"/api/reservas"})
public class ApiReservas extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // Filtro opcional: /api/reservas?status=Confirmada
        String filtro = request.getParameter("status");

        ResultSet rs = null;
        try {
            rs = new ReservasDao().listarReservas();
            JsonArrayBuilder lista = Json.createArrayBuilder();

            while (rs.next()) {
                String status = rs.getString("status");
                if (filtro != null && !filtro.equalsIgnoreCase(status)) {
                    continue;
                }

                JsonObjectBuilder item = Json.createObjectBuilder();
                item.add("id_reserva", rs.getInt("id_reserva"));
                item.add("cliente", nuloSeVazio(rs.getString("cliente")));
                item.add("email", nuloSeVazio(rs.getString("email")));
                item.add("telefone", nuloSeVazio(rs.getString("telefone")));

                Timestamp horario = rs.getTimestamp("horario");
                item.add("horario", horario == null ? "" : horario.toLocalDateTime().toString());

                item.add("qtd_pessoas", rs.getInt("qtd_pessoas"));

                int mesa = rs.getInt("id_mesa");
                if (rs.wasNull()) {
                    item.addNull("id_mesa");
                } else {
                    item.add("id_mesa", mesa);
                }

                item.add("status", nuloSeVazio(status));
                lista.add(item);
            }

            response.setContentType("application/json;charset=UTF-8");
            response.getWriter().write(lista.build().toString());

        } catch (ClassNotFoundException | SQLException e) {
            e.printStackTrace();
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Erro ao buscar reservas.");
        } finally {
            // O listarReservas() deixa a conexão aberta, então fechamos aqui
            try {
                if (rs != null) rs.getStatement().getConnection().close();
            } catch (SQLException ignorado) {
            }
        }
    }

    private String nuloSeVazio(String s) {
        return s == null ? "" : s;
    }
}
