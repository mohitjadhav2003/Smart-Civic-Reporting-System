<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="true" %>
<%@ page import="java.sql.*, utility.DBConnection" %>
<%
    // Security and Session Check
    String user = (String) session.getAttribute("user");
    Integer citizenId = (Integer) session.getAttribute("citizen_id");

    if (user == null || citizenId == null) {
        user = "Rahul Sharma";
        citizenId = 46; // Fallback for testing
    }

    // --- NAYA CODE: DP Session se nikalna ---
    String dpBase64 = (String) session.getAttribute("profileImage");
    String headerAvatar = (dpBase64 != null && !dpBase64.trim().isEmpty())
            ? dpBase64
            : "https://ui-avatars.com/api/?name=" + java.net.URLEncoder.encode(user, "UTF-8") + "&background=random";

    int unreadCount = 0;
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Notifications - Smart Civic</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">

    <style>
        :root { --sidebar-bg: #ebf3fa; --main-bg: #ffffff; --card-bg: #f3f6f9; --primary-green: #3bb160; --text-dark: #1e293b; --text-muted: #64748b; }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: var(--main-bg); color: var(--text-dark); margin: 0; overflow-x: hidden; }

        .wrapper { display: flex; min-height: 100vh; }
        .sidebar { width: 260px; background-color: var(--sidebar-bg); padding: 20px 15px; display: flex; flex-direction: column; border-right: 1px solid #e2e8f0; }
        .logo-container { display: flex; align-items: center; gap: 10px; padding: 10px; margin-bottom: 20px; }
        .logo-icon { font-size: 24px; color: #2563eb; }
        .logo-text h5 { margin: 0; font-weight: bold; color: #0f172a; }
        .logo-text span { font-size: 11px; color: var(--text-muted); }
        .nav-btn-add { background-color: var(--primary-green); color: white; border-radius: 8px; padding: 12px 15px; font-weight: 500; display: flex; align-items: center; gap: 10px; text-decoration: none; margin-bottom: 15px; transition: 0.2s; }
        .nav-btn-add:hover { background-color: #2e964f; color: white; }
        .sidebar-nav { list-style: none; padding: 0; margin: 0; flex-grow: 1; }
        .nav-item { margin-bottom: 5px; }
        .nav-link { display: flex; align-items: center; gap: 12px; padding: 10px 15px; color: var(--text-dark); border-radius: 8px; text-decoration: none; font-weight: 500; transition: 0.2s; }
        .nav-link:hover { background-color: rgba(0,0,0,0.03); }
        .nav-link.active { background-color: white; box-shadow: 0 2px 5px rgba(0,0,0,0.05); }
        .nav-link i { font-size: 18px; color: #475569; }
        .nav-badge { background-color: #ef4444; color: white; border-radius: 50%; padding: 2px 6px; font-size: 10px; margin-left: auto; transition: opacity 0.3s;}
        .logout-btn { border: 1px solid #cbd5e1; background: transparent; padding: 10px; border-radius: 8px; text-align: center; color: var(--text-dark); font-weight: 500; text-decoration: none; transition: 0.2s; }
        .logout-btn:hover { background-color: #e2e8f0; }

        .main-content { flex-grow: 1; padding: 25px 40px; max-width: calc(100% - 260px); }
        .top-header { display: flex; justify-content: space-between; align-items: center; padding-bottom: 20px; border-bottom: 1px solid #f1f5f9; margin-bottom: 30px; }
        .user-profile { display: flex; align-items: center; gap: 15px; }
        .user-profile img { width: 35px; height: 35px; border-radius: 50%; object-fit: cover; }

        .content-panel { border: 1px solid #e2e8f0; border-radius: 16px; background: white; overflow: hidden; }
        .panel-header { padding: 20px 30px; border-bottom: 1px solid #e2e8f0; display: flex; justify-content: space-between; align-items: center; }
        .btn-mark-read { background: transparent; border: 1px solid #cbd5e1; padding: 6px 15px; border-radius: 8px; font-size: 13px; font-weight: 500; color: #475569; transition: 0.2s; }
        .btn-mark-read:hover { background: #f8fafc; color: #1e293b; }

        .notification-item { display: flex; gap: 20px; padding: 20px 30px; border-bottom: 1px solid #f1f5f9; transition: background 0.2s; position: relative; }
        .notification-item:last-child { border-bottom: none; }
        .notification-item:hover { background-color: #f8fafc; cursor: pointer; }

        .notification-item.unread { background-color: #f0fdf4; }
        .notification-item.unread::before { content: ''; position: absolute; left: 0; top: 0; bottom: 0; width: 4px; background-color: var(--primary-green); }

        .notif-icon { width: 45px; height: 45px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 20px; flex-shrink: 0; }
        .icon-success { background-color: #dcfce7; color: #16a34a; }
        .icon-info { background-color: #dbeafe; color: #2563eb; }
        .icon-warning { background-color: #fef3c7; color: #d97706; }
        .icon-gray { background-color: #f1f5f9; color: #64748b; }

        .notif-content { flex-grow: 1; }
        .notif-content h6 { margin: 0 0 5px 0; font-weight: 600; color: var(--text-dark); }
        .notif-content p { margin: 0 0 8px 0; font-size: 14px; color: var(--text-muted); line-height: 1.5; }
        .notif-meta { display: flex; align-items: center; gap: 15px; font-size: 12px; color: #94a3b8; }
        .unread-dot { width: 8px; height: 8px; background-color: #ef4444; border-radius: 50%; display: inline-block; }
    </style>
</head>
<body>

<div class="wrapper">
    <aside class="sidebar">
        <div class="logo-container">
            <i class="bi bi-shield-check logo-icon"></i>
            <div class="logo-text"><h5>Smart Civic</h5><span>Problem Reporting System</span></div>
        </div>
        <a href="add-complaint.jsp" class="nav-btn-add"><i class="bi bi-plus-lg"></i> Add Complaint</a>
        <ul class="sidebar-nav">
            <li class="nav-item"><a href="dashboard.jsp" class="nav-link"><i class="bi bi-file-earmark-text"></i> My Complaints</a></li>
            <li class="nav-item"><a href="track-status.jsp" class="nav-link"><i class="bi bi-check2-circle"></i> Track Status</a></li>
            <li class="nav-item"><a href="notifications.jsp" class="nav-link active"><i class="bi bi-bell"></i> Notifications <span class="nav-badge" id="sidebarBadge">New</span></a></li>
            <li class="nav-item"><a href="profile.jsp" class="nav-link"><i class="bi bi-person"></i> Profile</a></li>
            <li class="nav-item mt-3"><a href="help-support.jsp" class="nav-link"><i class="bi bi-question-circle"></i> Help & Support</a></li>
        </ul>
        <a href="logout.jsp" class="logout-btn">Logout</a>
    </aside>

    <main class="main-content">
        <header class="top-header">
            <h4 class="m-0 fw-bold">Notifications</h4>
            <div class="user-profile">
                <div class="position-relative">
                    <i class="bi bi-bell fs-5 text-muted"></i>
                    <span class="position-absolute top-0 start-100 translate-middle p-1 bg-danger border border-light rounded-circle" id="headerBadge"></span>
                </div>
                <div class="d-flex align-items-center gap-2 ms-3">
                    <img src="<%= headerAvatar %>" alt="<%= user %>">
                    <span class="fw-medium"><%= user %></span>
                </div>
            </div>
        </header>

        <div class="row">
            <div class="col-lg-9">
                <div class="content-panel">

                    <div class="panel-header">
                        <h5 class="fw-bold m-0">Recent Activity</h5>
                        <button class="btn-mark-read" onclick="markAllAsRead()">
                            <i class="bi bi-check2-all"></i> Mark all as read
                        </button>
                    </div>

                    <div id="notificationList">

                        <div class="notification-item unread">
                            <div class="notif-icon icon-warning"><i class="bi bi-exclamation-triangle"></i></div>
                            <div class="notif-content">
                                <div class="d-flex justify-content-between">
                                    <h6>System Alert: Welcome to Smart Civic</h6>
                                    <span class="unread-dot"></span>
                                </div>
                                <p>Welcome to your centralized portal. Keep track of all your submitted complaints and local issues right here in real-time.</p>
                                <div class="notif-meta">
                                    <span><i class="bi bi-clock"></i> Just now</span>
                                </div>
                            </div>
                        </div>

                        <%
                            Connection conn = null;
                            PreparedStatement pstmt = null;
                            ResultSet rs = null;

                            try {
                                conn = DBConnection.getConnection();
                                // Fetching Top 10 recent complaints to build dynamic timeline notifications
                                String sql = "SELECT COMPLAINT_ID, PROBLEM_CATEGORY, STATUS, TO_CHAR(CREATED_AT, 'DD Mon, HH:MI AM') as f_date, EXTRACT(YEAR FROM CREATED_AT) as c_year " +
                                        "FROM (SELECT * FROM complaints WHERE CITIZEN_ID = ? ORDER BY CREATED_AT DESC) WHERE ROWNUM <= 10";

                                pstmt = conn.prepareStatement(sql);
                                pstmt.setInt(1, citizenId);
                                rs = pstmt.executeQuery();

                                while (rs.next()) {
                                    int cId = rs.getInt("COMPLAINT_ID");
                                    String cat = rs.getString("PROBLEM_CATEGORY");
                                    String status = rs.getString("STATUS");
                                    String date = rs.getString("f_date");
                                    int year = rs.getInt("c_year");
                                    String trackId = "#CMP-" + cId + "-" + year;

                                    String iconHtml = "";
                                    String title = "";
                                    String message = "";
                                    String unreadClass = "unread"; // Setting all as unread for demo

                                    // Dynamic Engine based on Real DB Status
                                    if ("Resolved".equalsIgnoreCase(status)) {
                                        iconHtml = "<div class=\"notif-icon icon-success\"><i class=\"bi bi-check-circle\"></i></div>";
                                        title = "Complaint Resolved!";
                                        message = "Great news! Your complaint <strong>" + trackId + "</strong> (" + cat + ") has been marked as successfully resolved by the municipal technician.";
                                    } else if ("In Progress".equalsIgnoreCase(status)) {
                                        iconHtml = "<div class=\"notif-icon icon-info\"><i class=\"bi bi-chat-left-dots\"></i></div>";
                                        title = "Status Update on " + trackId;
                                        message = "The status for your reported issue \"" + cat + "\" has changed from Pending to <strong>In Progress</strong>. A team is actively working on it.";
                                    } else { // Pending
                                        iconHtml = "<div class=\"notif-icon icon-gray\"><i class=\"bi bi-file-earmark-check\"></i></div>";
                                        title = "Complaint Received";
                                        message = "Your complaint regarding \"" + cat + "\" has been successfully logged into our system with ID <strong>" + trackId + "</strong>.";
                                        unreadClass = ""; // Pending ones are older/read in this simulation
                                    }
                        %>

                        <div class="notification-item <%= unreadClass %>">
                            <%= iconHtml %>
                            <div class="notif-content">
                                <div class="d-flex justify-content-between">
                                    <h6><%= title %></h6>
                                    <% if("unread".equals(unreadClass)) { %><span class="unread-dot"></span><% } %>
                                </div>
                                <p><%= message %></p>
                                <div class="notif-meta">
                                    <span><i class="bi bi-clock"></i> <%= date %></span>
                                    <a href="track-status.jsp?id=<%= cId %>" class="text-decoration-none">View Status</a>
                                </div>
                            </div>
                        </div>

                        <%
                                }
                            } catch (Exception e) {
                                e.printStackTrace();
                            } finally {
                                try { if (rs != null) rs.close(); } catch (Exception e) {}
                                try { if (pstmt != null) pstmt.close(); } catch (Exception e) {}
                                try { if (conn != null) conn.close(); } catch (Exception e) {}
                            }
                        %>

                    </div>
                </div>
            </div>
        </div>
    </main>
</div>

<script>
    function markAllAsRead() {
        const unreadItems = document.querySelectorAll('.notification-item.unread');
        unreadItems.forEach(item => {
            item.classList.remove('unread');
            item.style.transition = 'background-color 0.5s ease';
        });

        const unreadDots = document.querySelectorAll('.unread-dot');
        unreadDots.forEach(dot => {
            dot.style.display = 'none';
        });

        const sidebarBadge = document.getElementById('sidebarBadge');
        if(sidebarBadge) sidebarBadge.style.opacity = '0';

        const headerBadge = document.getElementById('headerBadge');
        if(headerBadge) headerBadge.style.display = 'none';
    }
</script>

</body>
</html>