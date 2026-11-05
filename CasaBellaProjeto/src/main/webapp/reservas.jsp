<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    // Só cliente logado pode reservar. Os outros voltam para o login.
    if (!"cliente".equals(session.getAttribute("perfil"))) {
        response.sendRedirect("login.html");
        return;
    }

    String hoje = java.time.LocalDate.now().toString();
%>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Reservar mesa — Casa Bella</title>
    <meta name="description" content="Reserve uma mesa na Casa Bella." />

    <link rel="preconnect" href="https://fonts.googleapis.com" />
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
    <link href="https://fonts.googleapis.com/css2?family=Fraunces:ital,wght@0,500;0,600;1,500;1,600&family=Manrope:wght@400;500;600;700&display=swap" rel="stylesheet" />

    <link rel="stylesheet" href="main.css" />

    <!-- O main.css só estiliza input dentro de .field. Aqui entra o select (pode ir para o main.css). -->
    <style>
        .field select {
            background: var(--color-bg-elevated);
            border: 1px solid var(--color-line);
            border-radius: var(--radius);
            padding: 0.85rem 1rem;
            font-family: var(--font-body);
            font-size: var(--step-0);
            color: var(--color-cream);
            transition: border-color 0.2s ease, background 0.2s ease;
        }
        .field select:focus { outline: none; border-color: var(--color-gold); background: var(--color-bg-elevated-2); }
        .field input[type="date"] { color-scheme: dark; }
        .field-help { font-size: var(--step--1); color: var(--color-cream-muted); }
    </style>
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
            <a href="areaCliente.jsp" class="avatar-button" aria-label="Minha área">
                <svg viewBox="0 0 24 24" fill="none" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round">
                    <circle cx="12" cy="8" r="3.6"></circle>
                    <path d="M4.5 20c1.6-3.6 4.6-5.4 7.5-5.4s5.9 1.8 7.5 5.4"></path>
                </svg>
            </a>
        </div>
    </div>
</header>

<main id="conteudo-principal">

    <section class="auth" aria-label="Reservar mesa">
        <div class="container">
            <figure class="auth-figure">
                <img src="https://picsum.photos/seed/casabella-reserva/800/1000" alt="Mesa posta no salão do restaurante, com velas e taças" />
            </figure>

            <div class="auth-panel">
                <span class="eyebrow-mark">Reservas</span>
                <h1 class="section-title">Reserve a sua mesa</h1>
                <p class="auth-lead">Escolha o dia, o horário e quantas pessoas vão à mesa. Sua reserva fica pendente até a nossa confirmação.</p>

                <form class="auth-form" action="ControleReserva" method="post">

                    <div class="field">
                        <label for="data">Data</label>
                        <input type="date" id="data" name="data" min="<%= hoje %>" required />
                        <span class="field-help">Terça a sexta, a partir das 18h. Sábado e domingo, a partir das 12h. Fechado às segundas.</span>
                    </div>

                    <div class="field">
                        <label for="hora">Horário</label>
                        <select id="hora" name="hora" required>
                            <option value="" disabled selected>Escolha um horário</option>
                            <%
                                for (int h = 12; h <= 22; h++) {
                                    for (int m = 0; m < 60; m += 30) {
                                        if (h == 22 && m == 30) break;
                                        String hh = String.format("%02d:%02d", h, m);
                            %>
                            <option value="<%= hh %>"><%= hh.replace(":", "h") %></option>
                            <%
                                    }
                                }
                            %>
                        </select>
                    </div>

                    <div class="field">
                        <label for="pessoas">Número de pessoas</label>
                        <select id="pessoas" name="pessoas" required>
                            <% for (int p = 1; p <= 6; p++) { %>
                            <option value="<%= p %>" <%= p == 2 ? "selected" : "" %>><%= p %> <%= p == 1 ? "pessoa" : "pessoas" %></option>
                            <% } %>
                        </select>
                        <span class="field-help">Para grupos maiores, ligue para (11) 3040-5060.</span>
                    </div>

                    <button type="submit" class="btn btn-primary btn-block">Solicitar reserva</button>
                </form>

                <p class="auth-switch">
                    Quer ver os pratos antes?
                    <a href="cardapio.html" class="link-gold">Abrir cardápio</a>
                </p>
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
