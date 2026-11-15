package dao;

import java.sql.*;

public class ConexaoBD {
    private static final String URL = "jdbc:mysql://100.65.236.39:3306/BDcasaBella";
    private static final String USUARIO = "grupo";
    private static final String SENHA = "senha123";

    public static Connection conectar() throws SQLException, ClassNotFoundException {
        Class.forName("com.mysql.cj.jdbc.Driver");
        return DriverManager.getConnection(URL, USUARIO, SENHA);
    }
}
