/* Esquema relacional de referência — SQL Server; banco: BDcasaBella.
   O app Flutter ainda usa persistência offline em SharedPreferences.
   Em produção, conecte esta API a um backend; nunca exponha credenciais SQL no app. */
IF DB_ID(N'BDcasaBella') IS NULL
    CREATE DATABASE BDcasaBella;
GO
USE BDcasaBella;
GO

CREATE TABLE dbo.clientes (
    id_cliente INT IDENTITY(1,1) PRIMARY KEY,
    nome NVARCHAR(120) NOT NULL,
    email NVARCHAR(254) NOT NULL UNIQUE,
    senha NVARCHAR(255) NOT NULL, -- guardar somente hash forte da senha
    telefone NVARCHAR(24) NOT NULL
);
GO

CREATE TABLE dbo.usuarios (
    id_usuario INT IDENTITY(1,1) PRIMARY KEY,
    cpf CHAR(11) NOT NULL UNIQUE,
    email NVARCHAR(254) NULL,
    nome NVARCHAR(120) NOT NULL,
    senha NVARCHAR(255) NOT NULL, -- guardar somente hash forte da senha
    cargo NVARCHAR(60) NOT NULL,
    admissao DATE NOT NULL
);
GO

CREATE UNIQUE INDEX UX_usuarios_email
    ON dbo.usuarios(email)
    WHERE email IS NOT NULL;
GO

CREATE TABLE dbo.produtos (
    id_produto INT IDENTITY(1,1) PRIMARY KEY,
    categoria NVARCHAR(80) NOT NULL,
    nome NVARCHAR(120) NOT NULL,
    descricao NVARCHAR(500) NOT NULL,
    preco DECIMAL(10,2) NOT NULL CHECK (preco >= 0),
    imagem NVARCHAR(1000) NULL,
    disponibilidade BIT NOT NULL CONSTRAINT DF_produtos_disponibilidade DEFAULT 1
);
GO

CREATE TABLE dbo.mesas (
    id_mesa INT IDENTITY(1,1) PRIMARY KEY,
    capacidade TINYINT NOT NULL CHECK (capacidade > 0),
    reservado BIT NOT NULL CONSTRAINT DF_mesas_reservado DEFAULT 0
);
GO

CREATE TABLE dbo.reservas (
    id_reserva INT IDENTITY(1,1) PRIMARY KEY,
    id_cliente INT NOT NULL,
    telefone NVARCHAR(24) NOT NULL,
    email NVARCHAR(254) NOT NULL,
    horario DATETIME2(0) NOT NULL,
    qtd_pessoas TINYINT NOT NULL CHECK (qtd_pessoas > 0),
    id_mesa INT NOT NULL,
    status NVARCHAR(24) NOT NULL CONSTRAINT DF_reservas_status DEFAULT N'pendente',
    CONSTRAINT FK_reservas_clientes FOREIGN KEY (id_cliente) REFERENCES dbo.clientes(id_cliente),
    CONSTRAINT FK_reservas_mesas FOREIGN KEY (id_mesa) REFERENCES dbo.mesas(id_mesa)
);
GO

CREATE TABLE dbo.pedidos (
    id_pedido INT IDENTITY(1,1) PRIMARY KEY,
    id_cliente INT NULL, -- permite atendimento sem cadastro de cliente
    id_mesa INT NULL, -- permite retirada/balcão
    data_pedido DATETIME2(0) NOT NULL CONSTRAINT DF_pedidos_data DEFAULT SYSDATETIME(),
    status NVARCHAR(24) NOT NULL CONSTRAINT DF_pedidos_status DEFAULT N'aberto',
    valor_total DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (valor_total >= 0),
    CONSTRAINT FK_pedidos_clientes FOREIGN KEY (id_cliente) REFERENCES dbo.clientes(id_cliente),
    CONSTRAINT FK_pedidos_mesas FOREIGN KEY (id_mesa) REFERENCES dbo.mesas(id_mesa)
);
GO

CREATE TABLE dbo.itens_pedido (
    id_itens INT IDENTITY(1,1) PRIMARY KEY,
    id_pedido INT NOT NULL,
    id_produto INT NOT NULL,
    quantidade SMALLINT NOT NULL CHECK (quantidade > 0),
    preco_unitario DECIMAL(10,2) NOT NULL CHECK (preco_unitario >= 0),
    CONSTRAINT FK_itens_pedido_pedidos FOREIGN KEY (id_pedido) REFERENCES dbo.pedidos(id_pedido),
    CONSTRAINT FK_itens_pedido_produtos FOREIGN KEY (id_produto) REFERENCES dbo.produtos(id_produto)
);
GO

CREATE INDEX IX_reservas_horario ON dbo.reservas(horario, id_mesa);
CREATE INDEX IX_pedidos_data_status ON dbo.pedidos(data_pedido, status);
CREATE INDEX IX_itens_pedido_pedido ON dbo.itens_pedido(id_pedido);
GO
