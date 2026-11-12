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

    // Abre o formulário de edição (painel) com os dados do cliente
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String origem = request.getParameter("origem");

        if ("editar".equalsIgnoreCase(origem)) {
            abrirEdicao(request, response);          // painel da equipe (já existia)
        } else if ("carregar".equalsIgnoreCase(origem)) {
            carregarMeusDados(request, response);    // NOVO: cliente editando os próprios dados
        } else {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Origem inválida.");
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8"); // antes de ler os parâmetros, para os acentos
        response.setContentType("text/html;charset=UTF-8");

        String origem = request.getParameter("origem");

        // A edição pelo painel tem o próprio fluxo e não passa pelo mensagens.jsp
        if ("atualizar".equalsIgnoreCase(origem)) {
            atualizar(request, response);
            return;
        }
        if ("excluirPainel".equalsIgnoreCase(origem)) {
            excluirPeloPainel(request, response);
            return;
        }

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
        } else if ("excluir".equalsIgnoreCase(origem)) {
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
        } else if ("alterar".equalsIgnoreCase(origem)) {
            HttpSession sessao = request.getSession(false);
            if (sessao == null || !"cliente".equals(sessao.getAttribute("perfil"))) {
                response.sendRedirect("login.html");
                return;
            }

            // E-mail vem da sessão, NUNCA do formulário
            String email = (String) sessao.getAttribute("email");
            String nome = valor(request.getParameter("nome"));
            String telefone = valor(request.getParameter("telefone"));

            if (nome.isEmpty() || telefone.isEmpty()) {
                mensagem = "Preencha nome e telefone.";
            } else {
                try {
                    if (new ClientesDao().alterarCliente(email, nome, telefone) == 1) {
                        sessao.setAttribute("nome", nome);
                        sessao.setAttribute("telefone", telefone);
                        sessao.setAttribute("aviso", "Dados alterados com sucesso.");
                        response.sendRedirect(request.getContextPath() + "/ControleReserva?origem=listarMinhas");
                        return;
                    } else {
                        mensagem = "Nenhuma alteração foi feita.";
                    }
                } catch (ClassNotFoundException | SQLException erro) {
                    mensagem = erro.getMessage();
                }
            }
        } else {
            mensagem = "Operação inválida.";
        }

        request.setAttribute("mens", mensagem);
        request.getRequestDispatcher("mensagens.jsp").forward(request, response);
    }

    // Cliente logado abre o formulário com os PRÓPRIOS dados (e-mail vem da sessão)
    private void carregarMeusDados(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession sessao = request.getSession(false);
        if (sessao == null || !"cliente".equals(sessao.getAttribute("perfil"))) {
            response.sendRedirect("login.html");
            return;
        }
        try {
            String email = (String) sessao.getAttribute("email");
            String[] dados = new ClientesDao().buscarDados(email); // {nome, email, telefone}
            if (dados == null) {
                response.sendRedirect("login.html");
                return;
            }
            request.setAttribute("cliente", dados);
            request.getRequestDispatcher("/areaCliente/editarCliente.jsp").forward(request, response);
        } catch (ClassNotFoundException | SQLException e) {
            e.printStackTrace();
            throw new ServletException(e);
        }
    }

    // ===================== EDIÇÃO PELO PAINEL =====================

    private void abrirEdicao(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        if (!ehFuncionario(request)) {
            response.sendRedirect("login.html");
            return;
        }
        try {
            int id = Integer.parseInt(request.getParameter("id").trim());
            String[] cliente = new ClientesDao().buscarPorId(id);

            if (cliente == null) {
                response.sendError(HttpServletResponse.SC_NOT_FOUND, "Cliente não encontrado.");
                return;
            }
            request.setAttribute("cliente", cliente);
            request.getRequestDispatcher("/gerenciamentoAdmins/alterarClientePainel.jsp").forward(request, response);
        } catch (NumberFormatException | NullPointerException e) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Cliente inválido.");
        } catch (ClassNotFoundException | SQLException e) {
            e.printStackTrace();
            throw new ServletException(e);
        }
    }

    private void atualizar(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        if (!ehFuncionario(request)) {
            response.sendRedirect("login.html");
            return;
        }
        try {
            int id = Integer.parseInt(request.getParameter("id_cliente").trim());
            String nome = valor(request.getParameter("nome"));
            String email = valor(request.getParameter("email"));
            String telefone = valor(request.getParameter("telefone"));
            String senha = request.getParameter("senha");

            if (nome.isEmpty() || email.isEmpty() || telefone.isEmpty()) {
                devolverForm(request, response, id, nome, email, telefone, "Preencha todos os campos.");
                return;
            }
            if (senha != null && !senha.trim().isEmpty() && senha.length() < 6) {
                devolverForm(request, response, id, nome, email, telefone, "A senha precisa ter ao menos 6 caracteres.");
                return;
            }

            int resultado = new ClientesDao().atualizar(id, nome, email, telefone, senha);

            if (resultado == 1) {
                response.sendRedirect("PainelGerenciamento");
            } else if (resultado == -1) {
                devolverForm(request, response, id, nome, email, telefone, "Esse e-mail já está em uso por outro cliente.");
            } else {
                response.sendError(HttpServletResponse.SC_NOT_FOUND, "Cliente não encontrado.");
            }

        } catch (NumberFormatException | NullPointerException e) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Dados inválidos.");
        } catch (ClassNotFoundException | SQLException e) {
            e.printStackTrace();
            throw new ServletException(e);
        }
    }

    // Reabre o formulário com o que a pessoa digitou e a mensagem de erro
    private void devolverForm(HttpServletRequest request, HttpServletResponse response,
                              int id, String nome, String email, String telefone, String erro)
            throws ServletException, IOException {
        request.setAttribute("cliente", new String[]{String.valueOf(id), nome, email, telefone});
        request.setAttribute("erro", erro);
        request.getRequestDispatcher("/gerenciamentoAdmins/alterarClientePainel.jsp").forward(request, response);    }

    private String valor(String s) {
        return s == null ? "" : s.trim();
    }


    // Só a equipe edita clientes
    private boolean ehFuncionario(HttpServletRequest request) {
        HttpSession sessao = request.getSession(false);
        // return sessao != null && "funcionario".equals(sessao.getAttribute("perfil"));
        return true; // TEMPORÁRIO: troque pela linha de cima quando o login da equipe gravar o perfil
    }

    private void excluirPeloPainel(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        if (!ehFuncionario(request)) {
            response.sendRedirect("login.html");
            return;
        }
        try {
            int id = Integer.parseInt(request.getParameter("id_cliente").trim());
            ClientesDao dao = new ClientesDao();
            int resultado = dao.excluirPorId(id);

            if (resultado == 1) {
                request.getSession().setAttribute("aviso", "Cliente excluído com sucesso.");
                response.sendRedirect("PainelGerenciamento?aba=clientes");
            } else if (resultado == -1) {
                String[] c = dao.buscarPorId(id);
                devolverForm(request, response, id, c[1], c[2], c[3],
                        "Não é possível excluir: o cliente tem reservas ligadas à conta.");
            } else {
                response.sendError(HttpServletResponse.SC_NOT_FOUND, "Cliente não encontrado.");
            }
        } catch (NumberFormatException | NullPointerException e) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Cliente inválido.");
        } catch (ClassNotFoundException | SQLException e) {
            e.printStackTrace();
            throw new ServletException(e);
        }
    }


}
