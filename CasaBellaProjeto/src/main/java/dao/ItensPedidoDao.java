package dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

public class ItensPedidoDao {

    private Connection conectado;

    // Códigos de retorno
    public static final int OK = 1;
    public static final int PEDIDO_FECHADO = 0;
    public static final int PRODUTO_INDISPONIVEL = -1;

    private void conectar() throws ClassNotFoundException, SQLException {
        conectado = ConexaoBD.conectar();
    }

    public ResultSet listarPorPedido(int idPedido) throws SQLException, ClassNotFoundException {
        Connection con = ConexaoBD.conectar();

        String sql = "SELECT i.id_itens, i.id_produto, pr.nome, i.quantidade, i.preco_uni " +
                "FROM itens_pedido i JOIN produtos pr ON pr.id_produto = i.id_produto " +
                "WHERE i.id_pedido = ? ORDER BY i.id_itens";

        PreparedStatement ps = con.prepareStatement(sql);
        ps.setInt(1, idPedido);
        return ps.executeQuery();
    }

    // Adiciona um item ao pedido e recalcula o valor_total
    public int adicionarItem(int idPedido, int idProduto, int quantidade)
            throws SQLException, ClassNotFoundException {
        conectar();
        try {
            conectado.setAutoCommit(false); // tudo ou nada

            // 1. O pedido precisa estar aberto
            PreparedStatement ps = conectado.prepareStatement(
                    "SELECT 1 FROM pedidos WHERE id_pedido = ? AND status = 'em preparo'");
            ps.setInt(1, idPedido);
            ResultSet r = ps.executeQuery();
            if (!r.next()) {
                conectado.rollback();
                return PEDIDO_FECHADO;
            }

            // 2. O preço vem do banco, nunca do app/formulário
            ps = conectado.prepareStatement(
                    "SELECT preco FROM produtos WHERE id_produto = ? AND disponibilidade = 'disponivel'");
            ps.setInt(1, idProduto);
            r = ps.executeQuery();
            if (!r.next()) {
                conectado.rollback();
                return PRODUTO_INDISPONIVEL;
            }
            java.math.BigDecimal preco = r.getBigDecimal("preco");

            // 3. Se o produto já está no pedido, soma a quantidade; senão insere um item novo
            ps = conectado.prepareStatement(
                    "UPDATE itens_pedido SET quantidade = quantidade + ? " +
                            "WHERE id_pedido = ? AND id_produto = ?");
            ps.setInt(1, quantidade);
            ps.setInt(2, idPedido);
            ps.setInt(3, idProduto);

            if (ps.executeUpdate() == 0) {
                ps = conectado.prepareStatement(
                        "INSERT INTO itens_pedido (id_pedido, id_produto, quantidade, preco_uni) VALUES (?, ?, ?, ?)");
                ps.setInt(1, idPedido);
                ps.setInt(2, idProduto);
                ps.setInt(3, quantidade);
                ps.setBigDecimal(4, preco);
                ps.executeUpdate();
            }

            // 4. Recalcula o total do pedido
            ps = conectado.prepareStatement(
                    "UPDATE pedidos SET valor_total = " +
                            "(SELECT SUM(quantidade * preco_uni) FROM itens_pedido WHERE id_pedido = ?) " +
                            "WHERE id_pedido = ?");
            ps.setInt(1, idPedido);
            ps.setInt(2, idPedido);
            ps.executeUpdate();

            conectado.commit();
            return OK;

        } catch (SQLException e) {
            conectado.rollback();
            throw e;
        } finally {
            conectado.close();
        }
    }

    // Remove um item do pedido (só se o pedido ainda estiver "em preparo") e recalcula o valor_total
    public boolean removerItem(int idPedido, int idItem) throws SQLException, ClassNotFoundException {
        conectar();
        try {
            conectado.setAutoCommit(false);

            PreparedStatement ps = conectado.prepareStatement(
                    "DELETE i FROM itens_pedido i JOIN pedidos p ON p.id_pedido = i.id_pedido " +
                            "WHERE i.id_itens = ? AND i.id_pedido = ? AND p.status = 'em preparo'");
            ps.setInt(1, idItem);
            ps.setInt(2, idPedido);

            if (ps.executeUpdate() == 0) {
                conectado.rollback();
                return false;
            }

            // COALESCE: se removeu o último item, o total volta a 0 em vez de NULL
            ps = conectado.prepareStatement(
                    "UPDATE pedidos SET valor_total = " +
                            "(SELECT COALESCE(SUM(quantidade * preco_uni), 0) FROM itens_pedido WHERE id_pedido = ?) " +
                            "WHERE id_pedido = ?");
            ps.setInt(1, idPedido);
            ps.setInt(2, idPedido);
            ps.executeUpdate();

            conectado.commit();
            return true;

        } catch (SQLException e) {
            conectado.rollback();
            throw e;
        } finally {
            conectado.close();
        }
    }

}
