package dao;

import utility.DBConnection;
import java.io.StringReader;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.Calendar; // Naya import current year ke liye

public class ComplaintDAO {

    public String insertComplaint(int citizenId, String category, String description, String location, String photoData) {
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        String trackingId = "CMP-ERROR";

        try {
            conn = DBConnection.getConnection();

            // 1. Database se next valid auto-increment ID fetch karna
            long nextId = 1;
            String idQuery = "SELECT NVL(MAX(COMPLAINT_ID), 0) + 1 FROM complaints";
            pstmt = conn.prepareStatement(idQuery);
            rs = pstmt.executeQuery();
            if (rs.next()) {
                nextId = rs.getLong(1);
            }
            rs.close();
            pstmt.close();

            // 2. Data insert karne ka logic
            String insertSql = "INSERT INTO complaints (COMPLAINT_ID, CITIZEN_ID, PROBLEM_CATEGORY, DESCRIPTION, LOCATION_ADDRESS, STATUS, IMAGE_PATH, CREATED_AT) "
                    + "VALUES (?, ?, ?, ?, ?, 'Pending', ?, SYSTIMESTAMP)";

            pstmt = conn.prepareStatement(insertSql);
            pstmt.setLong(1, nextId);
            pstmt.setInt(2, citizenId);
            pstmt.setString(3, category);
            pstmt.setString(4, description);
            pstmt.setString(5, location);

            if (photoData != null && !photoData.trim().isEmpty()) {
                pstmt.setClob(6, new StringReader(photoData));
            } else {
                pstmt.setString(6, null);
            }

            int rowAffected = pstmt.executeUpdate();

            if (rowAffected > 0) {
                // --- CURRENT YEAR LOGIC ---
                // Calendar class se system ka current year fetch karenge
                int currentYear = Calendar.getInstance().get(Calendar.YEAR);

                // Ab year hamesha dynamic dynamic rahega (e.g., #CMP-9-2026)
                trackingId = "#CMP-" + nextId + "-" + currentYear;
            }

        } catch (Exception e) {
            e.printStackTrace();
            trackingId = "Database Error";
        } finally {
            try { if (rs != null) rs.close(); } catch (Exception e) {}
            try { if (pstmt != null) pstmt.close(); } catch (Exception e) {}
            try { if (conn != null) conn.close(); } catch (Exception e) {}
        }

        return trackingId;
    }


    public java.util.HashMap<String, String> getComplaintStatus(long complaintId) {
        java.util.HashMap<String, String> details = null;
        java.sql.Connection conn = null;
        java.sql.PreparedStatement pstmt = null;
        java.sql.ResultSet rs = null;

        try {
            conn = utility.DBConnection.getConnection();
            String sql = "SELECT PROBLEM_CATEGORY, LOCATION_ADDRESS, STATUS, TO_CHAR(CREATED_AT, 'DD Mon YYYY, HH:MI AM') as formatted_date " +
                    "FROM complaints WHERE COMPLAINT_ID = ?";

            pstmt = conn.prepareStatement(sql);
            pstmt.setLong(1, complaintId);
            rs = pstmt.executeQuery();

            if (rs.next()) {
                details = new java.util.HashMap<>();
                details.put("category", rs.getString("PROBLEM_CATEGORY"));
                details.put("location", rs.getString("LOCATION_ADDRESS"));
                details.put("status", rs.getString("STATUS"));
                details.put("date", rs.getString("formatted_date"));
            }
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            try { if (rs != null) rs.close(); } catch (Exception e) {}
            try { if (pstmt != null) pstmt.close(); } catch (Exception e) {}
            try { if (conn != null) conn.close(); } catch (Exception e) {}
        }
        return details; // Returns map or null if ID doesn't exist
    }

}