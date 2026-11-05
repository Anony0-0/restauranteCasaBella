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
}
