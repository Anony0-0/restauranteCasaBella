package dao;
import java.math.BigDecimal;
import java.sql.*;

public class ProdutosDao {
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

    public ResultSet listarProdutos() throws ClassNotFoundException, SQLException{
        conectar();
        st = conectado.prepareStatement("SELECT * FROM produtos");

        rs = st.executeQuery();

        return rs;

    }

    public int cadastrarProduto(int idProduto, String categoria, String nome, String descricao,
                                BigDecimal preco, boolean disponibilidade)
            throws SQLException, ClassNotFoundException {

        Connection con = ConexaoBD.conectar();
        try (PreparedStatement ps = con.prepareStatement(
                "INSERT INTO produtos (id_produto, categoria, nome, descricao, preco, disponibilidade) VALUES (?, ?, ?, ?, ?, ?)")) {
            ps.setInt(1, idProduto);
            ps.setString(2, categoria);
            ps.setString(3, nome);
            ps.setString(4, descricao);
            ps.setBigDecimal(5, preco);
            ps.setString(6, disponibilidade ? "disponivel" : "indisponivel"); // boolean -> enum do banco
            return ps.executeUpdate();
        } finally {
            con.close();
        }
    }

}

