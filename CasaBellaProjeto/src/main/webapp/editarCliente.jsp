//ATENÇÃO, ESTA É A ALTERAÇÃO FEITA A PARTIR DO CLIENTE, PELO PRÓPRIO CLIENTE NA ÁREA DE CLIENTE.
//AS ALETRAÇÕES FEITA POR ADMINS É OUTRO ARQUIVO

<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%!
    // Escapa caracteres especiais antes de imprimir um texto dentro do HTML
    private String esc(String s) {
        if (s == null) return "";
        return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;");
    }
%>
<%
    // Só cliente logado pode ver esta página (o ControleLogin guarda o "perfil" na sessão)
    if (!"cliente".equals(session.getAttribute("perfil"))) {
        response.sendRedirect("login.html");
        return;
    }

    // O ControleCliente (origem=carregar) busca o cliente no banco e envia para cá.
    // Se alguém abrir a página direto, pedimos ao servlet para buscar os dados.
    // O ControleCliente (origem=carregar) busca o cliente no banco e envia: {id, nome, email, telefone}
    String[] cliente = (String[]) request.getAttribute("cliente");
    if (cliente == null) {
        response.sendRedirect("ControleCliente?origem=carregar");
        return;
    }
%>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Editar meus dados — Casa Bella</title>
    <meta name="description" content="Altere seus dados ou exclua sua conta na Casa Bella." />

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

    <section class="account" aria-label="Editar meus dados">
        <div class="container">

            <div class="account-head">
                <div>
                    <span class="eyebrow-mark">Área do cliente</span>
                    <h1>Editar meus dados</h1>
                    <p class="account-sub">Mantenha suas informações atualizadas.</p>
                </div>
                <div class="account-head-actions">
                    <a href="areaCliente.jsp" class="link-gold">Voltar para minha área</a>
                </div>
            </div>

            <div class="edit-wrap">

                <!-- ========== ALTERAR DADOS ========== -->
                <div class="edit-card">
                    <h2>Dados pessoais</h2>
                    <p>Altere seu nome e telefone. O e-mail é o seu login e não pode ser trocado aqui.</p>

                    <!--
                      O e-mail que identifica o registro NÃO vem deste formulário:
                      o servlet pega da sessão (quem fez login). Por isso o campo de
                      e-mail abaixo é só para exibição e não tem "name".
                    -->
                    <form class="auth-form" action="ControleCliente" method="post">
                        <input type="hidden" name="origem" value="alterar" />
                        <input type="hidden" name="id_cliente" value="<%= esc(cliente[0]) %>" />

                        <div class="field">
                            <label for="nome">Nome completo</label>
                            <input type="text" id="nome" name="nome" value="<%= esc(cliente[1]) %>" autocomplete="name" required />
                        </div>

                        <div class="field">
                            <label for="email">E-mail</label>
                            <input type="email" id="email" value="<%= esc(cliente[3])%>" readonly />
                        </div>

                        <div class="field">
                            <label for="telefone">Telefone</label>
                            <input type="tel" id="telefone" name="telefone" value="<%= esc(cliente[4]) %>" autocomplete="tel" required />
                        </div>

                        <div class="form-actions">
                            <button type="submit" class="btn btn-primary">Salvar alterações</button>
                            <a href="areaCliente.jsp" class="link-gold">Cancelar</a>
                        </div>
                    </form>
                </div>

                <!-- ========== EXCLUIR CONTA ========== -->
                <div class="edit-card is-danger">
                    <h2>Excluir minha conta</h2>
                    <p>Esta ação não pode ser desfeita. Para confirmar, digite a sua senha.</p>

                    <form class="auth-form" action="ControleCliente" method="post">
                        <input type="hidden" name="origem" value="excluir" />

                        <div class="field">
                            <label for="senhaConfirma">Senha</label>
                            <input type="password" id="senhaConfirma" name="senha" placeholder="••••••••" autocomplete="current-password" required />
                        </div>

                        <div class="form-actions">
                            <button type="submit" class="btn btn-danger">Excluir minha conta</button>
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
