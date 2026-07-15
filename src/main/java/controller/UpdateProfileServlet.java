package controller;

import utility.DBConnection;
import java.io.IOException;
import java.io.StringReader;
import java.sql.Connection;
import java.sql.PreparedStatement;
import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet("/UpdateProfileServlet")
@MultipartConfig(maxFileSize = 16777215, maxRequestSize = 16777215) // Ye 16MB tak ki profile image allow karega
public class UpdateProfileServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {

        HttpSession session = request.getSession();
        Integer citizenId = (Integer) session.getAttribute("citizen_id");

        if (citizenId == null) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            return;
        }

        // Fetch Data
        String fullName = request.getParameter("fullName");
        String phone = request.getParameter("phone");
        String address = request.getParameter("address");
        String newPassword = request.getParameter("newPassword");
        String dpBase64 = request.getParameter("dpBase64");

        // Safety Check: Agar data drop ho gaya toh ye database ko crash hone se bacha lega
        if (fullName == null || fullName.trim().isEmpty()) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            response.getWriter().write("Error: Form data missing. Try a smaller image.");
            return;
        }

        Connection conn = null;
        PreparedStatement pstmt = null;

        try {
            conn = DBConnection.getConnection();

            StringBuilder sql = new StringBuilder("UPDATE civicuser SET full_name = ?, mobile = ?, department = ?");

            boolean updatePassword = (newPassword != null && !newPassword.trim().isEmpty());
            boolean updateImage = (dpBase64 != null && !dpBase64.trim().isEmpty() && dpBase64.startsWith("data:image"));

            if (updatePassword) { sql.append(", user_password = ?"); }
            if (updateImage) { sql.append(", profile_image = ?"); }

            sql.append(" WHERE user_id = ?");

            pstmt = conn.prepareStatement(sql.toString());

            int paramIndex = 1;
            pstmt.setString(paramIndex++, fullName);
            pstmt.setString(paramIndex++, phone);
            pstmt.setString(paramIndex++, address);

            if (updatePassword) { pstmt.setString(paramIndex++, newPassword); }
            if (updateImage) { pstmt.setClob(paramIndex++, new StringReader(dpBase64)); }

            pstmt.setInt(paramIndex, citizenId);

            int rowAffected = pstmt.executeUpdate();

            if (rowAffected > 0) {
                session.setAttribute("user", fullName); // Session name update
                response.setContentType("text/plain");
                response.getWriter().write("Profile Updated");
            } else {
                response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            }

        } catch (Exception e) {
            e.printStackTrace();
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
        } finally {
            try { if (pstmt != null) pstmt.close(); } catch (Exception e) {}
            try { if (conn != null) conn.close(); } catch (Exception e) {}
        }
    }
}