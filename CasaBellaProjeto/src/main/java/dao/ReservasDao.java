package dao;

import java.sql.*;

public class ReservasDao {

    private ResultSet rs;
    private Connection conectado;
    private PreparedStatement st;

    private void conectar() throws ClassNotFoundException, SQLException {
        conectado = ConexaoBD.conectar();
    }

    public int reservar(String email, Timestamp horario, int pessoas)
            throws ClassNotFoundException, SQLException {
        conectar();
        try {
            st = conectado.prepareStatement("select id_cliente, telefone from clientes where email=?");
            st.setString(1, email);
            rs = st.executeQuery();
            if (!rs.next()) {
                return -1;
            }
            int id_cliente = rs.getInt("id_cliente");
            String telefone = rs.getString("telefone");

            st = conectado.prepareStatement(
                    "select id_mesa from mesas where capacidade >= ? " +
                            "and id_mesa not in (" +
                            "  select id_mesa from reservas " +
                            "   where id_mesa is not null and status <> 'Cancelada' " +
                            "     and horario > date_sub(?, interval 2 hour) " +
                            "     and horario < date_add(?, interval 2 hour)" +
                            ") order by capacidade, id_mesa limit 1");
            st.setInt(1, pessoas);
            st.setTimestamp(2, horario);
            st.setTimestamp(3, horario);
            rs = st.executeQuery();
            if (!rs.next()) {
                return 0;
            }
            int idMesa = rs.getInt("id_mesa");

            st = conectado.prepareStatement(
                    "insert into reservas (id_cliente, telefone, email, horario, qtd_pessoas, id_mesa, status) " +
                            "values (?,?,?,?,?,?,'Pendente')");
            st.setInt(1, id_cliente);
            st.setString(2, telefone);
            st.setString(3, email);
            st.setTimestamp(4, horario);
            st.setInt(5, pessoas);
            st.setInt(6, idMesa);
            return st.executeUpdate();
        } finally {
            conectado.close();
        }
    }

    // Confirma a chegada do cliente. Retorna 1 se confirmou, 0 se a reserva não estava pendente.
    public int confirmarChegada(int idReserva) throws SQLException, ClassNotFoundException {
        conectar();
        try {
            st = conectado.prepareStatement(
                    "UPDATE reservas SET status = 'Confirmada' WHERE id_reserva = ? AND status = 'Pendente'");
            st.setInt(1, idReserva);
            return st.executeUpdate();
        } finally {
            conectado.close();
        }
    }

    // Pendente/Confirmada -> Cancelada. Retorna 1 se cancelou, 0 se não pode cancelar,
    // -1 se já existe pedido ligado à reserva.
    public int cancelar(int idReserva) throws SQLException, ClassNotFoundException {
        Connection con = ConexaoBD.conectar();
        try {
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT 1 FROM pedidos WHERE id_reserva = ?")) {
                ps.setInt(1, idReserva);
                try (ResultSet r = ps.executeQuery()) {
                    if (r.next()) return -1;
                }
            }
            try (PreparedStatement ps = con.prepareStatement(
                    "UPDATE reservas SET status = 'Cancelada' WHERE id_reserva = ? AND status IN ('Pendente','Confirmada')")) {
                ps.setInt(1, idReserva);
                return ps.executeUpdate();
            }
        } finally {
            con.close();
        }
    }


    // LISTAR RESERVAS
    public ResultSet listarReservas() throws SQLException, ClassNotFoundException {

        conectar();

        String sql = "SELECT " +
                "r.id_reserva, " +
                "c.nome AS cliente, " +
                "r.email, " +
                "r.telefone, " +
                "r.horario, " +
                "r.qtd_pessoas, " +
                "r.id_mesa, " +
                "r.status " +
                "FROM reservas r " +
                "LEFT JOIN clientes c ON c.id_cliente = r.id_cliente " +
                "ORDER BY r.horario DESC";

        st = conectado.prepareStatement(sql);

        rs = st.executeQuery();

        return rs;
    }


    public ResultSet listarReservasPorCliente(int idCliente) throws SQLException, ClassNotFoundException {
        conectar();
        String sql = "SELECT * FROM reservas WHERE id_cliente = ? ORDER BY horario DESC";
        st = conectado.prepareStatement(sql);
        st.setInt(1, idCliente);
        rs = st.executeQuery();
        return rs;
    }
}
