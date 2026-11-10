package dao;

import java.sql.Connection;
import java.sql.SQLException;
import java.sql.PreparedStatement;
import java.sql.ResultSet;


public class FuncionariosDao {

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

    public int cadastrarFuncionarios(String id_func, String nome, String usermobi, String email, String senha, String cargo, String admissao) throws ClassNotFoundException, SQLException {
        conectar();
        st = conectado.prepareStatement("insert into funcionarios values(?,?,?,?,?,?,?)");
        st.setString(1,id_func);
        st.setString(2, nome);
        st.setString(3, usermobi);
        st.setString(4, email);
        st.setString(5, senha);
        st.setString(6, cargo);
        st.setString(7, admissao);
        resultado = st.executeUpdate(); //Executa o insert acima
        return resultado;
    }

    public String logar(String email, String senha) throws ClassNotFoundException, SQLException {
        //Conecta com o BD
        conectar();
        //Monta o comando Select a ser executado
        st = conectado.prepareStatement("select * from funcionarios where email=? and senha=?");
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

    // Login do mobile: devolve {nome, cargo} ou null se e-mail/senha não baterem.
    // Fecha a conexão sozinho.
    public String[] logarMobile(String email, String senha) throws ClassNotFoundException, SQLException {
        Connection con = ConexaoBD.conectar();
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT nome, cargo FROM funcionarios WHERE email = ? AND senha = ?")) {
            ps.setString(1, email);
            ps.setString(2, senha);
            try (ResultSet r = ps.executeQuery()) {
                if (r.next()) {
                    return new String[]{r.getString("nome"), r.getString("cargo")};
                }
                return null;
            }
        } finally {
            con.close();
        }
    }

    public ResultSet listarFuncionarios() throws ClassNotFoundException, SQLException {
        conectar();

        st = conectado.prepareStatement("SELECT * FROM funcionarios");

        rs = st.executeQuery();

        return rs;


    }

}

