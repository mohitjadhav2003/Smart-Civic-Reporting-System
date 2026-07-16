package utility;

import java.sql.Connection;
import java.sql.DriverManager;

public class DBConnection {

    private static Connection connection;

    public static Connection getConnection() {

        try {

            if (connection == null || connection.isClosed()) {

                Class.forName("org.postgresql.Driver");

                String url = System.getenv("DB_URL");
                String username = System.getenv("DB_USER");
                String password = System.getenv("DB_PASSWORD");

                // Local testing ke liye fallback
                if (url == null || url.isEmpty()) {

                    url = "jdbc:postgresql://ep-shy-art-azmjr8j0.c-3.ap-southeast-1.aws.neon.tech/neondb?sslmode=require";
                    username = "neondb_owner";
                    password = "npg_iR9ekTy3dExW";
                }

                connection = DriverManager.getConnection(
                        url,
                        username,
                        password
                );
            }

        } catch (Exception e) {
            e.printStackTrace();
        }

        return connection;
    }
}