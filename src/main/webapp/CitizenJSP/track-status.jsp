<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="true" %>
<%@ page import="dao.ComplaintDAO, java.util.HashMap" %>
<%
    // Session Verification
    String user = (String) session.getAttribute("user");
    if (user == null) {
        user = "Rahul Sharma";
    }

    // Dynamic Parameter Management
    String searchId = request.getParameter("id");
    if (searchId == null) {
        searchId = "";
    }

    HashMap<String, String> compDetails = null;

    // Input String Verification and Database Fetching Check
    if (!searchId.trim().isEmpty()) {
        try {
            String cleanIdStr = "";

            // Check if user entered full token template like #CMP-9-2026 or CMP-11-2026
            if (searchId.toUpperCase().contains("CMP-")) {
                String[] parts = searchId.split("-");
                if (parts.length >= 2) {
                    // Extract center numeric section (e.g. 9 or 11)
                    cleanIdStr = parts[1].replaceAll("[^0-9]", "");
                }
            } else {
                // If user just typed raw number like 9 or 11
                cleanIdStr = searchId.replaceAll("[^0-9]", "");
            }

            if (!cleanIdStr.isEmpty()) {
                long cid = Long.parseLong(cleanIdStr);
                ComplaintDAO dao = new ComplaintDAO();
                compDetails = dao.getComplaintStatus(cid);
            }
        } catch(Exception e) {
            e.printStackTrace();
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Track Status - Smart Civic</title>
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
        .nav-badge { background-color: #ef4444; color: white; border-radius: 50%; padding: 2px 6px; font-size: 10px; margin-left: auto; }
        .logout-btn { border: 1px solid #cbd5e1; background: transparent; padding: 10px; border-radius: 8px; text-align: center; color: var(--text-dark); font-weight: 500; text-decoration: none; transition: 0.2s; }
        .logout-btn:hover { background-color: #e2e8f0; }

        .main-content { flex-grow: 1; padding: 25px 40px; max-width: calc(100% - 260px); }
        .top-header { display: flex; justify-content: space-between; align-items: center; padding-bottom: 20px; border-bottom: 1px solid #f1f5f9; margin-bottom: 30px; }
        .user-profile { display: flex; align-items: center; gap: 15px; }
        .user-profile img { width: 35px; height: 35px; border-radius: 50%; object-fit: cover; }

        .content-panel { border: 1px solid #e2e8f0; border-radius: 16px; padding: 30px; background: white; }
        .search-box { display: flex; gap: 15px; margin-bottom: 40px; }
        .search-input { flex-grow: 1; padding: 15px 20px; border-radius: 10px; border: 1px solid #cbd5e1; font-size: 16px; background-color: #f8fafc; }
        .search-input:focus { outline: none; border-color: #3b82f6; background-color: white; box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1); }
        .btn-search { background-color: #2563eb; color: white; border: none; padding: 0 30px; border-radius: 10px; font-weight: bold; transition: 0.2s; }
        .btn-search:hover { background-color: #1d4ed8; }

        .complaint-details { background-color: #f8fafc; padding: 20px; border-radius: 12px; margin-bottom: 30px; }
        .timeline { border-left: 2px solid #e2e8f0; margin-left: 20px; padding-left: 30px; position: relative; }
        .timeline-step { margin-bottom: 30px; position: relative; }
        .timeline-step:last-child { margin-bottom: 0; }
        .timeline-step::before { content: ''; position: absolute; left: -40px; top: 0; width: 18px; height: 18px; border-radius: 50%; background: white; border: 3px solid #cbd5e1; }

        .timeline-step.completed::before { background: var(--primary-green); border-color: #bbf7d0; box-shadow: 0 0 0 4px #dcfce7;}
        .timeline-step.active::before { background: #3b82f6; border-color: #bfdbfe; box-shadow: 0 0 0 4px #dbeafe; }
        .timeline-step h6 { font-weight: bold; margin: 0 0 5px 0; color: var(--text-dark); }
        .timeline-step p { margin: 0; font-size: 14px; color: var(--text-muted); }
        .timeline-date { font-size: 12px; color: #94a3b8; font-weight: 500; margin-top: 5px; display: inline-block;}
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
            <li class="nav-item"><a href="track-status.jsp" class="nav-link active"><i class="bi bi-check2-circle"></i> Track Status</a></li>
            <li class="nav-item"><a href="notifications.jsp" class="nav-link"><i class="bi bi-bell"></i> Notifications <span class="nav-badge">3</span></a></li>
            <li class="nav-item"><a href="profile.jsp" class="nav-link"><i class="bi bi-person"></i> Profile</a></li>
            <li class="nav-item mt-3"><a href="help-support.jsp" class="nav-link"><i class="bi bi-question-circle"></i> Help & Support</a></li>
        </ul>
        <a href="logout.jsp" class="logout-btn">Logout</a>
    </aside>

    <main class="main-content">
        <header class="top-header">
            <h4 class="m-0 fw-bold">Track Status</h4>
            <div class="user-profile">
                <i class="bi bi-bell fs-5 text-muted"></i>
                <div class="d-flex align-items-center gap-2 ms-3">
                    <img src="https://ui-avatars.com/api/?name=<%= java.net.URLEncoder.encode(user, "UTF-8") %>&background=random" alt="<%= user %>">
                    <span class="fw-medium"><%= user %></span>
                </div>
            </div>
        </header>

        <div class="row">
            <div class="col-lg-8">
                <div class="content-panel">
                    <h5 class="fw-bold mb-2">Track Your Complaint</h5>
                    <p class="text-muted mb-4">Enter your Complaint ID or tracking number to see real-time updates.</p>

                    <form action="track-status.jsp" method="GET" class="search-box">
                        <input type="text" class="search-input" name="id" id="trackingId" placeholder="e.g. #CMP-9-2026" value="<%= searchId %>" required>
                        <button type="submit" class="btn-search">Track Issue</button>
                    </form>

                    <% if (!searchId.isEmpty()) {
                        if (compDetails != null) {
                            String category = compDetails.get("category");
                            String location = compDetails.get("location");
                            String status = compDetails.get("status");
                            String dbDate = compDetails.get("date");

                            // Dynamic Timeline CSS Engine Mapping
                            String step1Class = "completed";
                            String step2Class = "";
                            String step3Class = "";
                            String step4Class = "";
                            String badgeColor = "bg-danger text-white";

                            if ("Pending".equalsIgnoreCase(status)) {
                                step1Class = "active";
                                badgeColor = "bg-danger text-white";
                            } else if ("In Progress".equalsIgnoreCase(status)) {
                                step1Class = "completed";
                                step2Class = "completed";
                                step3Class = "active";
                                badgeColor = "bg-warning text-dark";
                            } else if ("Resolved".equalsIgnoreCase(status)) {
                                step1Class = "completed";
                                step2Class = "completed";
                                step3Class = "completed";
                                step4Class = "completed";
                                badgeColor = "bg-success text-white";
                            }
                    %>
                    <div class="tracking-result" id="trackingResult" style="display: block;">
                        <div class="complaint-details">
                            <div class="d-flex justify-content-between align-items-start">
                                <div>
                                    <h6 class="fw-bold mb-1"><%= category %></h6>
                                    <span class="badge <%= badgeColor %> mb-2"><%= status %></span>
                                    <p class="text-muted small m-0"><i class="bi bi-geo-alt"></i> <%= location %></p>
                                </div>
                                <div class="text-end">
                                    <small class="text-muted d-block">Complaint ID</small>
                                    <span class="fw-bold"><%= searchId.toUpperCase() %></span>
                                </div>
                            </div>
                        </div>

                        <h6 class="fw-bold mb-4">Tracking History</h6>

                        <div class="timeline">
                            <div class="timeline-step <%= step1Class %>">
                                <h6>Complaint Submitted</h6>
                                <p>Your complaint has been successfully registered in the system.</p>
                                <span class="timeline-date"><i class="bi bi-clock"></i> <%= dbDate %></span>
                            </div>

                            <div class="timeline-step <%= step2Class %>">
                                <h6>Assigned to Department</h6>
                                <p>The issue has been analyzed and routed to respective utility wing.</p>
                            </div>

                            <div class="timeline-step <%= step3Class %>">
                                <h6>In Progress</h6>
                                <p>A field technician has been dispatched to the reported location.</p>
                            </div>

                            <div class="timeline-step <%= step4Class %>">
                                <h6>Resolved</h6>
                                <p>Issue closed. Resolution evidence uploaded by the verification desk.</p>
                            </div>
                        </div>
                    </div>
                    <% } else { %>
                    <div class="alert alert-warning mt-4"><i class="bi bi-exclamation-triangle-fill me-2"></i> No record found for ID: <strong><%= searchId %></strong></div>
                    <% }
                    } %>
                </div>
            </div>
        </div>
    </main>
</div>
</body>
</html>