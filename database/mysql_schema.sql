-- Esquema MySQL 8.0 baseado no SQL fornecido com o projeto Casa Bella.
-- Execute este arquivo no MySQL. Ele cria estrutura, não cria contas com senha de demonstração.
CREATE DATABASE IF NOT EXISTS BDcasaBella
    CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE BDcasaBella;

CREATE TABLE IF NOT EXISTS clientes (
    id_cliente INT NOT NULL AUTO_INCREMENT,
    nome VARCHAR(120) NOT NULL,
    email VARCHAR(150) NOT NULL,
    senha VARCHAR(255) NOT NULL,
    telefone VARCHAR(20),
    PRIMARY KEY (id_cliente),
    UNIQUE KEY uq_clientes_email (email)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS usuarios (
    email VARCHAR(150) NOT NULL,
    nome VARCHAR(120) NOT NULL,
    senha VARCHAR(255) NOT NULL,
    cargo VARCHAR(50) NOT NULL,
    admissao DATE,
    PRIMARY KEY (email)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS produtos (
    id_produto INT NOT NULL AUTO_INCREMENT,
    categoria VARCHAR(80) NOT NULL,
    nome VARCHAR(150) NOT NULL,
    descricao TEXT,
    preco DECIMAL(10,2) NOT NULL,
    imagem VARCHAR(500),
    disponibilidade ENUM('disponivel', 'indisponivel') NOT NULL DEFAULT 'disponivel',
    PRIMARY KEY (id_produto),
    CONSTRAINT chk_produto_preco CHECK (preco >= 0)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS mesas (
    id_mesa INT NOT NULL AUTO_INCREMENT,
    capacidade INT NOT NULL,
    reservado BOOLEAN NOT NULL DEFAULT FALSE,
    PRIMARY KEY (id_mesa),
    CONSTRAINT chk_mesa_capacidade CHECK (capacidade > 0)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS reservas (
    id_reserva INT NOT NULL AUTO_INCREMENT,
    id_cliente INT,
    telefone VARCHAR(20),
    email VARCHAR(150),
    horario DATETIME NOT NULL,
    qtd_pessoas INT NOT NULL,
    id_mesa INT,
    status VARCHAR(30) NOT NULL DEFAULT 'Pendente',
    PRIMARY KEY (id_reserva),
    CONSTRAINT fk_reservas_cliente FOREIGN KEY (id_cliente)
        REFERENCES clientes(id_cliente),
    CONSTRAINT fk_reservas_mesa FOREIGN KEY (id_mesa)
        REFERENCES mesas(id_mesa),
    CONSTRAINT chk_reserva_pessoas CHECK (qtd_pessoas > 0),
    KEY ix_reservas_horario_mesa (horario, id_mesa)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS pedidos (
    id_pedido INT NOT NULL AUTO_INCREMENT,
    id_cliente INT,
    id_mesa INT,
    data_pedido DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(30) NOT NULL DEFAULT 'Pendente',
    valor_total DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    PRIMARY KEY (id_pedido),
    CONSTRAINT fk_pedidos_cliente FOREIGN KEY (id_cliente)
        REFERENCES clientes(id_cliente),
    CONSTRAINT fk_pedidos_mesa FOREIGN KEY (id_mesa)
        REFERENCES mesas(id_mesa),
    CONSTRAINT chk_total_nao_negativo CHECK (valor_total >= 0),
    KEY ix_pedidos_data_status (data_pedido, status)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS itens_pedido (
    id_itens INT NOT NULL AUTO_INCREMENT,
    id_pedido INT NOT NULL,
    id_produto INT NOT NULL,
    quantidade INT NOT NULL,
    preco_uni DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (id_itens),
    CONSTRAINT fk_itens_pedido FOREIGN KEY (id_pedido)
        REFERENCES pedidos(id_pedido) ON DELETE CASCADE,
    CONSTRAINT fk_itens_produto FOREIGN KEY (id_produto)
        REFERENCES produtos(id_produto),
    CONSTRAINT chk_quantidade_positiva CHECK (quantidade > 0),
    CONSTRAINT chk_preco_uni CHECK (preco_uni >= 0),
    KEY ix_itens_pedido_pedido (id_pedido)
) ENGINE=InnoDB;

DROP TRIGGER IF EXISTS trg_itens_insert;
DROP TRIGGER IF EXISTS trg_itens_update;
DROP TRIGGER IF EXISTS trg_itens_delete;

DELIMITER $$

CREATE TRIGGER trg_itens_insert
AFTER INSERT ON itens_pedido
FOR EACH ROW
BEGIN
    UPDATE pedidos
       SET valor_total = (
           SELECT COALESCE(SUM(quantidade * preco_uni), 0)
             FROM itens_pedido
            WHERE id_pedido = NEW.id_pedido
       )
     WHERE id_pedido = NEW.id_pedido;
END$$

CREATE TRIGGER trg_itens_update
AFTER UPDATE ON itens_pedido
FOR EACH ROW
BEGIN
    UPDATE pedidos
       SET valor_total = (
           SELECT COALESCE(SUM(quantidade * preco_uni), 0)
             FROM itens_pedido
            WHERE id_pedido = NEW.id_pedido
       )
     WHERE id_pedido = NEW.id_pedido;

    IF OLD.id_pedido <> NEW.id_pedido THEN
        UPDATE pedidos
           SET valor_total = (
               SELECT COALESCE(SUM(quantidade * preco_uni), 0)
                 FROM itens_pedido
                WHERE id_pedido = OLD.id_pedido
           )
         WHERE id_pedido = OLD.id_pedido;
    END IF;
END$$

CREATE TRIGGER trg_itens_delete
AFTER DELETE ON itens_pedido
FOR EACH ROW
BEGIN
    UPDATE pedidos
       SET valor_total = (
           SELECT COALESCE(SUM(quantidade * preco_uni), 0)
             FROM itens_pedido
            WHERE id_pedido = OLD.id_pedido
       )
     WHERE id_pedido = OLD.id_pedido;
END$$

DELIMITER ;

-- Catálogo e mesas para demonstração; sem contas ou senhas de exemplo.
INSERT INTO produtos (categoria, nome, descricao, preco, imagem, disponibilidade)
SELECT 'Massas', 'Spaghetti alla Carbonara', 'Massa com queijo, ovos e guanciale', 56.00, NULL, 'disponivel'
WHERE NOT EXISTS (SELECT 1 FROM produtos WHERE nome = 'Spaghetti alla Carbonara');

INSERT INTO produtos (categoria, nome, descricao, preco, imagem, disponibilidade)
SELECT 'Pizzas', 'Pizza Margherita', 'Molho de tomate, queijo e manjericao', 54.00, NULL, 'disponivel'
WHERE NOT EXISTS (SELECT 1 FROM produtos WHERE nome = 'Pizza Margherita');

INSERT INTO produtos (categoria, nome, descricao, preco, imagem, disponibilidade)
SELECT 'Bebidas', 'Agua mineral', 'Garrafa de 500 ml', 6.00, NULL, 'disponivel'
WHERE NOT EXISTS (SELECT 1 FROM produtos WHERE nome = 'Agua mineral');

INSERT INTO produtos (categoria, nome, descricao, preco, imagem, disponibilidade)
SELECT 'Sobremesas', 'Tiramisu', 'Sobremesa italiana com cafe e mascarpone', 32.00, NULL, 'disponivel'
WHERE NOT EXISTS (SELECT 1 FROM produtos WHERE nome = 'Tiramisu');

INSERT INTO produtos (categoria, nome, descricao, preco, imagem, disponibilidade)
SELECT 'Vinhos', 'Chianti Classico', 'Vinho tinto italiano', 168.00, NULL, 'disponivel'
WHERE NOT EXISTS (SELECT 1 FROM produtos WHERE nome = 'Chianti Classico');

INSERT INTO mesas (id_mesa, capacidade, reservado)
VALUES (1, 2, FALSE), (2, 4, TRUE), (3, 4, FALSE), (4, 6, FALSE)
ON DUPLICATE KEY UPDATE id_mesa = id_mesa;
