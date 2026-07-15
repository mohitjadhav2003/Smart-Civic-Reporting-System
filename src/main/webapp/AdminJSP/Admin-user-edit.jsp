<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="true" %>
<%@ page import="java.util.*, java.net.URLEncoder, java.sql.*, utility.DBConnection" %>
<%
    // 1. Security Check (Abhi testing ke liye band rakha hai)
    /* String sessionRole = (String) session.getAttribute("role");
    if (sessionRole == null || !"Admin".equalsIgnoreCase(sessionRole)) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    } */

    String adminUser = (String) session.getAttribute("user");
    if (adminUser == null) adminUser = "Admin";

    String adminDp = (String) session.getAttribute("profileImage");
    String headerAvatar = (adminDp != null && !adminDp.trim().isEmpty())
            ? adminDp
            : "https://ui-avatars.com/api/?name=" + URLEncoder.encode(adminUser, "UTF-8") + "&background=0D8ABC&color=fff";

    // Variables to hold user data
    String uId = "", uName = "", uEmail = "", uPhone = "", uRole = "", uDepartment = "";
    String successMsg = "";
    String errorMsg = "";

    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;

    try {
        conn = DBConnection.getConnection();

        // 2. Handle POST Request (Update Logic)
        if ("POST".equalsIgnoreCase(request.getMethod())) {
            String formId = request.getParameter("userId");
            String formName = request.getParameter("fullName");
            String formEmail = request.getParameter("email");
            String formPhone = request.getParameter("mobile");
            String formRole = request.getParameter("role");
            String formDept = request.getParameter("department");

            String updateSql = "UPDATE civicuser SET FULL_NAME=?, EMAIL=?, MOBILE=?, ROLE=?, DEPARTMENT=? WHERE USER_ID=?";
            pstmt = conn.prepareStatement(updateSql);
            pstmt.setString(1, formName);
            pstmt.setString(2, formEmail);
            pstmt.setString(3, formPhone);
            pstmt.setString(4, formRole);
            pstmt.setString(5, formDept);
            pstmt.setInt(6, Integer.parseInt(formId));

            int rowsAffected = pstmt.executeUpdate();
            if (rowsAffected > 0) {
                successMsg = "User profile updated successfully!";
            } else {
                errorMsg = "Failed to update profile. Please try again.";
            }
            pstmt.close();
        }

        // 3. Handle GET/Fetch Request (Load User Details)
        String fetchId = request.getParameter("id");
        if (fetchId != null && !fetchId.trim().isEmpty()) {
            String selectSql = "SELECT USER_ID, FULL_NAME, EMAIL, MOBILE, ROLE, DEPARTMENT FROM civicuser WHERE USER_ID=?";
            pstmt = conn.prepareStatement(selectSql);
            pstmt.setInt(1, Integer.parseInt(fetchId));
            rs = pstmt.executeQuery();

            if (rs.next()) {
                uId = String.valueOf(rs.getInt("USER_ID"));
                uName = rs.getString("FULL_NAME") != null ? rs.getString("FULL_NAME") : "";
                uEmail = rs.getString("EMAIL") != null ? rs.getString("EMAIL") : "";
                uPhone = rs.getString("MOBILE") != null ? rs.getString("MOBILE") : "";
                uRole = rs.getString("ROLE") != null ? rs.getString("ROLE") : "Citizen";
                uDepartment = rs.getString("DEPARTMENT") != null ? rs.getString("DEPARTMENT") : "";
            } else {
                errorMsg = "User not found in the database!";
            }
        } else {
            errorMsg = "Invalid User ID!";
        }

    } catch (Exception e) {
        e.printStackTrace();
        errorMsg = "Server Error: " + e.getMessage();
    } finally {
        try { if(rs != null) rs.close(); } catch(Exception e){}
        try { if(pstmt != null) pstmt.close(); } catch(Exception e){}
        try { if(conn != null) conn.close(); } catch(Exception e){}
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Edit Profile - Admin Panel</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">

    <style>
        :root {
            --sidebar-bg: #0b1727; --main-bg: #f4f7fe; --primary-blue: #2563eb;
            --primary-green: #16a34a; --text-dark: #1e293b; --text-muted: #64748b;
        }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: var(--main-bg); color: var(--text-dark); margin: 0; overflow-x: hidden; }

        /* --- Sidebar & Layout --- */
        .wrapper { display: flex; min-height: 100vh; }
        .sidebar { width: 260px; background-color: var(--sidebar-bg); color: white; padding: 20px 0; display: flex; flex-direction: column; position: fixed; height: 100vh; overflow-y: auto; }
        .logo-container { display: flex; align-items: center; gap: 12px; padding: 0 20px 20px 20px; border-bottom: 1px solid rgba(255,255,255,0.1); margin-bottom: 15px; }
        .logo-icon { font-size: 28px; color: white; }
        .logo-text h5 { margin: 0; font-weight: bold; font-size: 18px; }
        .logo-text span { font-size: 11px; color: #94a3b8; }
        .sidebar-nav { list-style: none; padding: 0; margin: 0; flex-grow: 1; }
        .nav-item { margin-bottom: 2px; padding: 0 10px; }
        .nav-link { display: flex; align-items: center; gap: 12px; padding: 12px 15px; color: #cbd5e1; border-radius: 8px; text-decoration: none; font-weight: 500; font-size: 14.5px; transition: 0.2s; }
        .nav-link:hover { background-color: rgba(255,255,255,0.05); color: white; }
        .nav-link.active { background-color: var(--primary-blue); color: white; }
        .nav-link i { font-size: 18px; width: 24px; text-align: center; }
        .logout-container { padding: 20px; margin-top: auto; }
        .logout-btn { display: flex; align-items: center; gap: 10px; border: 1px solid rgba(255,255,255,0.2); background: transparent; padding: 10px 15px; border-radius: 8px; color: white; text-decoration: none; transition: 0.2s; }
        .logout-btn:hover { background-color: rgba(255,255,255,0.1); }

        /* --- Main Content --- */
        .main-content { flex-grow: 1; margin-left: 260px; padding: 25px 35px; min-height: 100vh; }
        .top-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 25px; }
        .user-profile { display: flex; align-items: center; gap: 20px; }
        .user-profile img { width: 40px; height: 40px; border-radius: 50%; object-fit: cover; }
        .admin-text h6 { margin: 0; font-weight: bold; font-size: 15px; }
        .admin-text small { color: var(--text-muted); font-size: 12px; }

        /* --- Edit Form Specific --- */
        .admin-card { background-color: white; border-radius: 12px; padding: 30px; border: none; box-shadow: 0 2px 10px rgba(0,0,0,0.02); max-width: 800px; }
        .form-label { font-weight: 600; color: #334155; font-size: 14px; margin-bottom: 8px; }
        .form-control, .form-select { border-radius: 8px; padding: 10px 15px; border: 1px solid #cbd5e1; background-color: #f8fafc; font-size: 14.5px; }
        .form-control:focus, .form-select:focus { background-color: white; border-color: var(--primary-blue); box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.1); }
        .btn-save { background-color: var(--primary-blue); color: white; border-radius: 8px; padding: 10px 25px; font-weight: 600; border: none; transition: 0.2s; }
        .btn-save:hover { background-color: #1d4ed8; }
        .btn-cancel { background-color: #f1f5f9; color: #475569; border-radius: 8px; padding: 10px 25px; font-weight: 600; border: 1px solid #cbd5e1; text-decoration: none; transition: 0.2s; }
        .btn-cancel:hover { background-color: #e2e8f0; color: #1e293b; }

        .profile-header { display: flex; align-items: center; gap: 20px; margin-bottom: 30px; padding-bottom: 20px; border-bottom: 1px solid #f1f5f9; }
        .profile-header img { width: 80px; height: 80px; border-radius: 50%; object-fit: cover; border: 3px solid #e2e8f0; }
        .profile-header h5 { font-weight: bold; margin: 0 0 5px 0; color: #0f172a;}
        .profile-header span { background: #e0f2fe; color: #0369a1; padding: 4px 10px; border-radius: 6px; font-size: 12px; font-weight: 600; }
    </style>
</head>
<body>

<div class="wrapper">
    <aside class="sidebar">
        <div class="logo-container">
            <i class="bi bi-bank2 logo-icon"></i>
            <div class="logo-text"><h5>Smart Civic</h5><span>Problem Reporting System</span></div>
        </div>
        <ul class="sidebar-nav">
            <li class="nav-item"><a href="admin-dashboard.jsp" class="nav-link"><i class="bi bi-house-door"></i> Dashboard</a></li>
            <li class="nav-item"><a href="Admin-total-users.jsp" class="nav-link active"><i class="bi bi-people"></i> Total Users</a></li>
            <li class="nav-item"><a href="Admin-manage-complaints.jsp" class="nav-link"><i class="bi bi-card-checklist"></i> Manage Complaints</a></li>
            <li class="nav-item mt-4"><a href="Admin-settings.jsp" class="nav-link"><i class="bi bi-gear"></i> Settings</a></li>
        </ul>
        <div class="logout-container"><a href="../logout.jsp" class="logout-btn"><i class="bi bi-box-arrow-right"></i> Logout</a></div>
    </aside>

    <main class="main-content">
        <header class="top-header">
            <div class="d-flex align-items-center gap-3">
                <a href="Admin-total-users.jsp" class="text-dark"><i class="bi bi-arrow-left fs-4"></i></a>
                <h4 class="m-0 fw-bold">View / Edit User Profile</h4>
            </div>
            <div class="user-profile">
                <div class="d-flex align-items-center gap-2">
                    <img src="<%= headerAvatar %>" alt="Admin">
                    <div class="admin-text d-none d-md-block">
                        <h6><%= adminUser %></h6>
                        <small>Administrator</small>
                    </div>
                </div>
            </div>
        </header>

        <% if (!successMsg.isEmpty()) { %>
        <div class="alert alert-success alert-dismissible fade show" role="alert" style="max-width: 800px;">
            <i class="bi bi-check-circle-fill me-2"></i> <%= successMsg %>
            <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
        </div>
        <% } %>

        <% if (!errorMsg.isEmpty()) { %>
        <div class="alert alert-danger alert-dismissible fade show" role="alert" style="max-width: 800px;">
            <i class="bi bi-exclamation-triangle-fill me-2"></i> <%= errorMsg %>
            <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
        </div>
        <% } %>

        <% if (!uId.isEmpty()) { %>
        <div class="admin-card">
            <div class="profile-header">
                <img src="https://ui-avatars.com/api/?name=<%= URLEncoder.encode(uName, "UTF-8") %>&background=random&size=128" alt="Profile">
                <div>
                    <h5><%= uName %></h5>
                    <span>ID: #USR-<%= uId %></span>
                </div>
            </div>

            <form action="Admin-user-edit.jsp?id=<%= uId %>" method="POST">
                <input type="hidden" name="userId" value="<%= uId %>">

                <div class="row g-4">
                    <div class="col-md-6">
                        <label class="form-label">Full Name <span class="text-danger">*</span></label>
                        <input type="text" class="form-control" name="fullName" value="<%= uName %>" required>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label">Email Address <span class="text-danger">*</span></label>
                        <input type="email" class="form-control" name="email" value="<%= uEmail %>" required>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label">Mobile Number</label>
                        <input type="text" class="form-control" name="mobile" value="<%= uPhone %>">
                    </div>
                    <div class="col-md-6">
                        <label class="form-label">System Role <span class="text-danger">*</span></label>
                        <select class="form-select" name="role" required>
                            <option value="Citizen" <%= "Citizen".equalsIgnoreCase(uRole) ? "selected" : "" %>>Citizen</option>
                            <option value="Technician" <%= "Technician".equalsIgnoreCase(uRole) ? "selected" : "" %>>Technician (Staff)</option>
                            <option value="Admin" <%= "Admin".equalsIgnoreCase(uRole) ? "selected" : "" %>>System Admin</option>
                        </select>
                        <div class="form-text mt-1"><i class="bi bi-info-circle"></i> Changing role to Technician allows them to be assigned complaints.</div>
                    </div>
                    <div class="col-12">
                        <label class="form-label">Department / Address</label>
                        <input type="text" class="form-control" name="department" value="<%= uDepartment %>" placeholder="e.g., Water Department or Sector 15">
                    </div>
                </div>

                <div class="d-flex gap-3 mt-5 pt-3 border-top">
                    <button type="submit" class="btn-save"><i class="bi bi-floppy me-2"></i> Save Changes</button>
                    <a href="Admin-total-users.jsp" class="btn-cancel">Cancel</a>
                </div>
            </form>
        </div>
        <% } %>

    </main>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>