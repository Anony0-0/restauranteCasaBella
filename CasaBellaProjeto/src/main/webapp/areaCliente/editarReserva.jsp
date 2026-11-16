<%@page contentType="text/html" pageEncoding="UTF-8"%>
   <%!
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
       String ctx = request.getContextPath();

       // Só cliente logado
       if (!"cliente".equals(session.getAttribute("perfil"))) {
           response.sendRedirect(ctx + "/login.html");
           return;
       }

       // O ControleReserva (origem=editarMinha) envia: {id, cliente, data, hora, pessoas, status}
       String[] reserva = (String[]) request.getAttribute("reserva");
       if (reserva == null) {
           response.sendRedirect(ctx + "/ControleReserva?origem=listarMinhas");
           return;
       }

       String erro = (String) request.getAttribute("erro");
   %>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Alterar reserva — Casa Bella</title>
    <meta name="description" content="Altere ou cancele sua reserva na Casa Bella." />
    <link rel="preconnect" href="https://fonts.googleapis.com" />
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
    <link href="https://fonts.googleapis.com/css2?family=Fraunces:ital,wght@0,500;0,600;1,500;1,600&family=Manrope:wght@400;500;600;700&display=swap" rel="stylesheet" />

    <link rel="stylesheet" href="<%= ctx %>/main.css" />
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

        <a href="<%= ctx %>/index.html" class="brand">
            <span class="brand-mark">Casa <em>Bella</em></span>
            <span class="brand-sub">CUCINA ITALIANA</span>
        </a>

        <div class="header-actions">
            <nav class="primary-nav" aria-label="Navegação principal">
                <ul>
                    <li><a href="<%= ctx %>/index.html#inicio">Início</a></li>
                    <li><a href="<%= ctx %>/index.html#sabores">Sabores</a></li>
                    <li><a href="<%= ctx %>/index.html#ambiente">Ambiente</a></li>
                    <li><a href="<%= ctx %>/index.html#contato">Contato</a></li>
                </ul>
            </nav>
            <a href="<%= ctx %>/ControleReserva?origem=listarMinhas" class="avatar-button" aria-label="Minha área">
                <svg viewBox="0 0 24 24" fill="none" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round">
                    <circle cx="12" cy="8" r="3.6"></circle>
                    <path d="M4.5 20c1.6-3.6 4.6-5.4 7.5-5.4s5.9 1.8 7.5 5.4"></path>
                </svg>
            </a>
        </div>
    </div>
</header>

<main id="conteudo-principal">

    <section class="account" aria-label="Alterar reserva">
        <div class="container">

            <div class="account-head">
                <div>
                    <span class="eyebrow-mark">Área do cliente</span>
                    <h1>Alterar reserva #<%= esc(reserva[0]) %></h1>
                    <p class="account-sub">Status atual: <%= esc(reserva[5]) %></p>
                </div>
                <div class="account-head-actions">
                    <a href="<%= ctx %>/ControleReserva?origem=listarMinhas" class="link-gold">Voltar para minha área</a>
                </div>
            </div>

            <div class="edit-wrap">

                <!-- ========== ALTERAR RESERVA ========== -->
                <div class="edit-card">
                    <h2>Data, horário e pessoas</h2>
                    <p>Se mudar o horário ou a quantidade de pessoas, conferimos se a mesa ainda serve e, se não servir, escolhemos outra.</p>

                    <% if (erro != null) { %>
                    <p role="alert" style="color: var(--color-gold-bright);"><%= esc(erro) %></p>
                    <% } %>

                    <form class="auth-form" action="<%= ctx %>/ControleReserva" method="post">
                        <input type="hidden" name="origem" value="atualizarMinha" />
                        <input type="hidden" name="id_reserva" value="<%= esc(reserva[0]) %>" />

                        <div class="field">
                            <label for="data">Data</label>
                            <input type="date" id="data" name="data" value="<%= esc(valor(request, "data", reserva[2])) %>" required />
                        </div>

                        <div class="field">
                            <label for="hora">Horário</label>
                            <input type="time" id="hora" name="hora" value="<%= esc(valor(request, "hora", reserva[3])) %>" required />
                        </div>

                        <div class="field">
                            <label for="pessoas">Quantidade de pessoas</label>
                            <input type="number" id="pessoas" name="pessoas" min="1" max="6" value="<%= esc(valor(request, "pessoas", reserva[4])) %>" required />
                        </div>

                        <div class="form-actions">
                            <button type="submit" class="btn btn-primary">Salvar alterações</button>
                            <a href="<%= ctx %>/ControleReserva?origem=listarMinhas" class="link-gold">Voltar</a>
                        </div>
                    </form>
                </div>

                <!-- ========== CANCELAR RESERVA ========== -->
                <input type="checkbox" id="abrir-excluir" class="delete-toggle" aria-controls="card-excluir" />

                <div class="profile-actions">
                    <label for="abrir-excluir" class="btn btn-danger">Cancelar reserva</label>
                </div>

                <div class="edit-card is-danger delete-card" id="card-excluir">
                    <h2>Cancelar reserva</h2>
                    <p>A reserva ficará marcada como "Cancelada" e a mesa será liberada.</p>

                    <form class="auth-form" action="<%= ctx %>/ControleReserva" method="post">
                        <input type="hidden" name="origem" value="cancelarMinha" />
                        <input type="hidden" name="id_reserva" value="<%= esc(reserva[0]) %>" />

                        <label class="field-check">
                            <input type="checkbox" required />
                            Confirmo que quero cancelar esta reserva
                        </label>

                        <div class="form-actions">
                            <button type="submit" class="btn btn-danger">Confirmar cancelamento</button>
                        </div>
                    </form>
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
