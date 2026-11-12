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

    // Abre ou cria o pedido de uma reserva confirmada.
    // Pode receber o idReserva OU o idMesa (o outro vem null).
    // Retorna o id do pedido, ou 0 se não houver reserva confirmada.
    public int cadastrarPedido(Integer idReserva, Integer idMesa) throws SQLException, ClassNotFoundException {
        conectar();
        try {
            // 1. Acha a reserva confirmada (com mesa atribuída)
            String filtro = (idReserva != null) ? "id_reserva = ?" : "id_mesa = ?";
            int chave = (idReserva != null) ? idReserva : idMesa;

            int reserva, cliente, mesa;
            try (PreparedStatement ps = conectado.prepareStatement(
                    "SELECT id_reserva, id_cliente, id_mesa FROM reservas " +
                            "WHERE status = 'confirmada' AND id_mesa IS NOT NULL AND " + filtro)) {
                ps.setInt(1, chave);
                try (ResultSet r = ps.executeQuery()) {
                    if (!r.next()) return 0;
                    reserva = r.getInt("id_reserva");
                    cliente = r.getInt("id_cliente");
                    mesa = r.getInt("id_mesa");
                }
            }

            // 2. Se já existe pedido aberto dessa reserva, reaproveita
            try (PreparedStatement ps = conectado.prepareStatement(
                    "SELECT id_pedido FROM pedidos WHERE id_reserva = ? AND status = 'em preparo'")) {
                ps.setInt(1, reserva);
                try (ResultSet r = ps.executeQuery()) {
                    if (r.next()) return r.getInt("id_pedido");
                }
            }

            // 3. Senão, cria um novo
            try (PreparedStatement ps = conectado.prepareStatement(
                    "INSERT INTO pedidos (id_cliente, id_reserva, id_mesa, data_pedido, status, valor_total) " +
                            "VALUES (?, ?, ?, NOW(), 'em preparo', 0)",
                    Statement.RETURN_GENERATED_KEYS)) {
                ps.setInt(1, cliente);
                ps.setInt(2, reserva);
                ps.setInt(3, mesa);
                ps.executeUpdate();
                try (ResultSet chaves = ps.getGeneratedKeys()) {
                    return chaves.next() ? chaves.getInt(1) : 0;
                }
            }
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
    public int atualizarStatus(int idPedido, String novoStatus) throws SQLException, ClassNotFoundException {
        conectar();
        try {
            st = conectado.prepareStatement(
                    "UPDATE pedidos SET status = ? WHERE id_pedido = ? AND status = 'em preparo'");
            st.setString(1, novoStatus);
            st.setInt(2, idPedido);
            resultado = st.executeUpdate();
            return resultado;
        } finally {
            conectado.close();
        }
    }

}
