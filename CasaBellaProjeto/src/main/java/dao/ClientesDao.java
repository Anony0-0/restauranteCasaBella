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
        conectado = ConexaoBD.conectar();
    }

    //CADASTRO de CLIENTES

    public int cadastrarCliente(String nome, String email, String senha, String telefone) throws SQLException, ClassNotFoundException {
        conectar();
        st = conectado.prepareStatement("insert into clientes (nome,email,senha,telefone) values(?,?,?,?)");
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

    //Fazer listagem de TODOS clientes
    public ResultSet listarClientes() throws SQLException, ClassNotFoundException {

        conectar();
        String sql = "SELECT id_cliente, nome, email, telefone FROM clientes ORDER BY id_cliente DESC";
        st = conectado.prepareStatement(sql);
        rs = st.executeQuery();
        return rs;
    }

    // Busca os dados de um cliente: {id, nome, email, telefone}. Retorna null se não existir.
    public String[] buscarPorId(int id) throws SQLException, ClassNotFoundException {
        Connection con = ConexaoBD.conectar();
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT id_cliente, nome, email, telefone FROM clientes WHERE id_cliente = ?")) {
            ps.setInt(1, id);
            try (ResultSet r = ps.executeQuery()) {
                if (!r.next()) return null;
                return new String[]{
                        String.valueOf(r.getInt("id_cliente")),
                        r.getString("nome"),
                        r.getString("email"),
                        r.getString("telefone")
                };
            }
        } finally {
            con.close();
        }
    }

    // Descobre o id do cliente pelo e-mail. Retorna null se não existir.
    public Integer buscarIdPorEmail(String email) throws SQLException, ClassNotFoundException {
        Connection con = ConexaoBD.conectar();
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT id_cliente FROM clientes WHERE email = ?")) {
            ps.setString(1, email);
            try (ResultSet r = ps.executeQuery()) {
                return r.next() ? r.getInt("id_cliente") : null;
            }
        } finally {
            con.close();
        }
    }


    //Excluir Clientes
    public int excluirCliente(String email) throws SQLException, ClassNotFoundException {
        conectar();
        //Monta o comando delete a ser executado
        st = conectado.prepareStatement("DELETE from clientes where email=?");
        st.setString(1,email);
        return st.executeUpdate();

    }


    // Retorna 1 se atualizou, 0 se o cliente não existe, -1 se o e-mail já é de outro cliente.
    // novaSenha em branco = mantém a senha atual.
    public int atualizar(int id, String nome, String email, String telefone, String novaSenha)
            throws SQLException, ClassNotFoundException {
        Connection con = ConexaoBD.conectar();
        try {
            con.setAutoCommit(false); // tudo ou nada

            // 1. O e-mail não pode ser de outro cliente
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT 1 FROM clientes WHERE email = ? AND id_cliente <> ?")) {
                ps.setString(1, email);
                ps.setInt(2, id);
                try (ResultSet r = ps.executeQuery()) {
                    if (r.next()) {
                        con.rollback();
                        return -1;
                    }
                }
            }

            // 2. Atualiza o cliente (com ou sem senha)
            boolean trocaSenha = novaSenha != null && !novaSenha.trim().isEmpty();
            String sql = trocaSenha
                    ? "UPDATE clientes SET nome = ?, email = ?, telefone = ?, senha = ? WHERE id_cliente = ?"
                    : "UPDATE clientes SET nome = ?, email = ?, telefone = ? WHERE id_cliente = ?";

            int linhas;
            try (PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setString(1, nome);
                ps.setString(2, email);
                ps.setString(3, telefone);
                if (trocaSenha) {
                    ps.setString(4, novaSenha);
                    ps.setInt(5, id);
                } else {
                    ps.setInt(4, id);
                }
                linhas = ps.executeUpdate();
            }
            if (linhas == 0) {
                con.rollback();
                return 0;
            }

            // 3. As reservas guardam uma cópia do e-mail e do telefone: mantém igual
            try (PreparedStatement ps = con.prepareStatement(
                    "UPDATE reservas SET email = ?, telefone = ? WHERE id_cliente = ?")) {
                ps.setString(1, email);
                ps.setString(2, telefone);
                ps.setInt(3, id);
                ps.executeUpdate();
            }

            con.commit();
            return 1;

        } catch (SQLException e) {
            con.rollback();
            throw e;
        } finally {
            con.close();
        }
    }
}
