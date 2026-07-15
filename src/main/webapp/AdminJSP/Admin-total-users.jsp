<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="true" %>
<%@ page import="java.util.*, java.net.URLEncoder, java.sql.*, utility.DBConnection, java.text.SimpleDateFormat, java.sql.Clob" %>
<%
    // 1. Security Check (Abhi testing ke liye band rakha hai)
    /* String role = (String) session.getAttribute("role");
    if (role == null || !"Admin".equalsIgnoreCase(role)) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    */

    // 2. Fetch the admin user from the session
    String adminUser = (String) session.getAttribute("user");
    if (adminUser == null) {
        adminUser = "Admin";
    }

    // 3. Fetch DP for Top Header
    String adminDp = (String) session.getAttribute("profileImage");
    String headerAvatar = (adminDp != null && !adminDp.trim().isEmpty())
            ? adminDp
            : "https://ui-avatars.com/api/?name=" + URLEncoder.encode(adminUser, "UTF-8") + "&background=0D8ABC&color=fff";

    // 4. Initialize Data Variables
    int totalUsers = 0;
    int activeCitizens = 0;
    int newThisMonth = 0;
    List<Map<String, String>> userList = new ArrayList<>();

    Connection conn = null;
    PreparedStatement psStats = null;
    ResultSet rsStats = null;
    PreparedStatement psUsers = null;
    ResultSet rsUsers = null;

    try {
        conn = DBConnection.getConnection();

        // 5. Fetch Stats (Total Users, Active Citizens, New This Month)
        String statsSql = "SELECT " +
                "(SELECT COUNT(*) FROM civicuser) as total_u, " +
                "(SELECT COUNT(*) FROM civicuser WHERE ROLE='Citizen' OR ROLE IS NULL) as active_c, " +
                "(SELECT COUNT(*) FROM civicuser WHERE EXTRACT(MONTH FROM CREATED_AT) = EXTRACT(MONTH FROM SYSDATE) AND EXTRACT(YEAR FROM CREATED_AT) = EXTRACT(YEAR FROM SYSDATE)) as new_users " +
                "FROM DUAL";
        psStats = conn.prepareStatement(statsSql);
        rsStats = psStats.executeQuery();
        if (rsStats.next()) {
            totalUsers = rsStats.getInt("total_u");
            activeCitizens = rsStats.getInt("active_c");
            newThisMonth = rsStats.getInt("new_users");
        }

        // 6. Fetch All Users for Table
        String usersSql = "SELECT USER_ID, FULL_NAME, EMAIL, MOBILE, ROLE, CREATED_AT, PROFILE_IMAGE FROM civicuser ORDER BY USER_ID DESC";
        psUsers = conn.prepareStatement(usersSql);
        rsUsers = psUsers.executeQuery();

        SimpleDateFormat sdf = new SimpleDateFormat("dd MMM yyyy");

        while (rsUsers.next()) {
            Map<String, String> userMap = new HashMap<>();
            userMap.put("id", String.valueOf(rsUsers.getInt("USER_ID")));
            userMap.put("name", rsUsers.getString("FULL_NAME") != null ? rsUsers.getString("FULL_NAME") : "Unknown User");
            userMap.put("email", rsUsers.getString("EMAIL") != null ? rsUsers.getString("EMAIL") : "N/A");
            userMap.put("phone", rsUsers.getString("MOBILE") != null ? rsUsers.getString("MOBILE") : "N/A");

            String userRole = rsUsers.getString("ROLE");
            userMap.put("role", (userRole != null && !userRole.trim().isEmpty()) ? userRole : "Citizen");

            // Format Date
            if (rsUsers.getTimestamp("CREATED_AT") != null) {
                userMap.put("joinDate", sdf.format(rsUsers.getTimestamp("CREATED_AT")));
            } else {
                userMap.put("joinDate", "N/A");
            }

            // Handle Profile Image (CLOB to Base64 String)
            Clob clob = rsUsers.getClob("PROFILE_IMAGE");
            if (clob != null && clob.length() > 0) {
                userMap.put("image", clob.getSubString(1, (int) clob.length()));
            } else {
                userMap.put("image", "");
            }

            userList.add(userMap);
        }
    } catch (Exception e) {
        e.printStackTrace();
    } finally {
        // Clean up database resources safely
        try { if (rsUsers != null) rsUsers.close(); } catch (Exception e) {}
        try { if (psUsers != null) psUsers.close(); } catch (Exception e) {}
        try { if (rsStats != null) rsStats.close(); } catch (Exception e) {}
        try { if (psStats != null) psStats.close(); } catch (Exception e) {}
        try { if (conn != null) conn.close(); } catch (Exception e) {}
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Total Users - Admin Panel</title>
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

        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background-color: var(--main-bg);
            color: var(--text-dark);
            margin: 0;
            overflow-x: hidden;
        }

        /* --- Layout --- */
        .wrapper { display: flex; min-height: 100vh; }

        /* --- Sidebar --- */
        .sidebar {
            width: 260px;
            background-color: var(--sidebar-bg);
            color: white;
            padding: 20px 0;
            display: flex;
            flex-direction: column;
            position: fixed;
            height: 100vh;
            overflow-y: auto;
        }

        .logo-container {
            display: flex;
            align-items: center;
            gap: 12px;
            padding: 0 20px 20px 20px;
            border-bottom: 1px solid rgba(255,255,255,0.1);
            margin-bottom: 15px;
        }

        .logo-icon { font-size: 28px; color: white; }
        .logo-text h5 { margin: 0; font-weight: bold; font-size: 18px; }
        .logo-text span { font-size: 11px; color: #94a3b8; }

        .sidebar-nav { list-style: none; padding: 0; margin: 0; flex-grow: 1; }
        .nav-item { margin-bottom: 2px; padding: 0 10px; }

        .nav-link {
            display: flex;
            align-items: center;
            gap: 12px;
            padding: 12px 15px;
            color: #cbd5e1;
            border-radius: 8px;
            text-decoration: none;
            font-weight: 500;
            font-size: 14.5px;
            transition: 0.2s;
        }

        .nav-link:hover { background-color: rgba(255,255,255,0.05); color: white; }
        .nav-link.active { background-color: var(--primary-blue); color: white; }
        .nav-link i { font-size: 18px; width: 24px; text-align: center; }

        .logout-container { padding: 20px; margin-top: auto; }
        .logout-btn {
            display: flex;
            align-items: center;
            gap: 10px;
            border: 1px solid rgba(255,255,255,0.2);
            background: transparent;
            padding: 10px 15px;
            border-radius: 8px;
            color: white;
            text-decoration: none;
            transition: 0.2s;
        }
        .logout-btn:hover { background-color: rgba(255,255,255,0.1); }

        /* --- Main Content --- */
        .main-content {
            flex-grow: 1;
            margin-left: 260px;
            padding: 25px 35px;
            min-height: 100vh;
        }

        .top-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 25px;
        }

        .user-profile { display: flex; align-items: center; gap: 20px; }
        .user-profile img { width: 40px; height: 40px; border-radius: 50%; object-fit: cover; }
        .admin-text h6 { margin: 0; font-weight: bold; font-size: 15px; }
        .admin-text small { color: var(--text-muted); font-size: 12px; }

        /* Cards */
        .admin-card {
            background-color: white;
            border-radius: 12px;
            padding: 24px;
            border: none;
            box-shadow: 0 2px 10px rgba(0,0,0,0.02);
            height: 100%;
        }

        .card-header-flex {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
            flex-wrap: wrap;
            gap: 15px;
        }

        .card-title { font-weight: 700; font-size: 18px; margin: 0; color: #0f172a;}

        /* Stat Boxes */
        .stat-box { display: flex; align-items: center; gap: 15px; }
        .stat-icon {
            width: 55px; height: 55px; border-radius: 12px;
            display: flex; align-items: center; justify-content: center; font-size: 24px;
        }
        .stat-details h6 { margin: 0; color: var(--text-muted); font-size: 13px; font-weight: 600;}
        .stat-details h2 { margin: 2px 0; font-weight: 800; font-size: 28px; }

        .bg-blue-soft { background-color: #dbeafe; color: var(--primary-blue); }
        .bg-green-soft { background-color: #dcfce7; color: var(--primary-green); }
        .bg-orange-soft { background-color: #ffedd5; color: var(--primary-orange); }

        /* Toolbar */
        .toolbar { display: flex; gap: 15px; align-items: center; }
        .search-box { position: relative; width: 300px; }
        .search-box i { position: absolute; left: 15px; top: 50%; transform: translateY(-50%); color: var(--text-muted); }
        .search-box input { padding-left: 40px; border-radius: 8px; border: 1px solid #e2e8f0; background: #f8fafc; font-size: 14px; box-shadow: none;}
        .search-box input:focus { border-color: var(--primary-blue); background: white; }

        .filter-select { border-radius: 8px; border: 1px solid #e2e8f0; background: #f8fafc; font-size: 14px; padding: 8px 15px; color: #475569;}

        /* Tables & Badges */
        .table { margin-bottom: 0; font-size: 14px; }
        .table th { border-bottom: 2px solid #f1f5f9; color: var(--text-muted); font-weight: 600; padding: 15px 12px; text-transform: uppercase; font-size: 12px; letter-spacing: 0.5px;}
        .table td { vertical-align: middle; padding: 15px 12px; color: #334155; font-weight: 500; border-bottom: 1px solid #f8fafc;}

        .user-info { display: flex; align-items: center; gap: 12px; }
        .user-info img { width: 35px; height: 35px; border-radius: 50%; object-fit: cover;}
        .user-info div h6 { margin: 0; font-size: 14px; font-weight: 600; color: #0f172a;}
        .user-info div small { color: var(--text-muted); font-size: 12px; }

        .status-badge { padding: 5px 12px; border-radius: 6px; font-size: 11.5px; font-weight: 600; }
        .badge-active { background-color: #dcfce7; color: #16a34a; }
        .badge-inactive { background-color: #f1f5f9; color: #64748b; }
        .badge-banned { background-color: #fee2e2; color: #dc2626; }

        .role-badge { padding: 4px 10px; border-radius: 4px; font-size: 11px; font-weight: 600; border: 1px solid;}
        .role-citizen { background-color: #f8fafc; border-color: #cbd5e1; color: #475569; }
        .role-technician { background-color: #eff6ff; border-color: #bfdbfe; color: #2563eb; }
        .role-admin { background-color: #fef2f2; border-color: #fecaca; color: #dc2626; }

        .action-btns { display: flex; gap: 8px; }
        .btn-action { background: #f1f5f9; border: none; color: #475569; padding: 6px 12px; border-radius: 6px; transition: 0.2s; font-size: 13px; text-decoration: none; display: inline-block;}
        .btn-action:hover { background: #e2e8f0; color: var(--primary-blue); }
        .btn-delete:hover { background: #fee2e2; color: #dc2626; }

        /* Pagination */
        .pagination { margin: 0; }
        .page-link { border: none; color: #475569; font-size: 14px; font-weight: 500; border-radius: 6px; margin: 0 2px;}
        .page-item.active .page-link { background-color: var(--primary-blue); color: white; }

        /* Row hiding class for filters */
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
            <li class="nav-item"><a href="Admin-total-users.jsp" class="nav-link active"><i class="bi bi-people"></i> Total Users</a></li>
            <li class="nav-item"><a href="Admin-total-complaints.jsp" class="nav-link"><i class="bi bi-journal-text"></i> Total Complaints</a></li>
            <li class="nav-item"><a href="Admin-pending-complaints.jsp" class="nav-link"><i class="bi bi-hourglass-split"></i> Pending Complaints</a></li>
            <li class="nav-item"><a href="Admin-manage-complaints.jsp" class="nav-link"><i class="bi bi-card-checklist"></i> Manage Complaints</a></li>
            <li class="nav-item"><a href="Admin-update-status.jsp" class="nav-link"><i class="bi bi-arrow-clockwise"></i> Update Status</a></li>
            <li class="nav-item"><a href="Admin-user-management.jsp" class="nav-link"><i class="bi bi-person-gear"></i> User Management</a></li>
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
                <h4 class="m-0 fw-bold">User Directory</h4>
            </div>

            <div class="user-profile">
                <div class="position-relative">
                    <i class="bi bi-bell fs-5 text-muted"></i>
                    <span class="position-absolute top-0 start-100 translate-middle badge rounded-pill bg-danger" style="font-size: 9px;">8</span>
                </div>
                <div class="d-flex align-items-center gap-2">
                    <img src="<%= headerAvatar %>" alt="<%= adminUser %>">
                    <div class="admin-text d-none d-md-block">
                        <h6><%= adminUser %></h6>
                        <small>Administrator</small>
                    </div>
                </div>
            </div>
        </header>

        <div class="row g-4 mb-4">
            <div class="col-md-4">
                <div class="admin-card stat-box py-3">
                    <div class="stat-icon bg-blue-soft"><i class="bi bi-people-fill"></i></div>
                    <div class="stat-details">
                        <h6>Total Registered Users</h6>
                        <h2 id="displayTotalUsers"><%= totalUsers %></h2>
                    </div>
                </div>
            </div>
            <div class="col-md-4">
                <div class="admin-card stat-box py-3">
                    <div class="stat-icon bg-green-soft"><i class="bi bi-person-check-fill"></i></div>
                    <div class="stat-details">
                        <h6>Active Citizens</h6>
                        <h2><%= activeCitizens %></h2>
                    </div>
                </div>
            </div>
            <div class="col-md-4">
                <div class="admin-card stat-box py-3">
                    <div class="stat-icon bg-orange-soft"><i class="bi bi-person-plus-fill"></i></div>
                    <div class="stat-details">
                        <h6>New This Month</h6>
                        <h2>+<%= newThisMonth %></h2>
                    </div>
                </div>
            </div>
        </div>

        <div class="admin-card">
            <div class="card-header-flex">
                <h5 class="card-title">Manage Users</h5>

                <div class="toolbar">
                    <div class="search-box">
                        <i class="bi bi-search"></i>
                        <input type="text" id="searchInput" class="form-control form-control-sm" placeholder="Search by name, email or ID...">
                    </div>
                    <select id="roleFilter" class="form-select filter-select w-auto">
                        <option value="all">All Roles</option>
                        <option value="citizen">Citizen</option>
                        <option value="technician">Technician</option>
                        <option value="admin">Admin</option>
                    </select>
                    <select id="statusFilter" class="form-select filter-select w-auto">
                        <option value="all">All Status</option>
                        <option value="active">Active</option>
                        <option value="inactive">Inactive</option>
                        <option value="banned">Banned</option>
                    </select>
                    <button class="btn btn-primary" style="border-radius: 8px;"><i class="bi bi-download me-2"></i>Export</button>
                </div>
            </div>

            <div class="table-responsive mt-3">
                <table class="table table-hover align-middle" id="usersTable">
                    <thead>
                    <tr>
                        <th>User Details</th>
                        <th>Contact Info</th>
                        <th>Role</th>
                        <th>Join Date</th>
                        <th>Status</th>
                        <th>Actions</th>
                    </tr>
                    </thead>
                    <tbody>
                    <%
                        if(userList != null && !userList.isEmpty()) {
                            for(Map<String, String> u : userList) {
                                String uName = u.get("name") != null ? u.get("name") : "User";
                                String uEmail = u.get("email") != null ? u.get("email") : "N/A";
                                String uPhone = u.get("phone") != null ? u.get("phone") : "N/A";
                                String uId = u.get("id");
                                String uRole = u.get("role") != null ? u.get("role") : "Citizen";
                                String uJoinDate = u.get("joinDate");
                                String uImg = u.get("image");

                                // Dynamic Role Badge CSS
                                String roleClass = "role-citizen";
                                if(uRole.equalsIgnoreCase("Admin")) {
                                    roleClass = "role-admin";
                                } else if(uRole.equalsIgnoreCase("Technician")) {
                                    roleClass = "role-technician";
                                }

                                // For demonstration, we will assume all users in DB are "Active" for now.
                                String userStatus = "Active";
                                String statusBadge = "badge-active";

                                // Dynamic Image Fallback
                                String dpSrc = (uImg != null && !uImg.trim().isEmpty())
                                        ? uImg
                                        : "https://ui-avatars.com/api/?name=" + URLEncoder.encode(uName, "UTF-8") + "&background=random";
                    %>
                    <tr class="user-row" data-role="<%= uRole.toLowerCase() %>" data-status="<%= userStatus.toLowerCase() %>">
                        <td>
                            <div class="user-info">
                                <img src="<%= dpSrc %>" alt="<%= uName %>">
                                <div>
                                    <h6 class="user-name"><%= uName %></h6>
                                    <small class="user-id">ID: #USR-<%= uId %></small>
                                </div>
                            </div>
                        </td>
                        <td>
                            <div class="text-dark user-email"><%= uEmail %></div>
                            <small class="text-muted"><%= uPhone %></small>
                        </td>
                        <td><span class="role-badge <%= roleClass %>"><%= uRole %></span></td>
                        <td><%= uJoinDate %></td>
                        <td><span class="status-badge <%= statusBadge %>"><%= userStatus %></span></td>
                        <td>
                            <div class="action-btns">
                                <a href="Admin-user-edit.jsp?id=<%= uId %>" class="btn-action text-decoration-none" title="View/Edit Profile">
                                    <i class="bi bi-pencil-square"></i>
                                </a>

                                <a href="Admin-user-activity.jsp?id=<%= uId %>" class="btn-action text-decoration-none" title="View Complaints/Activity">
                                    <i class="bi bi-card-list"></i>
                                </a>

                                <% if(uRole.equalsIgnoreCase("Admin")) { %>
                                <a href="javascript:void(0);" class="btn-action text-decoration-none" style="opacity: 0.5; cursor: not-allowed;" title="Cannot Suspend Admin">
                                    <i class="bi bi-slash-circle"></i>
                                </a>
                                <% } else { %>
                                <a href="Admin-user-suspend.jsp?id=<%= uId %>" class="btn-action btn-delete text-decoration-none" title="Suspend User" onclick="return confirm('Are you sure you want to suspend <%= uName %>?');">
                                    <i class="bi bi-slash-circle"></i>
                                </a>
                                <% } %>
                            </div>
                        </td>
                    </tr>
                    <%
                        } // End For Loop
                    } else {
                    %>
                    <tr id="noDataRow"><td colspan="6" class="text-center py-5 text-muted">
                        <i class="bi bi-database-x fs-2 d-block mb-2 text-secondary"></i>
                        No users found in the database.
                    </td></tr>
                    <% } %>
                    </tbody>
                </table>
            </div>

            <div class="d-flex justify-content-between align-items-center mt-4 border-top pt-3">
                <span class="text-muted" style="font-size: 14px;" id="showingText">Showing <%= userList.size() %> users</span>
                <nav>
                    <ul class="pagination pagination-sm">
                        <li class="page-item disabled"><a class="page-link" href="#">Previous</a></li>
                        <li class="page-item active"><a class="page-link" href="#">1</a></li>
                        <li class="page-item"><a class="page-link" href="#">Next</a></li>
                    </ul>
                </nav>
            </div>

        </div>

    </main>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>

<script>
    document.addEventListener("DOMContentLoaded", function() {
        const searchInput = document.getElementById("searchInput");
        const roleFilter = document.getElementById("roleFilter");
        const statusFilter = document.getElementById("statusFilter");
        const userRows = document.querySelectorAll(".user-row");
        const showingText = document.getElementById("showingText");

        function filterTable() {
            const searchTerm = searchInput.value.toLowerCase();
            const selectedRole = roleFilter.value.toLowerCase();
            const selectedStatus = statusFilter.value.toLowerCase();
            let visibleCount = 0;

            userRows.forEach(row => {
                const name = row.querySelector(".user-name").textContent.toLowerCase();
                const email = row.querySelector(".user-email").textContent.toLowerCase();
                const id = row.querySelector(".user-id").textContent.toLowerCase();
                const role = row.getAttribute("data-role");
                const status = row.getAttribute("data-status");

                // Check matches
                const matchesSearch = name.includes(searchTerm) || email.includes(searchTerm) || id.includes(searchTerm);
                const matchesRole = (selectedRole === "all" || role === selectedRole);
                const matchesStatus = (selectedStatus === "all" || status === selectedStatus);

                if (matchesSearch && matchesRole && matchesStatus) {
                    row.classList.remove("hidden-row");
                    visibleCount++;
                } else {
                    row.classList.add("hidden-row");
                }
            });

            // Update text at the bottom
            showingText.textContent = `Showing ${visibleCount} users based on filters`;
        }

        // Attach Event Listeners to Inputs
        searchInput.addEventListener("keyup", filterTable);
        roleFilter.addEventListener("change", filterTable);
        statusFilter.addEventListener("change", filterTable);
    });
</script>

</body>
</html>