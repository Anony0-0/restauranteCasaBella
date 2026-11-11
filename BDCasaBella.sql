CREATE DATABASE IF NOT EXISTS BDcasaBella
    CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE BDcasaBella;

SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS itens_pedido;
DROP TABLE IF EXISTS pedidos;
DROP TABLE IF EXISTS reservas;
DROP TABLE IF EXISTS mesas;
DROP TABLE IF EXISTS produtos;
DROP TABLE IF EXISTS funcionarios;
DROP TABLE IF EXISTS usuarios;
DROP TABLE IF EXISTS clientes;

SET FOREIGN_KEY_CHECKS = 1;


CREATE TABLE clientes (
    id_cliente INT AUTO_INCREMENT NOT NULL,
    nome VARCHAR(120) NOT NULL,
    email VARCHAR(150) NOT NULL,
    senha VARCHAR(255) NOT NULL,
    telefone VARCHAR(20),

    CONSTRAINT pk_clientes PRIMARY KEY (id_cliente),
    CONSTRAINT uq_clientes_email UNIQUE (email)
) ENGINE=InnoDB;


CREATE TABLE funcionarios (
    id_func INT NOT NULL,
    nome VARCHAR(120) NOT NULL,
    usermobi VARCHAR(40) NOT NULL,
    email VARCHAR(80) NOT NULL,
    senha VARCHAR(255) NOT NULL,
    cargo VARCHAR(50) NOT NULL,
    admissao DATE,

    CONSTRAINT pk_funcionarios PRIMARY KEY (id_func),
    CONSTRAINT uq_funcionarios_email UNIQUE (email),
    CONSTRAINT uq_funcionarios_usermobi UNIQUE (usermobi)
) ENGINE=InnoDB;


CREATE TABLE produtos (
    id_produto INT NOT NULL,
    categoria VARCHAR(80) NOT NULL,
    nome VARCHAR(150) NOT NULL,
    descricao TEXT,
    preco DECIMAL(10,2) NOT NULL,
    disponibilidade VARCHAR(15) NOT NULL DEFAULT 'disponivel',

    CONSTRAINT pk_produtos PRIMARY KEY (id_produto),
    CONSTRAINT chk_produto_preco CHECK (preco >= 0),
    CONSTRAINT chk_produto_disp CHECK (
        disponibilidade IN ('disponivel', 'indisponivel')
    )
) ENGINE=InnoDB;


CREATE TABLE mesas (
    id_mesa INT AUTO_INCREMENT NOT NULL,
    capacidade INT NOT NULL,
    reservado TINYINT(1) NOT NULL DEFAULT 0,

    CONSTRAINT pk_mesas PRIMARY KEY (id_mesa),
    CONSTRAINT chk_mesa_capacidade CHECK (capacidade > 0)
) ENGINE=InnoDB;


CREATE TABLE reservas (
    id_reserva INT AUTO_INCREMENT NOT NULL,
    id_cliente INT,
    telefone VARCHAR(20),
    email VARCHAR(150),
    horario DATETIME NOT NULL,
    qtd_pessoas INT NOT NULL,
    id_mesa INT,
    status VARCHAR(30) NOT NULL DEFAULT 'Pendente',

    CONSTRAINT pk_reservas PRIMARY KEY (id_reserva),

    CONSTRAINT fk_reservas_cliente
        FOREIGN KEY (id_cliente)
        REFERENCES clientes(id_cliente),

    CONSTRAINT fk_reservas_mesa
        FOREIGN KEY (id_mesa)
        REFERENCES mesas(id_mesa),

    CONSTRAINT chk_reserva_pessoas CHECK (qtd_pessoas > 0)
) ENGINE=InnoDB;


CREATE TABLE pedidos (
    id_pedido INT AUTO_INCREMENT NOT NULL,
    id_cliente INT,
    id_mesa INT,
    id_reserva INT NOT NULL,
    data_pedido DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(30) NOT NULL DEFAULT 'Pendente',
    valor_total DECIMAL(10,2) NOT NULL DEFAULT 0.00,

    CONSTRAINT pk_pedidos PRIMARY KEY (id_pedido),

    CONSTRAINT fk_pedidos_cliente
        FOREIGN KEY (id_cliente)
        REFERENCES clientes(id_cliente),

    CONSTRAINT fk_pedidos_mesa
        FOREIGN KEY (id_mesa)
        REFERENCES mesas(id_mesa),

    CONSTRAINT fk_pedidos_reserva
        FOREIGN KEY (id_reserva)
        REFERENCES reservas(id_reserva),

    CONSTRAINT chk_total_nao_negativo CHECK (valor_total >= 0)
) ENGINE=InnoDB;


CREATE TABLE itens_pedido (
    id_itens INT AUTO_INCREMENT NOT NULL,
    id_pedido INT NOT NULL,
    id_produto INT NOT NULL,
    quantidade INT NOT NULL,
    preco_uni DECIMAL(10,2) NOT NULL,

    CONSTRAINT pk_itens_pedido PRIMARY KEY (id_itens),

    CONSTRAINT fk_itens_pedido
        FOREIGN KEY (id_pedido)
        REFERENCES pedidos(id_pedido)
        ON DELETE CASCADE,

    CONSTRAINT fk_itens_produto
        FOREIGN KEY (id_produto)
        REFERENCES produtos(id_produto),

    CONSTRAINT chk_quantidade_positiva CHECK (quantidade > 0),
    CONSTRAINT chk_preco_uni CHECK (preco_uni >= 0)
) ENGINE=InnoDB;


DELIMITER $$

CREATE TRIGGER trg_itens_total_insert
AFTER INSERT ON itens_pedido
FOR EACH ROW
BEGIN
    UPDATE pedidos
       SET valor_total = (
           SELECT IFNULL(SUM(quantidade * preco_uni), 0)
           FROM itens_pedido
           WHERE id_pedido = NEW.id_pedido
       )
     WHERE id_pedido = NEW.id_pedido;
END$$

CREATE TRIGGER trg_itens_total_update
AFTER UPDATE ON itens_pedido
FOR EACH ROW
BEGIN
    UPDATE pedidos
       SET valor_total = (
           SELECT IFNULL(SUM(quantidade * preco_uni), 0)
           FROM itens_pedido
           WHERE id_pedido = NEW.id_pedido
       )
     WHERE id_pedido = NEW.id_pedido;

    IF OLD.id_pedido <> NEW.id_pedido THEN
        UPDATE pedidos
           SET valor_total = (
               SELECT IFNULL(SUM(quantidade * preco_uni), 0)
               FROM itens_pedido
               WHERE id_pedido = OLD.id_pedido
           )
         WHERE id_pedido = OLD.id_pedido;
    END IF;
END$$

CREATE TRIGGER trg_itens_total_delete
AFTER DELETE ON itens_pedido
FOR EACH ROW
BEGIN
    UPDATE pedidos
       SET valor_total = (
           SELECT IFNULL(SUM(quantidade * preco_uni), 0)
           FROM itens_pedido
           WHERE id_pedido = OLD.id_pedido
       )
     WHERE id_pedido = OLD.id_pedido;
END$$

DELIMITER ;


INSERT INTO clientes (nome, email, senha, telefone) VALUES
('Mariana Souza', 'mariana@exemplo.com', 'DEMO_SEM_LOGIN', '(11) 98765-4321'),
('Lucas Pereira', 'lucas@exemplo.com', 'DEMO_SEM_LOGIN', '(11) 91234-5678');


INSERT INTO funcionarios
(id_func, nome, usermobi, email, senha, cargo, admissao)
VALUES
(1, 'Conta Geral', 'geral500mobi', 'geral@casabella.com', '12345678', 'Conta Geral', '2000-01-01'),
(2, 'Patricia Kaiane', 'patricia10mobi', 'patricia@casabella.com', 'cbpatricia12', 'DBA', '2025-01-15'),
(3, 'Alana Rafaela', 'alana10mobi', 'alana@casabella.com', 'cbalana5', 'Gerente de TI', '2025-01-15'),
(4, 'Elenice Alexandre', 'elenice10mobi', 'elenice@casabella.com', 'elenicecb10', 'Gerente de TI', '2025-01-13'),
(5, 'Gustavo Hitzschky', 'gustavocbmobi', 'gustavo@casabella.com', '12345678', 'Gerente de Administração', '2025-01-15'),
(6, 'Juan Carlos', 'juan10mobi', 'juan@casabella.com', 'juancb10', 'Suporte Técnico', '2025-04-07');


INSERT INTO produtos
(id_produto, categoria, nome, descricao, preco, disponibilidade)
VALUES
(11, 'Massas', 'Spaghetti alla Carbonara', 'Massa com queijo, ovos e guanciale', 56.00, 'disponivel'),
(21, 'Pizzas', 'Pizza Margherita', 'Molho de tomate, queijo e manjericao', 54.00, 'disponivel'),
(51, 'Sobremesas', 'Tiramisu', 'Sobremesa italiana com cafe e mascarpone', 32.00, 'disponivel'),
(61, 'Bebidas', 'Agua mineral', 'Garrafa de 500 ml', 6.00, 'disponivel'),
(71, 'Vinhos', 'Chianti Classico', 'Vinho tinto italiano', 168.00, 'disponivel');


INSERT INTO mesas (capacidade, reservado) VALUES
(2, 0),
(4, 1),
(4, 0),
(6, 0);


INSERT INTO reservas
(id_cliente, telefone, email, horario, qtd_pessoas, id_mesa, status)

SELECT id_cliente, telefone, email,
       '2026-11-15 19:30:00', 4, 2, 'Confirmada'
FROM clientes
WHERE email = 'mariana@exemplo.com';

INSERT INTO reservas
(id_cliente, telefone, email, horario, qtd_pessoas, id_mesa, status)

SELECT id_cliente, telefone, email,
       '2026-10-20 19:00:00', 2, 1, 'Confirmada'
FROM clientes
WHERE email = 'mariana@exemplo.com';

INSERT INTO reservas
(id_cliente, telefone, email, horario, qtd_pessoas, id_mesa, status)

SELECT id_cliente, telefone, email,
       '2026-10-20 19:10:00', 1, 3, 'Confirmada'
FROM clientes
WHERE email = 'lucas@exemplo.com';

INSERT INTO pedidos
(id_cliente, id_mesa, id_reserva, data_pedido, status)

SELECT id_cliente, id_mesa, id_reserva,
       '2026-10-20 19:00:00', 'Em preparo'
FROM reservas
WHERE horario = '2026-10-20 19:00:00'
  AND id_mesa = 1;

INSERT INTO pedidos
(id_cliente, id_mesa, id_reserva, data_pedido, status)

SELECT id_cliente, id_mesa, id_reserva,
       '2026-10-20 19:10:00', 'Pendente'
FROM reservas
WHERE horario = '2026-10-20 19:10:00'
  AND id_mesa = 3;


SET @pedido_mariana = (
    SELECT id_pedido
    FROM pedidos
    WHERE data_pedido = '2026-10-20 19:00:00'
    ORDER BY id_pedido
    LIMIT 1
);

SET @pedido_lucas = (
    SELECT id_pedido
    FROM pedidos
    WHERE data_pedido = '2026-10-20 19:10:00'
    ORDER BY id_pedido
    LIMIT 1
);

INSERT INTO itens_pedido
(id_pedido, id_produto, quantidade, preco_uni)
VALUES
(@pedido_mariana, 11, 2, 56.00),
(@pedido_mariana, 61, 2, 6.00),
(@pedido_lucas, 21, 1, 54.00);

SHOW TABLES;

SELECT id_func, nome, usermobi, email, cargo
FROM funcionarios
ORDER BY id_func;

SELECT id_produto, categoria, nome, preco
FROM produtos
ORDER BY id_produto;

SELECT id_pedido, id_cliente, id_mesa, id_reserva,
       status, valor_total
FROM pedidos
ORDER BY id_pedido;

SELECT
    p.id_pedido,
    pr.nome,
    i.quantidade,
    i.preco_uni,
    i.quantidade * i.preco_uni AS subtotal
FROM itens_pedido i
JOIN pedidos p ON p.id_pedido = i.id_pedido
JOIN produtos pr ON pr.id_produto = i.id_produto
ORDER BY p.id_pedido, i.id_itens;
