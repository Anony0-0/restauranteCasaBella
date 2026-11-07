package dao;

import org.w3c.dom.Text;

import javax.swing.*;
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

    public int cadastrarProduto(Integer id_produto, String categoria, String nome, String descricao, Double preco, Boolean disponibilidade)
            throws SQLException, ClassNotFoundException {
        conectar();

        st = conectado.prepareStatement("insert into produtos values(?,?,?,?,?,?)");
        st.setInt(1,id_produto);
        st.setString(2, categoria);
        st.setString(3, nome);
        st.setString(5, descricao);
        st.setDouble(4, preco);
        st.setBoolean(6, disponibilidade);
        resultado = st.executeUpdate(); //Executa o insert acima
        return resultado;

    }

}
