package controle;

import dao.FuncionariosDao;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.sql.ResultSet;
import java.sql.SQLException;

@WebServlet(name = "ControleFuncionario", urlPatterns = {"/ControleFuncionario"})
public class ControleFuncionario extends HttpServlet {

    // Só funcionário logado pode editar/excluir
    private boolean ehFuncionario(HttpServletRequest request) {
        HttpSession sessao = request.getSession(false);
        return sessao != null && "funcionario".equals(sessao.getAttribute("perfil"));
    }

    private void mostrarMensagem(HttpServletRequest request, HttpServletResponse response,
                                 String mensagem) throws ServletException, IOException {
        request.setAttribute("mens", mensagem);
        request.getRequestDispatcher("/mensagens.jsp").forward(request, response);
    }

    private void voltarParaLista(HttpServletRequest request, HttpServletResponse response,
                                 String aviso) throws IOException {
        request.getSession().setAttribute("aviso", aviso);
        response.sendRedirect(request.getContextPath() + "/PainelGerenciamento?aba=funcionarios");
    }

    // ===================== GET: LISTAR e abrir tela de EDITAR =====================
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String origem = request.getParameter("origem");

        if ("listarFuncionarios".equalsIgnoreCase(origem)) {
            listarFuncionarios(request, response);

        } else if ("editarFuncionario".equalsIgnoreCase(origem)) {
            if (!ehFuncionario(request)) {
                response.sendRedirect("login.html");
                return;
            }
            try {
                int id = Integer.parseInt(request.getParameter("id"));
                String[] funcionario = new FuncionariosDao().buscarFuncionario(id);
                if (funcionario == null) {
                    mostrarMensagem(request, response, "Funcionário não encontrado.");
                    return;
                }
                request.setAttribute("funcionario", funcionario);
                request.getRequestDispatcher("/editarFuncionario.jsp").forward(request, response);
            } catch (NumberFormatException e) {
                mostrarMensagem(request, response, "Id de funcionário inválido.");
            } catch (ClassNotFoundException | SQLException e) {
                mostrarMensagem(request, response, e.getMessage());
            }

        } else {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Origem inválida.");
        }
    }

    private void listarFuncionarios(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        try {
            FuncionariosDao dao = new FuncionariosDao();
            ResultSet rs = dao.listarFuncionarios();
            request.setAttribute("funcionarios", rs);
            request.getRequestDispatcher("/gerenciamento.jsp").forward(request, response);
        } catch (ClassNotFoundException | SQLException e) {
            e.printStackTrace();
            throw new ServletException(e);
        }
    }

    // ===================== POST: CADASTRAR, ALTERAR e EXCLUIR =====================
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        response.setContentType("text/html;charset=UTF-8");

        String origem = request.getParameter("origem");
        String mensagem;

        // ---------- CADASTRAR (o seu código, sem mudanças) ----------
        if ("cadastrar".equalsIgnoreCase(origem)) {
            Integer id_func = Integer.parseInt(request.getParameter("id_func"));
            String nome = request.getParameter("nome");
            String usermobi = request.getParameter("usermobi");
            String email = request.getParameter("email");
            String senha = request.getParameter("senha");
            String cargo = request.getParameter("cargo");
            String admissao = request.getParameter("admissao");

            try {
                int resultado = new FuncionariosDao().cadastrarFuncionarios(
                        id_func, nome, usermobi, email, senha, cargo, admissao);
                if (resultado == 1) {
                    mensagem = "Funcionário cadastrado com sucesso!";
                } else {
                    mensagem = "Funcionário não cadastrado.";
                }
            } catch (ClassNotFoundException | SQLException erro) {
                erro.printStackTrace();
                if (erro.getMessage() != null && erro.getMessage().contains("Duplicate entry")) {
                    mensagem = "Este e-mail já está cadastrado.";
                } else {
                    mensagem = "Erro ao cadastrar funcionário: " + erro.getMessage();
                }
            }

            request.setAttribute("mens", mensagem);
            request.getRequestDispatcher("/mensagens.jsp").forward(request, response);

            // ---------- ALTERAR ----------
        } else if ("alterarFuncionario".equalsIgnoreCase(origem)) {
            if (!ehFuncionario(request)) {
                response.sendRedirect("login.html");
                return;
            }
            try {
                int id = Integer.parseInt(request.getParameter("id_func"));
                int r = new FuncionariosDao().alterarFuncionario(id,
                        request.getParameter("nome"),
                        request.getParameter("usermobi"),
                        request.getParameter("email"),
                        request.getParameter("cargo"),
                        request.getParameter("admissao"));
                if (r == 1) {
                    voltarParaLista(request, response, "Funcionário alterado com sucesso.");
                } else {
                    mostrarMensagem(request, response, "Funcionário não alterado.");
                }
            } catch (NumberFormatException e) {
                mostrarMensagem(request, response, "Id de funcionário inválido.");
            } catch (ClassNotFoundException | SQLException | IllegalArgumentException e) {
                // IllegalArgumentException = data de admissão inválida
                mostrarMensagem(request, response, e.getMessage());
            }

            // ---------- EXCLUIR ----------
        } else if ("excluirFuncionario".equalsIgnoreCase(origem)) {
            if (!ehFuncionario(request)) {
                response.sendRedirect("login.html");
                return;
            }
            try {
                int id = Integer.parseInt(request.getParameter("id_func"));
                FuncionariosDao dao = new FuncionariosDao();

                // não deixa excluir a própria conta logada
                String[] alvo = dao.buscarFuncionario(id);
                String emailLogado = (String) request.getSession(false).getAttribute("email");
                if (alvo != null && alvo[3] != null && alvo[3].equalsIgnoreCase(emailLogado)) {
                    mostrarMensagem(request, response, "Você não pode excluir a sua própria conta.");
                    return;
                }

                int r = dao.excluirFuncionario(id);
                if (r == 1) {
                    voltarParaLista(request, response, "Funcionário excluído com sucesso.");
                } else {
                    mostrarMensagem(request, response, "Funcionário não excluído.");
                }
            } catch (NumberFormatException e) {
                mostrarMensagem(request, response, "Id de funcionário inválido.");
            } catch (ClassNotFoundException | SQLException e) {
                mostrarMensagem(request, response, e.getMessage());
            }

        } else {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Origem inválida.");
        }
    }
}