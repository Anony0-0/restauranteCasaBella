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
        st = conectado.prepareStatement(
                "UPDATE reservas SET status = 'Confirmada' WHERE id_reserva = ? AND status = 'Pendente'");
        st.setInt(1, idReserva);
        int linhas = st.executeUpdate();
        conectado.close();
        return linhas;
    }


    // Pendente/Confirmada -> Cancelada. Retorna 1 se cancelou, 0 se não pode cancelar,
    // -1 se já existe pedido ligado à reserva.
    public int cancelar(int idReserva) throws SQLException, ClassNotFoundException {
        conectar();
        st = conectado.prepareStatement("SELECT 1 FROM pedidos WHERE id_reserva = ?");
        st.setInt(1, idReserva);
        rs = st.executeQuery();

        if (rs.next()) {
            conectado.close();
            return -1;
        }

        st = conectado.prepareStatement(
                "UPDATE reservas SET status = 'Cancelada' WHERE id_reserva = ? AND status IN ('Pendente','Confirmada')");
        st.setInt(1, idReserva);
        int linhas = st.executeUpdate();
        conectado.close();
        return linhas;
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

    // Dados para o formulário: {id, cliente, data, hora, pessoas, status}. Retorna null se não existir.
    public String[] buscarParaEdicao(int idReserva) throws SQLException, ClassNotFoundException {
        conectar();
        st = conectado.prepareStatement(
                "SELECT r.id_reserva, c.nome AS cliente, r.horario, r.qtd_pessoas, r.status " +
                        "FROM reservas r LEFT JOIN clientes c ON c.id_cliente = r.id_cliente " +
                        "WHERE r.id_reserva = ?");
        st.setInt(1, idReserva);
        rs = st.executeQuery();

        String[] dados = null;
        if (rs.next()) {
            Timestamp h = rs.getTimestamp("horario");
            String cliente = rs.getString("cliente");
            dados = new String[]{
                    String.valueOf(rs.getInt("id_reserva")),
                    cliente == null ? "" : cliente,
                    h.toLocalDateTime().toLocalDate().toString(),   // 2026-11-15
                    h.toLocalDateTime().toLocalTime().toString(),   // 19:30
                    String.valueOf(rs.getInt("qtd_pessoas")),
                    rs.getString("status")
            };
        }
        conectado.close();
        return dados;
    }

    // Mesa atual da reserva (0 se não tiver)
    public int mesaDaReserva(int idReserva) throws SQLException, ClassNotFoundException {
        conectar();
        st = conectado.prepareStatement("SELECT id_mesa FROM reservas WHERE id_reserva = ?");
        st.setInt(1, idReserva);
        rs = st.executeQuery();
        int mesa = rs.next() ? rs.getInt("id_mesa") : 0;
        conectado.close();
        return mesa;
    }

    // A reserva já tem pedido?
    public boolean reservaTemPedido(int idReserva) throws SQLException, ClassNotFoundException {
        conectar();
        st = conectado.prepareStatement("SELECT 1 FROM pedidos WHERE id_reserva = ?");
        st.setInt(1, idReserva);
        rs = st.executeQuery();
        boolean tem = rs.next();
        conectado.close();
        return tem;
    }

    // Mesa com capacidade e sem conflito (ignorando esta própria reserva).
    // A mesa atual vem primeiro, se ainda servir. Retorna 0 se não houver nenhuma.
    public int escolherMesa(int idReserva, int pessoas, Timestamp horario, int mesaAtual)
            throws SQLException, ClassNotFoundException {
        conectar();
        st = conectado.prepareStatement(
                "SELECT id_mesa FROM mesas WHERE capacidade >= ? AND id_mesa NOT IN (" +
                        "  SELECT id_mesa FROM reservas WHERE id_mesa IS NOT NULL AND id_reserva <> ? " +
                        "   AND status NOT IN ('Cancelada','Concluida') " +
                        "   AND horario > DATE_SUB(?, INTERVAL 2 HOUR) " +
                        "   AND horario < DATE_ADD(?, INTERVAL 2 HOUR)" +
                        ") ORDER BY (id_mesa = ?) DESC, capacidade, id_mesa LIMIT 1");
        st.setInt(1, pessoas);
        st.setInt(2, idReserva);
        st.setTimestamp(3, horario);
        st.setTimestamp(4, horario);
        st.setInt(5, mesaAtual);
        rs = st.executeQuery();
        int mesa = rs.next() ? rs.getInt("id_mesa") : 0;
        conectado.close();
        return mesa;
    }

    // Salva a alteração
    public int atualizarReserva(int idReserva, Timestamp horario, int pessoas, int mesa)
            throws SQLException, ClassNotFoundException {
        conectar();
        st = conectado.prepareStatement(
                "UPDATE reservas SET horario = ?, qtd_pessoas = ?, id_mesa = ? WHERE id_reserva = ?");
        st.setTimestamp(1, horario);
        st.setInt(2, pessoas);
        st.setInt(3, mesa);
        st.setInt(4, idReserva);
        int linhas = st.executeUpdate();
        conectado.close();
        return linhas;
    }



}
