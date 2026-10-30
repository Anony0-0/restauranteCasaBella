package dao;

import java.sql.*;

public class ClientesDao {

    //rs é para guardar o que retorna do SELECT na tabela
    private ResultSet rs;
    //conectado é para guardar a conexão com o BD
    private Connection conectado;
    //st guarda uma sessão de comunicação com o BD (SELECT, INSERT...)
    private PreparedStatement st;
    private int resultado;

    //Conexão com BD
    private void conectar() throws ClassNotFoundException, SQLException {
        Class.forName("com.mysql.cj.jdbc.Driver");
        conectado = DriverManager.getConnection("jdbc:mysql://127.0.0.1:3306/bdcasabella", "root", "1234lanamysql#");
    }

    //CADASTRO DOS CLIENTES

    public int cadastrarCliente(String nome, String email, String senha, String telefone) throws SQLException, ClassNotFoundException {
        conectar();
        st = conectado.prepareStatement("insert into clientes values(?,?,?,?)");
        st.setString(1, nome);
        st.setString(2, email);
        st.setString(3, senha);
        st.setString(4, telefone);
        resultado = st.executeUpdate(); //Executa o insert acima
        return resultado;
    }

    //LOGIN DOS CLIENTES
    public String logarCliente(String email, String senha) throws SQLException, ClassNotFoundException {
        conectar();
        //Monta o comando Select a ser executado
        st = conectado.prepareStatement("select * from clientes where email=? and senha=?");
        st.setString(1, email);
        st.setString(2, senha);
        //Executa o select na tabela do bd
        rs = st.executeQuery();
        //Se encontrou o usuário na tabela do BD
        if(rs.next()){
            return rs.getString("nome");
        } else {
            return null;
        }
    }

}


