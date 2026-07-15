<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="true"%>
<%@ page import="java.sql.*, java.util.*, java.text.SimpleDateFormat, utility.DBConnection" %>
<%
    // =========================================================
    //   SESSION
    // =========================================================
    String adminUser = (String) session.getAttribute("adminUser");
    if(adminUser == null){
        adminUser = "Admin";
    }

    // =========================================================
    //   FILTER VALUES
    // =========================================================
    String search = request.getParameter("search") != null ? request.getParameter("search") : "";
    String category = request.getParameter("category") != null ? request.getParameter("category") : "";
    String statusFilter = request.getParameter("status") != null ? request.getParameter("status") : "";
    String priorityFilter = request.getParameter("priority") != null ? request.getParameter("priority") : "";

    // =========================================================
    //   DATABASE
    // =========================================================
    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    // =========================================================
    //   STATS
    // =========================================================
    int totalComplaints = 0;
    int resolvedComplaints = 0;
    int progressComplaints = 0;
    int pendingComplaints = 0;

    List<Map<String,String>> complaintList = new ArrayList<>();
    List<String> dynamicCategories = new ArrayList<>(); // To load dropdown dynamically

    try{
        conn = DBConnection.getConnection();

        // --- Fetch Categories for Dropdown dynamically ---
        try {
            ResultSet rsCat = conn.createStatement().executeQuery("SELECT CATEGORY_NAME FROM complaint_categories ORDER BY CATEGORY_NAME");
            while(rsCat.next()){
                dynamicCategories.add(rsCat.getString("CATEGORY_NAME"));
            }
        } catch(Exception ignored) { } // Ignore if table doesn't exist

        // --- STATS QUERIES ---
        rs = conn.createStatement().executeQuery("SELECT COUNT(*) FROM complaints");
        if(rs.next()) totalComplaints = rs.getInt(1);
        rs.close();

        rs = conn.createStatement().executeQuery("SELECT COUNT(*) FROM complaints WHERE LOWER(status)='resolved'");
        if(rs.next()) resolvedComplaints = rs.getInt(1);
        rs.close();

        rs = conn.createStatement().executeQuery("SELECT COUNT(*) FROM complaints WHERE LOWER(status)='in progress'");
        if(rs.next()) progressComplaints = rs.getInt(1);
        rs.close();

        rs = conn.createStatement().executeQuery("SELECT COUNT(*) FROM complaints WHERE LOWER(status)='pending'");
        if(rs.next()) pendingComplaints = rs.getInt(1);
        rs.close();

        // =========================================================
        //   DYNAMIC SEARCH QUERY (JOINING USERS & COMPLAINTS)
        // =========================================================
        String sql = "SELECT c.COMPLAINT_ID, c.PROBLEM_CATEGORY, c.DESCRIPTION, c.LOCATION_ADDRESS, c.STATUS, c.CREATED_AT, u.FULL_NAME, u.EMAIL " +
                "FROM complaints c " +
                "JOIN civicuser u ON c.CITIZEN_ID = u.USER_ID " +
                "WHERE 1=1 ";

        if(!search.isEmpty()){
            sql += " AND (LOWER(u.FULL_NAME) LIKE ? OR LOWER(c.PROBLEM_CATEGORY) LIKE ? OR TO_CHAR(c.COMPLAINT_ID) LIKE ?) ";
        }
        if(!category.isEmpty()){
            sql += " AND c.PROBLEM_CATEGORY = ? ";
        }
        if(!statusFilter.isEmpty()){
            sql += " AND c.STATUS = ? ";
        }
        if(!priorityFilter.isEmpty()){
            sql += " AND LOWER(c.DESCRIPTION) LIKE ? ";
        }

        sql += " ORDER BY c.COMPLAINT_ID DESC";

        ps = conn.prepareStatement(sql);
        int index = 1;

        if(!search.isEmpty()){
            ps.setString(index++, "%" + search.toLowerCase() + "%");
            ps.setString(index++, "%" + search.toLowerCase() + "%");
            ps.setString(index++, "%" + search + "%");
        }
        if(!category.isEmpty()){
            ps.setString(index++, category);
        }
        if(!statusFilter.isEmpty()){
            ps.setString(index++, statusFilter);
        }
        if(!priorityFilter.isEmpty()){
            ps.setString(index++, "%" + priorityFilter.toLowerCase() + "%");
        }

        rs = ps.executeQuery();
        SimpleDateFormat sdf = new SimpleDateFormat("dd MMM yyyy, hh:mm a");

        while(rs.next()){
            Map<String,String> data = new HashMap<>();
            data.put("complaint_id", rs.getString("COMPLAINT_ID"));
            data.put("problem_category", rs.getString("PROBLEM_CATEGORY") != null ? rs.getString("PROBLEM_CATEGORY") : "Unknown");
            data.put("description", rs.getString("DESCRIPTION") != null ? rs.getString("DESCRIPTION") : "");
            data.put("location", rs.getString("LOCATION_ADDRESS") != null ? rs.getString("LOCATION_ADDRESS") : "Not Provided");
            data.put("status", rs.getString("STATUS") != null ? rs.getString("STATUS") : "Pending");
            data.put("name", rs.getString("FULL_NAME") != null ? rs.getString("FULL_NAME") : "Unknown User");
            data.put("email", rs.getString("EMAIL") != null ? rs.getString("EMAIL") : "No Email");

            Timestamp ts = rs.getTimestamp("CREATED_AT");
            data.put("created_at", ts != null ? sdf.format(ts) : "Unknown Date");

            // Priority Logic based on description
            String desc = rs.getString("DESCRIPTION");
            String priority = "Medium";
            if(desc != null){
                if(desc.toLowerCase().contains("high") || desc.toLowerCase().contains("urgent") || desc.toLowerCase().contains("emergency")) priority = "High";
                else if(desc.toLowerCase().contains("low") || desc.toLowerCase().contains("minor")) priority = "Low";
            }
            data.put("priority", priority);

            complaintList.add(data);
        }

    } catch(Exception e){
        e.printStackTrace();
    } finally {
        try{ if(rs != null) rs.close(); if(ps != null) ps.close(); if(conn != null) conn.close(); }catch(Exception ex){}
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Total Complaints - Admin Panel</title>

    <!-- Bootstrap & Icons -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">

    <style>
        :root {
            --sidebar-bg: #0b1727;
            --main-bg: #f4f7fe;
            --primary-blue: #2563eb;
            --primary-green: #16a34a;
            --primary-orange: #ea580c;
            --primary-purple: #7c3aed;
            --text-dark: #1e293b;
            --text-muted: #64748b;
        }

        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: var(--main-bg); color: var(--text-dark); margin: 0; overflow-x: hidden; }
        .wrapper { display: flex; min-height: 100vh; }
        .sidebar { width: 260px; background-color: var(--sidebar-bg); color: white; padding: 20px 0; display: flex; flex-direction: column; position: fixed; height: 100vh; overflow-y: auto; z-index: 1000; }
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

        .main-content { flex-grow: 1; margin-left: 260px; padding: 25px 35px; min-height: 100vh; }
        .top-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 25px; }
        .user-profile { display: flex; align-items: center; gap: 20px; }
        .user-profile img { width: 40px; height: 40px; border-radius: 50%; object-fit: cover; }
        .admin-text h6 { margin: 0; font-weight: bold; font-size: 15px; }
        .admin-text small { color: var(--text-muted); font-size: 12px; }

        /* Stats Cards */
        .stats-card { background: white; border-radius: 12px; padding: 20px; box-shadow: 0 2px 10px rgba(0,0,0,0.02); display: flex; align-items: center; gap: 15px; }
        .stat-icon { width: 55px; height: 55px; border-radius: 12px; display: flex; align-items: center; justify-content: center; font-size: 24px; }
        .stat-details h6 { margin: 0; color: var(--text-muted); font-size: 13px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.5px;}
        .stat-details h2 { margin: 2px 0 0 0; font-weight: 800; font-size: 28px; color: var(--text-dark);}

        .bg-blue-soft { background-color: #dbeafe; color: var(--primary-blue); }
        .bg-green-soft { background-color: #dcfce7; color: var(--primary-green); }
        .bg-orange-soft { background-color: #ffedd5; color: var(--primary-orange); }
        .bg-red-soft { background-color: #fee2e2; color: #dc2626; }

        .dashboard-card { background: white; border-radius: 12px; padding: 24px; box-shadow: 0 2px 10px rgba(0,0,0,0.02); }
        .card-title { font-weight: 700; font-size: 18px; margin-bottom: 20px; color: #0f172a;}

        /* Form Controls */
        .search-box, .form-select { border-radius: 8px; border: 1px solid #e2e8f0; background: #f8fafc; font-size: 14px; box-shadow: none; padding: 10px 15px;}
        .search-box:focus, .form-select:focus { border-color: var(--primary-blue); background: white; }
        .btn-primary { border-radius: 8px; padding: 10px 20px; font-weight: 600; background: var(--primary-blue); border: none;}
        .btn-primary:hover { background: #1d4ed8; }

        /* Tables & Badges */
        .table { margin-bottom: 0; font-size: 14px; }
        .table th { border-bottom: 2px solid #f1f5f9; color: var(--text-muted); font-weight: 600; padding: 15px 12px; text-transform: uppercase; font-size: 12px; letter-spacing: 0.5px;}
        .table td { vertical-align: middle; padding: 15px 12px; color: #334155; font-weight: 500; border-bottom: 1px solid #f8fafc;}

        .status-badge { padding: 5px 12px; border-radius: 20px; font-size: 11px; font-weight: 700; text-transform: uppercase;}
        .badge-resolved { background-color: #dcfce7; color: #16a34a; }
        .badge-progress { background-color: #ffedd5; color: #ea580c; }
        .badge-pending { background-color: #fee2e2; color: #dc2626; }

        .priority-indicator { width: 10px; height: 10px; border-radius: 50%; display: inline-block; margin-right: 6px; }
        .priority-high { background-color: #dc2626; }
        .priority-med { background-color: #ea580c; }
        .priority-low { background-color: #2563eb; }

        .action-btns { display: flex; gap: 8px; }
        .btn-action { background: #f1f5f9; border: none; color: #475569; padding: 6px 12px; border-radius: 6px; transition: 0.2s; font-size: 13px;}
        .btn-action:hover { background: #e2e8f0; color: var(--primary-blue); }
    </style>
</head>
<body>

<div class="wrapper">

    <!-- SIDEBAR -->
    <aside class="sidebar">
        <div class="logo-container">
            <i class="bi bi-bank2 logo-icon"></i>
            <div class="logo-text"><h5>Smart Civic</h5><span>Problem Reporting System</span></div>
        </div>

        <ul class="sidebar-nav">
            <li class="nav-item"><a href="admin-dashboard.jsp" class="nav-link"><i class="bi bi-house-door"></i> Dashboard</a></li>
            <li class="nav-item"><a href="Admin-total-users.jsp" class="nav-link"><i class="bi bi-people"></i> Total Users</a></li>
            <li class="nav-item"><a href="Admin-total-complaints.jsp" class="nav-link active"><i class="bi bi-journal-text"></i> Total Complaints</a></li>
            <li class="nav-item"><a href="Admin-pending-complaints.jsp" class="nav-link"><i class="bi bi-hourglass-split"></i> Pending Complaints</a></li>
            <li class="nav-item"><a href="Admin-manage-complaints.jsp" class="nav-link"><i class="bi bi-card-checklist"></i> Manage Complaints</a></li>
            <li class="nav-item"><a href="Admin-update-status.jsp" class="nav-link"><i class="bi bi-arrow-clockwise"></i> Update Status</a></li>
            <li class="nav-item"><a href="Admin-user-management.jsp" class="nav-link"><i class="bi bi-person-gear"></i> User Management</a></li>
            <li class="nav-item"><a href="Admin-complaint-categories.jsp" class="nav-link"><i class="bi bi-grid"></i> Complaint Categories</a></li>
            <li class="nav-item"><a href="Admin-analytics.jsp" class="nav-link"><i class="bi bi-bar-chart"></i> Analytics</a></li>
            <li class="nav-item"><a href="Admin-reports.jsp" class="nav-link"><i class="bi bi-file-earmark-bar-graph"></i> Reports</a></li>
            <li class="nav-item mt-4"><a href="Admin-settings.jsp" class="nav-link"><i class="bi bi-gear"></i> Settings</a></li>
        </ul>

        <div class="logout-container"><a href="../logout.jsp" class="logout-btn"><i class="bi bi-box-arrow-right"></i> Logout</a></div>
    </aside>

    <!-- MAIN CONTENT -->
    <main class="main-content">
        <header class="top-header">
            <div class="d-flex align-items-center gap-3"><i class="bi bi-list fs-3" style="cursor: pointer;"></i><h4 class="m-0 fw-bold">Complaints Master List</h4></div>
            <div class="user-profile">
                <div class="position-relative"><i class="bi bi-bell fs-5 text-muted"></i></div>
                <div class="d-flex align-items-center gap-2">
                    <img src="https://ui-avatars.com/api/?name=<%= java.net.URLEncoder.encode(adminUser, "UTF-8") %>&background=0D8ABC&color=fff" alt="<%= adminUser %>">
                    <div class="admin-text d-none d-md-block"><h6><%= adminUser %></h6><small>Administrator</small></div>
                </div>
            </div>
        </header>

        <!-- STATS CARDS -->
        <div class="row g-4 mb-4">
            <div class="col-xl-3 col-md-6"><div class="stats-card"><div class="stat-icon bg-blue-soft"><i class="bi bi-folder2-open"></i></div><div class="stat-details"><h6>Total Complaints</h6><h2><%= totalComplaints %></h2></div></div></div>
            <div class="col-xl-3 col-md-6"><div class="stats-card"><div class="stat-icon bg-green-soft"><i class="bi bi-check-circle"></i></div><div class="stat-details"><h6>Resolved</h6><h2><%= resolvedComplaints %></h2></div></div></div>
            <div class="col-xl-3 col-md-6"><div class="stats-card"><div class="stat-icon bg-orange-soft"><i class="bi bi-tools"></i></div><div class="stat-details"><h6>In Progress</h6><h2><%= progressComplaints %></h2></div></div></div>
            <div class="col-xl-3 col-md-6"><div class="stats-card"><div class="stat-icon bg-red-soft"><i class="bi bi-hourglass-top"></i></div><div class="stat-details"><h6>Pending / New</h6><h2><%= pendingComplaints %></h2></div></div></div>
        </div>

        <!-- TABLE SECTION -->
        <div class="dashboard-card">
            <h5 class="card-title">All Complaints Directory</h5>

            <!-- FILTER FORM -->
            <form method="get" class="mb-4">
                <div class="row g-3">
                    <div class="col-md-3">
                        <input type="text" name="search" class="form-control search-box" placeholder="Search ID, keyword, or user..." value="<%= search %>">
                    </div>

                    <div class="col-md-2">
                        <select name="category" class="form-select">
                            <option value="">All Categories</option>
                            <% for(String cat : dynamicCategories) { %>
                            <option value="<%= cat %>" <%= category.equals(cat) ? "selected" : "" %>><%= cat %></option>
                            <% } if(dynamicCategories.isEmpty()) { %>
                            <option value="Garbage Overflow & Cleaning">Garbage Overflow & Cleaning</option>
                            <option value="Street Light Not Working">Street Light Not Working</option>
                            <option value="Water Leakage / Supply Issue">Water Leakage / Supply Issue</option>
                            <option value="Road Damage / Potholes">Road Damage / Potholes</option>
                            <% } %>
                        </select>
                    </div>

                    <div class="col-md-2">
                        <select name="status" class="form-select">
                            <option value="">All Statuses</option>
                            <option value="Pending" <%= statusFilter.equals("Pending") ? "selected" : "" %>>Pending</option>
                            <option value="In Progress" <%= statusFilter.equals("In Progress") ? "selected" : "" %>>In Progress</option>
                            <option value="Resolved" <%= statusFilter.equals("Resolved") ? "selected" : "" %>>Resolved</option>
                        </select>
                    </div>

                    <div class="col-md-2">
                        <select name="priority" class="form-select">
                            <option value="">All Priorities</option>
                            <option value="High" <%= priorityFilter.equals("High") ? "selected" : "" %>>High</option>
                            <option value="Medium" <%= priorityFilter.equals("Medium") ? "selected" : "" %>>Medium</option>
                            <option value="Low" <%= priorityFilter.equals("Low") ? "selected" : "" %>>Low</option>
                        </select>
                    </div>

                    <div class="col-md-2">
                        <button type="submit" class="btn btn-primary w-100"><i class="bi bi-search me-1"></i> Search</button>
                    </div>

                    <div class="col-md-1">
                        <!-- Redirects to the Admin-reports page -->
                        <a href="Admin-reports.jsp" class="btn btn-outline-secondary w-100" style="padding: 10px; border-radius: 8px;" title="Export Data"><i class="bi bi-download"></i></a>
                    </div>
                </div>
            </form>

            <!-- DATA TABLE -->
            <div class="table-responsive">
                <table class="table table-hover align-middle">
                    <thead>
                    <tr>
                        <th>ID & DATE</th>
                        <th>ISSUE DETAILS</th>
                        <th>REPORTED BY</th>
                        <th>PRIORITY</th>
                        <th>STATUS</th>
                        <th class="text-end">ACTIONS</th>
                    </tr>
                    </thead>
                    <tbody>
                    <%
                        for(Map<String,String> c : complaintList){
                            String status = c.get("status");
                            String statusClass = "badge-pending";
                            if("Resolved".equalsIgnoreCase(status)) statusClass = "badge-resolved";
                            else if("In Progress".equalsIgnoreCase(status)) statusClass = "badge-progress";

                            String priority = c.get("priority");
                            String priorityClass = "priority-med";
                            if("High".equalsIgnoreCase(priority)) priorityClass = "priority-high";
                            else if("Low".equalsIgnoreCase(priority)) priorityClass = "priority-low";
                    %>
                    <tr>
                        <td>
                            <span class="text-primary fw-bold">#CMP-<%= c.get("complaint_id") %></span>
                            <div class="text-muted small mt-1"><i class="bi bi-clock"></i> <%= c.get("created_at") %></div>
                        </td>
                        <td>
                            <h6 class="mb-1 text-dark" style="font-size: 14.5px;"><%= c.get("problem_category") %></h6>
                            <small class="text-muted"><i class="bi bi-geo-alt-fill text-danger opacity-75"></i> <%= c.get("location") %></small>
                        </td>
                        <td>
                            <div class="fw-semibold text-dark" style="font-size: 14px;"><%= c.get("name") %></div>
                            <small class="text-muted"><%= c.get("email") %></small>
                        </td>
                        <td>
                            <span class="priority-indicator <%= priorityClass %>"></span> <%= priority %>
                        </td>
                        <td>
                            <span class="status-badge <%= statusClass %>"><%= status %></span>
                        </td>
                        <td class="text-end">
                            <div class="action-btns justify-content-end">
                                <a href="Admin-manage-complaints.jsp?id=<%= c.get("complaint_id") %>" class="btn-action" title="View Details"><i class="bi bi-eye"></i></a>
                                <a href="Admin-update-status.jsp?id=<%= c.get("complaint_id") %>" class="btn-action" title="Update Status"><i class="bi bi-pencil-square"></i></a>
                            </div>
                        </td>
                    </tr>
                    <%
                        }
                        if(complaintList.isEmpty()) {
                    %>
                    <tr><td colspan="6" class="text-center py-5 text-muted">No complaints match your search criteria.</td></tr>
                    <% } %>
                    </tbody>
                </table>
            </div>
        </div>
    </main>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>