<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%!
    private String esc(String s) {
        if (s == null) return "";
        return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;");
    }
%>
<%
    // f = {id_func, nome, usermobi, email, cargo, admissao}
    String[] f = (String[]) request.getAttribute("funcionario");
    if (f == null) {
        response.sendRedirect(request.getContextPath() + "/PainelGerenciamento?aba=funcionarios");
        return;
    }
%>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Editar funcionário — Casa Bella</title>

    <link rel="preconnect" href="https://fonts.googleapis.com" />
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
    <link href="https://fonts.googleapis.com/css2?family=Fraunces:ital,wght@0,500;0,600;1,500;1,600&family=Manrope:wght@400;500;600;700&display=swap" rel="stylesheet" />

    <link rel="stylesheet" href="main.css" />
</head>
<body>

<main id="conteudo-principal">
    <section class="account" aria-label="Editar funcionário">
        <div class="container">

            <span class="eyebrow-mark">Gerenciamento</span>
            <h1 class="section-title">Editar funcionário</h1>

            <div class="edit-card">
                <h2>Dados do funcionário</h2>
                <p>Altere os dados abaixo e salve. A senha não é alterada aqui.</p>

                <form class="auth-form" action="ControleFuncionario" method="post">
                    <input type="hidden" name="origem" value="alterarFuncionario" />
                    <input type="hidden" name="id_func" value="<%= esc(f[0]) %>" />

                    <div class="field">
                        <label for="idFunc">Nº ID</label>
                        <input type="text" id="idFunc" value="<%= esc(f[0]) %>" readonly />
                    </div>

                    <div class="field">
                        <label for="nome">Nome</label>
                        <input type="text" id="nome" name="nome" value="<%= esc(f[1]) %>" autocomplete="name" required />
                    </div>

                    <div class="field">
                        <label for="usermobi">Mobile (usuário)</label>
                        <input type="text" id="usermobi" name="usermobi" value="<%= esc(f[2]) %>" required />
                    </div>

                    <div class="field">
                        <label for="email">E-mail</label>
                        <input type="email" id="email" name="email" value="<%= esc(f[3]) %>" autocomplete="email" required />
                    </div>

                    <div class="field">
                        <label for="cargo">Cargo</label>
                        <input type="text" id="cargo" name="cargo" value="<%= esc(f[4]) %>" required />
                    </div>

                    <div class="field">
                        <label for="admissao">Admissão</label>
                        <input type="date" id="admissao" name="admissao" value="<%= esc(f[5]) %>" />
                    </div>

                    <div class="form-actions">
                        <button type="submit" class="btn btn-primary">Salvar alterações</button>
                        <a href="<%= request.getContextPath() %>/PainelGerenciamento?aba=funcionarios" class="link-gold">Cancelar</a>
                    </div>
                </form>
            </div>

        </div>
    </section>
</main>

</body>
</html>