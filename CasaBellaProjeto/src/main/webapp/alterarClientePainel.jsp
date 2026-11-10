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

    String nomeLogado = (String) session.getAttribute("nome");
    if (nomeLogado == null) nomeLogado = "Funcionário(a)";
    String cargoLogado = (String) session.getAttribute("cargo");

    // O ControleCliente (origem=editar) envia: {id, nome, email, telefone}
    String[] cliente = (String[]) request.getAttribute("cliente");
    if (cliente == null) {
        response.sendRedirect("PainelGerenciamento");
        return;
    }

    // Mensagem opcional de erro (ex.: "E-mail já cadastrado")
    String erro = (String) request.getAttribute("erro");
%>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Editar cliente — Casa Bella</title>
    <meta name="robots" content="noindex" />

    <link rel="preconnect" href="https://fonts.googleapis.com" />
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
    <link href="https://fonts.googleapis.com/css2?family=Fraunces:ital,wght@0,500;0,600;1,500;1,600&family=Manrope:wght@400;500;600;700&display=swap" rel="stylesheet" />

    <link rel="stylesheet" href="<%=base%>/main.css" />
</head>
<body>

<div class="admin-shell">

    <!-- ============ BARRA LATERAL ============ -->
    <aside class="admin-sidebar">
        <a href="<%= base %>/PainelGerenciamento?aba=clientes" class="admin-logo">
            <span class="brand-mark">Casa <em>Bella</em></span>
        </a>

        <nav class="admin-nav" aria-label="Navegação do painel">
            <a href="<%= base %>/PainelGerenciamento?aba=clientes">Voltar ao painel</a>
        </nav>

        <div class="admin-logout">
            <a href="<%= base%>/login.html">Sair</a>
        </div>
    </aside>

    <!-- ============ CONTEÚDO ============ -->
    <main class="admin-main">
        <div class="admin-topbar">
            <div>
                <p class="admin-user-name"><%= esc(nomeLogado) %></p>
                <% if (cargoLogado != null) { %>
                <p class="admin-user-role"><%= esc(cargoLogado) %></p>
                <% } %>
            </div>
        </div>

        <div class="admin-content">
            <section class="admin-panel" style="display:block" aria-label="Editar cliente">
                <div class="admin-panel-header">
                    <div>
                        <h1>Editar cliente</h1>
                        <p class="admin-panel-subtitle">Cliente nº <%= esc(cliente[0]) %></p>
                    </div>
                </div>

                <div class="admin-panel-card" style="padding:2rem; max-width:640px;">

                    <% if (erro != null) { %>
                    <p role="alert"><%= esc(erro) %></p>
                    <% } %>

                    <form class="auth-form" action="<%= base %>/ControleCliente" method="post">
                        <input type="hidden" name="origem" value="atualizar" />
                        <input type="hidden" name="id_cliente" value="<%= esc(cliente[0]) %>" />

                        <div class="field">
                            <label for="nome">Nome completo</label>
                            <input type="text" id="nome" name="nome" value="<%= esc(cliente[1]) %>" autocomplete="off" required />
                        </div>

                        <div class="field">
                            <label for="email">E-mail</label>
                            <input type="email" id="email" name="email" value="<%= esc(cliente[2]) %>" autocomplete="off" required />
                        </div>

                        <div class="field">
                            <label for="telefone">Telefone</label>
                            <input type="tel" id="telefone" name="telefone" value="<%= esc(cliente[3]) %>" autocomplete="off" required />
                        </div>

                        <div class="field">
                            <label for="senha">Nova senha</label>
                            <input type="password" id="senha" name="senha" placeholder="Deixe em branco para manter a atual" autocomplete="new-password" minlength="6" />
                        </div>

                        <button type="submit" class="btn btn-primary btn-block">Salvar alterações</button>
                    </form>
                    <input type="checkbox" id="abrir-excluir" class="delete-toggle" aria-controls="card-excluir" />

                    <label for="abrir-excluir" class="btn btn-danger btn-block" style="margin-top:1rem;">Excluir cliente</label>

                    <div class="edit-card is-danger delete-card" id="card-excluir">
                        <h2>Excluir cliente</h2>
                        <p>Esta ação não pode ser desfeita. O cliente <strong><%= esc(cliente[1]) %></strong> será removido do sistema.</p>

                        <form class="auth-form" action="<%= base %>/ControleCliente" method="post">
                            <input type="hidden" name="origem" value="excluirPainel" />
                            <input type="hidden" name="id_cliente" value="<%= esc(cliente[0]) %>" />

                            <label class="field-check">
                                <input type="checkbox" required />
                                Entendo que não poderei desfazer
                            </label>

                            <div class="form-actions">
                                <button type="submit" class="btn btn-danger">Confirmar exclusão</button>
                            </div>
                        </form>
                    </div>


                </div>
            </section>
        </div>
    </main>

</div>
</body>
</html>
