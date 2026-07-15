<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="true" %>
<%@ page import="java.sql.*, utility.DBConnection, java.util.*, java.text.*" %>
<%
    // 1. Session & Security Check
    String adminUser = (String) session.getAttribute("user");
    String role = (String) session.getAttribute("role");

    if (adminUser == null) {
        adminUser = "Admin";
    }

    // Admin Profile DP
    String dpBase64 = (String) session.getAttribute("profileImage");
    String headerAvatar = (dpBase64 != null && !dpBase64.trim().isEmpty())
            ? dpBase64
            : "https://ui-avatars.com/api/?name=" + java.net.URLEncoder.encode(adminUser, "UTF-8") + "&background=0D8ABC&color=fff";

    // 2. Dynamic Variables Initialization
    int totalUsers = 0, totalComp = 0, pendingComp = 0, inProgComp = 0, resolvedComp = 0;

    // Data structures to hold table data
    List<Map<String, String>> recentComplaints = new ArrayList<>();
    List<Map<String, String>> topCitizens = new ArrayList<>();
    Map<String, Integer> categoryCounts = new HashMap<>();

    // NEW: Data structures for Monthly Trend Chart
    List<String> trendMonths = new ArrayList<>();
    List<Integer> trendCounts = new ArrayList<>();

    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;

    try {
        conn = DBConnection.getConnection();

        // A. Fetch Overall Statistics
        String statsSql = "SELECT " +
                "(SELECT COUNT(*) FROM civicuser WHERE ROLE='Citizen') as t_users, " +
                "(SELECT COUNT(*) FROM complaints) as t_comp, " +
                "(SELECT COUNT(*) FROM complaints WHERE STATUS='Pending') as p_comp, " +
                "(SELECT COUNT(*) FROM complaints WHERE STATUS='In Progress') as i_comp, " +
                "(SELECT COUNT(*) FROM complaints WHERE STATUS='Resolved') as r_comp FROM DUAL";
        pstmt = conn.prepareStatement(statsSql);
        rs = pstmt.executeQuery();
        if(rs.next()){
            totalUsers = rs.getInt("t_users");
            totalComp = rs.getInt("t_comp");
            pendingComp = rs.getInt("p_comp");
            inProgComp = rs.getInt("i_comp");
            resolvedComp = rs.getInt("r_comp");
        }
        rs.close(); pstmt.close();

        // B. Fetch Recent 5 Complaints
        String recentSql = "SELECT * FROM (SELECT c.COMPLAINT_ID, c.PROBLEM_CATEGORY, c.LOCATION_ADDRESS, u.full_name, c.STATUS, c.CREATED_AT FROM complaints c JOIN civicuser u ON c.CITIZEN_ID = u.USER_ID ORDER BY c.CREATED_AT DESC) WHERE ROWNUM <= 5";
        pstmt = conn.prepareStatement(recentSql);
        rs = pstmt.executeQuery();
        SimpleDateFormat sdf = new SimpleDateFormat("dd MMM yyyy");
        while(rs.next()){
            Map<String, String> map = new HashMap<>();
            map.put("id", String.valueOf(rs.getInt("COMPLAINT_ID")));
            map.put("category", rs.getString("PROBLEM_CATEGORY"));
            map.put("location", rs.getString("LOCATION_ADDRESS"));
            map.put("user", rs.getString("full_name"));
            map.put("status", rs.getString("STATUS"));
            map.put("date", rs.getTimestamp("CREATED_AT") != null ? sdf.format(rs.getTimestamp("CREATED_AT")) : "N/A");
            recentComplaints.add(map);
        }
        rs.close(); pstmt.close();

        // C. Fetch Category Distribution
        String catSql = "SELECT PROBLEM_CATEGORY, COUNT(*) as cnt FROM complaints GROUP BY PROBLEM_CATEGORY";
        pstmt = conn.prepareStatement(catSql);
        rs = pstmt.executeQuery();
        while(rs.next()){
            categoryCounts.put(rs.getString("PROBLEM_CATEGORY"), rs.getInt("cnt"));
        }
        rs.close(); pstmt.close();

        // D. Fetch Top 5 Users
        String topUsersSql = "SELECT * FROM (SELECT u.full_name, COUNT(*) as total_c, SUM(CASE WHEN c.STATUS='Resolved' THEN 1 ELSE 0 END) as res_c FROM complaints c JOIN civicuser u ON c.CITIZEN_ID = u.USER_ID GROUP BY u.full_name ORDER BY total_c DESC) WHERE ROWNUM <= 5";
        pstmt = conn.prepareStatement(topUsersSql);
        rs = pstmt.executeQuery();
        while(rs.next()){
            Map<String, String> map = new HashMap<>();
            map.put("name", rs.getString("full_name"));
            map.put("total", String.valueOf(rs.getInt("total_c")));
            map.put("resolved", String.valueOf(rs.getInt("res_c")));
            topCitizens.add(map);
        }
        rs.close(); pstmt.close();

        // E. NEW: Fetch Monthly Trend Data (Current Year)
        String trendSql = "SELECT TO_CHAR(CREATED_AT, 'Mon') as m_name, EXTRACT(MONTH FROM CREATED_AT) as m_num, COUNT(*) as m_count " +
                          "FROM complaints " +
                          "WHERE EXTRACT(YEAR FROM CREATED_AT) = EXTRACT(YEAR FROM SYSDATE) " +
                          "GROUP BY TO_CHAR(CREATED_AT, 'Mon'), EXTRACT(MONTH FROM CREATED_AT) " +
                          "ORDER BY m_num";
        pstmt = conn.prepareStatement(trendSql);
        rs = pstmt.executeQuery();
        while(rs.next()){
            trendMonths.add("\"" + rs.getString("m_name") + "\""); // Adding quotes for JavaScript array format
            trendCounts.add(rs.getInt("m_count"));
        }

        // Fallback agar is saal koi data nahi hai
        if(trendMonths.isEmpty()){
            trendMonths.add("\"No Data\"");
            trendCounts.add(0);
        }

    } catch(Exception e) {
        e.printStackTrace();
    } finally {
        try{ if(rs != null) rs.close(); }catch(Exception e){}
        try{ if(pstmt != null) pstmt.close(); }catch(Exception e){}
        try{ if(conn != null) conn.close(); }catch(Exception e){}
    }

    // Percentage Calculations for Charts and UI
    double resPerc = totalComp > 0 ? (resolvedComp * 100.0) / totalComp : 0;
    double inProgPerc = totalComp > 0 ? (inProgComp * 100.0) / totalComp : 0;
    double penPerc = totalComp > 0 ? (pendingComp * 100.0) / totalComp : 0;

    // Mapping specific categories safely to avoid NullPointers
    int garbageCnt = categoryCounts.getOrDefault("Garbage Overflow", 0);
    int streetCnt = categoryCounts.getOrDefault("Street Light", 0);
    int waterCnt = categoryCounts.getOrDefault("Water Leakage", 0);
    int roadCnt = categoryCounts.getOrDefault("Road Damage", 0);
    int othersCnt = totalComp - (garbageCnt + streetCnt + waterCnt + roadCnt);
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Smart Civic - Admin Dashboard</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>

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

        .sidebar { width: 260px; background-color: var(--sidebar-bg); color: white; padding: 20px 0; display: flex; flex-direction: column; position: fixed; height: 100vh; overflow-y: auto; z-index: 1000;}
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
        .user-profile img { width: 40px; height: 40px; border-radius: 50%; object-fit: cover; border: 2px solid white; box-shadow: 0 2px 5px rgba(0,0,0,0.1);}
        .admin-text h6 { margin: 0; font-weight: bold; font-size: 15px; }
        .admin-text small { color: var(--text-muted); font-size: 12px; }

        .admin-card { background-color: white; border-radius: 12px; padding: 20px; border: none; box-shadow: 0 2px 10px rgba(0,0,0,0.02); height: 100%; }
        .card-header-flex { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; }
        .card-title { font-weight: 700; font-size: 16px; margin: 0; color: #0f172a;}

        .stat-box { display: flex; align-items: center; gap: 15px; }
        .stat-icon { width: 55px; height: 55px; border-radius: 12px; display: flex; align-items: center; justify-content: center; font-size: 24px; }
        .stat-details h6 { margin: 0; color: var(--text-muted); font-size: 13px; font-weight: 600;}
        .stat-details h2 { margin: 2px 0; font-weight: 800; font-size: 28px; }
        .stat-trend { font-size: 12px; font-weight: 600; color: var(--primary-green); }

        .bg-blue-soft { background-color: #dbeafe; color: var(--primary-blue); }
        .bg-green-soft { background-color: #dcfce7; color: var(--primary-green); }
        .bg-orange-soft { background-color: #ffedd5; color: var(--primary-orange); }
        .bg-purple-soft { background-color: #f3e8ff; color: var(--primary-purple); }

        .table { margin-bottom: 0; font-size: 13.5px; }
        .table th { border-bottom-width: 1px; color: var(--text-muted); font-weight: 600; padding: 12px 10px; }
        .table td { vertical-align: middle; padding: 12px 10px; color: #334155; font-weight: 500;}

        .status-badge { padding: 5px 12px; border-radius: 6px; font-size: 11.5px; font-weight: 600; display: inline-block; min-width: 90px; text-align: center;}
        .badge-resolved { background-color: #dcfce7; color: #16a34a; }
        .badge-progress { background-color: #ffedd5; color: #ea580c; }
        .badge-pending { background-color: #fee2e2; color: #dc2626; }

        .btn-action { background: #f1f5f9; border: none; color: #475569; padding: 5px 10px; border-radius: 6px; transition: 0.2s; text-decoration: none;}
        .btn-action:hover { background: #e2e8f0; color: var(--primary-blue); }

        .custom-legend { display: flex; flex-direction: column; gap: 12px; justify-content: center; }
        .legend-item { display: flex; align-items: center; justify-content: space-between; font-size: 13px; font-weight: 500;}
        .legend-dot { width: 10px; height: 10px; border-radius: 50%; margin-right: 8px; display: inline-block; }

        .cat-item { display: flex; align-items: center; gap: 10px; margin-bottom: 15px; }
        .cat-icon { width: 32px; height: 32px; border-radius: 8px; display: flex; align-items: center; justify-content: center; font-size: 16px; }
        .cat-info { flex-grow: 1; display: flex; align-items: center; justify-content: space-between; font-size: 13px; font-weight: 600;}
        .progress-slim { height: 4px; border-radius: 2px; width: 60px; background-color: #e2e8f0; }

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
            <li class="nav-item"><a href="admin-dashboard.jsp" class="nav-link active"><i class="bi bi-house-door"></i> Dashboard</a></li>
            <li class="nav-item"><a href="Admin-total-users.jsp" class="nav-link"><i class="bi bi-people"></i> Total Users</a></li>
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
            <a href="../logout.jsp" class="logout-btn"><i class="bi bi-box-arrow-right"></i> Logout</a>
        </div>
    </aside>

    <main class="main-content">

        <header class="top-header">
            <div class="d-flex align-items-center gap-3">
                <i class="bi bi-list fs-3" style="cursor: pointer;"></i>
                <h4 class="m-0 fw-bold">Welcome, <%= adminUser %> 👋</h4>
            </div>

            <div class="user-profile">
                <div class="position-relative">
                    <i class="bi bi-bell fs-5 text-muted"></i>
                    <span class="position-absolute top-0 start-100 translate-middle badge rounded-pill bg-danger" style="font-size: 9px;"><%= pendingComp %></span>
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
            <div class="col-xl-3 col-md-6">
                <div class="admin-card stat-box">
                    <div class="stat-icon bg-blue-soft"><i class="bi bi-people-fill"></i></div>
                    <div class="stat-details">
                        <h6>Total Users</h6>
                        <h2><%= totalUsers %></h2>
                        <span class="stat-trend text-muted">Registered Citizens</span>
                    </div>
                </div>
            </div>
            <div class="col-xl-3 col-md-6">
                <div class="admin-card stat-box">
                    <div class="stat-icon bg-green-soft"><i class="bi bi-card-list"></i></div>
                    <div class="stat-details">
                        <h6>Total Complaints</h6>
                        <h2><%= totalComp %></h2>
                        <span class="stat-trend text-muted">All-time record</span>
                    </div>
                </div>
            </div>
            <div class="col-xl-3 col-md-6">
                <div class="admin-card stat-box">
                    <div class="stat-icon bg-orange-soft"><i class="bi bi-hourglass-split"></i></div>
                    <div class="stat-details">
                        <h6>Pending Complaints</h6>
                        <h2><%= pendingComp %></h2>
                        <span class="stat-trend text-warning">Requires action</span>
                    </div>
                </div>
            </div>
            <div class="col-xl-3 col-md-6">
                <div class="admin-card stat-box">
                    <div class="stat-icon bg-purple-soft"><i class="bi bi-check-circle-fill"></i></div>
                    <div class="stat-details">
                        <h6>Resolved Complaints</h6>
                        <h2><%= resolvedComp %></h2>
                        <span class="stat-trend text-success"><%= String.format(Locale.US, "%.1f", resPerc) %>% Success</span>
                    </div>
                </div>
            </div>
        </div>

        <div class="row g-4 mb-4">
            <div class="col-lg-4">
                <div class="admin-card">
                    <h5 class="card-title mb-4">Complaints Overview</h5>
                    <div class="row align-items-center">
                        <div class="col-6">
                            <canvas id="overviewChart" height="200"></canvas>
                        </div>
                        <div class="col-6 custom-legend">
                            <div class="legend-item">
                                <div><span class="legend-dot" style="background:#2563eb;"></span>Resolved (<%= resolvedComp %>)</div>
                                <span class="text-muted"><%= String.format(Locale.US, "%.1f", resPerc) %>%</span>
                            </div>
                            <div class="legend-item">
                                <div><span class="legend-dot" style="background:#16a34a;"></span>In Progress (<%= inProgComp %>)</div>
                                <span class="text-muted"><%= String.format(Locale.US, "%.1f", inProgPerc) %>%</span>
                            </div>
                            <div class="legend-item">
                                <div><span class="legend-dot" style="background:#ea580c;"></span>Pending (<%= pendingComp %>)</div>
                                <span class="text-muted"><%= String.format(Locale.US, "%.1f", penPerc) %>%</span>
                            </div>
                            <div class="legend-item mt-2 pt-2 border-top">
                                <div><span class="legend-dot" style="background:#64748b;"></span>Total (<%= totalComp %>)</div>
                                <span class="fw-bold">100%</span>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <div class="col-lg-8">
                <div class="admin-card">
                    <div class="card-header-flex">
                        <h5 class="card-title">Recent Complaints</h5>
                        <a href="Admin-manage-complaints.jsp" class="btn btn-sm btn-primary">View All</a>
                    </div>
                    <div class="table-responsive">
                        <table class="table table-borderless table-hover">
                            <thead>
                            <tr>
                                <th>ID</th>
                                <th>Problem</th>
                                <th>Location</th>
                                <th>User</th>
                                <th>Date</th>
                                <th>Status</th>
                                <th>Action</th>
                            </tr>
                            </thead>
                            <tbody>
                            <%
                                for(Map<String, String> c : recentComplaints) {
                                    String stat = c.get("status");
                                    String badgeClass = "badge-pending";
                                    if(stat.equalsIgnoreCase("Resolved")) badgeClass = "badge-resolved";
                                    else if(stat.equalsIgnoreCase("In Progress")) badgeClass = "badge-progress";
                            %>
                            <tr>
                                <td class="text-muted">#<%= c.get("id") %></td>
                                <td><%= c.get("category") %></td>
                                <td><%= c.get("location") %></td>
                                <td><%= c.get("user") %></td>
                                <td><%= c.get("date") %></td>
                                <td><span class="status-badge <%= badgeClass %>"><%= stat %></span></td>
                                <td><a href="Admin-update-status.jsp?id=<%= c.get("id") %>" class="btn-action"><i class="bi bi-pencil-square"></i></a></td>
                            </tr>
                            <% } if(recentComplaints.isEmpty()){ %>
                            <tr><td colspan="7" class="text-center py-4 text-muted">No complaints found.</td></tr>
                            <% } %>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </div>

        <div class="row g-4">
            <div class="col-lg-4">
                <div class="admin-card">
                    <div class="card-header-flex">
                        <h5 class="card-title">Complaints Trend <span class="fw-normal text-muted fs-6">(This Year)</span></h5>
                    </div>
                    <div style="height: 220px;">
                        <canvas id="trendChart"></canvas>
                    </div>
                </div>
            </div>

            <div class="col-lg-4">
                <div class="admin-card">
                    <div class="card-header-flex">
                        <h5 class="card-title">Complaints by Category</h5>
                        <a href="Admin-complaint-categories.jsp" class="btn btn-sm btn-outline-secondary border-0 bg-light">View All</a>
                    </div>

                    <div class="cat-item">
                        <div class="cat-icon bg-success-subtle text-success"><i class="bi bi-trash"></i></div>
                        <div class="cat-info">
                            <span>Garbage</span>
                            <div class="d-flex align-items-center gap-2">
                                <div class="progress-slim"><div class="progress-bar bg-primary" style="width: <%= totalComp > 0 ? (garbageCnt*100)/totalComp : 0 %>%"></div></div>
                                <span><%= garbageCnt %></span>
                            </div>
                        </div>
                    </div>
                    <div class="cat-item">
                        <div class="cat-icon bg-warning-subtle text-warning"><i class="bi bi-lightbulb"></i></div>
                        <div class="cat-info">
                            <span>Street Light</span>
                            <div class="d-flex align-items-center gap-2">
                                <div class="progress-slim"><div class="progress-bar bg-success" style="width: <%= totalComp > 0 ? (streetCnt*100)/totalComp : 0 %>%"></div></div>
                                <span><%= streetCnt %></span>
                            </div>
                        </div>
                    </div>
                    <div class="cat-item">
                        <div class="cat-icon bg-info-subtle text-info"><i class="bi bi-droplet"></i></div>
                        <div class="cat-info">
                            <span>Water Leakage</span>
                            <div class="d-flex align-items-center gap-2">
                                <div class="progress-slim"><div class="progress-bar bg-warning" style="width: <%= totalComp > 0 ? (waterCnt*100)/totalComp : 0 %>%"></div></div>
                                <span><%= waterCnt %></span>
                            </div>
                        </div>
                    </div>
                    <div class="cat-item">
                        <div class="cat-icon bg-purple-subtle text-purple"><i class="bi bi-cone-striped"></i></div>
                        <div class="cat-info">
                            <span>Road Damage</span>
                            <div class="d-flex align-items-center gap-2">
                                <div class="progress-slim"><div class="progress-bar" style="background:#7c3aed; width: <%= totalComp > 0 ? (roadCnt*100)/totalComp : 0 %>%"></div></div>
                                <span><%= roadCnt %></span>
                            </div>
                        </div>
                    </div>
                    <div class="cat-item">
                        <div class="cat-icon bg-danger-subtle text-danger"><i class="bi bi-exclamation-triangle"></i></div>
                        <div class="cat-info">
                            <span>Others</span>
                            <div class="d-flex align-items-center gap-2">
                                <div class="progress-slim"><div class="progress-bar bg-danger" style="width: <%= totalComp > 0 ? (othersCnt*100)/totalComp : 0 %>%"></div></div>
                                <span><%= othersCnt %></span>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <div class="col-lg-4">
                <div class="admin-card">
                    <div class="card-header-flex">
                        <h5 class="card-title">Top Users</h5>
                        <a href="Admin-user-management.jsp" class="btn btn-sm btn-outline-secondary border-0 bg-light">View All</a>
                    </div>
                    <table class="table table-borderless">
                        <thead>
                        <tr>
                            <th>User</th>
                            <th class="text-center">Total Complaints</th>
                            <th class="text-center">Resolved</th>
                        </tr>
                        </thead>
                        <tbody>
                        <% for(Map<String, String> tu : topCitizens) { %>
                        <tr>
                            <td><%= tu.get("name") %></td>
                            <td class="text-center fw-bold"><%= tu.get("total") %></td>
                            <td class="text-center text-success fw-bold"><%= tu.get("resolved") %></td>
                        </tr>
                        <% } if(topCitizens.isEmpty()){ %>
                        <tr><td colspan="3" class="text-center text-muted">No data available</td></tr>
                        <% } %>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>

    </main>
</div>

<script>
    document.addEventListener("DOMContentLoaded", function() {

        // 1. Donut Chart
        const overviewCtx = document.getElementById('overviewChart').getContext('2d');
        new Chart(overviewCtx, {
            type: 'doughnut',
            data: {
                labels: ['Resolved', 'In Progress', 'Pending'],
                datasets: [{
                    data: [<%= String.format(Locale.US, "%.1f", resPerc) %>, <%= String.format(Locale.US, "%.1f", inProgPerc) %>, <%= String.format(Locale.US, "%.1f", penPerc) %>],
                    backgroundColor: ['#2563eb', '#16a34a', '#ea580c'],
                    borderWidth: 2,
                    borderColor: '#ffffff',
                    hoverOffset: 4
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                cutout: '65%',
                plugins: {
                    legend: { display: false },
                    tooltip: {
                        callbacks: {
                            label: function(context) {
                                return ' ' + context.label + ': ' + context.raw + '%';
                            }
                        }
                    }
                }
            }
        });

        // 2. Line Chart (Trends) - UPDATED WITH DYNAMIC DATA
        const trendCtx = document.getElementById('trendChart').getContext('2d');

        let gradientFill = trendCtx.createLinearGradient(0, 0, 0, 220);
        gradientFill.addColorStop(0, 'rgba(37, 99, 235, 0.2)');
        gradientFill.addColorStop(1, 'rgba(37, 99, 235, 0.0)');

        new Chart(trendCtx, {
            type: 'line',
            data: {
                // Dynamically injecting months and counts
                labels: [<%= String.join(",", trendMonths) %>],
                datasets: [{
                    label: 'Complaints',
                    data: [<%= trendCounts.toString().replaceAll("[\\[\\]]", "") %>],
                    borderColor: '#2563eb',
                    backgroundColor: gradientFill,
                    borderWidth: 2,
                    pointBackgroundColor: '#2563eb',
                    pointBorderColor: '#ffffff',
                    pointBorderWidth: 2,
                    pointRadius: 5,
                    fill: true,
                    tension: 0.1
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: { display: false },
                    datalabels: { display: true, align: 'top', color: '#1e293b', font: { weight: 'bold' } }
                },
                scales: {
                    x: { grid: { display: false }, ticks: { color: '#64748b', font: { size: 12 } } },
                    y: { min: 0, grid: { color: '#f1f5f9' }, ticks: { stepSize: 5, color: '#64748b' }, border: { display: false } }
                },
                layout: { padding: { top: 20 } }
            },
            plugins: [{
                id: 'customDataLabels',
                afterDatasetsDraw(chart, args, pluginOptions) {
                    const { ctx, data } = chart;
                    ctx.save();
                    ctx.font = 'bold 12px sans-serif';
                    ctx.fillStyle = '#1e293b';
                    ctx.textAlign = 'center';
                    const meta = chart.getDatasetMeta(0);
                    meta.data.forEach((element, index) => {
                        const dataValue = data.datasets[0].data[index];
                        ctx.fillText(dataValue, element.x, element.y - 10);
                    });
                    ctx.restore();
                }
            }]
        });

    });
</script>

</body>
</html>