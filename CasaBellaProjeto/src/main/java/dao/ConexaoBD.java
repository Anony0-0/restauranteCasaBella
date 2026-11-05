package dao;

import java.sql.*;

public class ConexaoBD {
    private static final String URL = "caminho do banco";
    private static final String USUARIO = "usuario";
    private static final String SENHA = "senha";

    public static Connection conectar() throws SQLException, ClassNotFoundException {
        Class.forName("com.mysql.cj.jdbc.Driver");
        return DriverManager.getConnection(URL, USUARIO, SENHA);
    }
}
