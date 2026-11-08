<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%!
    // Escapa caracteres especiais antes de imprimir um texto dentro do HTML
    private String esc(String s) {
        if (s == null) return "";
        return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;");
    }
%>
<%
    // PROTEÇÃO DA PÁGINA: só o pessoal técnico acessa.
    // Ative (tirando os //) quando o ControleLogin passar a guardar
    // "nome" e "cargo" na sessão com session.setAttribute(...).
    // Troque "Técnico" pelo texto exato que está na coluna cargo do banco.
    // String cargoLogado = (String) session.getAttribute("cargo");
    // if (session.getAttribute("nome") == null || !"Técnico".equals(cargoLogado)) {
    //     response.sendRedirect("login.html");
    //     return;
    // }

    String id_func = request.getParameter("usuario");
    String nome = (String) session.getAttribute("nome");
    if (nome == null) nome = "Funcionário(a)";
    String cargo = (String) session.getAttribute("cargo");

    // Mensagem opcional enviada pelo servlet (ex.: "E-mail já cadastrado")
    String erro = (String) request.getAttribute("erro");
%>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Novo produto cardário — Casa Bella</title>
    <meta name="robots" content="noindex" />

    <link rel="preconnect" href="https://fonts.googleapis.com" />
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
    <link href="https://fonts.googleapis.com/css2?family=Fraunces:ital,wght@0,500;0,600;1,500;1,600&family=Manrope:wght@400;500;600;700&display=swap" rel="stylesheet" />

    <link rel="stylesheet" href="main.css" />
</head>
<body>

<div class="admin-shell">

    <!-- ============ BARRA LATERAL ============ -->
    <aside class="admin-sidebar">
        <a href="gerenciamento.jsp" class="admin-logo">
            <span class="brand-mark">Casa <em>Bella</em></span>
        </a>

        <nav class="admin-nav" aria-label="Navegação do painel">
            <a href="gerenciamento.jsp">Voltar ao painel</a>
        </nav>

        <div class="admin-logout">
            <a href="login.html">Sair</a>
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
            <section class="admin-panel" style="display:block" aria-label="Cadastro de Produtos">
                <div class="admin-panel-header">
                    <div>
                        <h1>Novo Produto</h1>
                        <p class="admin-panel-subtitle">Área restrita à equipe técnica.</p>
                    </div>
                </div>

                <div class="admin-panel-card" style="padding:2rem; max-width:640px;">

                    <% if (erro != null) { %>
                    <p role="alert"><%= esc(erro) %></p>
                    <% } %>

                    <form class="auth-form" action="ControleProduto" method="post">
                        <input type="hidden" name="origem" value="cadastrar" />

                        <div class="field">
                            <label for="id_produto">Nª ID do Produto </label>
                            <input type="number" id="id_produto" name="id_produto" min="2" placeholder="Número de Identificação do Produto" autocomplete="off" required />
                        </div>

                        <div class="field">
                            <label for="categoria">Categoria</label>
                            <select id="categoria" name="categoria" required>
                                <option>Massa</option>
                                <option>Vinhos</option>
                            </select>
                        </div>

                        <div class="field">
                            <label for="nome">Nome do Produto</label>
                            <input type="text" id="nome" name="nome" placeholder="Massa com molho branco" autocomplete="off" required />
                        </div>

                        <div class="field">
                            <label for="descricao">Descrição</label>
                            <input type="text" id="descricao" name="descricao" placeholder="Massa cremosa com molho branco" autocomplete="off" required />
                        </div>

                        <div class="field">
                            <label for="preco">Preço</label>
                            <input type="text" id="preco" name="preco" placeholder="R$ xxx,xx" autocomplete="off" required />
                        </div>

                        <div class="field">
                            <label for="disponibilidade">Disponibilidade</label>
                            <select id="disponibilidade" name="disponibilidade" required>
                                <option value="disponivel">Disponível</option>
                                <option value="indisponivel">Indisponível</option>
                            </select>
                        </div>

                        <button type="submit" class="btn btn-primary btn-block">Cadastrar novo produto</button>
                    </form>
                </div>
            </section>
        </div>
    </main>

</div>
</body>
</html>
