package dao;

import model.User;
import utility.DBConnection;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

public class UserDAO {

    Connection connection;

    // Check Duplicate Email or Mobile
    public boolean checkUserExists(String email,
                                   String mobile) {

        boolean status = false;

        try {

            connection = DBConnection.getConnection();

            String sql =
                    "SELECT * FROM civicuser WHERE email=? OR mobile=?";

            PreparedStatement ps =
                    connection.prepareStatement(sql);

            ps.setString(1, email);
            ps.setString(2, mobile);

            ResultSet rs = ps.executeQuery();

            if(rs.next()) {
                status = true;
            }

            rs.close();
            ps.close();

        } catch (Exception e) {
            e.printStackTrace();
        }

        return status;
    }

    // Registration
    public boolean registerUser(User user) {

        boolean status = false;

        try {

            connection = DBConnection.getConnection();

            String sql =
                    "INSERT INTO civicuser(full_name,email,user_password,mobile) VALUES(?,?,?,?)";

            PreparedStatement ps =
                    connection.prepareStatement(sql);

            ps.setString(1, user.getName());
            ps.setString(2, user.getEmail());
            ps.setString(3, user.getPassword());
            ps.setString(4, user.getMobile());

            int row = ps.executeUpdate();

            if(row > 0) {
                status = true;
            }

            ps.close();

        } catch (Exception e) {
            e.printStackTrace();
        }

        return status;
    }

    // Login
    public boolean loginUser(String email,
                             String password) {

        boolean status = false;

        try {

            connection = DBConnection.getConnection();

            String sql =
                    "SELECT * FROM civicuser WHERE email=? AND user_password=?";

            PreparedStatement ps =
                    connection.prepareStatement(sql);

            ps.setString(1, email);
            ps.setString(2, password);

            ResultSet rs = ps.executeQuery();

            if(rs.next()) {
                status = true;
            }

            rs.close();
            ps.close();

        } catch (Exception e) {
            e.printStackTrace();
        }

        return status;
    }

    public User getUserByEmail(String email) {
        User user = null;
        try {
            connection = utility.DBConnection.getConnection();
            // SQL update kiya gaya hai: PROFILE_IMAGE add kiya hai
            String sql = "SELECT USER_ID, FULL_NAME, EMAIL, ROLE,DEPARTMENT,PROFILE_IMAGE FROM civicuser WHERE email=?";
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setString(1, email);
            ResultSet rs = ps.executeQuery();

            if (rs.next()) {
                user = new User();
                // Dhyaan dein: Agar aapke Model class me id set karne ka naam alag hai (jaise setId), toh uske hisaab se update karein
                user.setId(rs.getInt("USER_ID"));
                user.setName(rs.getString("FULL_NAME"));
                user.setEmail(rs.getString("EMAIL"));
                user.setRole(rs.getString("ROLE"));// Oracle me data 'Citizen' ya 'Technician' hai
                user.setDepartment(rs.getString("DEPARTMENT"));
                // Naya logic image fetch karne ke liye
                java.sql.Clob clob = rs.getClob("PROFILE_IMAGE");
                if (clob != null) {
                    user.setProfileImage(clob.getSubString(1, (int) clob.length()));
                } else {
                    user.setProfileImage("");
                }
            }
            rs.close();
            ps.close();
        } catch (Exception e) {
            e.printStackTrace();
        }
        return user;
    }
}