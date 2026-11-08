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

            // 3. Insere o item
            ps = conectado.prepareStatement(
                    "INSERT INTO itens_pedido (id_pedido, id_produto, quantidade, preco_uni) VALUES (?, ?, ?, ?)");
            ps.setInt(1, idPedido);
            ps.setInt(2, idProduto);
            ps.setInt(3, quantidade);
            ps.setBigDecimal(4, preco);
            ps.executeUpdate();

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
}
