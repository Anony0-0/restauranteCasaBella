<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.sql.ResultSet, java.sql.Timestamp, java.math.BigDecimal, java.text.SimpleDateFormat, java.util.Locale"%>
<%!
    // Escapa caracteres especiais antes de imprimir um texto dentro do HTML
    private String esc(String s) {
        if (s == null) return "";
        return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;");
    }

    // Formata data/hora vindas do banco (ex.: 24/09 · 20h15)
    private String fmtData(Timestamp t, boolean comAno) {
        if (t == null) return "—";
        String padrao = comAno ? "dd/MM/yyyy · HH'h'mm" : "dd/MM · HH'h'mm";
        return new SimpleDateFormat(padrao).format(t);
    }

    // Formata dinheiro (ex.: R$ 187,00)
    private String fmtPreco(BigDecimal v) {
        if (v == null) return "—";
        return String.format(new Locale("pt", "BR"), "R$ %,.2f", v);
    }

    // Escolhe a classe CSS da "pílula" de status a partir do texto do status
    private String statusClass(String status) {
        if (status == null) return "is-pendente";
        String s = status.toLowerCase();
        if (s.contains("preparo"))                          return "is-preparo";
        if (s.contains("conclu") || s.contains("confirm") || s.equals("disponivel")) return "is-concluido";
        if (s.contains("cancel") || s.equals("indisponivel")) return "is-cancelado";
        return "is-pendente";
    }

    private String rotuloDisponibilidade(String d) {
        return "disponivel".equals(d) ? "Disponível" : "Indisponível";
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

    String aviso = (String) session.getAttribute("aviso");
    session.removeAttribute("aviso"); // mostra só uma vez

    // Aba que deve abrir marcada (vem da URL: PainelGerenciamento?aba=produtos)
    String aba = request.getParameter("aba");
    if (!"clientes".equals(aba) && !"reservas".equals(aba)
            && !"produtos".equals(aba) && !"funcionarios".equals(aba)) {
        aba = "pedidos"; // padrão, e também para qualquer valor estranho
    }

    // ResultSets enviados pelo servlet (request.setAttribute). Se algum vier
    // null, o painel correspondente mostra "Nenhum registro".
    ResultSet pedidos      = (ResultSet) request.getAttribute("pedidos");
    ResultSet clientes     = (ResultSet) request.getAttribute("clientes");
    ResultSet reservas     = (ResultSet) request.getAttribute("reservas");
    ResultSet produtos     = (ResultSet) request.getAttribute("produtos");
    ResultSet funcionarios = (ResultSet) request.getAttribute("funcionarios");

    boolean achou; // controla a mensagem de "tabela vazia" em cada painel
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
  As "abas" (Pedidos / Clientes / Reservas / Produtos / Funcionários) trocam
  de conteúdo só com CSS, usando radio buttons escondidos. Só uma aba pode
  estar ativa por vez.

  Os dados de todas as tabelas vêm do servlet via request.setAttribute:
  "pedidos", "clientes", "reservas", "produtos" e "funcionarios".
-->
<input type="radio" name="admin-tab" id="tab-pedidos" class="admin-tab-radio" autocomplete="off" <%= "pedidos".equals(aba) ? "checked" : "" %> />
<input type="radio" name="admin-tab" id="tab-clientes" class="admin-tab-radio" autocomplete="off" <%= "clientes".equals(aba) ? "checked" : "" %> />
<input type="radio" name="admin-tab" id="tab-reservas" class="admin-tab-radio" autocomplete="off" <%= "reservas".equals(aba) ? "checked" : "" %> />
<input type="radio" name="admin-tab" id="tab-produtos" class="admin-tab-radio" autocomplete="off" <%= "produtos".equals(aba) ? "checked" : "" %> />
<input type="radio" name="admin-tab" id="tab-funcionarios" class="admin-tab-radio" autocomplete="off" <%= "funcionarios".equals(aba) ? "checked" : "" %> />

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
            <a href="ControleLogin?acao=sair">
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
                <div class="admin-panel-header">
                    <div>
                        <h1>Pedidos</h1>
                        <p class="admin-panel-subtitle">Acompanhamento dos pedidos em andamento e finalizados.</p>
                    </div>
                    <label for="tab-reservas" class="btn btn-primary">Novo pedido</label>
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
                            </select>
                        </div>

                        <div class="admin-filter-actions">
                            <a href="#" class="btn btn-outline">Buscar</a>
                        </div>
                    </div>

                    <div class="admin-table-wrap">
                        <table class="admin-table">

                            <thead>
                            <tr>
                                <th>Nº</th>
                                <th>Nome Cliente</th>
                                <th>Nº Reserva</th>
                                <th>Mesa</th>
                                <th>Data</th>
                                <th>Status</th>
                                <th>Total</th>
                                <th>Ações</th>
                            </tr>
                            </thead>

                            <tbody>

                            <%
                                achou = false;

                                if (pedidos != null) {
                                    while (pedidos.next()) {
                                        achou = true;

                                        String clientePedido = pedidos.getString("cliente");

                                        int reservaPedido = pedidos.getInt("id_reserva");
                                        boolean semReservaPedido = pedidos.wasNull();

                                        int mesaPedido = pedidos.getInt("id_mesa");
                                        boolean semMesaPedido = pedidos.wasNull();

                                        String statusPedido = pedidos.getString("status");
                            %>

                            <tr>
                                <td><%= pedidos.getInt("id_pedido") %></td>
                                <td><%= clientePedido == null ? "—" : esc(clientePedido) %></td>
                                <td><%= semReservaPedido ? "—" : reservaPedido %></td>
                                <td><%= semMesaPedido ? "—" : "Mesa " + mesaPedido %></td>
                                <td><%= fmtData(pedidos.getTimestamp("data_pedido"), false) %></td>

                                <td>
                                <span class="status-pill <%= statusClass(statusPedido) %>">
                                <%= esc(statusPedido) %>
                                </span>
                                </td>

                                <td><%= fmtPreco(pedidos.getBigDecimal("valor_total")) %></td>

                                <td>
                                    <div class="admin-row-actions">
                                        <a href="#" class="chip-btn">Ver</a>
                                        <a href="#" class="chip-btn">Editar</a>
                                        <a href="#" class="chip-btn">Cancelar</a>
                                    </div>
                                </td>
                            </tr>

                            <%
                                    }
                                }

                                if (!achou) {
                            %>
                            <tr>
                                <td colspan="8">Nenhum pedido cadastrado.</td>
                            </tr>
                            <%
                                }
                            %>

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
                    <a href="cadastroCliente.jsp" class="btn btn-primary">Novo cliente</a>
                </div>

                <div class="admin-table-wrap">
                    <table class="admin-table">
                        <thead>
                        <tr>
                            <th>Nº ID</th>
                            <th>Nome</th>
                            <th>E-mail</th>
                            <th>Telefone</th>
                            <th></th>
                        </tr>
                        </thead>
                        <tbody>
                        <%
                            achou = false;
                            if (clientes != null) {
                                while (clientes.next()) {
                                    achou = true;
                        %>
                        <tr>
                            <td><%= clientes.getInt("id_cliente") %></td>
                            <td><%= esc(clientes.getString("nome")) %></td>
                            <td><%= esc(clientes.getString("email")) %></td>
                            <td><%= esc(clientes.getString("telefone")) %></td>
                            <td>
                                <div class="admin-row-actions">
                                    <a href="<%= request.getContextPath() %>/ControleCliente?origem=editar&id=<%= clientes.getInt("id_cliente") %>">Editar</a>
                                </div>
                            </td>
                        </tr>
                        <%
                                }
                            }
                            if (!achou) {
                        %>
                        <tr><td colspan="5">Nenhum cliente cadastrado.</td></tr>
                        <% } %>
                        </tbody>
                    </table>
                </div>
            </section>

            <!-- ============ PAINEL: RESERVAS ============ -->
            <section class="admin-panel" id="panel-reservas" aria-label="Reservas">
                <div class="admin-panel-header">
                    <h1>Reservas</h1>
                    <a href="<%= request.getContextPath() %>/gerenciamentoAdmins/cadastroReserva.jsp" class="btn btn-primary">Nova reserva</a>
                </div>

                <% if (aviso != null && "reservas".equals(aba)) { %>
                <p class="admin-aviso" role="status"><%= esc(aviso) %></p>
                <% } %>

                <div class="admin-table-wrap">
                    <table class="admin-table">
                        <thead>
                        <tr>
                            <th>Nº</th>
                            <th>Cliente</th>
                            <th>Contato</th>
                            <th>Horário</th>
                            <th>Pessoas</th>
                            <th>Mesa</th>
                            <th>Status</th>
                            <th></th>
                        </tr>
                        </thead>
                        <tbody>
                        <%
                            achou = false;
                            if (reservas != null) {
                                while (reservas.next()) {
                                    achou = true;
                                    String clienteReserva = reservas.getString("cliente");
                                    String emailReserva = reservas.getString("email");
                                    String telReserva = reservas.getString("telefone");
                                    int mesaReserva = reservas.getInt("id_mesa");
                                    boolean semMesaReserva = reservas.wasNull();
                                    String statusReserva = reservas.getString("status");
                        %>
                        <tr>
                            <td>#<%= reservas.getInt("id_reserva") %></td>
                            <td><%= clienteReserva == null ? "—" : esc(clienteReserva) %></td>
                            <td>
                                <%= esc(telReserva) %>
                                <% if (emailReserva != null && !emailReserva.isEmpty()) { %>
                                <br /><%= esc(emailReserva) %>
                                <% } %>
                            </td>
                            <td><%= fmtData(reservas.getTimestamp("horario"), true) %></td>
                            <td><%= reservas.getInt("qtd_pessoas") %></td>
                            <td><%= semMesaReserva ? "—" : "Mesa " + mesaReserva %></td>
                            <td><span class="status-pill <%= statusClass(statusReserva) %>"><%= esc(statusReserva) %></span></td>
                            <%
                                int idReservaLinha = reservas.getInt("id_reserva");
                            %>
                            <td>
                                <div class="admin-row-actions">
                                    <% if ("pendente".equalsIgnoreCase(statusReserva)) { %>
                                    <form action="ControleReserva" method="post" style="display:inline">
                                        <input type="hidden" name="origem" value="confirmarChegada" />
                                        <input type="hidden" name="id_reserva" value="<%= idReservaLinha %>" />
                                        <button type="submit" class="chip-btn">Confirmar chegada</button>
                                    </form>
                                    <% } else if ("confirmada".equalsIgnoreCase(statusReserva) && !semMesaReserva) { %>
                                    <form action="ControlePedidos" method="post" style="display:inline">
                                        <input type="hidden" name="origem" value="cadastrarPedido" />
                                        <input type="hidden" name="id_reserva" value="<%= idReservaLinha %>" />
                                        <button type="submit" class="chip-btn">Abrir pedido</button>
                                    </form>
                                    <% } %>

                                    <% if ("pendente".equalsIgnoreCase(statusReserva) || "confirmada".equalsIgnoreCase(statusReserva)) { %>
                                    <a href="<%= request.getContextPath() %>/ControleReserva?origem=editar&id=<%= idReservaLinha %>" class="chip-btn">Editar</a>
                                    <% } %>

                                    <% if ("pendente".equalsIgnoreCase(statusReserva) || "confirmada".equalsIgnoreCase(statusReserva)) { %>
                                    <form action="ControleReserva" method="post" style="display:inline"
                                          onsubmit="return confirm('Cancelar esta reserva?');">
                                        <input type="hidden" name="origem" value="cancelar" />
                                        <input type="hidden" name="id_reserva" value="<%= idReservaLinha %>" />
                                        <button type="submit" class="chip-btn">Cancelar</button>
                                    </form>
                                    <% } %>
                                </div>
                            </td>
                        </tr>
                        <%
                                }
                            }
                            if (!achou) {
                        %>
                        <tr><td colspan="8">Nenhuma reserva encontrada.</td></tr>
                        <% } %>
                        </tbody>
                    </table>
                </div>
            </section>

            <!-- ============ PAINEL: PRODUTOS ============ -->
            <section class="admin-panel" id="panel-produtos" aria-label="Produtos">
                <div class="admin-panel-header">
                    <h1>Produtos</h1>
                    <a href="cadastroProduto.jsp" class="btn btn-primary">Novo produto</a>
                </div>

                <% if (aviso != null && "produtos".equals(aba)) { %>
                <p class="admin-aviso" role="status"><%= esc(aviso) %></p>
                <% } %>

                <div class="admin-table-wrap">
                    <table class="admin-table">
                        <thead>
                        <tr>
                            <th>Nª ID</th>
                            <th>Nome</th>
                            <th>Categoria</th>
                            <th>Descrição</th>
                            <th>Preço</th>
                            <th>Disponibilidade</th>
                            <th></th>
                        </tr>
                        </thead>
                        <tbody>
                        <%
                            achou = false;
                            if (produtos != null) {
                                while (produtos.next()) {
                                    achou = true;
                                    String dispProduto = produtos.getString("disponibilidade");
                        %>
                        <tr>

                            <td><%= esc(produtos.getString("id_produto")) %></td>
                            <td><%= esc(produtos.getString("nome")) %></td>
                            <td><%= esc(produtos.getString("categoria")) %></td>
                            <td><%= esc(produtos.getString("descricao")) %></td>
                            <td><%= fmtPreco(produtos.getBigDecimal("preco")) %></td>
                            <td><span class="status-pill <%= statusClass(dispProduto) %>"><%= rotuloDisponibilidade(dispProduto) %></span></td>
                            <td>
                                <div class="admin-row-actions">
                                    <a href="#">Editar</a>
                                </div>
                            </td>
                        </tr>
                        <%
                                }
                            }
                            if (!achou) {
                        %>
                        <tr>
                            <td colspan="6">Nenhum produto cadastrado.</td>
                        </tr>
                        <% } %>
                        </tbody>
                    </table>
                </div>
            </section>

            <!-- ============ PAINEL: FUNCIONÁRIOS ============ -->
            <section class="admin-panel" id="panel-funcionarios" aria-label="Funcionários">
                <div class="admin-panel-header">
                    <h1>Funcionários</h1>
                    <a href="cadastroFuncionario.jsp" class="btn btn-primary">Novo funcionário</a>
                </div>

                <div class="admin-table-wrap">
                    <table class="admin-table">
                        <thead>
                        <tr>
                            <th>Nº ID</th>
                            <th>Nome</th>
                            <th>Cargo</th>
                            <th>Mobile</th>
                            <th>E-mail</th>
                            <th>Admissão</th>
                            <th></th>
                        </tr>
                        </thead>
                        <tbody>
                        <%
                            achou = false;
                            if (funcionarios != null) {
                                while (funcionarios.next()) {
                                    achou = true;
                        %>
                        <tr>
                            <td><%= esc(funcionarios.getString("id_func")) %></td>
                            <td><%= esc(funcionarios.getString("nome")) %></td>
                            <td><%= esc(funcionarios.getString("cargo")) %></td>
                            <td><%= esc(funcionarios.getString("usermobi")) %></td>
                            <td><%= esc(funcionarios.getString("email")) %></td>
                            <td><%= esc(funcionarios.getString("admissao")) %></td>
                            <td>
                                <div class="admin-row-actions">
                                    <a href="#">Editar</a>
                                </div>
                            </td>
                        </tr>
                        <%
                                }
                            }
                            if (!achou) {
                        %>
                        <tr><td colspan="7">Nenhum funcionário cadastrado.</td></tr>
                        <% } %>
                        </tbody>
                    </table>
                </div>
            </section>

        </div>
    </main>

</div>
</body>
</html>
