package dao;

import java.sql.*;

public class PedidosDao {
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


    //Cadastro de pedidos (feito pelo web e mobile)
    /*public int cadastrarPedidos() throws SQLException, ClassNotFoundException {
        conectar();
        st = conectado.prepareStatement("insert into pedidos () values ()" );


    }*/

    //MOSTRAR PEDIDOS
    public ResultSet listarPedidos() throws SQLException, ClassNotFoundException {
        conectar();

        String sql = "SELECT p.id_pedido, p.id_cliente, c.nome AS cliente,p.id_reserva, p.id_mesa, p.data_pedido, p.status, p.valor_total FROM pedidos p LEFT JOIN clientes c ON c.id_cliente = p.id_cliente ORDER BY p.data_pedido DESC";

        st = conectado.prepareStatement(sql);

        rs = st.executeQuery();

        return rs;

    }


}
