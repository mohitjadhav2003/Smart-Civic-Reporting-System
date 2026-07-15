<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="true" %>
<%@ page import="java.util.*, java.sql.*, utility.DBConnection" %>
<%
    String uId = request.getParameter("id");
    String uName = "", uRole = "";
    List<Map<String, String>> activityList = new ArrayList<>();

    Connection conn = null;
    PreparedStatement psUser = null, psActivity = null;
    ResultSet rsUser = null, rsActivity = null;

    try {
        conn = DBConnection.getConnection();

        // 1. Fetch User Basic Info
        String userSql = "SELECT FULL_NAME, ROLE FROM civicuser WHERE USER_ID=?";
        psUser = conn.prepareStatement(userSql);
        psUser.setInt(1, Integer.parseInt(uId));
        rsUser = psUser.executeQuery();
        if(rsUser.next()){
            uName = rsUser.getString("FULL_NAME");
            uRole = rsUser.getString("ROLE");
        }

        // 2. Fetch Complaints/Activity based on Role
        String activitySql = "";
        if("Technician".equalsIgnoreCase(uRole)) {
            // Technician ke liye assigned complaints
            activitySql = "SELECT COMPLAINT_ID, TITLE, STATUS, CREATED_AT FROM civiccomplaints WHERE TECHNICIAN_ID=? ORDER BY CREATED_AT DESC";
        } else {
            // Citizen ke liye unki apni complaints
            activitySql = "SELECT COMPLAINT_ID, TITLE, STATUS, CREATED_AT FROM civiccomplaints WHERE USER_ID=? ORDER BY CREATED_AT DESC";
        }

        psActivity = conn.prepareStatement(activitySql);
        psActivity.setInt(1, Integer.parseInt(uId));
        rsActivity = psActivity.executeQuery();

        while(rsActivity.next()){
            Map<String, String> act = new HashMap<>();
            act.put("id", rsActivity.getString("COMPLAINT_ID"));
            act.put("title", rsActivity.getString("TITLE"));
            act.put("status", rsActivity.getString("STATUS"));
            act.put("date", rsActivity.getString("CREATED_AT"));
            activityList.add(act);
        }
    } catch(Exception e) { e.printStackTrace(); }
    finally { try { if(conn!=null) conn.close(); } catch(Exception e){} }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>User Activity - <%= uName %></title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        .admin-card { background: white; border-radius: 12px; padding: 25px; box-shadow: 0 2px 10px rgba(0,0,0,0.02); }
        .status-pill { padding: 5px 12px; border-radius: 20px; font-size: 12px; font-weight: 600; }
        .bg-pending { background: #fff7ed; color: #c2410c; }
        .bg-resolved { background: #f0fdf4; color: #166534; }
    </style>
</head>
<body class="bg-light p-4">
<div class="container">
    <a href="Admin-total-users.jsp" class="btn btn-sm btn-secondary mb-3"><i class="bi bi-arrow-left"></i> Back to Directory</a>

    <div class="admin-card">
        <h4>Activity History for: <strong><%= uName %></strong> (<%= uRole %>)</h4>
        <hr>
        <table class="table table-hover mt-3">
            <thead>
            <tr>
                <th>Complaint ID</th>
                <th>Title</th>
                <th>Status</th>
                <th>Date</th>
            </tr>
            </thead>
            <tbody>
            <% for(Map<String, String> act : activityList) { %>
            <tr>
                <td>#CMP-<%= act.get("id") %></td>
                <td><%= act.get("title") %></td>
                <td><span class="status-pill <%= act.get("status").equalsIgnoreCase("Resolved") ? "bg-resolved" : "bg-pending" %>"><%= act.get("status") %></span></td>
                <td><%= act.get("date") %></td>
            </tr>
            <% } if(activityList.isEmpty()){ %>
            <tr><td colspan="4" class="text-center">No activity found.</td></tr>
            <% } %>
            </tbody>
        </table>
    </div>
</div>
</body>
</html>