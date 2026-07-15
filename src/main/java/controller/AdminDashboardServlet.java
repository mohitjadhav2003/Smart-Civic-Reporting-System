package controller;

import utility.DBConnection;
import java.io.IOException;
import java.sql.*;
import java.util.*;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

@WebServlet("/AdminDashboardServlet")
public class AdminDashboardServlet extends HttpServlet {
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        Connection conn = null;
        try {
            conn = DBConnection.getConnection();

            // 1. Stats Calculation
            PreparedStatement psStats = conn.prepareStatement(
                    "SELECT (SELECT COUNT(*) FROM civicuser) as total_users, " +
                            "(SELECT COUNT(*) FROM complaints) as total_comp, " +
                            "(SELECT COUNT(*) FROM complaints WHERE STATUS='Pending') as pending_comp, " +
                            "(SELECT COUNT(*) FROM complaints WHERE STATUS='Resolved') as resolved_comp FROM DUAL");
            ResultSet rs = psStats.executeQuery();
            if (rs.next()) {
                request.setAttribute("totalUsers", rs.getInt("total_users"));
                request.setAttribute("totalComp", rs.getInt("total_comp"));
                request.setAttribute("pendingComp", rs.getInt("pending_comp"));
                request.setAttribute("resolvedComp", rs.getInt("resolved_comp"));
            }

            // 2. Recent Complaints Table
            List<Map<String, Object>> recentList = new ArrayList<>();
            PreparedStatement psList = conn.prepareStatement(
                    "SELECT * FROM (SELECT c.*, u.full_name FROM complaints c JOIN civicuser u ON c.CITIZEN_ID = u.USER_ID ORDER BY CREATED_AT DESC) WHERE ROWNUM <= 5");
            ResultSet rsList = psList.executeQuery();
            while (rsList.next()) {
                Map<String, Object> map = new HashMap<>();
                map.put("id", rsList.getInt("COMPLAINT_ID"));
                map.put("problem", rsList.getString("PROBLEM_CATEGORY"));
                map.put("loc", rsList.getString("LOCATION_ADDRESS"));
                map.put("user", rsList.getString("full_name"));
                map.put("status", rsList.getString("STATUS"));
                recentList.add(map);
            }
            request.setAttribute("recentComplaints", recentList);

            request.getRequestDispatcher("AdminJSP/admin-dashboard.jsp").forward(request, response);

        } catch (Exception e) { e.printStackTrace(); } finally { try { if(conn!=null) conn.close(); } catch(Exception e){} }
    }
}