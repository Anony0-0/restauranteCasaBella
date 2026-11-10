<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.*, java.text.SimpleDateFormat, java.sql.ResultSet, java.sql.Timestamp"%>
<%!
    // Escapa caracteres especiais antes de imprimir um texto dentro do HTML
    private String esc(String s) {
        if (s == null) return "";
        return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;");
    }
%>
<%
    String nome = (String) request.getAttribute("nome");
    if (nome == null) nome = (String) session.getAttribute("nome");
    if (nome == null) nome = "Cliente";

    String email = (String) request.getAttribute("email");
    if (email == null) email = (String) session.getAttribute("email");
    if (email == null) email = "—";

    String telefone = (String) request.getAttribute("telefone");
    if (telefone == null) telefone = (String) session.getAttribute("telefone");
    if (telefone == null) telefone = "—";

    Integer idClienteLogado = (Integer) session.getAttribute("id_cliente");
    String primeiroNome = nome.trim().split("\\s+")[0];
%>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Área do cliente — Casa Bella</title>
    <meta name="description" content="Acompanhe suas reservas e pedidos na Casa Bella." />

    <link rel="preconnect" href="https://fonts.googleapis.com" />
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
    <link href="https://fonts.googleapis.com/css2?family=Fraunces:ital,wght@0,500;0,600;1,500;1,600&family=Manrope:wght@400;500;600;700&display=swap" rel="stylesheet" />

    <link rel="stylesheet" href="main.css" />
</head>
<body>

<a class="visually-hidden" href="#conteudo-principal">Pular para o conteúdo principal</a>

<!-- ============ CABEÇALHO ============ -->
<header class="site-header">
    <div class="container">
        <input type="checkbox" id="nav-toggle" class="nav-toggle-checkbox" />
        <label for="nav-toggle" class="nav-toggle">
            <span></span><span></span><span></span>
            <span class="visually-hidden">Abrir menu de navegação</span>
        </label>

        <a href="index.html" class="brand">
            <span class="brand-mark">Casa <em>Bella</em></span>
            <span class="brand-sub">CUCINA ITALIANA</span>
        </a>

        <div class="header-actions">
            <nav class="primary-nav" aria-label="Navegação principal">
                <ul>
                    <li><a href="index.html#inicio">Início</a></li>
                    <li><a href="index.html#sabores">Sabores</a></li>
                    <li><a href="index.html#ambiente">Ambiente</a></li>
                    <li><a href="index.html#contato">Contato</a></li>
                </ul>
            </nav>
            <a href="ControleLogin" class="avatar-button" aria-label="Minha área">
                <svg viewBox="0 0 24 24" fill="none" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round">
                    <circle cx="12" cy="8" r="3.6"></circle>
                    <path d="M4.5 20c1.6-3.6 4.6-5.4 7.5-5.4s5.9 1.8 7.5 5.4"></path>
                </svg>
            </a>
        </div>
    </div>
</header>

<main id="conteudo-principal">
    <section class="account" aria-label="Área do cliente">
        <div class="container">

            <input type="radio" name="account-tab" id="acc-reservas" class="account-radio" checked />
            <input type="radio" name="account-tab" id="acc-pedidos" class="account-radio" />
            <input type="radio" name="account-tab" id="acc-dados" class="account-radio" />

            <!-- Cabeçalho da página -->
            <div class="account-head">
                <div>
                    <span class="eyebrow-mark">Área do cliente</span>
                    <h1>Olá, <%= esc(primeiroNome) %></h1>
                    <p class="account-sub">Aqui você acompanha suas reservas e os pedidos feitos no seu nome.</p>
                </div>
                <div class="account-head-actions">
                    <a href="reservas.jsp" class="btn btn-primary">Nova reserva</a>
                    <a href="ControleLogin?acao=sair" class="link-gold">Sair</a>
                </div>
            </div>

            <!-- Destaque: próxima reserva -->
            <div class="next-reservation">
                <div class="next-reservation-date">
                    <span class="next-reservation-day">31</span>
                    <span class="next-reservation-month">out</span>
                </div>

                <div>
                    <span class="eyebrow-mark">Sua próxima reserva</span>
                    <p class="next-reservation-title">Sábado, às 20h00</p>
                    <p class="next-reservation-meta">4 pessoas, salão principal</p>
                </div>

                <div class="next-reservation-actions">
                    <span class="status-pill is-confirmada">Confirmada</span>
                    <a href="#" class="chip-btn">Ver detalhes</a>
                    <a href="#" class="chip-btn">Cancelar</a>
                </div>
            </div>

            <div class="account-body">
                <div class="account-tabs">
                    <label for="acc-reservas">Minhas reservas</label>
                    <label for="acc-pedidos">Meus pedidos</label>
                    <label for="acc-dados">Meus dados</label>
                </div>

                <!-- ========== RESERVAS ========== -->
                <div class="account-panel" id="acc-panel-reservas">
                    <div class="admin-table-wrap">
                        <table class="admin-table">
                            <thead>
                            <tr>
                                <th>Data / Horário</th>
                                <th>Pessoas</th>
                                <th>Mesa</th>
                                <th>Status</th>
                                <th></th>
                            </tr>
                            </thead>
                            <tbody>
                        <%
                            ResultSet rsReservas = (ResultSet) request.getAttribute("reservas");
                            SimpleDateFormat formatoData = new SimpleDateFormat("dd/MM/yyyy HH:mm");
                            boolean temReservas = false;

                            while (rsReservas != null && rsReservas.next()) {
                                temReservas = true;
                                Timestamp horarioReserva = rsReservas.getTimestamp("horario");
                                int qtdPessoas = rsReservas.getInt("qtd_pessoas");
                                int idMesa = rsReservas.getInt("id_mesa");
                                String statusReserva = rsReservas.getString("status");

                                String classeStatus = "is-pendente";
                                if ("Confirmada".equalsIgnoreCase(statusReserva)) classeStatus = "is-confirmada";
                                else if ("Realizada".equalsIgnoreCase(statusReserva)) classeStatus = "is-realizada";
                                else if ("Cancelada".equalsIgnoreCase(statusReserva)) classeStatus = "is-cancelada";
                        %>
                        <tr>
                            <td><%= esc(formatoData.format(horarioReserva)) %></td>
                            <td><%= qtdPessoas %></td>
                            <td>Mesa <%= idMesa %></td>
                            <td><span class="status-pill <%= classeStatus %>"><%= esc(statusReserva) %></span></td>
                            <td><a href="#" class="chip-btn">Ver</a></td>
                        </tr>
                        <%
                            }
                            if (!temReservas) {
                        %>
                        <tr>
                            <td colspan="5" style="text-align: center; color: var(--color-cream-muted);">Ainda não tem reservas registradas.</td>
                        </tr>
                        <%
                            }
                        %>
                        </tbody>
                        </table>
                    </div>
                </div>
                <!-- ========== MEUS DADOS========== -->
                <div class="account-panel" id="acc-panel-dados">
                    <dl class="profile-list">
                        <div>
                            <dt>Nome</dt>
                            <dd><%= esc(nome) %></dd>
                        </div>
                        <div>
                            <dt>E-mail</dt>
                            <dd><%= esc(email) %></dd>
                        </div>
                        <div>
                            <dt>Telefone</dt>
                            <dd><%= esc(telefone) %></dd>
                        </div>
                    </dl>

                    </dl>

                    <input type="checkbox" id="abrir-excluir" class="delete-toggle" aria-controls="card-excluir" />

                    <div class="profile-actions">
                        <a href="#" class="btn btn-outline">Editar meus dados</a>
                        <label for="abrir-excluir" class="btn btn-danger">Excluir minha conta</label>
                    </div>

                    <div class="edit-card is-danger delete-card" id="card-excluir">
                        <h2>Excluir minha conta</h2>
                        <p>Esta ação não pode ser desfeita. Para confirmar, digite a sua senha.</p>

                        <form class="auth-form" action="ControleCliente" method="post">
                            <input type="hidden" name="origem" value="excluir" />

                            <div class="field">
                                <label for="senhaExcluir">Senha</label>
                                <input type="password" id="senhaExcluir" name="senha" placeholder="••••••••" autocomplete="current-password" required />
                            </div>

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
                </div>
            </div>

        </div>
    </section>

</main>

<!-- ============ RODAPÉ ============ -->
<footer class="site-footer" id="contato">
    <div class="container footer-grid">
        <div class="footer-brand">
            <span class="brand-mark">Casa <em>Bella</em></span>
            <p>Cozinha italiana autêntica, carta de vinhos selecionada e um salão para celebrar
                o essencial: boa comida e boa companhia.</p>
        </div>

        <div class="footer-col">
            <h3>Endereço</h3>
            <address>
                Rua dos Jasmins, 214<br />
                Jardim Europa — São Paulo, SP<br />
                CEP 01449-000
            </address>
        </div>

        <div class="footer-col">
            <h3>Contato</h3>
            <ul>
                <li><a href="tel:+551130405060">(11) 3040-5060</a></li>
                <li><a href="mailto:ola@casabella.com.br">ola@casabella.com.br</a></li>
            </ul>
            <div class="social-row">
                <a href="#" aria-label="Instagram da Casa Bella">
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="1.6"><rect x="3" y="3" width="18" height="18" rx="5"></rect><circle cx="12" cy="12" r="4"></circle><circle cx="17.5" cy="6.5" r="1"></circle></svg>
                </a>
                <a href="#" aria-label="Facebook da Casa Bella">
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="1.6"><path d="M14 9h3V6h-3c-2 0-3.5 1.5-3.5 3.5V12H8v3h2.5v6h3v-6H16l.5-3h-3V9.7c0-.4.3-.7.7-.7z"></path></svg>
                </a>
            </div>
        </div>

        <div class="footer-col">
            <h3>Horário</h3>
            <ul>
                <li>Ter a sex — 18h às 23h30</li>
                <li>Sáb e dom — 12h às 23h30</li>
                <li>Segunda — fechado</li>
            </ul>
        </div>
    </div>

    <div class="container footer-bottom">
        <p>© 2026 Casa Bella. Todos os direitos reservados.</p>
        <p>Projeto acadêmico — desenvolvido para fins de estudo.</p>
    </div>
</footer>

</body>
</html>
