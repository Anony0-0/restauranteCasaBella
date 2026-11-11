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

    // O ControleProduto (origem=editar) envia: {id, categoria, nome, descricao, preco, disponibilidade}
    String[] produto = (String[]) request.getAttribute("produto");
    if (produto == null) {
        response.sendRedirect("PainelGerenciamento?aba=produtos");
        return;
    }
    String idOriginal = (String) request.getAttribute("idOriginal");
    if (idOriginal == null) idOriginal = produto[0];

    // Mensagem opcional de erro (ex.: "O preço deve ser maior que zero.")
    String erro = (String) request.getAttribute("erro");

    boolean disponivel = "disponivel".equals(produto[5]);
%>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Editar produto — Casa Bella</title>
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
        <a href="<%= base %>/PainelGerenciamento?aba=produtos" class="admin-logo">
            <span class="brand-mark">Casa <em>Bella</em></span>
        </a>

        <nav class="admin-nav" aria-label="Navegação do painel">
            <a href="<%= base %>/PainelGerenciamento?aba=produtos">Voltar ao painel</a>
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
            <section class="admin-panel" style="display:block" aria-label="Editar produto">
                <div class="admin-panel-header">
                    <div>
                        <h1>Editar produto</h1>
                        <p class="admin-panel-subtitle">Produto nº <%= esc(produto[0]) %></p>
                    </div>
                </div>

                <div class="admin-panel-card" style="padding:2rem; max-width:640px;">

                    <% if (erro != null) { %>
                    <p role="alert"><%= esc(erro) %></p>
                    <% } %>

                    <form class="auth-form" action="<%= base %>/ControleProduto" method="post">
                        <input type="hidden" name="origem" value="atualizar" />

                        <input type="hidden" name="id_original" value="<%= esc(idOriginal) %>" />

                        <div class="field">
                            <label for="id_produto">Novo ID do Produto</label>
                            <input type="number" id="id_produto" name="id_produto" value="<%= esc(produto[0]) %>" min="1" autocomplete="off" required />
                        </div>

                        <div class="field">
                            <label for="categoria">Categoria</label>
                            <select id="categoria" name="categoria" required>
                                <%
                                    String[] categorias = {"Massa", "Pizzas", "Risotos", "Saladas", "Sobremesas",
                                            "Bebidas Diversas", "Vinhos", "Entradas", "Infantil"};
                                    for (String c : categorias) {
                                %>
                                <option value="<%= c %>" <%= c.equals(produto[1]) ? "selected" : "" %>><%= c %></option>
                                <% } %>
                            </select>
                        </div>

                        <div class="field">
                            <label for="nome">Nome do produto</label>
                            <input type="text" id="nome" name="nome" value="<%= esc(produto[2]) %>" autocomplete="off" required />
                        </div>

                        <div class="field">
                            <label for="descricao">Descrição</label>
                            <textarea id="descricao" name="descricao" rows="4"><%= esc(produto[3]) %></textarea>
                        </div>

                        <div class="field">
                            <label for="preco">Preço (R$)</label>
                            <input type="text" id="preco" name="preco" value="<%= esc(produto[4]) %>" inputmode="decimal" autocomplete="off" required />
                        </div>

                        <div class="field">
                            <label for="disponibilidade">Disponibilidade</label>
                            <select id="disponibilidade" name="disponibilidade">
                                <option value="disponivel" <%= disponivel ? "selected" : "" %>>Disponível</option>
                                <option value="indisponivel" <%= !disponivel ? "selected" : "" %>>Indisponível</option>
                            </select>
                        </div>

                        <button type="submit" class="btn btn-primary btn-block">Salvar alterações</button>
                    </form>

                    <input type="checkbox" id="abrir-excluir" class="delete-toggle" aria-controls="card-excluir" />

                    <label for="abrir-excluir" class="btn btn-danger btn-block" style="margin-top:1rem;">Excluir Produto</label>

                    <div class="edit-card is-danger delete-card" id="card-excluir">
                        <h2>Excluir Produto</h2>
                        <p>Esta ação não pode ser desfeita. O produto <strong><%= esc(produto[0]) %></strong> será removido do sistema.</p>

                        <form class="auth-form" action="<%= base %>/ControleProduto" method="post">

                            <input type="hidden" name="origem" value="excluirPainel" />

                            <input type="hidden" name="id_produto" value="<%= esc(produto[0]) %>" />

                            <label class="field-check">
                                <input type="checkbox" required />
                                Entendo que não poderei desfazer
                            </label>

                            <div class="form-actions">
                                <button type="submit" class="btn btn-danger">
                                    Confirmar exclusão
                                </button>
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
