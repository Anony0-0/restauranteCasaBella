//url api: http://SEU_IP:8080/CasaBellaProjeto-1.0-SNAPSHOT/api/reservas

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

@WebServlet(name = "ApiReservas", urlPatterns = {"/api/reservas","/api/reservas/*"})
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
                item.add("status_pedido", nuloSeVazio(rs.getString("status_pedido")));
                lista.add(item);
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

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String acao = request.getParameter("acao");
        String idParam = request.getParameter("id");

        if (acao == null || idParam == null) {
            responder(response, HttpServletResponse.SC_BAD_REQUEST, false,
                    "Parâmetros 'acao' e 'id' são obrigatórios.", null);
            return;
        }

        int idReserva;
        try {
            idReserva = Integer.parseInt(idParam.trim());
        } catch (NumberFormatException e) {
            responder(response, HttpServletResponse.SC_BAD_REQUEST, false, "ID de reserva inválido.", null);
            return;
        }

        try {
            ReservasDao dao = new ReservasDao();

            switch (acao.trim().toLowerCase()) {
                case "confirmar": {
                    int linhas = dao.confirmarChegada(idReserva);
                    if (linhas > 0) {
                        responder(response, HttpServletResponse.SC_OK, true,
                                "Chegada confirmada com sucesso.", "Confirmada");
                    } else {
                        // Não existe ou não estava Pendente
                        responder(response, HttpServletResponse.SC_CONFLICT, false,
                                "Não foi possível confirmar: a reserva não existe ou não está pendente.", null);
                    }
                    break;
                }

                case "cancelar": {
                    int resultado = dao.cancelar(idReserva);
                    if (resultado > 0) {
                        responder(response, HttpServletResponse.SC_OK, true,
                                "Reserva cancelada com sucesso.", "Cancelada");
                    } else if (resultado == -1) {
                        responder(response, HttpServletResponse.SC_CONFLICT, false,
                                "Não é possível cancelar: já existe pedido ligado a esta reserva.", null);
                    } else {
                        responder(response, HttpServletResponse.SC_CONFLICT, false,
                                "Não foi possível cancelar: a reserva não existe ou já foi cancelada/concluída.", null);
                    }
                    break;
                }

                default:
                    responder(response, HttpServletResponse.SC_BAD_REQUEST, false,
                            "Ação inválida. Use 'confirmar' ou 'cancelar'.", null);
            }

        } catch (ClassNotFoundException | SQLException e) {
            e.printStackTrace();
            responder(response, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, false,
                    "Erro interno ao processar a reserva.", null);
        }
    }

    // Resposta JSON padronizada: {"sucesso":true,"mensagem":"...","status":"Confirmada"}
    private void responder(HttpServletResponse response, int httpStatus,
                           boolean sucesso, String mensagem, String novoStatus) throws IOException {
        JsonObjectBuilder json = Json.createObjectBuilder()
                .add("sucesso", sucesso)
                .add("mensagem", mensagem);
        if (novoStatus != null) {
            json.add("status", novoStatus);
        }

        response.setStatus(httpStatus);
        response.setContentType("application/json;charset=UTF-8");
        response.getWriter().write(json.build().toString());
    }

    private String nuloSeVazio(String s) {
        return s == null ? "" : s;
    }
}
