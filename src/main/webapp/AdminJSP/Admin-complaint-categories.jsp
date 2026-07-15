<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="true" %>
<%@ page import="java.util.*, java.sql.*, utility.DBConnection, java.text.SimpleDateFormat" %>
<%
    // Fetch the admin user from the session
    String adminUser = (String) session.getAttribute("adminUser");
    if (adminUser == null) {
        adminUser = "Admin";
    }

    // --- ADD CATEGORY LOGIC (POST REQUEST) ---
    String actionMsg = "";
    String actionType = "";

    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String cName = request.getParameter("catName");
        String cDesc = request.getParameter("catDesc");
        String cDept = request.getParameter("catDept");
        String cStatus = request.getParameter("catStatus");

        Connection postConn = null;
        PreparedStatement psId = null, psInsert = null;
        ResultSet rsId = null;
        try {
            postConn = DBConnection.getConnection();

            // Generate next ID
            psId = postConn.prepareStatement("SELECT NVL(MAX(CATEGORY_ID), 0) + 1 FROM complaint_categories");
            rsId = psId.executeQuery();
            int nextId = 1;
            if(rsId.next()) nextId = rsId.getInt(1);

            // Insert into Database
            String insertSql = "INSERT INTO complaint_categories (CATEGORY_ID, CATEGORY_NAME, DESCRIPTION, DEFAULT_DEPT, STATUS) VALUES (?, ?, ?, ?, ?)";
            psInsert = postConn.prepareStatement(insertSql);
            psInsert.setInt(1, nextId);
            psInsert.setString(2, cName);
            psInsert.setString(3, cDesc);
            psInsert.setString(4, cDept);
            psInsert.setString(5, cStatus);

            int rows = psInsert.executeUpdate();
            if (rows > 0) {
                actionMsg = "New Complaint Category created successfully!";
                actionType = "success";
            } else {
                actionMsg = "Failed to add category.";
                actionType = "danger";
            }
        } catch(Exception e) {
            actionMsg = "Database Error: " + e.getMessage();
            actionType = "danger";
        } finally {
            if(rsId != null) try{ rsId.close(); } catch(Exception e){}
            if(psId != null) try{ psId.close(); } catch(Exception e){}
            if(psInsert != null) try{ psInsert.close(); } catch(Exception e){}
            if(postConn != null) try{ postConn.close(); } catch(Exception e){}
        }
    }
    // --- END POST LOGIC ---

    // Variables for Data Display
    int activeCats = 0;
    String mostUsed = "N/A";
    List<Map<String, Object>> categories = new ArrayList<>();
    String dbError = "";

    Connection conn = null;
    try {
        conn = DBConnection.getConnection();

        // 1. Get Total Active Categories
        ResultSet rs1 = conn.createStatement().executeQuery("SELECT COUNT(*) FROM complaint_categories WHERE LOWER(STATUS) = 'active'");
        if(rs1.next()) activeCats = rs1.getInt(1);

        // 2. Get Most Used Category (From complaints table)
        try {
            String mostUsedSql = "SELECT PROBLEM_CATEGORY FROM (SELECT PROBLEM_CATEGORY, COUNT(*) as c FROM complaints GROUP BY PROBLEM_CATEGORY ORDER BY c DESC) WHERE ROWNUM = 1";
            ResultSet rs2 = conn.createStatement().executeQuery(mostUsedSql);
            if(rs2.next()) mostUsed = rs2.getString(1);
            if(mostUsed == null || mostUsed.trim().isEmpty()) mostUsed = "No Data Yet";
        } catch(Exception ignored) { }

        // 3. Get All Categories & Calculate their totals dynamically from complaints table
        String listSql = "SELECT c.CATEGORY_ID, c.CATEGORY_NAME, c.DESCRIPTION, c.DEFAULT_DEPT, c.STATUS, " +
                "(SELECT COUNT(*) FROM complaints cmp WHERE cmp.PROBLEM_CATEGORY = c.CATEGORY_NAME) as cmp_count " +
                "FROM complaint_categories c ORDER BY c.CATEGORY_ID DESC";

        try {
            ResultSet rs3 = conn.createStatement().executeQuery(listSql);
            while(rs3.next()){
                Map<String, Object> map = new HashMap<>();
                map.put("id", rs3.getString("CATEGORY_ID"));
                map.put("name", rs3.getString("CATEGORY_NAME") != null ? rs3.getString("CATEGORY_NAME") : "Unknown");
                map.put("desc", rs3.getString("DESCRIPTION") != null ? rs3.getString("DESCRIPTION") : "");
                map.put("dept", rs3.getString("DEFAULT_DEPT") != null ? rs3.getString("DEFAULT_DEPT") : "N/A");
                map.put("status", rs3.getString("STATUS") != null ? rs3.getString("STATUS") : "Active");
                map.put("count", rs3.getInt("cmp_count"));
                categories.add(map);
            }
        } catch(Exception e) {
            dbError = "Table 'complaint_categories' does not exist. Please run the CREATE TABLE SQL command in your database first.";
        }

    } catch(Exception e) {
        e.printStackTrace();
        dbError = e.getMessage();
    } finally {
        if(conn != null) try{ conn.close(); } catch(Exception e){}
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Manage Categories - Admin Panel</title>
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

        .admin-card { background-color: white; border-radius: 12px; padding: 24px; border: none; box-shadow: 0 2px 10px rgba(0,0,0,0.02); height: 100%; }
        .card-header-flex { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; flex-wrap: wrap; gap: 15px; }
        .card-title { font-weight: 700; font-size: 18px; margin: 0; color: #0f172a;}

        .stat-box { display: flex; align-items: center; gap: 15px; }
        .stat-icon { width: 55px; height: 55px; border-radius: 12px; display: flex; align-items: center; justify-content: center; font-size: 24px; }
        .stat-details h6 { margin: 0; color: var(--text-muted); font-size: 13px; font-weight: 600;}
        .stat-details h2 { margin: 2px 0; font-weight: 800; font-size: 28px; }
        .bg-blue-soft { background-color: #dbeafe; color: var(--primary-blue); }
        .bg-green-soft { background-color: #dcfce7; color: var(--primary-green); }

        .toolbar { display: flex; gap: 10px; align-items: center; flex-wrap: wrap; }
        .search-box { position: relative; width: 300px; }
        .search-box i { position: absolute; left: 15px; top: 50%; transform: translateY(-50%); color: var(--text-muted); }
        .search-box input { padding-left: 40px; border-radius: 8px; border: 1px solid #e2e8f0; background: #f8fafc; font-size: 14px; box-shadow: none;}
        .search-box input:focus { border-color: var(--primary-blue); background: white; }

        .table { margin-bottom: 0; font-size: 14px; }
        .table th { border-bottom: 2px solid #f1f5f9; color: var(--text-muted); font-weight: 600; padding: 15px 12px; text-transform: uppercase; font-size: 12px; letter-spacing: 0.5px;}
        .table td { vertical-align: middle; padding: 15px 12px; color: #334155; font-weight: 500; border-bottom: 1px solid #f8fafc;}

        .cat-info { display: flex; align-items: center; gap: 12px; }
        .cat-icon-box { width: 40px; height: 40px; border-radius: 8px; display:flex; align-items:center; justify-content:center; font-size:18px; }
        .cat-info div h6 { margin: 0; font-size: 14.5px; font-weight: 600; color: #0f172a;}
        .cat-info div small { color: var(--text-muted); font-size: 12px; }

        .status-badge { padding: 4px 10px; border-radius: 20px; font-size: 11px; font-weight: 600; }
        .badge-active { background-color: #dcfce7; color: #16a34a; }
        .badge-inactive { background-color: #fee2e2; color: #dc2626; }

        .action-btns { display: flex; gap: 8px; }
        .btn-action { background: #f1f5f9; border: none; color: #475569; padding: 6px 12px; border-radius: 6px; transition: 0.2s; font-size: 13px;}
        .btn-action:hover { background: #e2e8f0; color: var(--primary-blue); }
        .btn-danger-soft:hover { background: #fee2e2; color: #dc2626; }

        /* Color Presets for Icons */
        .color-success { background-color: #dcfce7; color: #16a34a; }
        .color-warning { background-color: #ffedd5; color: #ea580c; }
        .color-info { background-color: #dbeafe; color: #2563eb; }
        .color-purple { background-color: #f3e8ff; color: #7c3aed; }
        .color-danger { background-color: #fee2e2; color: #dc2626; }
        .color-dark { background-color: #f1f5f9; color: #475569; }

        /* Modal Customization */
        .modal-content { border-radius: 12px; border: none; box-shadow: 0 10px 30px rgba(0,0,0,0.1); }
        .modal-header { border-bottom: 1px solid #f1f5f9; padding: 20px 25px; }
        .modal-body { padding: 25px; }
        .modal-footer { border-top: 1px solid #f1f5f9; padding: 15px 25px; }
        .form-label { font-weight: 600; font-size: 13px; color: #334155; }
        .modal .form-control, .modal .form-select { border-radius: 8px; background-color: #f8fafc; border-color: #e2e8f0; }
        .modal .form-control:focus, .modal .form-select:focus { background-color: white; border-color: var(--primary-blue); box-shadow: 0 0 0 3px rgba(37,99,235,0.1); }
    </style>
</head>
<body>

<div class="wrapper">

    <aside class="sidebar">
        <div class="logo-container">
            <i class="bi bi-bank2 logo-icon"></i>
            <div class="logo-text">
                <h5>Smart Civic</h5>
                <span>Problem Reporting System</span>
            </div>
        </div>

        <ul class="sidebar-nav">
            <li class="nav-item"><a href="admin-dashboard.jsp" class="nav-link"><i class="bi bi-house-door"></i> Dashboard</a></li>
            <li class="nav-item"><a href="Admin-total-users.jsp" class="nav-link"><i class="bi bi-people"></i> Total Users</a></li>
            <li class="nav-item"><a href="Admin-total-complaints.jsp" class="nav-link"><i class="bi bi-journal-text"></i> Total Complaints</a></li>
            <li class="nav-item"><a href="Admin-pending-complaints.jsp" class="nav-link"><i class="bi bi-hourglass-split"></i> Pending Complaints</a></li>
            <li class="nav-item"><a href="Admin-manage-complaints.jsp" class="nav-link"><i class="bi bi-card-checklist"></i> Manage Complaints</a></li>
            <li class="nav-item"><a href="Admin-update-status.jsp" class="nav-link"><i class="bi bi-arrow-clockwise"></i> Update Status</a></li>
            <li class="nav-item"><a href="Admin-user-management.jsp" class="nav-link"><i class="bi bi-person-gear"></i> User Management</a></li>
            <li class="nav-item"><a href="Admin-complaint-categories.jsp" class="nav-link active"><i class="bi bi-grid"></i> Complaint Categories</a></li>
            <li class="nav-item"><a href="Admin-analytics.jsp" class="nav-link"><i class="bi bi-bar-chart"></i> Analytics</a></li>
            <li class="nav-item"><a href="Admin-reports.jsp" class="nav-link"><i class="bi bi-file-earmark-bar-graph"></i> Reports</a></li>
            <li class="nav-item mt-4"><a href="Admin-settings.jsp" class="nav-link"><i class="bi bi-gear"></i> Settings</a></li>
        </ul>

        <div class="logout-container">
            <a href="../logout.jsp" class="logout-btn">
                <i class="bi bi-box-arrow-right"></i> Logout
            </a>
        </div>
    </aside>

    <main class="main-content">

        <header class="top-header">
            <div class="d-flex align-items-center gap-3">
                <i class="bi bi-list fs-3" style="cursor: pointer;"></i>
                <h4 class="m-0 fw-bold">Complaint Categories</h4>
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

        <!-- SERVER RESPONSE ALERT -->
        <% if (!actionMsg.isEmpty()) { %>
        <div class="alert alert-<%= actionType %> alert-dismissible fade show mb-4" role="alert">
            <i class="bi <%= actionType.equals("success") ? "bi-check-circle-fill" : "bi-exclamation-triangle-fill" %> me-2 fs-5"></i>
            <%= actionMsg %>
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
        <% } %>

        <!-- DATABASE ERROR BANNER -->
        <% if (!dbError.isEmpty()) { %>
        <div class="alert alert-danger shadow-sm border-0 mb-4" role="alert">
            <i class="bi bi-exclamation-triangle-fill me-2 fs-5"></i>
            <strong>Database Error:</strong> <%= dbError %>
        </div>
        <% } %>

        <div class="row g-4 mb-4">
            <div class="col-md-6">
                <div class="admin-card stat-box py-3">
                    <div class="stat-icon bg-blue-soft"><i class="bi bi-grid-fill"></i></div>
                    <div class="stat-details">
                        <h6>Total Active Categories</h6>
                        <h2><%= activeCats %></h2>
                    </div>
                </div>
            </div>
            <div class="col-md-6">
                <div class="admin-card stat-box py-3">
                    <div class="stat-icon bg-green-soft"><i class="bi bi-bar-chart-fill"></i></div>
                    <div class="stat-details">
                        <h6>Most Used Category</h6>
                        <h2><%= mostUsed %></h2>
                    </div>
                </div>
            </div>
        </div>

        <div class="admin-card">
            <div class="card-header-flex">
                <h5 class="card-title">Manage Issue Types</h5>

                <div class="toolbar">
                    <div class="search-box">
                        <i class="bi bi-search"></i>
                        <input type="text" id="searchInput" class="form-control form-control-sm" placeholder="Search categories...">
                    </div>
                    <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#addCategoryModal" style="border-radius: 8px;">
                        <i class="bi bi-plus-lg me-1"></i> Add Category
                    </button>
                </div>
            </div>

            <div class="table-responsive mt-3">
                <table class="table table-hover align-middle">
                    <thead>
                    <tr>
                        <th>Category Name & Desc</th>
                        <th class="text-center">Total Complaints</th>
                        <th class="text-center">Assigned Dept</th>
                        <th class="text-center">Status</th>
                        <th class="text-end">Actions</th>
                    </tr>
                    </thead>
                    <tbody>
                    <%
                        for(Map<String, Object> c : categories) {
                            String name = (String) c.get("name");
                            String nameLower = name.toLowerCase();

                            // Auto-assign UI Icons based on keywords
                            String icon = "bi-grid";
                            String color = "color-dark";

                            if(nameLower.contains("garbage") || nameLower.contains("waste") || nameLower.contains("clean")) { icon = "bi-trash"; color = "color-success"; }
                            else if(nameLower.contains("light") || nameLower.contains("elect")) { icon = "bi-lightbulb"; color = "color-warning"; }
                            else if(nameLower.contains("water") || nameLower.contains("leak") || nameLower.contains("pipe")) { icon = "bi-droplet"; color = "color-info"; }
                            else if(nameLower.contains("road") || nameLower.contains("pothole")) { icon = "bi-cone-striped"; color = "color-purple"; }
                            else if(nameLower.contains("park") || nameLower.contains("tree") || nameLower.contains("garden")) { icon = "bi-tree"; color = "color-danger"; }
                            else if(nameLower.contains("animal") || nameLower.contains("stray")) { icon = "bi-shield-exclamation"; color = "color-dark"; }

                            String status = (String) c.get("status");
                            boolean isActive = status.equalsIgnoreCase("Active");
                            String rowStyle = isActive ? "" : "background-color: #f8fafc;";
                            String opacityStyle = isActive ? "" : "opacity: 0.5;";
                    %>
                    <tr style="<%= rowStyle %>" class="c-row">
                        <td>
                            <div class="cat-info">
                                <div class="cat-icon-box <%= color %>" style="<%= opacityStyle %>"><i class="bi <%= icon %>"></i></div>
                                <div style="<%= opacityStyle %>">
                                    <h6 class="c-name"><%= name %></h6>
                                    <small><%= c.get("desc") %></small>
                                </div>
                            </div>
                        </td>
                        <td class="text-center fw-bold text-dark" style="<%= opacityStyle %>"><%= c.get("count") %></td>
                        <td class="text-center"><span class="text-muted small"><%= c.get("dept") %></span></td>
                        <td class="text-center">
                            <% if(isActive) { %>
                            <span class="status-badge badge-active">Active</span>
                            <% } else { %>
                            <span class="status-badge badge-inactive">Inactive</span>
                            <% } %>
                        </td>
                        <td class="text-end">
                            <div class="action-btns justify-content-end">
                                <button class="btn-action" title="Edit Category" data-bs-toggle="modal" data-bs-target="#addCategoryModal"><i class="bi bi-pencil"></i></button>
                                <% if(isActive) { %>
                                <button class="btn-action btn-danger-soft" title="Deactivate"><i class="bi bi-slash-circle"></i></button>
                                <% } else { %>
                                <button class="btn-action text-success bg-white border" title="Activate"><i class="bi bi-check-circle"></i></button>
                                <% } %>
                            </div>
                        </td>
                    </tr>
                    <% } if(categories.isEmpty() && dbError.isEmpty()) { %>
                    <tr><td colspan="5" class="text-center py-5 text-muted">No Categories found. Please add a new category.</td></tr>
                    <% } %>
                    </tbody>
                </table>
            </div>
        </div>
    </main>
</div>

<!-- Modal ADD CATEGORY -->
<div class="modal fade" id="addCategoryModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title fw-bold">Category Details</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>

            <form method="POST" action="Admin-complaint-categories.jsp" onsubmit="showSpinner()">
                <div class="modal-body">
                    <div class="row g-3">
                        <div class="col-12">
                            <label class="form-label">Category Name</label>
                            <input type="text" name="catName" class="form-control" placeholder="e.g. Broken Sidewalk" required>
                        </div>
                        <div class="col-12">
                            <label class="form-label">Short Description</label>
                            <textarea class="form-control" name="catDesc" rows="2" placeholder="Describe what falls under this category..." required></textarea>
                        </div>
                        <div class="col-md-6">
                            <label class="form-label">Default Department</label>
                            <select name="catDept" class="form-select" required>
                                <option value="" selected disabled>Select Dept</option>
                                <option value="Electrical Dept">Electrical Dept</option>
                                <option value="Water & Sewage">Water & Sewage</option>
                                <option value="Infrastructure">Infrastructure</option>
                                <option value="Sanitation Dept">Sanitation Dept</option>
                                <option value="Horticulture">Horticulture</option>
                                <option value="Animal Control">Animal Control</option>
                            </select>
                        </div>
                        <div class="col-md-6">
                            <label class="form-label">Status</label>
                            <select name="catStatus" class="form-select">
                                <option value="Active" selected>Active</option>
                                <option value="Inactive">Inactive</option>
                            </select>
                        </div>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-light border" data-bs-dismiss="modal">Cancel</button>
                    <button type="submit" class="btn btn-primary" id="saveCatBtn">Save Category</button>
                </div>
            </form>
        </div>
    </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>

<script>
    function showSpinner() {
        const btn = document.getElementById('saveCatBtn');
        btn.innerHTML = '<span class="spinner-border spinner-border-sm" role="status"></span> Saving...';
    }

    // Search bar functionality
    document.getElementById("searchInput").addEventListener("keyup", function() {
        const searchTerm = this.value.toLowerCase();
        const rows = document.querySelectorAll(".c-row");

        rows.forEach(row => {
            const name = row.querySelector(".c-name").textContent.toLowerCase();
            if(name.includes(searchTerm)) {
                row.style.display = "";
            } else {
                row.style.display = "none";
            }
        });
    });
</script>

</body>
</html>