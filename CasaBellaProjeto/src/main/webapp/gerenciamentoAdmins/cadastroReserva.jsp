<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%!
    // Escapa caracteres especiais antes de imprimir um texto dentro do HTML
    private String esc(String s) {
        if (s == null) return "";
        return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;");
    }
%>
<%
    String base = request.getContextPath();

    String nome = (String) session.getAttribute("nome");
    if (nome == null) nome = "Funcionário(a)";
    String cargo = (String) session.getAttribute("cargo");

    // Mensagem de erro enviada pelo ControleReserva (ex.: "Não há mesa disponível")
    String erro = (String) request.getAttribute("erro");
%>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Nova reserva — Casa Bella</title>
    <meta name="robots" content="noindex" />

    <link rel="preconnect" href="https://fonts.googleapis.com" />
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
    <link href="https://fonts.googleapis.com/css2?family=Fraunces:ital,wght@0,500;0,600;1,500;1,600&family=Manrope:wght@400;500;600;700&display=swap" rel="stylesheet" />

    <link rel="stylesheet" href="<%= base %>/main.css" />
</head>
<body>

<div class="admin-shell">

    <!-- ============ BARRA LATERAL ============ -->
    <aside class="admin-sidebar">
        <a href="<%= base %>/PainelGerenciamento?aba=reservas" class="admin-logo">
            <span class="brand-mark">Casa <em>Bella</em></span>
        </a>

        <nav class="admin-nav" aria-label="Navegação do painel">
            <a href="<%= base %>/PainelGerenciamento?aba=reservas">Voltar ao painel</a>
        </nav>

        <div class="admin-logout">
            <a href="<%= base %>/login.html">Sair</a>
        </div>
    </aside>

    <!-- ============ CONTEÚDO ============ -->
    <main class="admin-main">
        <div class="admin-topbar">
            <div>
                <p class="admin-user-name"><%= esc(nome) %></p>
                <% if (cargo != null) { %>
                <p class="admin-user-role"><%= esc(cargo) %></p>
                <% } %>
            </div>
        </div>

        <div class="admin-content">
            <section class="admin-panel" style="display:block" aria-label="Cadastro de reserva">
                <div class="admin-panel-header">
                    <div>
                        <h1>Nova reserva</h1>
                        <p class="admin-panel-subtitle">A mesa é escolhida automaticamente pela quantidade de pessoas.</p>
                    </div>
                </div>

                <div class="admin-panel-card" style="padding:2rem; max-width:640px;">

                    <% if (erro != null) { %>
                    <p role="alert"><%= esc(erro) %></p>
                    <% } %>

                    <%-- Quando há erro, o servlet devolve a página e os parâmetros continuam
                         disponíveis: os campos voltam preenchidos. --%>
                    <form class="auth-form" action="<%= base %>/ControleReserva" method="post">
                        <input type="hidden" name="origem" value="cadastrarPainel" />

                        <div class="field">
                            <label for="email">E-mail do cliente</label>
                            <input type="email" id="email" name="email" placeholder="cliente@email.com"
                                   value="<%= esc(request.getParameter("email")) %>" autocomplete="off" required />
                        </div>

                        <div class="field">
                            <label for="data">Data</label>
                            <input type="date" id="data" name="data"
                                   value="<%= esc(request.getParameter("data")) %>" required />
                        </div>

                        <div class="field">
                            <label for="hora">Horário</label>
                            <input type="time" id="hora" name="hora"
                                   value="<%= esc(request.getParameter("hora")) %>" required />
                        </div>

                        <div class="field">
                            <label for="pessoas">Quantidade de pessoas</label>
                            <input type="number" id="pessoas" name="pessoas" min="1" max="6"
                                   value="<%= esc(request.getParameter("pessoas")) %>" required />
                        </div>

                        <button type="submit" class="btn btn-primary btn-block">Cadastrar reserva</button>
                    </form>
                </div>
            </section>
        </div>
    </main>

</div>
</body>
</html>
