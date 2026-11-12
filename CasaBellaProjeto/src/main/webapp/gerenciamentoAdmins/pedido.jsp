<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.sql.ResultSet, java.sql.Timestamp, java.math.BigDecimal, java.text.SimpleDateFormat, java.util.Locale"%>
<%!
    // Mesmas funções de apoio do gerenciamento.jsp
    private String esc(String s) {
        if (s == null) return "";
        return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;");
    }

    private String fmtData(Timestamp t, boolean comAno) {
        if (t == null) return "—";
        String padrao = comAno ? "dd/MM/yyyy · HH'h'mm" : "dd/MM · HH'h'mm";
        return new SimpleDateFormat(padrao).format(t);
    }

    private String fmtPreco(BigDecimal v) {
        if (v == null) return "—";
        return String.format(new Locale("pt", "BR"), "R$ %,.2f", v);
    }

    private String statusClass(String status) {
        if (status == null) return "is-pendente";
        String s = status.toLowerCase();
        if (s.contains("preparo"))                          return "is-preparo";
        if (s.contains("conclu") || s.contains("confirm") || s.equals("disponivel")) return "is-concluido";
        if (s.contains("cancel") || s.equals("indisponivel")) return "is-cancelado";
        return "is-pendente";
    }
%>
<%
    String base = request.getContextPath();

    // Dados de quem logou (igual ao gerenciamento.jsp)
    String nome = (String) request.getAttribute("nome");
    if (nome == null) nome = (String) session.getAttribute("nome");
    if (nome == null) nome = "Funcionário(a)";

    String cargo = (String) request.getAttribute("cargo");
    if (cargo == null) cargo = (String) session.getAttribute("cargo");

    // Dados enviados pelo ControlePedidos (origem=verPedido)
    ResultSet pedido   = (ResultSet) request.getAttribute("pedido");
    ResultSet itens    = (ResultSet) request.getAttribute("itens");
    ResultSet produtos = (ResultSet) request.getAttribute("produtos");

    // Aviso vindo na URL (ex.: "Produto indisponível.")
    String aviso = request.getParameter("aviso");

    // Se abriram o JSP direto (sem passar pelo controle), volta para o painel
    if (pedido == null || !pedido.next()) {
        response.sendRedirect(base + "/PainelGerenciamento?aba=pedidos");
        return;
    }

    int idPedido = pedido.getInt("id_pedido");
    String cliente = pedido.getString("cliente");
    int idReserva = pedido.getInt("id_reserva");
    boolean semReserva = pedido.wasNull();
    int idMesa = pedido.getInt("id_mesa");
    boolean semMesa = pedido.wasNull();
    String status = pedido.getString("status");
    boolean aberto = "em preparo".equalsIgnoreCase(status);
    BigDecimal total = pedido.getBigDecimal("valor_total");
    boolean achou;
%>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Pedido #<%= idPedido %> — Casa Bella</title>

    <link rel="preconnect" href="https://fonts.googleapis.com" />
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
    <link href="https://fonts.googleapis.com/css2?family=Fraunces:ital,wght@0,500;0,600;1,500;1,600&family=Manrope:wght@400;500;600;700&display=swap" rel="stylesheet" />

    <link rel="stylesheet" href="<%= base %>/main.css" />
</head>
<body>

<input type="radio" name="admin-tab" id="tab-pedidos" class="admin-tab-radio" autocomplete="off" checked />
<input type="radio" name="admin-tab" id="tab-clientes" class="admin-tab-radio" autocomplete="off" />
<input type="radio" name="admin-tab" id="tab-reservas" class="admin-tab-radio" autocomplete="off" />
<input type="radio" name="admin-tab" id="tab-produtos" class="admin-tab-radio" autocomplete="off" />
<input type="radio" name="admin-tab" id="tab-funcionarios" class="admin-tab-radio" autocomplete="off" />

<div class="admin-shell">

    <!-- ============ BARRA LATERAL ============ -->
    <aside class="admin-sidebar">
        <a href="<%= base %>/index.html" class="admin-logo">
            <span class="brand-mark">Casa <em>Bella</em></span>
        </a>

        <!-- Aqui as abas viram navegação: clicar leva de volta ao painel na aba escolhida -->
        <nav class="admin-nav" aria-label="Navegação do painel">
            <label for="tab-pedidos"      onclick="location.href='<%= base %>/PainelGerenciamento?aba=pedidos'">Pedidos</label>
            <label for="tab-clientes"     onclick="location.href='<%= base %>/PainelGerenciamento?aba=clientes'">Clientes</label>
            <label for="tab-reservas"     onclick="location.href='<%= base %>/PainelGerenciamento?aba=reservas'">Reservas</label>
            <label for="tab-produtos"     onclick="location.href='<%= base %>/PainelGerenciamento?aba=produtos'">Produtos</label>
            <label for="tab-funcionarios" onclick="location.href='<%= base %>/PainelGerenciamento?aba=funcionarios'">Funcionários</label>
        </nav>

        <div class="admin-logout">
            <a href="<%= base %>/ControleLogin?acao=sair">
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

            <!-- ============ PAINEL: PEDIDO (detalhe) ============ -->
            <section class="admin-panel" id="panel-pedidos" aria-label="Pedido">
                <div class="admin-panel-header">
                    <div>
                        <h1>Pedido #<%= idPedido %></h1>
                        <p class="admin-panel-subtitle">
                            <%= cliente == null ? "—" : esc(cliente) %>
                            • <%= semMesa ? "sem mesa" : "Mesa " + idMesa %>
                            • <%= semReserva ? "sem reserva" : "Reserva #" + idReserva %>
                            • aberto em <%= fmtData(pedido.getTimestamp("data_pedido"), true) %>
                        </p>
                    </div>
                    <div>
                        <span class="status-pill <%= statusClass(status) %>"><%= esc(status) %></span>
                        <a href="<%= base %>/PainelGerenciamento?aba=pedidos" class="btn btn-outline">Voltar</a>
                    </div>
                </div>

                <% if (aviso != null && !aviso.isEmpty()) { %>
                <p class="admin-aviso" role="status"><%= esc(aviso) %></p>
                <% } %>

                <div class="admin-panel-card">

                    <% if (aberto) { %>
                    <!-- ADICIONAR PRODUTO -->
                    <form action="<%= base %>/ControlePedidos" method="post" class="admin-filter-bar">
                        <input type="hidden" name="origem" value="adicionarItemPainel" />
                        <input type="hidden" name="id_pedido" value="<%= idPedido %>" />

                        <div class="admin-filter-field">
                            <label for="id_produto">Produto</label>
                            <select id="id_produto" name="id_produto" required>
                                <option value="">Selecione</option>
                                <%
                                    if (produtos != null) {
                                        while (produtos.next()) {
                                %>
                                <option value="<%= produtos.getInt("id_produto") %>">
                                    <%= esc(produtos.getString("categoria")) %> - <%= esc(produtos.getString("nome")) %>
                                    (<%= fmtPreco(produtos.getBigDecimal("preco")) %>)
                                </option>
                                <%
                                        }
                                    }
                                %>
                            </select>
                        </div>

                        <div class="admin-filter-field">
                            <label for="quantidade">Quantidade</label>
                            <input type="number" id="quantidade" name="quantidade" min="1" value="1" required />
                        </div>

                        <div class="admin-filter-actions">
                            <button type="submit" class="btn btn-primary">Adicionar ao pedido</button>
                        </div>
                    </form>
                    <% } %>

                    <!-- ITENS DO PEDIDO -->
                    <div class="admin-table-wrap">
                        <table class="admin-table">
                            <thead>
                            <tr>
                                <th>Produto</th>
                                <th>Qtd</th>
                                <th>Preço un.</th>
                                <th>Subtotal</th>
                                <th></th>
                            </tr>
                            </thead>
                            <tbody>
                            <%
                                achou = false;
                                if (itens != null) {
                                    while (itens.next()) {
                                        achou = true;
                                        int idItem = itens.getInt("id_itens");
                                        int qtd = itens.getInt("quantidade");
                                        BigDecimal precoUni = itens.getBigDecimal("preco_uni");
                                        BigDecimal subtotal = precoUni.multiply(BigDecimal.valueOf(qtd));
                            %>
                            <tr>
                                <td><%= esc(itens.getString("nome")) %></td>
                                <td><%= qtd %></td>
                                <td><%= fmtPreco(precoUni) %></td>
                                <td><%= fmtPreco(subtotal) %></td>
                                <td>
                                    <% if (aberto) { %>
                                    <div class="admin-row-actions">
                                        <form action="<%= base %>/ControlePedidos" method="post" style="display:inline">
                                            <input type="hidden" name="origem" value="removerItem" />
                                            <input type="hidden" name="id_pedido" value="<%= idPedido %>" />
                                            <input type="hidden" name="id_itens" value="<%= idItem %>" />
                                            <button type="submit" class="chip-btn">Remover</button>
                                        </form>
                                    </div>
                                    <% } %>
                                </td>
                            </tr>
                            <%
                                    }
                                }
                                if (!achou) {
                            %>
                            <tr><td colspan="5">Nenhum item neste pedido ainda.</td></tr>
                            <% } %>
                            </tbody>
                            <tfoot>
                            <tr>
                                <th colspan="3" style="text-align:right">Total</th>
                                <th colspan="2"><%= fmtPreco(total) %></th>
                            </tr>
                            </tfoot>
                        </table>
                    </div>

                    <% if (aberto) { %>
                    <!-- FECHAR O PEDIDO -->
                    <div class="admin-row-actions" style="margin-top:16px">
                        <form action="<%= base %>/ControlePedidos" method="post" style="display:inline"
                              onsubmit="return confirm('Finalizar este pedido?');">
                            <input type="hidden" name="origem" value="finalizar" />
                            <input type="hidden" name="id_pedido" value="<%= idPedido %>" />
                            <button type="submit" class="btn btn-primary">Finalizar pedido</button>
                        </form>

                        <form action="<%= base %>/ControlePedidos" method="post" style="display:inline"
                              onsubmit="return confirm('Cancelar este pedido?');">
                            <input type="hidden" name="origem" value="cancelar" />
                            <input type="hidden" name="id_pedido" value="<%= idPedido %>" />
                            <button type="submit" class="btn btn-outline">Cancelar pedido</button>
                        </form>
                    </div>
                    <% } %>

                </div>
            </section>

        </div>
    </main>

</div>
</body>
</html>
