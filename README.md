# Casa Bella — Cucina Italiana

Aplicativo Flutter de atendimento, cardápio e acompanhamento de pedidos.

## Arquitetura MVC

- `lib/models/`: modelos tipados que espelham clientes, usuários, produtos, mesas, reservas, pedidos e itens de pedido.
- `lib/controllers/`: regras de autenticação, catálogo, mesas e pedidos; as telas chamam os controladores.
- `lib/repositories/`: persistência offline e comunicação opcional com a API da cozinha.
- `lib/telas/`: apresentação e navegação do aplicativo.
- `database/schema.sql`: esquema relacional SQL Server legado de referência.
- `database/mysql_schema.sql`: estrutura MySQL baseada no SQL anexado (7 tabelas e triggers de total).

O anexo diz “Total: 6”, mas descreve também `itens_pedido` como tabela própria. O esquema contempla as **7 tabelas descritas**. A senha é armazenada como hash; o aplicativo não deve gravar senha em texto aberto.

## Funcionalidades

- Cadastro/login local de colaboradores por ID de usuário e senha. O ID é gerado automaticamente no dispositivo e exibido ao concluir o cadastro; o primeiro cadastro recebe perfil Gerente e os seguintes recebem perfil Atendente. Em instalações anteriores sem perfil gerente, o primeiro colaborador cadastrado é promovido para permitir a gestão da equipe. Cadastros locais antigos que usavam CPF recebem um ID durante a migração.
- Gerenciamento da equipe para Gerente/Administrador: consultar colaboradores e remover o acesso de quem não trabalha mais no local; o último gerente e a conta da sessão não podem ser removidos.
- Catálogo com busca e filtro por categoria, carrinho e total do pedido.
- Seleção de mesas com capacidade ou atendimento de balcão.
- Criação local de pedidos com identificadores de mesa/produto, itens, quantidades, preços e total.
- Acompanhamento do status, com integração opcional à API da cozinha.
- Alteração de quantidades e remoção de itens, além de cancelamento enquanto o pedido estiver aguardando ou em preparo. Pedidos prontos, entregues ou cancelados ficam bloqueados para novas alterações.

## Persistência, banco e integração

O app funciona em modo de demonstração offline: usuários, mesas e pedidos ficam no armazenamento local do dispositivo. Isso mantém os fluxos de apresentação utilizáveis sem rede, mas **não sincroniza dados entre aparelhos e não conecta diretamente ao MySQL ou SQL Server**. Nunca coloque credenciais de banco no aplicativo Flutter; a integração real deve passar por uma API HTTPS.

O anexo fornecido usa MySQL e difere do esquema SQL Server preexistente. Para evitar misturar dialetos, `database/mysql_schema.sql` contém a estrutura MySQL fornecida; `database/schema.sql` continua sendo uma referência SQL Server antiga. O código de modelos reconhece `disponibilidade` como `ENUM`, `BIT`, número ou booleano e aceita `preco_uni`/`preco_unitario`.

Ainda há uma incompatibilidade de contrato que requer API/migração antes de integrar: a tabela MySQL `usuarios` usa email como chave primária e não tem `id_usuario`, enquanto o app gera IDs apenas no armazenamento local. Esses IDs não são IDs garantidos pelo banco nem devem ser usados para integração com produção. Além disso, o catálogo e as mesas de demonstração são locais. Não envie pedidos deste modo a um banco real. A API deve fornecer IDs reais, validar disponibilidade/mesa e gravar pedidos e itens atomicamente; o total deve ser recalculado no servidor (ou pelas triggers do MySQL), nunca confiado ao total enviado pelo app.

O SQL anexado inclui usuários/contas com senha de demonstração em texto (`DEMO_SEM_LOGIN`); essas inserções foram deliberadamente excluídas do schema MySQL deste workspace. Cadastre usuários por backend com hash de senha forte. O cadastro local atual é somente para a demonstração offline.

A remoção de colaborador apaga apenas as credenciais locais do dispositivo; registros históricos de pedidos são mantidos. Para uso em produção ou em vários aparelhos, a autorização e a revogação de acesso devem ser validadas pela API central, não apenas pelo aplicativo.

Para integração já existente com a cozinha, configure `KITCHEN_API_URL` via `--dart-define`. O cliente usa `POST <URL_BASE>/orders` e `GET <URL_BASE>/orders/<id>`; confirme o contrato e o mapeamento de IDs com o serviço da cozinha. Isso **não é integração com o banco** e não deve ser ativado com IDs locais. No Flutter Web, a API também precisa permitir CORS.

Para aceitar as ações no sistema da cozinha, a API também deve implementar `PATCH <URL_BASE>/orders/<id>`. Alterações enviam `{ "itens": [...], "valor_total": 0 }`; cancelamentos enviam `{ "status": "cancelado", "motivo": "..." }` (o motivo é opcional). A API deve validar o estado atual e responder com status HTTP 2xx somente quando aceitar a operação. Se a integração não estiver configurada, o estado e os itens são atualizados apenas no dispositivo. O app não oferece alteração/cancelamento depois que o pedido fica pronto ou é entregue.

## Executar e validar

Use `flutter pub get`, `flutter run` e `flutter test`. O app foi estruturado para Android, iOS, desktop e Web; a persistência offline usa `SharedPreferences` para preservar compatibilidade entre plataformas.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
