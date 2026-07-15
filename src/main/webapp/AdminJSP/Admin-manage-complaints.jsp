<%@page import="java.sql.*"%>
<%@page import="java.util.*"%>
<%@page import="java.text.SimpleDateFormat"%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="true"%>

<%
    /* =========================================================
       SESSION
    ========================================================= */
    String adminUser = (String) session.getAttribute("adminUser");
    if(adminUser == null){
        adminUser = "Admin";
    }

    /* =========================================================
       FILTERS
    ========================================================= */
    String search = request.getParameter("search");
    String category = request.getParameter("category");
    String statusFilter = request.getParameter("status");

    if(search == null) search = "";
    if(category == null) category = "";
    if(statusFilter == null) statusFilter = "";

    /* =========================================================
       DATABASE
    ========================================================= */
    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;
    List<Map<String,String>> complaintList = new ArrayList<>();

    try{
        Class.forName("oracle.jdbc.driver.OracleDriver");
        conn = DriverManager.getConnection("jdbc:oracle:thin:@localhost:1521:orcl", "scott", "radhaswami");

        /* =========================================================
           QUERY - Added image_path and resolution_image
        ========================================================= */
        String sql =
                "SELECT " +
                        "c.complaint_id, " +
                        "c.problem_category, " +
                        "c.location_address, " +
                        "c.status, " +
                        "c.description, " +
                        "c.created_at, " +
                        "c.image_path, " +
                        "c.resolution_image, " + // New Column
                        "u.full_name " +
                        "FROM complaints c " +
                        "JOIN civicuser u " +
                        "ON c.citizen_id = u.user_id " +
                        "WHERE 1=1 ";

        if(!search.equals("")){
            sql += " AND (LOWER(c.problem_category) LIKE ? OR LOWER(u.full_name) LIKE ? OR TO_CHAR(c.complaint_id) LIKE ?)";
        }
        if(!category.equals("")){
            sql += " AND LOWER(c.problem_category)=?";
        }
        if(!statusFilter.equals("")){
            sql += " AND LOWER(c.status)=?";
        }

        sql += " ORDER BY c.complaint_id DESC";
        ps = conn.prepareStatement(sql);

        int index = 1;
        if(!search.equals("")){
            ps.setString(index++, "%" + search.toLowerCase() + "%");
            ps.setString(index++, "%" + search.toLowerCase() + "%");
            ps.setString(index++, "%" + search + "%");
        }
        if(!category.equals("")){
            ps.setString(index++, category.toLowerCase());
        }
        if(!statusFilter.equals("")){
            ps.setString(index++, statusFilter.toLowerCase());
        }

        rs = ps.executeQuery();

        /* =========================================================
           FETCH DATA
        ========================================================= */
        while(rs.next()){
            Map<String,String> data = new HashMap<>();
            data.put("id", rs.getString("complaint_id"));
            data.put("category", rs.getString("problem_category"));
            data.put("location", rs.getString("location_address"));
            data.put("status", rs.getString("status"));
            data.put("name", rs.getString("full_name"));
            data.put("description", rs.getString("description"));

            // Get Images Safely
            String imgPath = rs.getString("image_path");
            data.put("image_path", imgPath != null ? imgPath : "");

            String resImg = "";
            try {
                resImg = rs.getString("resolution_image"); // Use try-catch in case column isn't created yet
            } catch(Exception e) {}
            data.put("resolution_image", resImg != null ? resImg : "");

            /* =========================================================
               PRIORITY
            ========================================================= */
            String desc = rs.getString("description");
            String priority = "Medium";
            if(desc != null){
                if(desc.toLowerCase().contains("high")) priority = "High";
                else if(desc.toLowerCase().contains("low")) priority = "Low";
            }
            data.put("priority", priority);

            /* =========================================================
               DATE FORMAT
            ========================================================= */
            Timestamp ts = rs.getTimestamp("created_at");
            String formattedDate = "";
            if(ts != null){
                formattedDate = new SimpleDateFormat("dd MMM, hh:mm a").format(ts);
            }
            data.put("date", formattedDate);

            /* =========================================================
               ASSIGNED
            ========================================================= */
            String assignedName = "Unassigned";
            if(priority.equals("High")) assignedName = "Karan Singh";
            else if(priority.equals("Medium")) assignedName = "Priya Verma";
            else assignedName = "Raj Patel";
            data.put("assigned", assignedName);

            complaintList.add(data);
        }
    }
    catch(Exception e){
        out.println(e);
    }
    finally{
        try{
            if(rs != null) rs.close();
            if(ps != null) ps.close();
            if(conn != null) conn.close();
        }
        catch(Exception ex){}
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Manage Complaints - Admin Panel</title>
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

        .admin-card { background-color: white; border-radius: 12px; padding: 24px; border: none; box-shadow: 0 2px 10px rgba(0,0,0,0.02); }

        .toolbar-top { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; flex-wrap: wrap; gap: 15px; border-bottom: 1px solid #f1f5f9; padding-bottom: 16px;}
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

        .status-badge { padding: 6px 12px; border-radius: 8px; font-size: 12.5px; font-weight: 600; }
        .badge-resolved { background: #dcfce7; color: #16a34a; }
        .badge-progress { background: #ffedd5; color: #ea580c; }
        .badge-pending { background: #fee2e2; color: #dc2626; }

        .btn-dropdown-action { background: #f8fafc; border: 1px solid #e2e8f0; padding: 7px 14px; border-radius: 8px; color: #475569; font-weight: 500;}
        .avatar-small { width: 32px; height: 32px; border-radius: 50%; background: #0ea5e9; color: white; display: flex; align-items: center; justify-content: center; font-weight: 700; font-size: 12px;}
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
            <li class="nav-item"><a href="Admin-pending-complaints.jsp" class="nav-link"><i class="bi bi-hourglass-split"></i> Pending Complaints</a></li>
            <li class="nav-item"><a href="Admin-manage-complaints.jsp" class="nav-link active"><i class="bi bi-card-checklist"></i> Manage Complaints</a></li>
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
                <h4 class="m-0 fw-bold">Complaint Management</h4>
            </div>
            <div class="user-profile">
                <div class="position-relative">
                    <i class="bi bi-bell fs-5 text-muted"></i>
                </div>
                <div class="d-flex align-items-center gap-2">
                    <img src="https://ui-avatars.com/api/?name=<%= java.net.URLEncoder.encode(adminUser, "UTF-8") %>&background=0D8ABC&color=fff" alt="<%= adminUser %>">
                    <div class="admin-text d-none d-md-block">
                        <h6><%= adminUser %></h6>
                        <small>Administrator</small>
                    </div>
                </div>
            </div>
        </header>

        <div class="admin-card">
            <div class="toolbar-top">
                <div class="d-flex align-items-center gap-2">
                    <select class="form-select filter-select" style="width: auto;">
                        <option>Bulk Actions</option>
                        <option>Mark Resolved</option>
                        <option>Mark In Progress</option>
                        <option>Delete Selected</option>
                    </select>
                    <button class="btn btn-outline-secondary">Apply</button>
                </div>
                <button class="btn btn-primary"><i class="bi bi-plus-lg me-1"></i> Create Ticket</button>
            </div>

            <form method="get">
                <div class="toolbar-filters">
                    <div class="search-box">
                        <i class="bi bi-search"></i>
                        <input type="text" class="form-control" name="search" value="<%= search %>" placeholder="Search ID, Subject, or Assignee...">
                    </div>
                    <select class="form-select filter-select" name="category">
                        <option value="">All Categories</option>
                        <option value="garbage" <%= category.equals("garbage")?"selected":"" %>>Garbage</option>
                        <option value="street light" <%= category.equals("street light")?"selected":"" %>>Street Light</option>
                        <option value="water leakage" <%= category.equals("water leakage")?"selected":"" %>>Water Leakage</option>
                        <option value="road damage" <%= category.equals("road damage")?"selected":"" %>>Road Damage</option>
                    </select>
                    <select class="form-select filter-select" name="status">
                        <option value="">All Statuses</option>
                        <option value="pending" <%= statusFilter.equals("pending")?"selected":"" %>>Pending</option>
                        <option value="in progress" <%= statusFilter.equals("in progress")?"selected":"" %>>In Progress</option>
                        <option value="resolved" <%= statusFilter.equals("resolved")?"selected":"" %>>Resolved</option>
                    </select>
                    <button type="submit" class="btn btn-primary">Search</button>
                </div>
            </form>

            <div class="table-responsive mt-3">
                <table class="table table-hover align-middle">
                    <thead>
                    <tr>
                        <th style="width: 40px;"></th>
                        <th>ID & Date</th>
                        <th>Subject & Location</th>
                        <th>Assigned To</th>
                        <th>Priority</th>
                        <th>Status</th>
                        <th class="text-center">Manage</th>
                    </tr>
                    </thead>
                    <tbody>
                    <%
                        for(Map<String,String> c : complaintList){
                            String priorityClass = "priority-med";
                            if(c.get("priority").equalsIgnoreCase("High")) priorityClass = "priority-high";
                            else if(c.get("priority").equalsIgnoreCase("Low")) priorityClass = "priority-low";

                            String statusClass = "badge-pending";
                            if(c.get("status").equalsIgnoreCase("Resolved")) statusClass = "badge-resolved";
                            else if(c.get("status").equalsIgnoreCase("In Progress")) statusClass = "badge-progress";
                    %>
                    <tr>
                        <td>
                            <input type="checkbox" class="form-check-input">
                            <input type="hidden" id="comp_img_<%= c.get("id") %>" value="<%= c.get("image_path") %>">
                            <input type="hidden" id="res_img_<%= c.get("id") %>" value="<%= c.get("resolution_image") %>">
                        </td>
                        <td>
                            <div class="text-primary fw-bold">#CMP-<%= c.get("id") %></div>
                            <div class="text-muted small mt-1"><%= c.get("date") %></div>
                        </td>
                        <td>
                            <div class="fw-semibold"><%= c.get("category") %></div>
                            <small class="text-muted"><i class="bi bi-geo-alt"></i> <%= c.get("location") %></small>
                        </td>
                        <td>
                            <div class="d-flex align-items-center gap-2">
                                <div class="avatar-small"><%= c.get("assigned").substring(0,1) %></div>
                                <span><%= c.get("assigned") %></span>
                            </div>
                        </td>
                        <td><span class="priority-indicator <%= priorityClass %>"></span> <%= c.get("priority") %></td>
                        <td><span class="status-badge <%= statusClass %>"><%= c.get("status") %></span></td>
                        <td class="text-center">
                            <div class="dropdown">
                                <button class="btn-dropdown-action dropdown-toggle" type="button" data-bs-toggle="dropdown">Actions</button>
                                <ul class="dropdown-menu dropdown-menu-end shadow border-0">
                                    <li>
                                        <a class="dropdown-item" href="javascript:void(0)" onclick="viewDetails('<%= c.get("id") %>', '<%= c.get("status") %>')">
                                            <i class="bi bi-eye text-primary me-2"></i> View Details
                                        </a>
                                    </li>
                                    <li><hr class="dropdown-divider"></li>
                                    <li>
                                        <a class="dropdown-item text-danger" href="#">
                                            <i class="bi bi-trash me-2"></i> Delete
                                        </a>
                                    </li>
                                </ul>
                            </div>
                        </td>
                    </tr>
                    <% }
                       if(complaintList.isEmpty()) {
                    %>
                    <tr>
                        <td colspan="7" class="text-center py-4 text-muted">No complaints found.</td>
                    </tr>
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

<div class="modal fade" id="viewDetailsModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-lg modal-dialog-centered">
        <div class="modal-content border-0 shadow">
            <div class="modal-header bg-light border-0 pb-3">
                <h5 class="modal-title fw-bold">
                    Complaint Evidence <span id="modalComplaintId" class="text-primary ms-2"></span>
                </h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body p-4">
                <div class="row g-4">
                    <div class="col-md-6 text-center">
                        <h6 class="fw-bold text-muted mb-3"><i class="bi bi-image me-1"></i> Problem Reported</h6>
                        <div class="card shadow-sm border-0 bg-light">
                            <div class="card-body p-2">
                                <img id="modalComplaintImg" src="" class="img-fluid rounded" style="max-height: 280px; object-fit: contain; width: 100%;">
                            </div>
                        </div>
                    </div>
                    <div class="col-md-6 text-center" id="resolutionImageSection">
                        <h6 class="fw-bold text-success mb-3"><i class="bi bi-check-circle-fill me-1"></i> Problem Solved</h6>
                        <div class="card shadow-sm border-success">
                            <div class="card-body p-2">
                                <img id="modalResolutionImg" src="" class="img-fluid rounded" style="max-height: 280px; object-fit: contain; width: 100%;">
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>

<script>
    function viewDetails(id, status) {
        document.getElementById('modalComplaintId').innerText = '#CMP-' + id;

        let compImgData = document.getElementById('comp_img_' + id).value;
        let resImgData = document.getElementById('res_img_' + id).value;

        let compImgEl = document.getElementById('modalComplaintImg');
        if (compImgData && compImgData.trim() !== '' && compImgData !== 'null') {
            compImgEl.src = compImgData;
        } else {
            compImgEl.src = 'https://placehold.co/400x300/f1f5f9/64748b?text=No+Image+Provided';
        }

        let resSection = document.getElementById('resolutionImageSection');
        let resImgEl = document.getElementById('modalResolutionImg');

        if (status.toLowerCase() === 'resolved') {
            resSection.style.display = 'block';
            if (resImgData && resImgData.trim() !== '' && resImgData !== 'null') {
                resImgEl.src = resImgData;
            } else {
                resImgEl.src = 'https://placehold.co/400x300/dcfce7/16a34a?text=Resolution+Pending+Upload';
            }
        } else {
            resSection.style.display = 'none';
        }

        new bootstrap.Modal(document.getElementById('viewDetailsModal')).show();
    }
</script>

</body>
</html>