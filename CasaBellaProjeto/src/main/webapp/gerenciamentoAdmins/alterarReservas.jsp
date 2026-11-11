<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%!
    // Escapa caracteres especiais antes de imprimir um texto dentro do HTML
    private String esc(String s) {
        if (s == null) return "";
        return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;");
    }

    // Usa o que a pessoa digitou (se houve erro e a página voltou) ou o valor do banco
    private String valor(HttpServletRequest request, String parametro, String doBanco) {
        String digitado = request.getParameter(parametro);
        return digitado != null ? digitado : doBanco;
    }
%>
<%
    String base = request.getContextPath();
    
    String nome = (String) session.getAttribute("nome");
    if (nome == null) nome = "Funcionário(a)";
    String cargo = (String) session.getAttribute("cargo");

    // O ControleReserva (origem=editar) envia: {id, cliente, data, hora, pessoas, status}
    String[] reserva = (String[]) request.getAttribute("reserva");
    if (reserva == null) {
        response.sendRedirect(base + "/PainelGerenciamento?aba=reservas");
        return;
    }

    // Mensagem de erro enviada pelo servlet (ex.: "Não há mesa disponível")
    String erro = (String) request.getAttribute("erro");
%>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Editar reserva — Casa Bella</title>
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
            <section class="admin-panel" style="display:block" aria-label="Editar reserva">
                <div class="admin-panel-header">
                    <div>
                        <h1>Editar reserva #<%= esc(reserva[0]) %></h1>
                        <p class="admin-panel-subtitle">
                            Cliente: <%= reserva[1].isEmpty() ? "—" : esc(reserva[1]) %> · Status: <%= esc(reserva[5]) %>
                        </p>
                    </div>
                </div>

                <div class="admin-panel-card" style="padding:2rem; max-width:640px;">

                    <% if (erro != null) { %>
                    <p role="alert"><%= esc(erro) %></p>
                    <% } %>

                    <p>Se o horário ou a quantidade de pessoas mudarem, o sistema confere se a mesa
                        atual ainda serve e, se não servir, escolhe outra automaticamente.</p>

                    <form class="auth-form" action="<%= base %>/ControleReserva" method="post">
                        <input type="hidden" name="origem" value="atualizarPainel" />
                        <input type="hidden" name="id_reserva" value="<%= esc(reserva[0]) %>" />

                        <div class="field">
                            <label for="data">Data</label>
                            <input type="date" id="data" name="data"
                                   value="<%= esc(valor(request, "data", reserva[2])) %>" required />
                        </div>

                        <div class="field">
                            <label for="hora">Horário</label>
                            <input type="time" id="hora" name="hora"
                                   value="<%= esc(valor(request, "hora", reserva[3])) %>" required />
                        </div>

                        <div class="field">
                            <label for="pessoas">Quantidade de pessoas</label>
                            <input type="number" id="pessoas" name="pessoas" min="1" max="6"
                                   value="<%= esc(valor(request, "pessoas", reserva[4])) %>" required />
                        </div>

                        <button type="submit" class="btn btn-primary btn-block">Salvar alterações</button>
                    </form>
                </div>
            </section>
        </div>
    </main>

</div>
</body>
</html>
