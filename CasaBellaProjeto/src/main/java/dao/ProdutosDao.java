package dao;

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

}
