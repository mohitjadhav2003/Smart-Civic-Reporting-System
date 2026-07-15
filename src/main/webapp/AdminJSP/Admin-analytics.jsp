<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="true" %>
<%@ page import="java.util.*, java.sql.*, utility.DBConnection, java.text.DecimalFormat" %>
<%
    String adminUser = (String) session.getAttribute("adminUser");
    if (adminUser == null) {
        adminUser = "Admin";
    }

    // --- Dynamic Stats Variables ---
    int totalReports = 0;
    int resolvedReports = 0;
    double resolutionRate = 0.0;
    double avgResolutionDays = 0.0;
    String dbError = "";

    // --- Chart Data Variables (Builders for JS Arrays) ---
    StringBuilder trendLabels = new StringBuilder("[");
    StringBuilder trendReported = new StringBuilder("[");
    StringBuilder trendResolved = new StringBuilder("[");

    StringBuilder catLabels = new StringBuilder("[");
    StringBuilder catData = new StringBuilder("[");
    List<Map<String, String>> customLegendData = new ArrayList<>();
    String[] catColors = {"#2563eb", "#16a34a", "#ea580c", "#7c3aed", "#0891b2", "#dc2626"};

    StringBuilder locLabels = new StringBuilder("[");
    StringBuilder locData = new StringBuilder("[");

    StringBuilder deptLabels = new StringBuilder("[");
    StringBuilder deptData = new StringBuilder("[");

    Connection conn = null;
    try {
        conn = DBConnection.getConnection();
        Statement stmt = conn.createStatement();

        // 1. Fetch Top Stats (Total & Resolved)
        String statsSql = "SELECT COUNT(*) as total, SUM(CASE WHEN STATUS='Resolved' THEN 1 ELSE 0 END) as resolved FROM complaints";
        ResultSet rsStats = stmt.executeQuery(statsSql);
        if(rsStats.next()){
            totalReports = rsStats.getInt("total");
            resolvedReports = rsStats.getInt("resolved");
        }
        if(totalReports > 0) {
            resolutionRate = ((double) resolvedReports / totalReports) * 100;
        }

        // 2. Fetch Avg Resolution Time (Dynamic calculation in Days)
        try {
            String avgSql = "SELECT AVG(CAST(RESOLVED_AT AS DATE) - CAST(CREATED_AT AS DATE)) as avg_days FROM complaints WHERE STATUS='Resolved' AND RESOLVED_AT IS NOT NULL";
            ResultSet rsAvg = stmt.executeQuery(avgSql);
            if(rsAvg.next()){
                avgResolutionDays = rsAvg.getDouble("avg_days");
            }
        } catch(Exception ignored) {
            // Fallback to 0 if column is missing or empty
        }

        // 3. Fetch Trend Data (Lifetime View: Grouped by Year-Month)
        String trendSql = "SELECT TO_CHAR(CREATED_AT, 'Mon YYYY') as month_name, " +
                "COUNT(*) as total_reported, " +
                "SUM(CASE WHEN STATUS='Resolved' THEN 1 ELSE 0 END) as total_resolved " +
                "FROM complaints " +
                "WHERE CREATED_AT IS NOT NULL " +
                "GROUP BY TO_CHAR(CREATED_AT, 'YYYY-MM'), TO_CHAR(CREATED_AT, 'Mon YYYY') " +
                "ORDER BY TO_CHAR(CREATED_AT, 'YYYY-MM')";
        ResultSet rsTrend = stmt.executeQuery(trendSql);
        boolean firstTrend = true;
        while(rsTrend.next()){
            if(!firstTrend) { trendLabels.append(","); trendReported.append(","); trendResolved.append(","); }
            trendLabels.append("'").append(rsTrend.getString("month_name")).append("'");
            trendReported.append(rsTrend.getInt("total_reported"));
            trendResolved.append(rsTrend.getInt("total_resolved"));
            firstTrend = false;
        }
        trendLabels.append("]"); trendReported.append("]"); trendResolved.append("]");

        // 4. Fetch Category Distribution (Top Categories)
        String catSql = "SELECT * FROM (SELECT PROBLEM_CATEGORY, COUNT(*) as c FROM complaints WHERE PROBLEM_CATEGORY IS NOT NULL GROUP BY PROBLEM_CATEGORY ORDER BY c DESC) WHERE ROWNUM <= 5";
        ResultSet rsCat = stmt.executeQuery(catSql);
        boolean firstCat = true;
        int colorIdx = 0;
        while(rsCat.next()){
            if(!firstCat) { catLabels.append(","); catData.append(","); }
            String catName = rsCat.getString("PROBLEM_CATEGORY");
            int cCount = rsCat.getInt("c");
            int percentage = (totalReports > 0) ? (cCount * 100 / totalReports) : 0;

            catLabels.append("'").append(catName).append("'");
            catData.append(cCount);

            Map<String, String> leg = new HashMap<>();
            leg.put("name", catName.length() > 15 ? catName.substring(0,15)+"..." : catName);
            leg.put("percent", percentage + "%");
            leg.put("color", catColors[colorIdx % catColors.length]);
            customLegendData.add(leg);

            firstCat = false;
            colorIdx++;
        }
        catLabels.append("]"); catData.append("]");

        // 5. Fetch Top Locations / Zones
        String locSql = "SELECT * FROM (SELECT LOCATION_ADDRESS, COUNT(*) as c FROM complaints WHERE LOCATION_ADDRESS IS NOT NULL GROUP BY LOCATION_ADDRESS ORDER BY c DESC) WHERE ROWNUM <= 5";
        ResultSet rsLoc = stmt.executeQuery(locSql);
        boolean firstLoc = true;
        while(rsLoc.next()){
            if(!firstLoc) { locLabels.append(","); locData.append(","); }
            String loc = rsLoc.getString("LOCATION_ADDRESS");
            locLabels.append("'").append(loc.length() > 15 ? loc.substring(0, 15) : loc).append("'");
            locData.append(rsLoc.getInt("c"));
            firstLoc = false;
        }
        locLabels.append("]"); locData.append("]");

        // 6. Fetch Dept Workload
        try {
            String deptSql = "SELECT cc.DEFAULT_DEPT, COUNT(cmp.COMPLAINT_ID) as c " +
                    "FROM complaint_categories cc " +
                    "LEFT JOIN complaints cmp ON cc.CATEGORY_NAME = cmp.PROBLEM_CATEGORY " +
                    "WHERE cc.DEFAULT_DEPT IS NOT NULL " +
                    "GROUP BY cc.DEFAULT_DEPT " +
                    "ORDER BY c DESC";
            ResultSet rsDept = stmt.executeQuery(deptSql);
            boolean firstDept = true;
            while(rsDept.next()){
                if(!firstDept) { deptLabels.append(","); deptData.append(","); }
                deptLabels.append("'").append(rsDept.getString("DEFAULT_DEPT")).append("'");
                deptData.append(rsDept.getInt("c"));
                firstDept = false;
            }
        } catch(Exception ignored) {
            // Silently ignore if complaint_categories table is not set up yet
        }
        deptLabels.append("]"); deptData.append("]");

    } catch(Exception e) {
        e.printStackTrace();
        dbError = e.getMessage();
    } finally {
        if(conn != null) try{ conn.close(); } catch(Exception e){}
    }

    // Decimal Formatting for UI
    DecimalFormat df = new DecimalFormat("#.0");
    DecimalFormat dfDays = new DecimalFormat("#.00");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Analytics & Reports - Admin Panel</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>

    <style>
        :root { --sidebar-bg: #0b1727; --main-bg: #f4f7fe; --primary-blue: #2563eb; --primary-green: #16a34a; --primary-orange: #ea580c; --primary-purple: #7c3aed; --text-dark: #1e293b; --text-muted: #64748b; }
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
        .card-title { font-weight: 700; font-size: 16px; margin: 0; color: #0f172a;}
        .stat-box { display: flex; align-items: center; gap: 15px; }
        .stat-icon { width: 55px; height: 55px; border-radius: 12px; display: flex; align-items: center; justify-content: center; font-size: 24px; }
        .stat-details h6 { margin: 0; color: var(--text-muted); font-size: 13px; font-weight: 600;}
        .stat-details h2 { margin: 2px 0; font-weight: 800; font-size: 26px; }
        .stat-trend { font-size: 12px; font-weight: 600; display:flex; align-items:center; gap:4px; }
        .trend-up { color: var(--primary-green); }
        .bg-blue-soft { background-color: #dbeafe; color: var(--primary-blue); }
        .bg-green-soft { background-color: #dcfce7; color: var(--primary-green); }
        .bg-orange-soft { background-color: #ffedd5; color: var(--primary-orange); }
        .bg-purple-soft { background-color: #f3e8ff; color: var(--primary-purple); }
        .date-filter { display: flex; align-items: center; gap: 10px; background: white; padding: 8px 15px; border-radius: 8px; border: 1px solid #cbd5e1; font-size: 14px; font-weight: 500; color: #334155; cursor: pointer; box-shadow: 0 2px 5px rgba(0,0,0,0.02); }
        .chart-container { position: relative; height: 280px; width: 100%; }
        .custom-legend { display: flex; flex-direction: column; gap: 10px; justify-content: center; }
        .legend-item { display: flex; align-items: center; justify-content: space-between; font-size: 13px; font-weight: 500;}
        .legend-dot { width: 10px; height: 10px; border-radius: 50%; margin-right: 8px; display: inline-block; }
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
            <li class="nav-item"><a href="Admin-manage-complaints.jsp" class="nav-link"><i class="bi bi-card-checklist"></i> Manage Complaints</a></li>
            <li class="nav-item"><a href="Admin-update-status.jsp" class="nav-link"><i class="bi bi-arrow-clockwise"></i> Update Status</a></li>
            <li class="nav-item"><a href="Admin-user-management.jsp" class="nav-link"><i class="bi bi-person-gear"></i> User Management</a></li>
            <li class="nav-item"><a href="Admin-complaint-categories.jsp" class="nav-link"><i class="bi bi-grid"></i> Complaint Categories</a></li>
            <li class="nav-item"><a href="Admin-analytics.jsp" class="nav-link active"><i class="bi bi-bar-chart"></i> Analytics</a></li>
            <li class="nav-item"><a href="Admin-reports.jsp" class="nav-link"><i class="bi bi-file-earmark-bar-graph"></i> Reports</a></li>
            <li class="nav-item mt-4"><a href="Admin-settings.jsp" class="nav-link"><i class="bi bi-gear"></i> Settings</a></li>
        </ul>
        <div class="logout-container"><a href="../logout.jsp" class="logout-btn"><i class="bi bi-box-arrow-right"></i> Logout</a></div>
    </aside>

    <main class="main-content">
        <header class="top-header">
            <div class="d-flex align-items-center gap-3"><i class="bi bi-list fs-3" style="cursor: pointer;"></i><h4 class="m-0 fw-bold">Performance Analytics</h4></div>
            <div class="d-flex align-items-center gap-4">
                <div class="date-filter"><i class="bi bi-calendar3 text-muted"></i><span class="text-primary fw-bold">Lifetime Data View</span><i class="bi bi-check-circle-fill ms-2 text-success" style="font-size: 14px;"></i></div>
                <div class="user-profile">
                    <div class="position-relative"><i class="bi bi-bell fs-5 text-muted"></i></div>
                    <div class="d-flex align-items-center gap-2">
                        <img src="https://ui-avatars.com/api/?name=<%= java.net.URLEncoder.encode(adminUser, "UTF-8") %>&background=0D8ABC&color=fff" alt="<%= adminUser %>">
                        <div class="admin-text d-none d-md-block"><h6><%= adminUser %></h6><small>Administrator</small></div>
                    </div>
                </div>
            </div>
        </header>

        <% if (!dbError.isEmpty()) { %>
        <div class="alert alert-danger shadow-sm border-0 mb-4"><i class="bi bi-exclamation-triangle-fill me-2 fs-5"></i><strong>Database Error:</strong> <%= dbError %></div>
        <% } %>

        <div class="row g-4 mb-4">
            <div class="col-xl-3 col-md-6">
                <div class="admin-card stat-box py-3">
                    <div class="stat-icon bg-blue-soft"><i class="bi bi-file-earmark-bar-graph"></i></div>
                    <div class="stat-details">
                        <h6>Total Reports Filed</h6>
                        <h2><%= totalReports %></h2>
                        <span class="stat-trend trend-up"><i class="bi bi-arrow-up-right"></i> All-Time Dynamic</span>
                    </div>
                </div>
            </div>
            <div class="col-xl-3 col-md-6">
                <div class="admin-card stat-box py-3">
                    <div class="stat-icon bg-green-soft"><i class="bi bi-check2-all"></i></div>
                    <div class="stat-details">
                        <h6>Resolution Rate</h6>
                        <h2><%= df.format(resolutionRate) %>%</h2>
                        <span class="stat-trend trend-up"><i class="bi bi-arrow-up-right"></i> Dynamic Data</span>
                    </div>
                </div>
            </div>
            <div class="col-xl-3 col-md-6">
                <div class="admin-card stat-box py-3">
                    <div class="stat-icon bg-orange-soft"><i class="bi bi-stopwatch"></i></div>
                    <div class="stat-details">
                        <h6>Avg. Resolution Time</h6>
                        <h2><%= dfDays.format(avgResolutionDays) %> <span style="font-size:16px; color:#64748b; font-weight:600;">Days</span></h2>
                        <span class="stat-trend trend-up"><i class="bi bi-arrow-up-right"></i> Real-Time Calc</span>
                    </div>
                </div>
            </div>
            <div class="col-xl-3 col-md-6">
                <div class="admin-card stat-box py-3">
                    <div class="stat-icon bg-purple-soft"><i class="bi bi-star-fill"></i></div>
                    <div class="stat-details">
                        <h6>System Reliability</h6>
                        <h2>Active <span style="font-size:16px; color:#64748b; font-weight:600;">Status</span></h2>
                        <span class="stat-trend text-muted">Running Optimally</span>
                    </div>
                </div>
            </div>
        </div>

        <div class="row g-4 mb-4">
            <div class="col-lg-8">
                <div class="admin-card">
                    <div class="card-header-flex">
                        <h5 class="card-title">Lifetime Complaints Trend (Reported vs Resolved)</h5>
                    </div>
                    <div class="chart-container"><canvas id="trendChart"></canvas></div>
                </div>
            </div>

            <div class="col-lg-4">
                <div class="admin-card">
                    <h5 class="card-title mb-4">Distribution by Category</h5>
                    <div class="row align-items-center h-100">
                        <div class="col-6"><canvas id="categoryChart" height="200"></canvas></div>
                        <div class="col-6 custom-legend">
                            <% for(Map<String, String> leg : customLegendData) { %>
                            <div class="legend-item">
                                <div><span class="legend-dot" style="background:<%= leg.get("color") %>;"></span><%= leg.get("name") %></div>
                                <span class="text-muted"><%= leg.get("percent") %></span>
                            </div>
                            <% } if(customLegendData.isEmpty()) { %>
                            <div class="text-muted small">No data available</div>
                            <% } %>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="row g-4">
            <div class="col-lg-6">
                <div class="admin-card">
                    <div class="card-header-flex">
                        <h5 class="card-title">Complaints by Zone / Location</h5>
                    </div>
                    <div class="chart-container"><canvas id="zoneChart"></canvas></div>
                </div>
            </div>

            <div class="col-lg-6">
                <div class="admin-card">
                    <div class="card-header-flex">
                        <h5 class="card-title">Dept Workload (Total Complaints)</h5>
                    </div>
                    <div class="chart-container"><canvas id="performanceChart"></canvas></div>
                </div>
            </div>
        </div>
    </main>
</div>

<script>
    document.addEventListener("DOMContentLoaded", function() {
        const tLabels = <%= trendLabels.toString() %>;
        const tReported = <%= trendReported.toString() %>;
        const tResolved = <%= trendResolved.toString() %>;
        const cLabels = <%= catLabels.toString() %>;
        const cData = <%= catData.toString() %>;
        const lLabels = <%= locLabels.toString() %>;
        const lData = <%= locData.toString() %>;
        const dLabels = <%= deptLabels.toString() %>;
        const dData = <%= deptData.toString() %>;

        // 1. Line Chart (Reported vs Resolved - Lifetime View)
        if(document.getElementById('trendChart') && tLabels.length > 0) {
            new Chart(document.getElementById('trendChart').getContext('2d'), {
                type: 'line',
                data: {
                    labels: tLabels,
                    datasets: [
                        { label: 'Reported', data: tReported, borderColor: '#ea580c', backgroundColor: '#ea580c', borderWidth: 2, tension: 0.3 },
                        { label: 'Resolved', data: tResolved, borderColor: '#16a34a', backgroundColor: '#16a34a', borderWidth: 2, tension: 0.3 }
                    ]
                },
                options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { position: 'top', align: 'end', labels: { usePointStyle: true, boxWidth: 8 } } }, scales: { x: { grid: { display: false } }, y: { grid: { color: '#f1f5f9' }, beginAtZero: true } }, interaction: { mode: 'index', intersect: false } }
            });
        }

        // 2. Donut Chart (Categories)
        if(document.getElementById('categoryChart') && cLabels.length > 0) {
            new Chart(document.getElementById('categoryChart').getContext('2d'), {
                type: 'doughnut',
                data: { labels: cLabels, datasets: [{ data: cData, backgroundColor: ['#2563eb', '#16a34a', '#ea580c', '#7c3aed', '#0891b2', '#dc2626'], borderWidth: 2, borderColor: '#ffffff', hoverOffset: 4 }] },
                options: { responsive: true, maintainAspectRatio: false, cutout: '70%', plugins: { legend: { display: false } } }
            });
        }

        // 3. Bar Chart (Zones)
        if(document.getElementById('zoneChart') && lLabels.length > 0) {
            new Chart(document.getElementById('zoneChart').getContext('2d'), {
                type: 'bar',
                data: { labels: lLabels, datasets: [{ label: 'Complaints', data: lData, backgroundColor: '#2563eb', borderRadius: 4 }] },
                options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { display: false } }, scales: { x: { grid: { display: false } }, y: { grid: { color: '#f1f5f9' }, beginAtZero: true } } }
            });
        }

        // 4. Horizontal Bar Chart (Dept Performance)
        if(document.getElementById('performanceChart') && dLabels.length > 0) {
            new Chart(document.getElementById('performanceChart').getContext('2d'), {
                type: 'bar',
                data: {
                    labels: dLabels,
                    datasets: [{
                        label: 'Total Complaints',
                        data: dData,
                        backgroundColor: function(context) {
                            const val = context.dataset.data[context.dataIndex];
                            if(val < 10) return '#16a34a';
                            if(val < 30) return '#f59e0b';
                            return '#dc2626';
                        },
                        borderRadius: 4
                    }]
                },
                options: { indexAxis: 'y', responsive: true, maintainAspectRatio: false, plugins: { legend: { display: false } }, scales: { x: { grid: { color: '#f1f5f9' }, beginAtZero: true }, y: { grid: { display: false } } } }
            });
        }
    });
</script>

</body>
</html>