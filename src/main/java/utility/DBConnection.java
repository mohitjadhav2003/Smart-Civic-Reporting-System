package utility;

import java.sql.Connection;
import java.sql.DriverManager;

public class DBConnection {

    private static Connection connection;

    public static Connection getConnection() {

        try {

            Class.forName("oracle.jdbc.driver.OracleDriver");

            connection = DriverManager.getConnection(
                    "jdbc:oracle:thin:@localhost:1521:orcl",
                    "scott",
                    "radhaswami"
            );

        } catch (Exception e) {
            e.printStackTrace();
        }

        return connection;
    }
}