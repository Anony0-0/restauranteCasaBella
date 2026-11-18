package dao;

import java.sql.*;

public class PedidosDao {
    //rs é para guardar o que retorna do SELECT na tabela
    private ResultSet rs;
    //conectado é para guardar a conexão com o BD
    private Connection conectado;
    //st guarda uma sessão de comunicação com o BD (SELECT, INSERT...)
    private PreparedStatement st;
    private int resultado;

    //Conexão com BD
    private void conectar() throws ClassNotFoundException, SQLException {
        conectado = ConexaoBD.conectar();
    }

    //MOSTRAR PEDIDOS
    public ResultSet listarPedidos() throws SQLException, ClassNotFoundException {
        conectar();

        String sql = "SELECT p.id_pedido, p.id_cliente, c.nome AS cliente,p.id_reserva, p.id_mesa, p.data_pedido, p.status, p.valor_total FROM pedidos p LEFT JOIN clientes c ON c.id_cliente = p.id_cliente ORDER BY p.data_pedido DESC";

        st = conectado.prepareStatement(sql);

        rs = st.executeQuery();

        return rs;
    }

    // Lista os pedidos de um status só (abinhas do painel)
    public ResultSet listarPedidosPorStatus(String status) throws SQLException, ClassNotFoundException {
        conectar();

        String sql = "SELECT p.id_pedido, p.id_cliente, c.nome AS cliente, p.id_reserva, p.id_mesa, " +
                "p.data_pedido, p.status, p.valor_total " +
                "FROM pedidos p LEFT JOIN clientes c ON c.id_cliente = p.id_cliente " +
                "WHERE p.status = ? ORDER BY p.data_pedido DESC";

        st = conectado.prepareStatement(sql);
        st.setString(1, status);
        rs = st.executeQuery();

        return rs;
    }

    // FILTRAR PEDIDOS POR CLIENTE E/OU MESA
    public ResultSet buscarPedidos(String busca, String mesa)
            throws SQLException, ClassNotFoundException {

        conectar();

        String sql = "SELECT p.id_pedido, p.id_cliente, c.nome AS cliente, " +
                "p.id_reserva, p.id_mesa, p.data_pedido, p.status, p.valor_total " +
                "FROM pedidos p " +
                "LEFT JOIN clientes c ON c.id_cliente = p.id_cliente " +
                "WHERE c.nome LIKE ? " +
                "AND (? = '' OR p.id_mesa = ?) " +
                "ORDER BY p.data_pedido DESC";

        st = conectado.prepareStatement(sql);

        String filtro = "%" + busca + "%";

        st.setString(1, filtro);
        st.setString(2, mesa);
        st.setString(3, mesa);

        rs = st.executeQuery();

        return rs;
    }

    // Abre ou cria o pedido de uma reserva confirmada.
    // Pode receber o idReserva OU o idMesa (o outro vem null).
    // Retorna o id do pedido, ou 0 se não houver reserva confirmada.
    // Ao abrir o pedido, a reserva passa de "Confirmada" para "Pedido em aberto".
    public int cadastrarPedido(Integer idReserva, Integer idMesa) throws SQLException, ClassNotFoundException {
        conectar();
        try {
            // Transação: o pedido e o status da reserva são salvos juntos (ou nenhum dos dois)
            conectado.setAutoCommit(false);

            // 1. Acha a reserva confirmada (ou que já está com pedido em aberto), com mesa atribuída
            String filtro = (idReserva != null) ? "id_reserva = ?" : "id_mesa = ?";
            int chave = (idReserva != null) ? idReserva : idMesa;

            int reserva, cliente, mesa;
            try (PreparedStatement ps = conectado.prepareStatement(
                    "SELECT id_reserva, id_cliente, id_mesa FROM reservas " +
                            "WHERE status IN ('Confirmada','Pedido em aberto') AND id_mesa IS NOT NULL AND " + filtro)) {
                ps.setInt(1, chave);
                try (ResultSet r = ps.executeQuery()) {
                    if (!r.next()) return 0;
                    reserva = r.getInt("id_reserva");
                    cliente = r.getInt("id_cliente");
                    mesa = r.getInt("id_mesa");
                }
            }

            int idPedido = 0;

            // 2. Se já existe pedido aberto dessa reserva, reaproveita
            try (PreparedStatement ps = conectado.prepareStatement(
                    "SELECT id_pedido FROM pedidos WHERE id_reserva = ? AND status = 'em preparo'")) {
                ps.setInt(1, reserva);
                try (ResultSet r = ps.executeQuery()) {
                    if (r.next()) idPedido = r.getInt("id_pedido");
                }
            }

            // 3. Senão, cria um novo
            if (idPedido == 0) {
                try (PreparedStatement ps = conectado.prepareStatement(
                        "INSERT INTO pedidos (id_cliente, id_reserva, id_mesa, data_pedido, status, valor_total) " +
                                "VALUES (?, ?, ?, NOW(), 'em preparo', 0)",
                        Statement.RETURN_GENERATED_KEYS)) {
                    ps.setInt(1, cliente);
                    ps.setInt(2, reserva);
                    ps.setInt(3, mesa);
                    ps.executeUpdate();
                    try (ResultSet chaves = ps.getGeneratedKeys()) {
                        idPedido = chaves.next() ? chaves.getInt(1) : 0;
                    }
                }
            }

            if (idPedido == 0) {
                conectado.rollback();
                return 0;
            }

            // 4. Marca a reserva como "Pedido em aberto" (só se ainda estiver "Confirmada")
            try (PreparedStatement ps = conectado.prepareStatement(
                    "UPDATE reservas SET status = 'Pedido em aberto' " +
                            "WHERE id_reserva = ? AND status = 'Confirmada'")) {
                ps.setInt(1, reserva);
                ps.executeUpdate();
            }

            conectado.commit();
            return idPedido;

        } catch (SQLException e) {
            conectado.rollback();
            throw e;
        } finally {
            conectado.close(); // fecha a conexão para não acumular conexões abertas
        }
    }

    // Dados de UM pedido (cabeçalho da tela pedido.jsp)
    public ResultSet buscarPorId(int idPedido) throws SQLException, ClassNotFoundException {
        conectar();

        String sql = "SELECT p.id_pedido, c.nome AS cliente, p.id_reserva, p.id_mesa, " +
                "p.data_pedido, p.status, p.valor_total " +
                "FROM pedidos p LEFT JOIN clientes c ON c.id_cliente = p.id_cliente " +
                "WHERE p.id_pedido = ?";

        st = conectado.prepareStatement(sql);
        st.setInt(1, idPedido);
        rs = st.executeQuery();

        return rs;
    }

    // Finaliza ou cancela. Só muda se o pedido ainda estiver "em preparo".
    // Retorna quantas linhas mudaram (0 = pedido já estava fechado ou não existe).
    // Também atualiza a reserva: pedido concluído -> "Concluida"; pedido cancelado -> volta para "Confirmada".
    public int atualizarStatus(int idPedido, String novoStatus) throws SQLException, ClassNotFoundException {
        conectar();
        try {
            // Transação: pedido e reserva mudam juntos
            conectado.setAutoCommit(false);

            st = conectado.prepareStatement(
                    "UPDATE pedidos SET status = ? WHERE id_pedido = ? AND status = 'em preparo'");
            st.setString(1, novoStatus);
            st.setInt(2, idPedido);
            resultado = st.executeUpdate();

            if (resultado == 0) {
                conectado.rollback();
                return 0;
            }

            String statusReserva = novoStatus.equalsIgnoreCase("cancelado") ? "Confirmada" : "Concluida";

            st = conectado.prepareStatement(
                    "UPDATE reservas r JOIN pedidos p ON p.id_reserva = r.id_reserva " +
                            "SET r.status = ? " +
                            "WHERE p.id_pedido = ? AND r.status = 'Pedido em aberto'");
            st.setString(1, statusReserva);
            st.setInt(2, idPedido);
            st.executeUpdate();

            conectado.commit();
            return resultado;

        } catch (SQLException e) {
            conectado.rollback();
            throw e;
        } finally {
            conectado.close();
        }
    }

    // Mesas para o filtro do painel de pedidos
    public ResultSet listarMesas() throws SQLException, ClassNotFoundException {
        conectar();
        st = conectado.prepareStatement("SELECT id_mesa, capacidade FROM mesas ORDER BY id_mesa");
        rs = st.executeQuery();
        return rs;
    }
}