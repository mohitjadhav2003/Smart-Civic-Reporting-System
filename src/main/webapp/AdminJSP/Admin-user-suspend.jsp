<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="true" %>
<%@ page import="java.sql.*, utility.DBConnection" %>
<%
    // 1. Security Check (Admin Only)
    String role = (String) session.getAttribute("role");
    if (role == null || !"Admin".equalsIgnoreCase(role)) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    String uId = request.getParameter("id");

    if (uId != null && !uId.trim().isEmpty()) {
        Connection conn = null;
        PreparedStatement pstmt = null;
        try {
            conn = DBConnection.getConnection();

            // Status Update: 'Banned' set kar rahe hain
            String sql = "UPDATE civicuser SET STATUS='Banned' WHERE USER_ID=? AND ROLE != 'Admin'";
            pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, Integer.parseInt(uId));

            int result = pstmt.executeUpdate();

            if (result > 0) {
                // Success: Wapas list par bhej do
                response.sendRedirect("Admin-total-users.jsp?msg=User_Suspended");
            } else {
                // Fail: Ya toh Admin tha ya ID galat
                response.sendRedirect("Admin-total-users.jsp?error=Action_Failed");
            }
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("Admin-total-users.jsp?error=Server_Error");
        } finally {
            try { if(pstmt != null) pstmt.close(); } catch(Exception e){}
            try { if(conn != null) conn.close(); } catch(Exception e){}
        }
    } else {
        response.sendRedirect("Admin-total-users.jsp?error=Invalid_ID");
    }
%>