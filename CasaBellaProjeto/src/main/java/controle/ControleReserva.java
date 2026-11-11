package controle;

import dao.ReservasDao;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.sql.ResultSet;
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

        String origem = request.getParameter("origem");

        if ("cadastrarPainel".equalsIgnoreCase(origem)) {
            cadastrarPeloPainel(request, response);
            return;
        } else if ("confirmarChegada".equalsIgnoreCase(origem) || "cancelar".equalsIgnoreCase(origem)) {
            statusPeloPainel(request, response, origem);
            return;
        } else if ("atualizarPainel".equalsIgnoreCase(origem)) { // NOVO
            atualizarPeloPainel(request, response);
            return;
        }

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
            erro.printStackTrace();
            mensagem = "Não foi possível concluir a reserva agora. Tente novamente em instantes.";
        }

        definirBotoes(request, mensagem.toLowerCase().contains("sucesso"));
        request.setAttribute("mens", mensagem);
        request.getRequestDispatcher("mensagens.jsp").forward(request, response);
    }

    // Botões da tela de mensagem para o fluxo de reserva do cliente
    private void definirBotoes(HttpServletRequest request, boolean sucesso) {
        if (sucesso) {
            request.setAttribute("lead", "Sua reserva foi enviada e fica pendente até a confirmação da equipe.");
            request.setAttribute("btn1Url", "ControleReserva?origem=listarMinhas");
            request.setAttribute("btn1Texto", "Ver minhas reservas");
            request.setAttribute("btn2Url", "index.html");
            request.setAttribute("btn2Texto", "Voltar ao início");
        } else {
            request.setAttribute("btn1Url", "reservas.jsp");
            request.setAttribute("btn1Texto", "Tentar novamente");
            request.setAttribute("btn2Url", "ControleReserva?origem=listarMinhas");
            request.setAttribute("btn2Texto", "Voltar à minha área");
        }
    }


    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String origem = request.getParameter("origem");

        if ("listarMinhas".equalsIgnoreCase(origem)) {
            listarMinhasReservas(request, response);
        } else if ("editar".equalsIgnoreCase(origem)) { // NOVO
            abrirEdicaoPeloPainel(request, response);
        } else {
            response.sendRedirect("reservas.jsp");
        }
    }

    // Lista as reservas do cliente logado na área do cliente
    private void listarMinhasReservas(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        System.out.println(">>> listarMinhasReservas foi chamado");
        HttpSession sessao = request.getSession(false);
        if (sessao == null || !"cliente".equals(sessao.getAttribute("perfil"))) {
            response.sendRedirect("login.html");
            return;
        }

        Integer idCliente = (Integer) sessao.getAttribute("id_cliente");
        System.out.println(">>> id_cliente na sessão: " + idCliente);

        try {
            if (idCliente != null) {
                ResultSet rs = new ReservasDao().listarReservasPorCliente(idCliente);
                request.setAttribute("reservas", rs);
            }
            request.getRequestDispatcher("/areaCliente.jsp").forward(request, response);

        } catch (ClassNotFoundException | SQLException e) {
            e.printStackTrace();
            throw new ServletException(e);
        }
    }

    // Cadastro de reserva feito pela equipe, pelo painel
    private void cadastrarPeloPainel(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        if (!ehFuncionario(request)) {
            response.sendRedirect("login.html");
            return;
        }

        String erro = null;
        try {
            String email = request.getParameter("email");
            LocalDate data = LocalDate.parse(request.getParameter("data"));
            LocalTime hora = LocalTime.parse(request.getParameter("hora"));
            int pessoas = Integer.parseInt(request.getParameter("pessoas"));
            LocalDateTime horario = LocalDateTime.of(data, hora);

            erro = validar(horario, pessoas); // as mesmas regras do cliente

            if (erro == null) {
                int resultado = new ReservasDao().reservar(email.trim(), Timestamp.valueOf(horario), pessoas);

                if (resultado == 1) {
                    request.getSession().setAttribute("aviso", "Reserva cadastrada com sucesso.");
                    response.sendRedirect("PainelGerenciamento?aba=reservas");
                    return;
                } else if (resultado == 0) {
                    erro = "Não há mesa disponível para esse horário. Tente outro horário.";
                } else {
                    erro = "Cliente não encontrado. Confira o e-mail ou cadastre o cliente antes.";
                }
            }
        } catch (DateTimeParseException | NumberFormatException | NullPointerException e) {
            erro = "Dados da reserva inválidos.";
        } catch (ClassNotFoundException | SQLException e) {
            e.printStackTrace();
            erro = "Não foi possível cadastrar a reserva agora.";
        }

        // Em caso de erro, volta para o formulário com a mensagem
        request.setAttribute("erro", erro);
        request.getRequestDispatcher("/gerenciamentoAdmins/cadastroReserva.jsp").forward(request, response);
    }

    // NOVO: abre o formulário de edição da reserva
    private void abrirEdicaoPeloPainel(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        if (!ehFuncionario(request)) {
            response.sendRedirect("login.html");
            return;
        }
        try {
            int id = Integer.parseInt(request.getParameter("id").trim());
            String[] reserva = new ReservasDao().buscarParaEdicao(id);

            if (reserva == null) {
                response.sendError(HttpServletResponse.SC_NOT_FOUND, "Reserva não encontrada.");
                return;
            }
            String status = reserva[5];
            if (!"pendente".equalsIgnoreCase(status) && !"confirmada".equalsIgnoreCase(status)) {
                request.getSession().setAttribute("aviso", "Só reservas pendentes ou confirmadas podem ser editadas.");
                response.sendRedirect("PainelGerenciamento?aba=reservas");
                return;
            }
            request.setAttribute("reserva", reserva);
            request.getRequestDispatcher("/gerenciamentoAdmins/alterarReservas.jsp").forward(request, response);

        } catch (NumberFormatException | NullPointerException e) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Reserva inválida.");
        } catch (ClassNotFoundException | SQLException e) {
            e.printStackTrace();
            throw new ServletException(e);
        }
    }

    // NOVO: salva a edição da reserva
    private void atualizarPeloPainel(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        if (!ehFuncionario(request)) {
            response.sendRedirect("login.html");
            return;
        }
        try {
            int id = Integer.parseInt(request.getParameter("id_reserva").trim());
            LocalDate data = LocalDate.parse(request.getParameter("data"));
            LocalTime hora = LocalTime.parse(request.getParameter("hora"));
            int pessoas = Integer.parseInt(request.getParameter("pessoas"));
            LocalDateTime horario = LocalDateTime.of(data, hora);

            ReservasDao dao = new ReservasDao();
            String[] atual = dao.buscarParaEdicao(id);
            if (atual == null) {
                request.getSession().setAttribute("aviso", "Reserva não encontrada.");
                response.sendRedirect("PainelGerenciamento?aba=reservas");
                return;
            }

            // Só exige horário futuro se a data/hora foram mudadas
            boolean mudouHorario = !(data.toString().equals(atual[2])
                    && hora.equals(LocalTime.parse(atual[3])));
            String erro = validar(horario, pessoas, mudouHorario);

            if (erro == null) {
                String status = atual[5];

                if (!"pendente".equalsIgnoreCase(status) && !"confirmada".equalsIgnoreCase(status)) {
                    erro = "Só reservas pendentes ou confirmadas podem ser editadas.";
                } else if (dao.reservaTemPedido(id)) {
                    erro = "Esta reserva já tem pedido e não pode ser alterada.";
                } else {
                    int mesa = dao.escolherMesa(id, pessoas, Timestamp.valueOf(horario), dao.mesaDaReserva(id));

                    if (mesa == 0) {
                        erro = "Não há mesa disponível para esse horário e quantidade de pessoas.";
                    } else {
                        dao.atualizarReserva(id, Timestamp.valueOf(horario), pessoas, mesa);
                        request.getSession().setAttribute("aviso", "Reserva atualizada com sucesso.");
                        response.sendRedirect("PainelGerenciamento?aba=reservas");
                        return;
                    }
                }
            }

            // Com erro, volta para o formulário (os campos continuam como foram digitados)
            request.setAttribute("reserva", atual);
            request.setAttribute("erro", erro);
            request.getRequestDispatcher("/gerenciamentoAdmins/alterarReservas.jsp").forward(request, response);

        } catch (DateTimeParseException | NumberFormatException | NullPointerException e) {
            request.getSession().setAttribute("aviso", "Dados da reserva inválidos.");
            response.sendRedirect("PainelGerenciamento?aba=reservas");
        } catch (ClassNotFoundException | SQLException e) {
            e.printStackTrace();
            request.getSession().setAttribute("aviso", "Não foi possível atualizar a reserva agora.");
            response.sendRedirect("PainelGerenciamento?aba=reservas");
        }
    }

    // Só a equipe cadastra reservas pelo painel
    private boolean ehFuncionario(HttpServletRequest request) {
        HttpSession sessao = request.getSession(false);
        // return sessao != null && "funcionario".equals(sessao.getAttribute("perfil"));
        return true; // TEMPORÁRIO: troque pela linha de cima quando o login da equipe gravar o perfil
    }

    private String validar(LocalDateTime horario, int pessoas) {
        return validar(horario, pessoas, true);
    }

    private String validar(LocalDateTime horario, int pessoas, boolean exigirFuturo) {
        if (pessoas < 1 || pessoas > MAX_PESSOAS) {
            return "Para grupos acima de " + MAX_PESSOAS + " pessoas, ligue para (11) 3040-5060.";
        }
        if (exigirFuturo && !horario.isAfter(LocalDateTime.now())) {
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

    // Confirmar chegada ou cancelar, pelo painel
    private void statusPeloPainel(HttpServletRequest request, HttpServletResponse response, String acao)
            throws ServletException, IOException {
        if (!ehFuncionario(request)) {
            response.sendRedirect("login.html");
            return;
        }

        String aviso;
        try {
            int idReserva = Integer.parseInt(request.getParameter("id_reserva").trim());
            ReservasDao dao = new ReservasDao();

            if ("confirmarChegada".equalsIgnoreCase(acao)) {
                aviso = (dao.confirmarChegada(idReserva) == 1)
                        ? "Chegada confirmada."
                        : "Só reservas pendentes podem ser confirmadas.";
            } else {
                int resultado = dao.cancelar(idReserva);
                if (resultado == 1) {
                    aviso = "Reserva cancelada.";
                } else if (resultado == -1) {
                    aviso = "Não é possível cancelar: já existe pedido para essa reserva.";
                } else {
                    aviso = "Essa reserva não pode ser cancelada.";
                }
            }
        } catch (NumberFormatException | NullPointerException e) {
            aviso = "Reserva inválida.";
        } catch (ClassNotFoundException | SQLException e) {
            e.printStackTrace();
            aviso = "Não foi possível atualizar a reserva agora.";
        }

        request.getSession().setAttribute("aviso", aviso);
        response.sendRedirect("PainelGerenciamento?aba=reservas");
    }
}
