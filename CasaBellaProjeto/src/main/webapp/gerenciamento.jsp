<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%!
    // Escapa caracteres especiais antes de imprimir um texto dentro do HTML
    private String esc(String s) {
        if (s == null) return "";
        return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;");
    }
%>
<%
    // PROTEÇÃO DA PÁGINA: ative (tirando os //) quando o ControleLogin passar
    // a guardar o usuário na sessão. Quem não estiver logado volta para o login.
    // if (session.getAttribute("nome") == null && request.getAttribute("nome") == null) {
    //     response.sendRedirect("login.html");
    //     return;
    // }

    // Dados de quem logou. O ControleLogin envia com request.setAttribute(...)
    // ou guarda na sessão com session.setAttribute(...).
    String nome = (String) request.getAttribute("nome");
    if (nome == null) nome = (String) session.getAttribute("nome");
    if (nome == null) nome = "Funcionário(a)"; // aparece só se a página for aberta direto

    String cargo = (String) request.getAttribute("cargo");
    if (cargo == null) cargo = (String) session.getAttribute("cargo");
%>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Gerenciamento — Casa Bella</title>
    <meta name="description" content="Painel de gerenciamento da Casa Bella para a equipe do restaurante." />

    <link rel="preconnect" href="https://fonts.googleapis.com" />
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
    <link href="https://fonts.googleapis.com/css2?family=Fraunces:ital,wght@0,500;0,600;1,500;1,600&family=Manrope:wght@400;500;600;700&display=swap" rel="stylesheet" />

    <link rel="stylesheet" href="main.css" />
</head>
<body>

<!--
  Painel interno da equipe (funcionários), separado do site do cliente.
  As três "abas" (Pedidos / Clientes / Funcionários) trocam de conteúdo
  só com CSS, usando radio buttons escondidos — mesma ideia do menu
  hambúrguer do cabeçalho, só que aqui com radio em vez de checkbox
  porque só uma aba pode estar ativa por vez.

  O nome e o cargo no topo já vêm de quem logou. Os dados das tabelas
  abaixo ainda são exemplo (fixos no HTML): quando o DAO estiver pronto,
  as linhas do tbody serão geradas a partir do banco.
-->

<input type="radio" name="admin-tab" id="tab-pedidos" class="admin-tab-radio" checked />
<input type="radio" name="admin-tab" id="tab-clientes" class="admin-tab-radio" />
<input type="radio" name="admin-tab" id="tab-reservas" class="admin-tab-radio" />
<input type="radio" name="admin-tab" id="tab-funcionarios" class="admin-tab-radio" />

<div class="admin-shell">

    <!-- ============ BARRA LATERAL ============ -->
    <aside class="admin-sidebar">
        <a href="index.html" class="admin-logo">
            <span class="brand-mark">Casa <em>Bella</em></span>
        </a>

        <nav class="admin-nav" aria-label="Navegação do painel">
            <label for="tab-pedidos">Pedidos</label>
            <label for="tab-clientes">Clientes</label>
            <label for="tab-reservas">Reservas</label>
            <label for="tab-produtos">Produtos</label>
            <label for="tab-funcionarios">Funcionários</label>
        </nav>

        <div class="admin-logout">
            <a href="login.html">
                <svg viewBox="0 0 24 24" fill="none" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M15 3H6a1.5 1.5 0 0 0-1.5 1.5v15A1.5 1.5 0 0 0 6 21h9"></path>
                    <path d="M10 12h11m0 0-3.5-3.5M21 12l-3.5 3.5"></path>
                </svg>
                Sair
            </a>
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

            <!-- ============ PAINEL: PEDIDOS ============ -->
            <section class="admin-panel" id="panel-pedidos" aria-label="Pedidos">
                <!--
                  Exemplo de layout: as sub-abas, a busca, o "Exportar" e a paginação
                  são só visuais — nenhum deles filtra ou faz nada de verdade ainda.
                -->
                <div class="admin-panel-header">
                    <div>
                        <h1>Pedidos</h1>
                        <p class="admin-panel-subtitle">Acompanhamento dos pedidos em andamento e finalizados.</p>
                    </div>
                    <a href="#" class="btn btn-primary">Novo pedido</a>
                </div>

                <div class="admin-panel-card">
                    <div class="admin-subtabs">
                        <span class="is-active">Todos os pedidos</span>
                        <span>Em preparo</span>
                        <span>Concluídos</span>
                        <span>Cancelados</span>
                    </div>

                    <div class="admin-filter-bar">
                        <div class="admin-filter-field">
                            <label for="filtro-cliente">Cliente</label>
                            <input type="text" id="filtro-cliente" placeholder="Buscar por nome" />
                        </div>

                        <div class="admin-filter-field">
                            <label for="filtro-mesa">Mesa</label>
                            <select id="filtro-mesa">
                                <option>Todas</option>
                                <option>Mesa 2</option>
                                <option>Mesa 6</option>
                                <option>Mesa 9</option>
                            </select>
                        </div>

                        <div class="admin-filter-actions">
                            <a href="#" class="btn btn-outline">Buscar</a>
                            <a href="#" class="btn btn-primary">Exportar</a>
                        </div>
                    </div>

                    <div class="admin-table-wrap">
                        <table class="admin-table">
                            <thead>
                            <tr>
                                <th>Nº</th>
                                <th>Cliente</th>
                                <th>Mesa</th>
                                <th>Data</th>
                                <th>Status</th>
                                <th>Total</th>
                                <th></th>
                            </tr>
                            </thead>
                            <tbody>
                            <tr>
                                <td>#1042</td>
                                <td>Renata Prado</td>
                                <td>Mesa 6</td>
                                <td>24/09 · 20h15</td>
                                <td><span class="status-pill is-preparo">Em preparo</span></td>
                                <td>R$ 187,00</td>
                                <td>
                                    <div class="admin-row-actions">
                                        <a href="#" class="chip-btn">Ver</a>
                                        <a href="#" class="chip-btn">Editar</a>
                                        <a href="#" class="chip-btn">Cancelar</a>
                                    </div>
                                </td>
                            </tr>
                            <tr>
                                <td>#1041</td>
                                <td>Marco Fontana</td>
                                <td>Mesa 2</td>
                                <td>24/09 · 19h50</td>
                                <td><span class="status-pill is-pendente">Pendente</span></td>
                                <td>R$ 96,50</td>
                                <td>
                                    <div class="admin-row-actions">
                                        <a href="#" class="chip-btn">Ver</a>
                                        <a href="#" class="chip-btn">Editar</a>
                                        <a href="#" class="chip-btn">Cancelar</a>
                                    </div>
                                </td>
                            </tr>
                            <tr>
                                <td>#1040</td>
                                <td>Lívia Torres</td>
                                <td>Mesa 9</td>
                                <td>24/09 · 19h20</td>
                                <td><span class="status-pill is-concluido">Concluído</span></td>
                                <td>R$ 243,00</td>
                                <td>
                                    <div class="admin-row-actions">
                                        <a href="#" class="chip-btn">Ver</a>
                                        <a href="#" class="chip-btn">Editar</a>
                                        <a href="#" class="chip-btn">Cancelar</a>
                                    </div>
                                </td>
                            </tr>
                            </tbody>
                        </table>
                    </div>

                    <div class="admin-pagination">
                        <span>‹</span>
                        <span class="is-active">1</span>
                        <span>2</span>
                        <span>3</span>
                        <span class="is-ellipsis">…</span>
                        <span>9</span>
                        <span>›</span>
                    </div>
                </div>
            </section>

            <!-- ============ PAINEL: CLIENTES ============ -->
            <section class="admin-panel" id="panel-clientes" aria-label="Clientes">
                <div class="admin-panel-header">
                    <h1>Clientes</h1>
                    <a href="#" class="btn btn-primary">Novo cliente</a>
                </div>

                <div class="admin-table-wrap">
                    <table class="admin-table">
                        <thead>
                        <tr>
                            <th>Nome</th>
                            <th>E-mail</th>
                            <th>Senha</th>
                            <th>Telefone</th>
                            <th>Cliente desde</th>
                            <th></th>
                        </tr>
                        </thead>
                        <tbody>
                        <tr>
                            <td>Renata Prado</td>
                            <td>renata.prado@email.com</td>
                            <td>12345</td>
                            <td>(11) 98888-1234</td>
                            <td>12/03/2024</td>
                            <td>
                                <div class="admin-row-actions">
                                    <a href="#">Ver</a>
                                    <a href="#">Editar</a>
                                </div>
                            </td>
                        </tr>
                        <tr>
                            <td>Marco Fontana</td>
                            <td>marco.fontana@email.com</td>
                            <td>12345</td>
                            <td>(11) 97777-5678</td>
                            <td>28/07/2023</td>
                            <td>
                                <div class="admin-row-actions">
                                    <a href="#">Ver</a>
                                    <a href="#">Editar</a>
                                </div>
                            </td>
                        </tr>
                        <tr>
                            <td>Lívia Torres</td>
                            <td>livia.torres@email.com</td>
                            <td>12345</td>
                            <td>(11) 96666-4321</td>
                            <td>05/01/2025</td>
                            <td>
                                <div class="admin-row-actions">
                                    <a href="#">Ver</a>
                                    <a href="#">Editar</a>
                                </div>
                            </td>
                        </tr>
                        </tbody>
                    </table>
                </div>
            </section>

            <!-- ============ PAINEL: RESERVAS ============ -->
            <SECTION class="admin-panel" id="panel-reservas" aria-label="Reservas">
                <h1>Reservas</h1>
            </SECTION>

            <!-- ============ PAINEL: PRODUTOS ============ -->
            <SECTION class="admin-panel" id="panel-produtos" aria-label="Produtos">
                <h1>Produtos</h1>
            </SECTION>



            <!-- ============ PAINEL: FUNCIONÁRIOS ============ -->
            <section class="admin-panel" id="panel-funcionarios" aria-label="Funcionários">
                <div class="admin-panel-header">
                    <h1>Funcionários</h1>
                    <a href="#" class="btn btn-primary">Novo funcionário</a>
                </div>

                <div class="admin-table-wrap">

                    <table class="admin-table">
                        <thead>
                        <tr>
                            <th>Usuário</th>
                            <th>Nome</th>
                            <th>Cargo</th>
                            <th>E-mail</th>
                            <th>Senha</th>
                            <th>Admissão</th>
                            <th></th>
                        </tr>
                        </thead>
                        <tbody>

                            <%
                                java.sql.ResultSet funcionarios =
                                        (java.sql.ResultSet) request.getAttribute("funcionarios");

                                if (funcionarios != null) {

                                    while (funcionarios.next()) {
                            %>

                            <tr>
                                <td><%= esc(funcionarios.getString("nome")) %></td>
                                <td><%= esc(funcionarios.getString("nome")) %></td>
                                <td><%= esc(funcionarios.getString("cargo")) %></td>
                                <td><%= esc(funcionarios.getString("email")) %></td>
                                <td>Não disponível</td>
                                <td><%= esc(funcionarios.getString("admissao")) %></td>

                                <td>
                                    <div class="admin-row-actions">
                                        <a href="#">Ver</a>
                                        <a href="#">Editar</a>
                                    </div>
                                </td>
                            </tr>

                            <%
                                    }
                                }
                            %>
                        </tbody>
                    </table>
                </div>
            </section>

        </div>
    </main>

</div>
</body>
</html>
