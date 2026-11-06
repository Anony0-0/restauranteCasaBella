package dao;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.PreparedStatement;
import java.sql.ResultSet;


public class UsuariosDao {

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

    public int cadastrarUsuario(String id_usuario, String email, String nome, String senha, String cargo, String admissao) throws ClassNotFoundException, SQLException {
        conectar();
        st = conectado.prepareStatement("insert into usuarios values(?,?,?,?,?,?)");
        st.setString(1,id_usuario);
        st.setString(2, email);
        st.setString(3, nome);
        st.setString(5, senha);
        st.setString(4, cargo);
        st.setString(6, admissao);
        resultado = st.executeUpdate(); //Executa o insert acima
        return resultado;
    }

    public String logar(String email, String senha) throws ClassNotFoundException, SQLException {
        //Conecta com o BD
        conectar();
        //Monta o comando Select a ser executado
        st = conectado.prepareStatement("select * from usuarios where email=? and senha=?");
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

    public ResultSet listarUsuarios() throws ClassNotFoundException, SQLException {
        conectar();

        st = conectado.prepareStatement("SELECT * FROM usuarios");

        rs = st.executeQuery();

        return rs;

    }

}

