package controller;

import utility.DBConnection;
import java.io.IOException;
import java.sql.Clob;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet("/AdminTotalUsers")
public class AdminTotalUsersServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {

        // Security Check
        HttpSession session = request.getSession();
        String role = (String) session.getAttribute("role");
System.out.println("inside the admintotaluser");
        if (role == null || !"Admin".equalsIgnoreCase(role)) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        int totalUsers = 0;
        int activeCitizens = 0;
        int newThisMonth = 0;

        List<Map<String, String>> userList = new ArrayList<>();
        Connection conn = null;

        try {
            conn = DBConnection.getConnection();

            // 1. Fetch Stats (Total Users, Active Citizens, New This Month)
            String statsSql = "SELECT " +
                    "(SELECT COUNT(*) FROM civicuser) as total_u, " +
                    "(SELECT COUNT(*) FROM civicuser WHERE ROLE='Citizen' OR ROLE IS NULL) as active_c, " +
                    "(SELECT COUNT(*) FROM civicuser WHERE EXTRACT(MONTH FROM CREATED_AT) = EXTRACT(MONTH FROM SYSDATE) AND EXTRACT(YEAR FROM CREATED_AT) = EXTRACT(YEAR FROM SYSDATE)) as new_users " +
                    "FROM DUAL";
            PreparedStatement psStats = conn.prepareStatement(statsSql);
            ResultSet rsStats = psStats.executeQuery();
            if (rsStats.next()) {
                totalUsers = rsStats.getInt("total_u");
                activeCitizens = rsStats.getInt("active_c");
                newThisMonth = rsStats.getInt("new_users");
            }
            rsStats.close(); psStats.close();

            // 2. Fetch All Users for Table
            String usersSql = "SELECT USER_ID, FULL_NAME, EMAIL, MOBILE, ROLE, CREATED_AT, PROFILE_IMAGE FROM civicuser ORDER BY USER_ID DESC";
            PreparedStatement psUsers = conn.prepareStatement(usersSql);
            ResultSet rsUsers = psUsers.executeQuery();

            SimpleDateFormat sdf = new SimpleDateFormat("dd MMM yyyy"); // E.g., 12 Jan 2024

            while (rsUsers.next()) {
                Map<String, String> user = new HashMap<>();
                user.put("id", String.valueOf(rsUsers.getInt("USER_ID")));
                user.put("name", rsUsers.getString("FULL_NAME") != null ? rsUsers.getString("FULL_NAME") : "Unknown User");
                user.put("email", rsUsers.getString("EMAIL") != null ? rsUsers.getString("EMAIL") : "N/A");
                user.put("phone", rsUsers.getString("MOBILE") != null ? rsUsers.getString("MOBILE") : "N/A");

                String userRole = rsUsers.getString("ROLE");
                user.put("role", (userRole != null && !userRole.trim().isEmpty()) ? userRole : "Citizen");

                // Format Date
                if (rsUsers.getTimestamp("CREATED_AT") != null) {
                    user.put("joinDate", sdf.format(rsUsers.getTimestamp("CREATED_AT")));
                } else {
                    user.put("joinDate", "N/A");
                }

                // Handle Profile Image (CLOB to Base64 String)
                Clob clob = rsUsers.getClob("PROFILE_IMAGE");
                if (clob != null && clob.length() > 0) {
                    user.put("image", clob.getSubString(1, (int) clob.length()));
                } else {
                    user.put("image", "");
                }

                userList.add(user);
            }
            rsUsers.close(); psUsers.close();

        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            try { if (conn != null) conn.close(); } catch (Exception e) {}
        }

        // Add fetched data to the request attributes
        request.setAttribute("totalUsers", totalUsers);
        request.setAttribute("activeCitizens", activeCitizens);
        request.setAttribute("newThisMonth", newThisMonth);
        request.setAttribute("userList", userList);

        // Forward to the JSP page
        request.getRequestDispatcher("AdminJSP/Admin-total-users.jsp").forward(request, response);
    }
}