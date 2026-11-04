package controle;

import dao.ReservasDao;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeParseException;

@WebServlet(name = "ControleReserva", urlPatterns = {"/ControleReserva"})
public class ControleReserva extends HttpServlet {

    private static final int MAX_PESSOAS = 6; // maior mesa cadastrada no banco

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        response.setContentType("text/html;charset=UTF-8");

        HttpSession sessao = request.getSession(false);
        if (sessao == null || !"cliente".equals(sessao.getAttribute("perfil"))) {
            response.sendRedirect("login.html");
            return;
        }

        String email = (String) sessao.getAttribute("email");
        String mensagem;

        try {
            LocalDate data = LocalDate.parse(request.getParameter("data"));
            LocalTime hora = LocalTime.parse(request.getParameter("hora"));
            int pessoas = Integer.parseInt(request.getParameter("pessoas"));
            LocalDateTime horario = LocalDateTime.of(data, hora);

            mensagem = validar(horario, pessoas);

            if (mensagem == null) {
                int resultado = new ReservasDao().reservar(email, Timestamp.valueOf(horario), pessoas);
                if (resultado == 1) {
                    mensagem = "Reserva solicitada com sucesso";
                } else if (resultado == 0) {
                    mensagem = "Não há mesa disponível para esse horário. Tente outro horário.";
                } else {
                    mensagem = "Não encontramos o seu cadastro. Entre novamente na sua conta.";
                }
            }
        } catch (DateTimeParseException | NumberFormatException | NullPointerException erro) {
            mensagem = "Dados da reserva inválidos.";
        } catch (ClassNotFoundException | SQLException erro) {
            mensagem = erro.getMessage();
        }

        request.setAttribute("mens", mensagem);
        request.getRequestDispatcher("mensagens.jsp").forward(request, response);
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.sendRedirect("reservas.jsp");
    }

    private String validar(LocalDateTime horario, int pessoas) {
        if (pessoas < 1 || pessoas > MAX_PESSOAS) {
            return "Para grupos acima de " + MAX_PESSOAS + " pessoas, ligue para (11) 3040-5060.";
        }
        if (!horario.isAfter(LocalDateTime.now())) {
            return "Escolha uma data e um horário futuros.";
        }

        DayOfWeek dia = horario.getDayOfWeek();
        if (dia == DayOfWeek.MONDAY) {
            return "Não abrimos às segundas-feiras.";
        }

        boolean fimDeSemana = (dia == DayOfWeek.SATURDAY || dia == DayOfWeek.SUNDAY);
        LocalTime abre = fimDeSemana ? LocalTime.of(12, 0) : LocalTime.of(18, 0);
        LocalTime ultima = LocalTime.of(22, 0);

        if (horario.toLocalTime().isBefore(abre) || horario.toLocalTime().isAfter(ultima)) {
            return "Nesse dia recebemos reservas das " + abre + " às " + ultima + ".";
        }
        return null;
    }
}
