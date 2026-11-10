
# Casa Bella — Cucina Italiana

Aplicativo Flutter de atendimento, cardápio e acompanhamento de pedidos.

## Arquitetura MVC

- `lib/models/`: modelos tipados que representam clientes, usuários, produtos, mesas, reservas, pedidos e itens de pedido.
- `lib/controllers/`: regras de autenticação, catálogo, mesas e pedidos; as telas chamam os controladores.
- `lib/repositories/`: persistência offline e comunicação opcional com a API da cozinha.
- `lib/servicos/`: serviços responsáveis pela comunicação com as APIs do backend.
- `lib/telas/`: apresentação e navegação do aplicativo.
- `database/schema.sql`: esquema relacional SQL Server legado de referência.
- `database/mysql_schema.sql`: estrutura MySQL baseada no SQL anexado (7 tabelas e triggers de total).

O anexo diz "Total: 6", mas descreve também `itens_pedido` como tabela própria. O esquema contempla as 7 tabelas descritas. A senha é armazenada conforme o mecanismo de autenticação implementado no backend; o aplicativo não deve gravar senhas em texto aberto.

## Funcionalidades

- Tela de login para colaboradores integrada à API do backend, com validação de e-mail e senha e identificação do funcionário autenticado.
- Catálogo com busca e filtro por categoria, carrinho e total do pedido.
- Seleção de mesas com capacidade ou atendimento de balcão.
- Criação local de pedidos com identificadores de mesa/produto, itens, quantidades, preços e total.
- Acompanhamento do status, com integração opcional à API da cozinha.
- Alteração de quantidades e remoção de itens, além de cancelamento enquanto o pedido estiver aguardando ou em preparo. Pedidos prontos, entregues ou cancelados ficam bloqueados para novas alterações.

## Persistência, banco e integração

O aplicativo funciona em modo de demonstração offline para mesas e pedidos; esses dados ficam no armazenamento local do dispositivo. Isso mantém os fluxos de apresentação utilizáveis sem rede, mas não sincroniza automaticamente esses dados entre aparelhos e não conecta diretamente ao MySQL ou SQL Server.

A autenticação dos colaboradores é realizada por meio de uma API REST do backend. O aplicativo envia e-mail e senha em uma requisição HTTP POST para o endpoint `/api/login`, utilizando JSON.

O backend recebe as credenciais e realiza a validação por meio do método existente `FuncionariosDao.logar(email, senha)`, consultando os funcionários cadastrados no banco de dados. O aplicativo recebe uma resposta JSON com o resultado da autenticação e os dados básicos do funcionário, como nome, e-mail e perfil.

O endpoint mobile foi implementado separadamente do fluxo de login web. O Servlet `ControleLogin.java` continua responsável pela autenticação da aplicação web, enquanto o novo Servlet `ApiLoginMobile.java` atende às requisições do aplicativo Flutter.

O aplicativo não consulta diretamente o banco de dados. Toda validação de credenciais deve ser realizada pelo backend. Para produção, a comunicação deve utilizar HTTPS, autenticação segura e gerenciamento de sessão ou tokens.

O workspace não contém a aplicação web nem todo o código do backend. O banco efetivamente utilizado deve ser confirmado com a equipe responsável pelo sistema web.

Os esquemas de referência divergem: `database/mysql_schema.sql` define `usuarios.email` como chave primária; `database/schema.sql` define `dbo.usuarios.id_usuario` como chave e CPF como único. Antes de integrar outras funcionalidades, confirme o schema implantado e o contrato da API.

O Flutter deve receber identificadores reais fornecidos pelo backend. IDs gerados apenas no armazenamento local não são IDs garantidos pelo banco e não devem ser utilizados para integração com produção.

Além disso, o catálogo e as mesas de demonstração são locais. Não envie pedidos deste modo a um banco real. A API deve fornecer IDs reais, validar disponibilidade e mesa e gravar pedidos e itens atomicamente. O total deve ser recalculado no servidor ou pelas triggers do MySQL, nunca confiado somente ao total enviado pelo aplicativo.

O SQL anexado inclui usuários/contas com senha de demonstração em texto (`DEMO_SEM_LOGIN`); essas inserções foram deliberadamente excluídas do schema MySQL deste workspace. O cadastro de usuários deve ser realizado pelo backend, com armazenamento seguro de senhas.

Para uso em produção ou em vários aparelhos, a autorização, a sessão segura e a revogação de acesso devem ser validadas pela API central, não apenas pelo aplicativo.

Para integração já existente com a cozinha, configure `KITCHEN_API_URL` via `--dart-define`. O cliente usa `POST <URL_BASE>/orders` e `GET <URL_BASE>/orders/<id>`; confirme o contrato e o mapeamento de IDs com o serviço da cozinha. Isso não é integração com o banco e não deve ser ativado com IDs locais. No Flutter Web, a API também precisa permitir CORS.

Para aceitar as ações no sistema da cozinha, a API também deve implementar `PATCH <URL_BASE>/orders/<id>`. Alterações enviam `{ "itens": [...], "valor_total": 0 }`; cancelamentos enviam `{ "status": "cancelado", "motivo": "..." }` (o motivo é opcional). A API deve validar o estado atual e responder com status HTTP 2xx somente quando aceitar a operação.

Se a integração não estiver configurada, o estado e os itens são atualizados apenas no dispositivo. O aplicativo não oferece alteração ou cancelamento depois que o pedido fica pronto ou é entregue.

## Executar e validar

Utilize os comandos:

```bash
flutter pub get
flutter run
flutter test
```

O aplicativo foi estruturado para Android, iOS, desktop e Web; a persistência offline utiliza `SharedPreferences` para preservar compatibilidade entre plataformas.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, and a full API reference.
