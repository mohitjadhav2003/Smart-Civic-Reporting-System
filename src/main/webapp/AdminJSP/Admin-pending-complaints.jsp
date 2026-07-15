<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="true" %>
<%
    String adminUser = (String) session.getAttribute("adminUser");
    if(adminUser == null) adminUser = "Admin";

    String search = request.getParameter("search");
    String category = request.getParameter("category");
    String priority = request.getParameter("priority");
    if(search == null) search = "";
    if(category == null) category = "";
    if(priority == null) priority = "";

    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    int totalPending = 0, highPriority = 0, unassigned = 0, overdue = 0;
    List<Map<String,String>> complaintList = new ArrayList<>();

    try {
        Class.forName("oracle.jdbc.driver.OracleDriver");
        conn = DriverManager.getConnection("jdbc:oracle:thin:@localhost:1521:orcl", "scott", "radhaswami");

        ps = conn.prepareStatement("SELECT COUNT(*) FROM complaints WHERE status='Pending'");
        rs = ps.executeQuery();
        if(rs.next()) totalPending = rs.getInt(1);
        rs.close(); ps.close();

        ps = conn.prepareStatement("SELECT COUNT(*) FROM complaints WHERE status='Pending' AND LOWER(description) LIKE '%high%'");
        rs = ps.executeQuery();
        if(rs.next()) highPriority = rs.getInt(1);
        rs.close(); ps.close();

        ps = conn.prepareStatement("SELECT COUNT(*) FROM complaints WHERE assigned_to IS NULL");
        rs = ps.executeQuery();
        if(rs.next()) unassigned = rs.getInt(1);
        rs.close(); ps.close();

        ps = conn.prepareStatement("SELECT COUNT(*) FROM complaints WHERE status='Pending' AND created_at < SYSTIMESTAMP - INTERVAL '2' DAY");
        rs = ps.executeQuery();
        if(rs.next()) overdue = rs.getInt(1);
        rs.close(); ps.close();

        String sql = "SELECT c.complaint_id, c.problem_category, c.description, c.location_address, c.created_at, u.full_name, u.mobile, c.assigned_to " +
                "FROM complaints c JOIN civicuser u ON c.citizen_id = u.user_id WHERE c.status='Pending' ";

        if(!search.equals("")) sql += " AND (LOWER(c.problem_category) LIKE ? OR LOWER(u.full_name) LIKE ? OR TO_CHAR(c.complaint_id) LIKE ?)";
        if(!category.equals("")) sql += " AND LOWER(c.problem_category)=?";
        if(!priority.equals("")) sql += " AND LOWER(c.description) LIKE ?";
        sql += " ORDER BY c.complaint_id DESC";

        ps = conn.prepareStatement(sql);
        int index = 1;
        if(!search.equals("")){
            ps.setString(index++, "%" + search.toLowerCase() + "%");
            ps.setString(index++, "%" + search.toLowerCase() + "%");
            ps.setString(index++, "%" + search + "%");
        }
        if(!category.equals("")) ps.setString(index++, category.toLowerCase());
        if(!priority.equals("")) ps.setString(index++, "%" + priority.toLowerCase() + "%");

        rs = ps.executeQuery();
        while(rs.next()){
            Map<String,String> data = new HashMap<>();
            data.put("id", rs.getString("complaint_id"));
            data.put("category", rs.getString("problem_category"));
            data.put("location", rs.getString("location_address"));
            data.put("name", rs.getString("full_name"));
            data.put("mobile", rs.getString("mobile"));

            String desc = rs.getString("description");
            String priorityLevel = "Medium";
            if(desc != null){
                if(desc.toLowerCase().contains("high")) priorityLevel = "High";
                else if(desc.toLowerCase().contains("low")) priorityLevel = "Low";
            }
            data.put("priority", priorityLevel);

            Timestamp created = rs.getTimestamp("created_at");
            long hours = 0;
            if(created != null){
                long diff = System.currentTimeMillis() - created.getTime();
                hours = diff / (1000 * 60 * 60);
            }
            data.put("hours", hours + " Hours");
            data.put("date", created != null ? new SimpleDateFormat("dd MMM yyyy").format(created) : "N/A");

            String assigned = rs.getString("assigned_to");
            data.put("assigned", (assigned == null || assigned.trim().isEmpty()) ? "No" : "Yes");
            complaintList.add(data);
        }
    } catch(Exception e){ out.println(e); } finally {
        try{ if(rs != null) rs.close(); if(ps != null) ps.close(); if(conn != null) conn.close(); }catch(Exception ex){}
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Pending Complaints Queue - Admin Panel</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">

    <style>
        /* CSS Matched with Dashboard Style */
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

        .admin-card { background-color: white; border-radius: 12px; padding: 24px; border: none; box-shadow: 0 2px 10px rgba(0,0,0,0.02); height: 100%; }
        .card-header-flex { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; flex-wrap: wrap; gap: 15px; border-bottom: 1px solid #f1f5f9; padding-bottom: 16px; }

        .stat-box { display: flex; align-items: center; gap: 15px; min-height: 90px; }
        .stat-icon { width: 55px; height: 55px; border-radius: 12px; display: flex; align-items: center; justify-content: center; font-size: 24px; }
        .stat-details h6 { margin: 0; color: var(--text-muted); font-size: 13px; font-weight: 600;}
        .stat-details h2 { margin: 2px 0; font-weight: 800; font-size: 26px; }

        .bg-blue-soft { background-color: #dbeafe; color: var(--primary-blue); }
        .bg-red-soft { background-color: #fee2e2; color: #dc2626; }
        .bg-orange-soft { background-color: #ffedd5; color: var(--primary-orange); }
        .bg-purple-soft { background-color: #f3e8ff; color: var(--primary-purple); }
        .bg-dark-soft { background-color: #e2e8f0; color: #334155; }

        .toolbar-filters { display: flex; gap: 10px; margin-bottom: 16px; flex-wrap: wrap; }
        .search-box { position: relative; width: 300px; }
        .search-box i { position: absolute; top: 11px; left: 12px; color: #64748b; }
        .search-box input { padding-left: 36px; height: 42px; border-radius: 8px; border: 1px solid #cbd5e1; }
        .filter-select { min-width: 160px; border-radius: 8px; border: 1px solid #cbd5e1; height: 42px; }

        .table { margin-bottom: 0; font-size: 14px; }
        .table th { border-bottom-width: 1px; color: var(--text-muted); font-weight: 600; padding: 15px 10px; font-size: 13px; text-transform: uppercase;}
        .table td { vertical-align: middle; padding: 15px 10px; color: #334155; font-weight: 500;}

        .priority-indicator { width: 8px; height: 8px; border-radius: 50%; display: inline-block; margin-right: 8px; }
        .priority-high { background: #dc2626; }
        .priority-med { background: #ea580c; }
        .priority-low { background: #2563eb; }

        .time-danger { color: #dc2626; font-weight: 600; background: #fee2e2; padding: 4px 8px; border-radius: 6px; font-size: 12.5px;}
        .time-warning { color: #ea580c; font-weight: 600; background: #ffedd5; padding: 4px 8px; border-radius: 6px; font-size: 12.5px;}
        .time-normal { color: #64748b; font-weight: 600; background: #f1f5f9; padding: 4px 8px; border-radius: 6px; font-size: 12.5px;}

        .action-btns { display: flex; gap: 10px; }
        .btn-primary-action { background-color: var(--primary-orange); color: white; padding: 7px 14px; border-radius: 8px; text-decoration: none; font-size: 13px; font-weight: 600; display: inline-flex; align-items: center; transition: 0.2s;}
        .btn-primary-action:hover { background-color: #c2410c; color: white; }
    </style>
</head>
<body>

<div class="wrapper">
    <aside class="sidebar">
        <div class="logo-container"><i class="bi bi-bank2 logo-icon"></i><div class="logo-text"><h5>Smart Civic</h5><span>Problem Reporting System</span></div></div>
        <ul class="sidebar-nav">
            <li class="nav-item"><a href="admin-dashboard.jsp" class="nav-link"><i class="bi bi-house-door"></i> Dashboard</a></li>
            <li class="nav-item"><a href="Admin-total-users.jsp" class="nav-link"><i class="bi bi-people"></i> Total Users</a></li>
            <li class="nav-item"><a href="Admin-total-complaints.jsp" class="nav-link"><i class="bi bi-journal-text"></i> Total Complaints</a></li>
            <li class="nav-item"><a href="Admin-pending-complaints.jsp" class="nav-link active"><i class="bi bi-hourglass-split"></i> Pending Complaints</a></li>
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

    <main class="main-content">
        <header class="top-header">
            <div class="d-flex align-items-center gap-3">
                <i class="bi bi-list fs-3" style="cursor: pointer;"></i>
                <h4 class="m-0 fw-bold">Pending Complaints Queue</h4>
            </div>
            <div class="user-profile">
                <div class="position-relative">
                    <i class="bi bi-bell fs-5 text-muted"></i>
                    <span class="position-absolute top-0 start-100 translate-middle badge rounded-pill bg-danger" style="font-size: 9px;">8</span>
                </div>
                <div class="d-flex align-items-center gap-2 ms-3">
                    <img src="https://ui-avatars.com/api/?name=<%= java.net.URLEncoder.encode(adminUser, "UTF-8") %>&background=0D8ABC&color=fff" alt="<%= adminUser %>">
                    <div class="admin-text d-none d-md-block">
                        <h6><%= adminUser %></h6>
                        <small>Administrator</small>
                    </div>
                </div>
            </div>
        </header>

        <div class="row g-4 mb-4">
            <div class="col-xl-3 col-md-6">
                <div class="admin-card stat-box py-3">
                    <div class="stat-icon bg-orange-soft"><i class="bi bi-hourglass-split"></i></div>
                    <div class="stat-details">
                        <h6>Total Pending</h6>
                        <h2><%= totalPending %></h2>
                    </div>
                </div>
            </div>
            <div class="col-xl-3 col-md-6">
                <div class="admin-card stat-box py-3">
                    <div class="stat-icon bg-red-soft"><i class="bi bi-exclamation-triangle-fill"></i></div>
                    <div class="stat-details">
                        <h6>High Priority</h6>
                        <h2 class="text-danger"><%= highPriority %></h2>
                    </div>
                </div>
            </div>
            <div class="col-xl-3 col-md-6">
                <div class="admin-card stat-box py-3">
                    <div class="stat-icon bg-purple-soft"><i class="bi bi-person-x-fill"></i></div>
                    <div class="stat-details">
                        <h6>Unassigned</h6>
                        <h2><%= unassigned %></h2>
                    </div>
                </div>
            </div>
            <div class="col-xl-3 col-md-6">
                <div class="admin-card stat-box py-3">
                    <div class="stat-icon bg-dark-soft"><i class="bi bi-clock-history"></i></div>
                    <div class="stat-details">
                        <h6>Overdue (>48h)</h6>
                        <h2><%= overdue %></h2>
                    </div>
                </div>
            </div>
        </div>

        <div class="admin-card">
            <div class="card-header-flex pb-3">
                <h5 class="fw-bold m-0">Action Required Queue</h5>
            </div>

            <form method="get">
                <div class="toolbar-filters">
                    <div class="search-box">
                        <i class="bi bi-search"></i>
                        <input type="text" class="form-control" name="search" value="<%= search %>" placeholder="Search ID, Subject, or Assignee...">
                    </div>
                    <select class="form-select filter-select" name="category">
                        <option value="">All Categories</option>
                        <option value="street light" <%= category.equals("street light")?"selected":"" %>>Street Light</option>
                        <option value="garbage overflow" <%= category.equals("garbage overflow")?"selected":"" %>>Garbage Overflow</option>
                        <option value="water leakage" <%= category.equals("water leakage")?"selected":"" %>>Water Leakage</option>
                        <option value="road damage" <%= category.equals("road damage")?"selected":"" %>>Road Damage</option>
                    </select>
                    <select class="form-select filter-select" name="priority">
                        <option value="">All Priorities</option>
                        <option value="high" <%= priority.equals("high")?"selected":"" %>>High</option>
                        <option value="medium" <%= priority.equals("medium")?"selected":"" %>>Medium</option>
                        <option value="low" <%= priority.equals("low")?"selected":"" %>>Low</option>
                    </select>
                    <button type="submit" class="btn btn-primary">Search</button>
                </div>
            </form>

            <div class="table-responsive mt-3">
                <table class="table table-hover align-middle">
                    <thead>
                    <tr>
                        <th>ID & Reported</th>
                        <th>Issue Details</th>
                        <th>Reported By</th>
                        <th>Priority</th>
                        <th>Time Pending</th>
                        <th class="text-center">Actions</th>
                    </tr>
                    </thead>
                    <tbody>
                    <%
                        for(Map<String,String> c : complaintList){
                            String priorityClass = "priority-med";
                            String timeClass = "time-warning";
                            if(c.get("priority").equalsIgnoreCase("High")){ priorityClass = "priority-high"; timeClass = "time-danger"; }
                            else if(c.get("priority").equalsIgnoreCase("Low")){ priorityClass = "priority-low"; timeClass = "time-normal"; }
                    %>
                    <tr>
                        <td>
                            <div class="fw-bold text-primary">#CMP-<%= c.get("id") %></div>
                            <div class="text-muted small mt-1"><%= c.get("date") %></div>
                        </td>
                        <td>
                            <div class="fw-semibold"><%= c.get("category") %></div>
                            <small class="text-muted"><i class="bi bi-geo-alt"></i> <%= c.get("location") %></small>
                        </td>
                        <td>
                            <div class="fw-semibold text-dark"><%= c.get("name") %></div>
                            <small class="text-muted"><%= c.get("mobile") %></small>
                        </td>
                        <td><span class="priority-indicator <%= priorityClass %>"></span> <%= c.get("priority") %></td>
                        <td><span class="<%= timeClass %>"><i class="bi bi-clock me-1"></i><%= c.get("hours") %></span></td>
                        <td class="text-center">
                            <% if(c.get("assigned").equals("No")){ %>
                                <a href="Admin-update-status.jsp?searchId=CMP-<%= c.get("id") %>" class="btn-primary-action">
                                    <i class="bi bi-person-plus-fill me-2"></i> Assign
                                </a>
                            <% } else { %>
                                <a href="Admin-update-status.jsp?searchId=CMP-<%= c.get("id") %>" class="btn btn-light border fw-semibold text-decoration-none text-dark" style="font-size: 13px; padding: 7px 14px; border-radius: 8px;">
                                    Update
                                </a>
                            <% } %>
                        </td>
                    </tr>
                    <% } if(complaintList.isEmpty()) { %>
                    <tr><td colspan="6" class="text-center py-4 text-muted">No pending complaints found.</td></tr>
                    <% } %>
                    </tbody>
                </table>
            </div>

            <div class="d-flex justify-content-between align-items-center mt-4 border-top pt-3">
                <span class="text-muted">Showing <%= complaintList.size() %> complaints</span>
                <nav>
                    <ul class="pagination pagination-sm mb-0">
                        <li class="page-item disabled"><a class="page-link" href="#">Previous</a></li>
                        <li class="page-item active"><a class="page-link" href="#">1</a></li>
                        <li class="page-item"><a class="page-link" href="#">2</a></li>
                        <li class="page-item"><a class="page-link" href="#">Next</a></li>
                    </ul>
                </nav>
            </div>
        </div>
    </main>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>