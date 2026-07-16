package dao;

import utility.DBConnection;

import java.io.StringReader;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.Calendar;
import java.util.HashMap;

public class ComplaintDAO {

    public String insertComplaint(int citizenId,
                                  String category,
                                  String description,
                                  String location,
                                  String photoData) {

        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;

        String trackingId = "CMP-ERROR";

        try {

            conn = DBConnection.getConnection();

            // PostgreSQL automatically generates COMPLAINT_ID
            String insertSql =
                    "INSERT INTO complaints " +
                            "(citizen_id, problem_category, description, location_address, status, image_path, created_at) " +
                            "VALUES (?, ?, ?, ?, 'Pending', ?, CURRENT_TIMESTAMP) " +
                            "RETURNING complaint_id";

            pstmt = conn.prepareStatement(insertSql);

            pstmt.setInt(1, citizenId);
            pstmt.setString(2, category);
            pstmt.setString(3, description);
            pstmt.setString(4, location);

            if (photoData != null && !photoData.trim().isEmpty()) {

                pstmt.setCharacterStream(5, new StringReader(photoData));

            } else {

                pstmt.setNull(5, java.sql.Types.LONGVARCHAR);

            }

            rs = pstmt.executeQuery();

            if (rs.next()) {

                long complaintId = rs.getLong("complaint_id");

                int currentYear = Calendar.getInstance().get(Calendar.YEAR);

                trackingId = "#CMP-" + complaintId + "-" + currentYear;
            }

        } catch (Exception e) {

            e.printStackTrace();

            trackingId = "Database Error";

        } finally {

            try {
                if (rs != null)
                    rs.close();
            } catch (Exception e) {
            }

            try {
                if (pstmt != null)
                    pstmt.close();
            } catch (Exception e) {
            }

            try {
                if (conn != null)
                    conn.close();
            } catch (Exception e) {
            }

        }

        return trackingId;
    }

    public HashMap<String, String> getComplaintStatus(long complaintId) {

        HashMap<String, String> details = null;

        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;

        try {

            conn = DBConnection.getConnection();

            String sql =
                    "SELECT problem_category, location_address, status, " +
                            "TO_CHAR(created_at, 'DD Mon YYYY, HH12:MI AM') AS formatted_date " +
                            "FROM complaints WHERE complaint_id=?";

            pstmt = conn.prepareStatement(sql);

            pstmt.setLong(1, complaintId);

            rs = pstmt.executeQuery();

            if (rs.next()) {

                details = new HashMap<>();

                details.put("category",
                        rs.getString("problem_category"));

                details.put("location",
                        rs.getString("location_address"));

                details.put("status",
                        rs.getString("status"));

                details.put("date",
                        rs.getString("formatted_date"));

            }

        } catch (Exception e) {

            e.printStackTrace();

        } finally {

            try {
                if (rs != null)
                    rs.close();
            } catch (Exception e) {
            }

            try {
                if (pstmt != null)
                    pstmt.close();
            } catch (Exception e) {
            }

            try {
                if (conn != null)
                    conn.close();
            } catch (Exception e) {
            }

        }

        return details;
    }
}