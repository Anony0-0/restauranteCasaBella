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

    public int cadastrarFuncionarios(Integer id_func, String nome, String usermobi, String email, String senha, String cargo, String admissao) throws ClassNotFoundException, SQLException {
        conectar();
        st = conectado.prepareStatement("insert into funcionarios values(?,?,?,?,?,?,?)");
        st.setInt(1,id_func);
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

    public String[] buscarFuncionario(int idFunc) throws ClassNotFoundException, SQLException {
        Connection con = ConexaoBD.conectar();
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT id_func, nome, usermobi, email, cargo, admissao FROM funcionarios WHERE id_func = ?")) {
            ps.setInt(1, idFunc);
            try (ResultSet r = ps.executeQuery()) {
                if (r.next()) {
                    return new String[]{
                            r.getString("id_func"), r.getString("nome"), r.getString("usermobi"),
                            r.getString("email"), r.getString("cargo"), r.getString("admissao")
                    };
                }
                return null;
            }
        } finally {
            con.close();
        }
    }

    // Não mexe na senha
    public int alterarFuncionario(int idFunc, String nome, String usermobi, String email,
                                  String cargo, String admissao) throws ClassNotFoundException, SQLException {
        Connection con = ConexaoBD.conectar();
        try (PreparedStatement ps = con.prepareStatement(
                "UPDATE funcionarios SET nome=?, usermobi=?, email=?, cargo=?, admissao=? WHERE id_func=?")) {
            ps.setString(1, nome);
            ps.setString(2, usermobi);
            ps.setString(3, email);
            ps.setString(4, cargo);
            if (admissao == null || admissao.trim().isEmpty()) {
                ps.setNull(5, java.sql.Types.DATE);
            } else {
                ps.setDate(5, java.sql.Date.valueOf(admissao)); // yyyy-MM-dd
            }
            ps.setInt(6, idFunc);
            return ps.executeUpdate();
        } finally {
            con.close();
        }
    }

    public int excluirFuncionario(int idFunc) throws ClassNotFoundException, SQLException {
        Connection con = ConexaoBD.conectar();
        try (PreparedStatement ps = con.prepareStatement("DELETE FROM funcionarios WHERE id_func = ?")) {
            ps.setInt(1, idFunc);
            return ps.executeUpdate();
        } finally {
            con.close();
        }
    }

}

