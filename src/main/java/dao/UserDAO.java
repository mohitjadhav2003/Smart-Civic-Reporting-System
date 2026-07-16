package dao;

import model.User;
import utility.DBConnection;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

public class UserDAO {

    // Check Duplicate Email or Mobile
    public boolean checkUserExists(String email, String mobile) {

        String sql = "SELECT 1 FROM civicuser WHERE email=? OR mobile=?";

        try (Connection connection = DBConnection.getConnection();
             PreparedStatement ps = connection.prepareStatement(sql)) {

            ps.setString(1, email);
            ps.setString(2, mobile);

            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }

        } catch (Exception e) {
            e.printStackTrace();
        }

        return false;
    }

    // Registration
    public boolean registerUser(User user) {

        String sql = "INSERT INTO civicuser (full_name,email,user_password,mobile) VALUES (?,?,?,?)";

        try (Connection connection = DBConnection.getConnection();
             PreparedStatement ps = connection.prepareStatement(sql)) {

            ps.setString(1, user.getName());
            ps.setString(2, user.getEmail());
            ps.setString(3, user.getPassword());
            ps.setString(4, user.getMobile());

            return ps.executeUpdate() > 0;

        } catch (Exception e) {
            e.printStackTrace();
        }

        return false;
    }

    // Login
    public boolean loginUser(String email, String password) {

        String sql = "SELECT 1 FROM civicuser WHERE email=? AND user_password=?";

        try (Connection connection = DBConnection.getConnection();
             PreparedStatement ps = connection.prepareStatement(sql)) {

            ps.setString(1, email);
            ps.setString(2, password);

            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }

        } catch (Exception e) {
            e.printStackTrace();
        }

        return false;
    }

    // Get User Details
    public User getUserByEmail(String email) {

        User user = null;

        String sql =
                "SELECT user_id, full_name, email, role, department, profile_image " +
                        "FROM civicuser WHERE email=?";

        try (Connection connection = DBConnection.getConnection();
             PreparedStatement ps = connection.prepareStatement(sql)) {

            ps.setString(1, email);

            try (ResultSet rs = ps.executeQuery()) {

                if (rs.next()) {

                    user = new User();

                    user.setId(rs.getInt("user_id"));
                    user.setName(rs.getString("full_name"));
                    user.setEmail(rs.getString("email"));
                    user.setRole(rs.getString("role"));
                    user.setDepartment(rs.getString("department"));

                    String profileImage = rs.getString("profile_image");

                    if (profileImage != null) {
                        user.setProfileImage(profileImage);
                    } else {
                        user.setProfileImage("");
                    }
                }
            }

        } catch (Exception e) {
            e.printStackTrace();
        }

        return user;
    }
}