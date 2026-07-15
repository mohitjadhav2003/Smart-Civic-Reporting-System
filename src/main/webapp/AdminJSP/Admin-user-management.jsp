<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="true" %>
<%@ page import="java.util.*, java.sql.*, utility.DBConnection, java.text.SimpleDateFormat" %>
<%
    // Fetch the admin user from the session
    String adminUser = (String) session.getAttribute("adminUser");
    if (adminUser == null) {
        adminUser = "Admin";
    }

    // --- ADD NEW USER LOGIC (POST REQUEST) ---
    String actionMsg = "";
    String actionType = ""; // "success" or "danger"

    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String fName = request.getParameter("fullName");
        String fEmail = request.getParameter("email");
        String fMobile = request.getParameter("mobile");
        String fRoleRaw = request.getParameter("roleSelect");
        String fPass = request.getParameter("password");
        String fDept = request.getParameter("department");

        String dbRole = "Citizen";
        if ("admin".equals(fRoleRaw)) dbRole = "Admin";
        else if ("tech".equals(fRoleRaw)) dbRole = "Technician";

        // Assign department only to Technician
        String dbDept = ("tech".equals(fRoleRaw) && fDept != null) ? fDept : "N/A";

        Connection postConn = null;
        PreparedStatement psId = null;
        ResultSet rsId = null;
        PreparedStatement psInsert = null;

        try {
            postConn = DBConnection.getConnection();

            // Auto-Generate new USER_ID (Max ID + 1)
            psId = postConn.prepareStatement("SELECT NVL(MAX(USER_ID), 0) + 1 FROM civicuser");
            rsId = psId.executeQuery();
            int nextId = 1;
            if(rsId.next()) nextId = rsId.getInt(1);

            // Insert Query based on your table structure
            String insertSql = "INSERT INTO civicuser (USER_ID, FULL_NAME, EMAIL, MOBILE, USER_PASSWORD, ROLE, DEPARTMENT, CREATED_AT) VALUES (?, ?, ?, ?, ?, ?, ?, SYSDATE)";
            psInsert = postConn.prepareStatement(insertSql);
            psInsert.setInt(1, nextId);
            psInsert.setString(2, fName);
            psInsert.setString(3, fEmail);
            psInsert.setString(4, fMobile);
            psInsert.setString(5, fPass);
            psInsert.setString(6, dbRole);
            psInsert.setString(7, dbDept);

            int rows = psInsert.executeUpdate();
            if (rows > 0) {
                actionMsg = "User account created and saved to database successfully!";
                actionType = "success";
            } else {
                actionMsg = "Failed to create user account.";
                actionType = "danger";
            }
        } catch(Exception ex) {
            actionMsg = "Database Error: " + ex.getMessage();
            actionType = "danger";
        } finally {
            if(rsId != null) try{ rsId.close(); } catch(Exception e){}
            if(psId != null) try{ psId.close(); } catch(Exception e){}
            if(psInsert != null) try{ psInsert.close(); } catch(Exception e){}
            if(postConn != null) try{ postConn.close(); } catch(Exception e){}
        }
    }
    // --- END ADD NEW USER LOGIC ---

    // Dynamic Variables for Stats & Display
    int totalAccounts = 0, adminCount = 0, techCount = 0, suspendedCount = 0;
    List<Map<String, String>> usersList = new ArrayList<>();
    String dbError = "";

    Connection conn = null;
    try {
        conn = DBConnection.getConnection();

        // 1. Fetch Stats dynamically
        String statSql = "SELECT COUNT(*) as t, " +
                "SUM(CASE WHEN ROLE='Admin' THEN 1 ELSE 0 END) as a, " +
                "SUM(CASE WHEN ROLE='Technician' THEN 1 ELSE 0 END) as te " +
                "FROM civicuser";
        ResultSet rsStat = conn.createStatement().executeQuery(statSql);
        if(rsStat.next()){
            totalAccounts = rsStat.getInt("t");
            adminCount = rsStat.getInt("a");
            techCount = rsStat.getInt("te");
            suspendedCount = 0; // Keeping 0 because STATUS column is missing in DB
        }

        // 2. Fetch User Directory Data
        String uSql = "SELECT USER_ID, FULL_NAME, EMAIL, ROLE, DEPARTMENT, CREATED_AT FROM civicuser ORDER BY USER_ID DESC";
        ResultSet rs = conn.createStatement().executeQuery(uSql);
        SimpleDateFormat sdf = new SimpleDateFormat("dd MMM yyyy");

        while(rs.next()) {
            Map<String, String> m = new HashMap<>();
            m.put("id", rs.getString("USER_ID"));

            String name = rs.getString("FULL_NAME");
            m.put("name", name != null ? name : "Unknown User");
            m.put("email", rs.getString("EMAIL") != null ? rs.getString("EMAIL") : "N/A");

            String role = rs.getString("ROLE");
            m.put("role", (role != null && !role.trim().isEmpty()) ? role : "Citizen");

            String dept = rs.getString("DEPARTMENT");
            m.put("dept", (dept != null && !dept.trim().isEmpty()) ? dept : "N/A");

            m.put("status", "Active");

            // Using CREATED_AT for the date column
            m.put("date", rs.getTimestamp("CREATED_AT") != null ? sdf.format(rs.getTimestamp("CREATED_AT")) : "N/A");

            // Calculate initials for Avatar
            String initials = "U";
            if(name != null && !name.trim().isEmpty()){
                String[] parts = name.trim().split("\\s+");
                initials = parts[0].substring(0, 1).toUpperCase();
                if(parts.length > 1) {
                    initials += parts[1].substring(0, 1).toUpperCase();
                }
            }
            m.put("initials", initials);

            usersList.add(m);
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
    <title>User Management - Admin Panel</title>
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
        .bg-purple-soft { background-color: #f3e8ff; color: var(--primary-purple); }
        .bg-dark-soft { background-color: #f1f5f9; color: #475569; }
        .toolbar { display: flex; gap: 10px; align-items: center; flex-wrap: wrap; }
        .search-box { position: relative; width: 300px; }
        .search-box i { position: absolute; left: 15px; top: 50%; transform: translateY(-50%); color: var(--text-muted); }
        .search-box input { padding-left: 40px; border-radius: 8px; border: 1px solid #e2e8f0; background: #f8fafc; font-size: 14px; box-shadow: none;}
        .search-box input:focus { border-color: var(--primary-blue); background: white; }
        .filter-select { border-radius: 8px; border: 1px solid #e2e8f0; background: #f8fafc; font-size: 14px; padding: 8px 30px 8px 15px; color: #475569;}
        .table { margin-bottom: 0; font-size: 14px; }
        .table th { border-bottom: 2px solid #f1f5f9; color: var(--text-muted); font-weight: 600; padding: 15px 12px; text-transform: uppercase; font-size: 12px; letter-spacing: 0.5px;}
        .table td { vertical-align: middle; padding: 15px 12px; color: #334155; font-weight: 500; border-bottom: 1px solid #f8fafc;}
        .user-info { display: flex; align-items: center; gap: 12px; }
        .user-info-icon { width: 38px; height: 38px; border-radius: 50%; display:flex; align-items:center; justify-content:center; color:white; font-weight:bold; font-size:14px; }
        .user-info div h6 { margin: 0; font-size: 14.5px; font-weight: 600; color: #0f172a;}
        .user-info div small { color: var(--text-muted); font-size: 12px; }
        .role-badge { padding: 4px 10px; border-radius: 6px; font-size: 11.5px; font-weight: 600; display: inline-flex; align-items: center; gap: 5px;}
        .role-admin { background-color: #fef2f2; color: #dc2626; border: 1px solid #fecaca;}
        .role-tech { background-color: #eff6ff; color: #2563eb; border: 1px solid #bfdbfe;}
        .role-citizen { background-color: #f8fafc; color: #475569; border: 1px solid #e2e8f0;}
        .status-badge { padding: 4px 10px; border-radius: 20px; font-size: 11px; font-weight: 600; }
        .badge-active { background-color: #dcfce7; color: #16a34a; }
        .badge-banned { background-color: #fee2e2; color: #dc2626; }
        .action-btns { display: flex; gap: 8px; }
        .btn-action { background: #f1f5f9; border: none; color: #475569; padding: 6px 12px; border-radius: 6px; transition: 0.2s; font-size: 13px;}
        .btn-action:hover { background: #e2e8f0; color: var(--primary-blue); }
        .btn-danger-soft:hover { background: #fee2e2; color: #dc2626; }
        .btn-warning-soft:hover { background: #ffedd5; color: #ea580c; }
        .modal-content { border-radius: 12px; border: none; box-shadow: 0 10px 30px rgba(0,0,0,0.1); }
        .modal-header { border-bottom: 1px solid #f1f5f9; padding: 20px 25px; }
        .modal-body { padding: 25px; }
        .modal-footer { border-top: 1px solid #f1f5f9; padding: 15px 25px; }
        .form-label { font-weight: 600; font-size: 13px; color: #334155; }
        .modal .form-control, .modal .form-select { border-radius: 8px; background-color: #f8fafc; border-color: #e2e8f0; }
        .modal .form-control:focus, .modal .form-select:focus { background-color: white; border-color: var(--primary-blue); box-shadow: 0 0 0 3px rgba(37,99,235,0.1); }
        .hidden-row { display: none !important; }
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
            <li class="nav-item"><a href="Admin-user-management.jsp" class="nav-link active"><i class="bi bi-person-gear"></i> User Management</a></li>
            <li class="nav-item"><a href="Admin-complaint-categories.jsp" class="nav-link"><i class="bi bi-grid"></i> Complaint Categories</a></li>
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
                <h4 class="m-0 fw-bold">System Access & Roles</h4>
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

        <% if (!actionMsg.isEmpty()) { %>
        <div class="alert alert-<%= actionType %> alert-dismissible fade show mb-4" role="alert">
            <i class="bi <%= actionType.equals("success") ? "bi-check-circle-fill" : "bi-exclamation-triangle-fill" %> me-2 fs-5"></i>
            <%= actionMsg %>
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
        <% } %>

        <% if (!dbError.isEmpty()) { %>
        <div class="alert alert-danger shadow-sm border-0 mb-4" role="alert">
            <i class="bi bi-exclamation-triangle-fill me-2 fs-5"></i>
            <strong>Database Error:</strong> <%= dbError %>
        </div>
        <% } %>

        <div class="row g-4 mb-4">
            <div class="col-xl-3 col-md-6">
                <div class="admin-card stat-box py-3">
                    <div class="stat-icon bg-blue-soft"><i class="bi bi-person-badge"></i></div>
                    <div class="stat-details">
                        <h6>Total Accounts</h6>
                        <h2><%= totalAccounts %></h2>
                    </div>
                </div>
            </div>
            <div class="col-xl-3 col-md-6">
                <div class="admin-card stat-box py-3">
                    <div class="stat-icon bg-purple-soft"><i class="bi bi-shield-lock"></i></div>
                    <div class="stat-details">
                        <h6>Administrators</h6>
                        <h2><%= adminCount %></h2>
                    </div>
                </div>
            </div>
            <div class="col-xl-3 col-md-6">
                <div class="admin-card stat-box py-3">
                    <div class="stat-icon bg-green-soft"><i class="bi bi-tools"></i></div>
                    <div class="stat-details">
                        <h6>Field Technicians</h6>
                        <h2><%= techCount %></h2>
                    </div>
                </div>
            </div>
            <div class="col-xl-3 col-md-6">
                <div class="admin-card stat-box py-3">
                    <div class="stat-icon bg-dark-soft"><i class="bi bi-person-slash"></i></div>
                    <div class="stat-details">
                        <h6>Suspended Users</h6>
                        <h2><%= suspendedCount %></h2>
                    </div>
                </div>
            </div>
        </div>

        <div class="admin-card">
            <div class="card-header-flex">
                <h5 class="card-title">User Accounts</h5>

                <div class="toolbar">
                    <div class="search-box">
                        <i class="bi bi-search"></i>
                        <input type="text" id="searchInput" class="form-control form-control-sm" placeholder="Search user or email...">
                    </div>
                    <select id="roleFilter" class="form-select filter-select w-auto">
                        <option value="all">All Roles</option>
                        <option value="admin">Administrator</option>
                        <option value="technician">Technician</option>
                        <option value="citizen">Citizen</option>
                    </select>
                    <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#addUserModal" style="border-radius: 8px;">
                        <i class="bi bi-person-plus me-1"></i> Add User
                    </button>
                </div>
            </div>

            <div class="table-responsive mt-3">
                <table class="table table-hover align-middle" id="userTable">
                    <thead>
                    <tr>
                        <th>User Name</th>
                        <th>Role & Access</th>
                        <th>Department</th>
                        <th>Last Login / Date Joined</th>
                        <th>Status</th>
                        <th class="text-end">Actions</th>
                    </tr>
                    </thead>
                    <tbody>
                    <%
                        for(Map<String, String> u : usersList) {
                            String r = u.get("role");
                            String s = u.get("status");
                            String styleBanned = s.equalsIgnoreCase("Banned") ? "style=\"background-color: #fef2f2;\"" : "";
                    %>
                    <tr class="u-row" data-role="<%= r.toLowerCase() %>" <%= styleBanned %>>
                        <td>
                            <div class="user-info">
                                <% if(r.equalsIgnoreCase("Admin")) { %>
                                <div class="user-info-icon" style="background-color: #7c3aed;"><%= u.get("initials") %></div>
                                <% } else if (r.equalsIgnoreCase("Technician")) { %>
                                <div class="user-info-icon" style="background-color: #2563eb;"><%= u.get("initials") %></div>
                                <% } else { %>
                                <img src="https://ui-avatars.com/api/?name=<%= java.net.URLEncoder.encode(u.get("name"), "UTF-8") %>&background=random" alt="<%= u.get("name") %>">
                                <% } %>
                                <div>
                                    <h6 class="u-name"><%= u.get("name") %></h6>
                                    <small class="u-email"><%= u.get("email") %></small>
                                </div>
                            </div>
                        </td>

                        <td>
                            <% if(r.equalsIgnoreCase("Admin")) { %>
                            <span class="role-badge role-admin"><i class="bi bi-shield-check"></i> Administrator</span>
                            <% } else if (r.equalsIgnoreCase("Technician")) { %>
                            <span class="role-badge role-tech"><i class="bi bi-tools"></i> Technician</span>
                            <% } else { %>
                            <span class="role-badge role-citizen"><i class="bi bi-person"></i> Citizen</span>
                            <% } %>
                        </td>

                        <td>
                            <% if(r.equalsIgnoreCase("Admin")) { %>
                            <span class="text-muted small"><%= u.get("dept") %></span>
                            <% } else if (r.equalsIgnoreCase("Technician")) { %>
                            <span class="text-dark fw-medium" style="font-size:13px;"><%= u.get("dept") %></span>
                            <% } else { %>
                            <span class="text-muted small">N/A</span>
                            <% } %>
                        </td>

                        <td><small class="text-muted"><%= u.get("date") %></small></td>

                        <td>
                            <% if(s.equalsIgnoreCase("Banned")) { %>
                            <span class="status-badge badge-banned">Banned</span>
                            <% } else { %>
                            <span class="status-badge badge-active">Active</span>
                            <% } %>
                        </td>

                        <td class="text-end">
                            <div class="action-btns justify-content-end">
                                <% if(r.equalsIgnoreCase("Admin")) { %>
                                <button class="btn-action" title="Edit Permissions"><i class="bi bi-pencil"></i></button>
                                <button class="btn-action" disabled style="opacity:0.4"><i class="bi bi-trash"></i></button>
                                <% } else if (r.equalsIgnoreCase("Technician")) { %>
                                <button class="btn-action" title="Edit Profile"><i class="bi bi-pencil"></i></button>
                                <button class="btn-action btn-warning-soft" title="Reset Password"><i class="bi bi-key"></i></button>
                                <% if(s.equalsIgnoreCase("Banned")) { %>
                                <button class="btn-action text-success bg-white border" title="Unban User"><i class="bi bi-check-circle me-1"></i> Unban</button>
                                <% } else { %>
                                <button class="btn-action btn-danger-soft" title="Suspend"><i class="bi bi-slash-circle"></i></button>
                                <% } %>
                                <% } else { %>
                                <button class="btn-action" title="View Activity"><i class="bi bi-eye"></i></button>
                                <% if(s.equalsIgnoreCase("Banned")) { %>
                                <button class="btn-action text-success bg-white border" title="Unban User"><i class="bi bi-check-circle me-1"></i> Unban</button>
                                <% } else { %>
                                <button class="btn-action btn-danger-soft" title="Ban Account"><i class="bi bi-slash-circle"></i></button>
                                <% } %>
                                <% } %>
                            </div>
                        </td>
                    </tr>
                    <% } if(usersList.isEmpty() && dbError.isEmpty()) { %>
                    <tr><td colspan="6" class="text-center py-5 text-muted">No users found in database.</td></tr>
                    <% } %>
                    </tbody>
                </table>
            </div>

            <div class="d-flex justify-content-between align-items-center mt-4 border-top pt-3">
                <span class="text-muted" style="font-size: 14px;">Showing total <%= usersList.size() %> users</span>
                <nav>
                    <ul class="pagination pagination-sm">
                        <li class="page-item disabled"><a class="page-link" href="#">Previous</a></li>
                        <li class="page-item active"><a class="page-link" href="#">1</a></li>
                        <li class="page-item"><a class="page-link" href="#">2</a></li>
                        <li class="page-item"><a class="page-link" href="#">3</a></li>
                        <li class="page-item"><a class="page-link" href="#">Next</a></li>
                    </ul>
                </nav>
            </div>

        </div>
    </main>
</div>

<div class="modal fade" id="addUserModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title fw-bold">Add New System User</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>

            <form method="POST" action="Admin-user-management.jsp">
                <div class="modal-body">
                    <div class="row g-3">
                        <div class="col-12">
                            <label class="form-label">Full Name <span class="text-danger">*</span></label>
                            <input type="text" class="form-control" name="fullName" placeholder="e.g. John Doe" required>
                        </div>

                        <div class="col-md-6">
                            <label class="form-label">Email Address <span class="text-danger">*</span></label>
                            <input type="email" class="form-control" name="email" placeholder="john@staff.gov" required>
                        </div>
                        <div class="col-md-6">
                            <label class="form-label">Mobile Number <span class="text-danger">*</span></label>
                            <input type="text" class="form-control" name="mobile" placeholder="e.g. 9876543210" required>
                        </div>

                        <div class="col-md-6">
                            <label class="form-label">System Role <span class="text-danger">*</span></label>
                            <select class="form-select" name="roleSelect" id="roleSelect" onchange="toggleDepartment()" required>
                                <option value="" selected disabled>Select Role</option>
                                <option value="admin">Administrator</option>
                                <option value="tech">Field Technician</option>
                            </select>
                        </div>
                        <div class="col-md-6">
                            <label class="form-label">Temporary Password <span class="text-danger">*</span></label>
                            <input type="text" class="form-control" name="password" value="Welcome123!" required>
                        </div>
                        <div class="col-12 d-none" id="departmentDiv">
                            <label class="form-label">Assigned Department</label>
                            <select class="form-select" name="department">
                                <option value="Electrical Dept">Electrical / Street Lights</option>
                                <option value="Water & Sewage">Water & Sewage</option>
                                <option value="Roads & Infrastructure">Roads & Infrastructure</option>
                                <option value="Garbage & Sanitation">Garbage & Sanitation</option>
                            </select>
                        </div>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-light border" data-bs-dismiss="modal">Cancel</button>
                    <button type="submit" class="btn btn-primary">Create Account</button>
                </div>
            </form>
        </div>
    </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>

<script>
    // JS for Search and Filter without reloading page
    document.addEventListener("DOMContentLoaded", function() {
        const searchInput = document.getElementById("searchInput");
        const roleFilter = document.getElementById("roleFilter");
        const rows = document.querySelectorAll(".u-row");

        function applyFilters() {
            const searchTerm = searchInput.value.toLowerCase();
            const filterVal = roleFilter.value.toLowerCase();

            rows.forEach(row => {
                const name = row.querySelector(".u-name").textContent.toLowerCase();
                const email = row.querySelector(".u-email").textContent.toLowerCase();
                const role = row.getAttribute("data-role");

                const matchesSearch = name.includes(searchTerm) || email.includes(searchTerm);
                const matchesRole = filterVal === "all" || role === filterVal;

                if(matchesSearch && matchesRole) {
                    row.classList.remove("hidden-row");
                } else {
                    row.classList.add("hidden-row");
                }
            });
        }

        searchInput.addEventListener("keyup", applyFilters);
        roleFilter.addEventListener("change", applyFilters);
    });

    // Logic to show/hide "Department" dropdown based on Role selection
    function toggleDepartment() {
        const role = document.getElementById('roleSelect').value;
        const deptDiv = document.getElementById('departmentDiv');
        if(role === 'tech') {
            deptDiv.classList.remove('d-none');
            // deptDiv.querySelector('select').setAttribute('required', 'true');
        } else {
            deptDiv.classList.add('d-none');
            // deptDiv.querySelector('select').removeAttribute('required');
        }
    }
</script>

</body>
</html>