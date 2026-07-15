<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="true" %>
<%@ page import="java.sql.*, java.util.*, java.text.SimpleDateFormat, utility.DBConnection" %>
<%
    // =========================================================
    //   1. ROLE-BASED ACCESS CONTROL (RBAC)
    // =========================================================
    // Ensure only users with "Technician" role can access this page
    String currentUserRole = (String) session.getAttribute("role");
    System.out.println("Role: " + currentUserRole);
    if (currentUserRole == null || !currentUserRole.equalsIgnoreCase("Technician")) {
        response.sendRedirect("login.jsp?error=unauthorized");
        return; // Stop rendering the page
    }

    // =========================================================
    //   2. FETCH TECHNICIAN INFO FROM SESSION
    // =========================================================
    String techId = (String) session.getAttribute("userId");
    String techUser = (String) session.getAttribute("userName");
    String techDept = (String) session.getAttribute("userDept");
    System.out.println("Tech Info: " + techId +","+ techUser +","+techDept);

    // =========================================================
    //   FIX FOR ORA-01722 ERROR: ASSIGNED_TO expects a NUMBER
    // =========================================================
    // If techId is null or contains non-numeric characters, default to "0" instead of "Unknown"
    if (techId == null || !techId.matches("\\d+")) {
        techId = "0";
    }
    if (techUser == null) techUser = "Technician";
    if (techDept == null) techDept = "Maintenance Team";

    // =========================================================
    //   3. BACKEND LOGIC: FETCHING DYNAMIC DATA FROM DATABASE
    // =========================================================
    int totalAssigned = 0;
    int pendingCount = 0;
    int progressCount = 0;
    int completedCount = 0;

    List<Map<String, String>> myTasks = new ArrayList<>();
    String dbError = "";

    Connection conn = null;
    try {
        conn = DBConnection.getConnection();

        // --- A. Fetch Stats for the Logged-In Technician ---
        String statSql = "SELECT " +
                "COUNT(*) as total_tasks, " +
                "SUM(CASE WHEN LOWER(STATUS) = 'pending' THEN 1 ELSE 0 END) as pending_tasks, " +
                "SUM(CASE WHEN LOWER(STATUS) = 'in progress' THEN 1 ELSE 0 END) as in_progress_tasks, " +
                "SUM(CASE WHEN LOWER(STATUS) = 'resolved' THEN 1 ELSE 0 END) as resolved_tasks " +
                "FROM complaints WHERE ASSIGNED_TO = ?";

        PreparedStatement psStat = conn.prepareStatement(statSql);
        psStat.setString(1, techId);
        ResultSet rsStat = psStat.executeQuery();

        if(rsStat.next()){
            totalAssigned = rsStat.getInt("total_tasks");
            pendingCount = rsStat.getInt("pending_tasks");
            progressCount = rsStat.getInt("in_progress_tasks");
            completedCount = rsStat.getInt("resolved_tasks");
        }
        rsStat.close();
        psStat.close();

        // --- B. Fetch Recent Assigned Tasks for Table (Limit 5) + Fetch Photo Data ---
        String taskSql = "SELECT * FROM (SELECT COMPLAINT_ID, PROBLEM_CATEGORY, LOCATION_ADDRESS, STATUS, CREATED_AT, IMAGE_PATH " +
                "FROM complaints WHERE ASSIGNED_TO = ? ORDER BY COMPLAINT_ID DESC) WHERE ROWNUM <= 5";

        PreparedStatement psTask = conn.prepareStatement(taskSql);
        psTask.setString(1, techId);
        ResultSet rsTask = psTask.executeQuery();

        SimpleDateFormat sdf = new SimpleDateFormat("dd MMM yyyy");

        while(rsTask.next()){
            Map<String, String> m = new HashMap<>();
            m.put("id", rsTask.getString("COMPLAINT_ID"));
            m.put("prob", rsTask.getString("PROBLEM_CATEGORY") != null ? rsTask.getString("PROBLEM_CATEGORY") : "Unknown Issue");
            m.put("loc", rsTask.getString("LOCATION_ADDRESS") != null ? rsTask.getString("LOCATION_ADDRESS") : "Location not provided");
            m.put("status", rsTask.getString("STATUS") != null ? rsTask.getString("STATUS") : "Pending");

            // --- FIX FOR CLOB IMAGE DATA ---
            String photoData = rsTask.getString("IMAGE_PATH");
            if (photoData != null && !photoData.trim().isEmpty()) {
                // Remove all newlines and carriage returns from Base64 string to prevent HTML/JS breakage
                photoData = photoData.replaceAll("[\\r\\n]+", "");
                m.put("photo", photoData);
            } else {
                m.put("photo", "");
            }

            Timestamp ts = rsTask.getTimestamp("CREATED_AT");
            m.put("date", ts != null ? sdf.format(ts) : "N/A");

            myTasks.add(m);
        }
        rsTask.close();
        psTask.close();

    } catch(Exception e) {
        e.printStackTrace();
        dbError = "Error loading data: " + e.getMessage();
    } finally {
        if(conn != null) try{ conn.close(); } catch(Exception e){}
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Technician Dashboard - Smart Civic</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>

    <style>
        :root {
            --sidebar-bg: #0b1727;
            --sidebar-hover: #1e293b;
            --main-bg: #f8fafc;
            --card-bg: #ffffff;
            --primary-blue: #2563eb;
            --text-dark: #0f172a;
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

        /* --- Dark Sidebar --- */
        .sidebar {
            width: 260px;
            background-color: var(--sidebar-bg);
            color: white;
            display: flex;
            flex-direction: column;
            position: fixed;
            height: 100vh;
            overflow-y: auto;
            z-index: 100;
        }

        .logo-container {
            display: flex;
            align-items: center;
            gap: 12px;
            padding: 25px 20px;
            background-color: rgba(0,0,0,0.2);
            margin-bottom: 10px;
        }

        .logo-icon { font-size: 28px; color: white; }
        .logo-text h5 { margin: 0; font-weight: bold; font-size: 18px; }
        .logo-text span { font-size: 11px; color: #cbd5e1; }

        .sidebar-nav { list-style: none; padding: 0 15px; margin: 0; flex-grow: 1; }
        .nav-item { margin-bottom: 5px; }

        .nav-link {
            display: flex;
            align-items: center;
            gap: 12px;
            padding: 12px 15px;
            color: #cbd5e1;
            border-radius: 8px;
            text-decoration: none;
            font-weight: 500;
            font-size: 14px;
            transition: 0.2s;
        }

        .nav-link:hover { background-color: var(--sidebar-hover); color: white; }
        .nav-link.active { background-color: var(--primary-blue); color: white; }
        .nav-link i { font-size: 18px; width: 24px; text-align: center; }

        /* Tech Info Card in Sidebar */
        .tech-info-card {
            margin: 15px;
            background-color: rgba(255,255,255,0.05);
            border-radius: 12px;
            padding: 15px;
            border: 1px solid rgba(255,255,255,0.1);
        }
        .tech-info-item { display: flex; align-items: flex-start; gap: 12px; margin-bottom: 12px; }
        .tech-info-item:last-child { margin-bottom: 0; }
        .tech-info-item i { font-size: 18px; color: #94a3b8; margin-top: 2px;}
        .tech-info-item div span { display: block; font-size: 11px; color: #94a3b8; text-transform: uppercase; letter-spacing: 0.5px;}
        .tech-info-item div h6 { margin: 0; font-size: 13px; font-weight: 600; color: white; }

        /* --- Main Content --- */
        .main-content {
            flex-grow: 1;
            margin-left: 260px;
            width: calc(100% - 260px);
            padding: 25px 35px;
            display: flex;
            flex-direction: column;
        }

        .top-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 25px;
        }

        .header-title-section { display: flex; align-items: center; gap: 15px; }
        .header-title h4 { margin: 0; font-weight: 700; color: var(--text-dark); }
        .header-title p { margin: 0; font-size: 13px; color: var(--text-muted); }

        .user-profile { display: flex; align-items: center; gap: 20px; }
        .user-profile img { width: 40px; height: 40px; border-radius: 50%; object-fit: cover; }
        .admin-text h6 { margin: 0; font-weight: bold; font-size: 14px; }
        .admin-text small { color: var(--text-muted); font-size: 12px; }

        /* Generic Card Style */
        .ui-card {
            background-color: var(--card-bg);
            border-radius: 12px;
            padding: 20px;
            border: 1px solid #e2e8f0;
            box-shadow: 0 2px 5px rgba(0,0,0,0.02);
            height: 100%;
            display: flex;
            flex-direction: column;
        }

        .card-header-flex {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
        }
        .card-title { font-weight: 700; font-size: 16px; margin: 0; color: #0f172a;}

        /* --- KPI Stat Boxes --- */
        .kpi-container {
            display: flex;
            align-items: center;
            gap: 15px;
        }
        .kpi-icon {
            width: 55px; height: 55px; border-radius: 50%;
            display: flex; align-items: center; justify-content: center; font-size: 24px; color: white;
        }
        .kpi-details h6 { margin: 0; color: var(--text-dark); font-size: 14px; font-weight: 600;}
        .kpi-details h2 { margin: 2px 0; font-weight: 800; font-size: 26px; }
        .kpi-details span { font-size: 12px; color: var(--text-muted); }

        /* --- Tables & Badges --- */
        .table { margin-bottom: 0; font-size: 13px; }
        .table th { color: var(--text-muted); font-weight: 600; padding: 12px 10px; border-bottom: 1px solid #f1f5f9;}
        .table td { vertical-align: middle; padding: 12px 10px; color: #334155; font-weight: 500; border-bottom: 1px solid #f8fafc;}

        .status-badge { padding: 5px 12px; border-radius: 6px; font-size: 11.5px; font-weight: 600; }
        .badge-progress { background-color: #dbeafe; color: #2563eb; }
        .badge-pending { background-color: #ffedd5; color: #ea580c; }
        .badge-completed { background-color: #dcfce7; color: #16a34a; }

        .btn-update { border: 1px solid #2563eb; color: #2563eb; background: white; padding: 4px 12px; border-radius: 6px; font-size: 12px; font-weight: 600; transition: 0.2s; text-decoration:none; display:inline-block;}
        .btn-update:hover { background: #eff6ff; }

        /* New Buttons Styling */
        .btn-map { border: 1px solid #16a34a; color: #16a34a; background: white; padding: 4px 12px; border-radius: 6px; font-size: 12px; font-weight: 600; transition: 0.2s; text-decoration:none; display:inline-block; margin-left: 5px; }
        .btn-map:hover { background: #f0fdf4; color: #16a34a;}

        .btn-photo { border: 1px solid #8b5cf6; color: #8b5cf6; background: white; padding: 4px 12px; border-radius: 6px; font-size: 12px; font-weight: 600; transition: 0.2s; text-decoration:none; display:inline-block; margin-left: 5px; cursor: pointer; }
        .btn-photo:hover { background: #f5f3ff; color: #8b5cf6;}


        /* --- Timelines --- */
        .activity-item { display: flex; gap: 15px; margin-bottom: 18px; }
        .activity-item:last-child { margin-bottom: 0; }
        .activity-icon {
            width: 32px; height: 32px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 14px; color: white; flex-shrink: 0;
            z-index: 2; position: relative;
        }
        .activity-content p { margin: 0; font-size: 13px; color: var(--text-dark); font-weight: 500; line-height: 1.4;}
        .activity-content span { font-size: 11px; color: var(--text-muted); }

        .schedule-item { display: flex; gap: 15px; margin-bottom: 18px; position: relative;}
        .schedule-item:last-child { margin-bottom: 0; }
        .schedule-time { width: 60px; font-size: 12px; font-weight: 600; color: var(--text-dark); text-align: right; flex-shrink: 0;}
        .schedule-dot { width: 10px; height: 10px; border-radius: 50%; margin-top: 5px; position: relative; z-index: 2;}
        .schedule-line { position: absolute; left: 80px; top: 15px; bottom: -25px; width: 2px; background-color: #e2e8f0; z-index: 1;}
        .schedule-item:last-child .schedule-line { display: none; }
        .schedule-content h6 { margin: 0 0 2px 0; font-size: 13px; font-weight: 600; color: var(--text-dark); }
        .schedule-content span { font-size: 11.5px; color: var(--text-muted); }

        /* --- Quick Actions --- */
        .quick-action-box {
            text-align: center; padding: 20px 10px; border-radius: 12px; border: 1px solid #f1f5f9; transition: 0.2s; cursor: pointer; background: #f8fafc; height: 100%; display: flex; flex-direction: column; justify-content: center; align-items: center;
        }
        .quick-action-box:hover { border-color: #cbd5e1; background: white; box-shadow: 0 4px 10px rgba(0,0,0,0.03);}
        .quick-action-box i { font-size: 24px; margin-bottom: 10px; display: block; }
        .quick-action-box h6 { font-size: 13px; font-weight: 600; margin: 0 0 4px 0;}
        .quick-action-box span { font-size: 11px; color: var(--text-muted); }

        /* Donut Chart Container */
        .chart-wrapper { position: relative; height: 220px; width: 100%; display: flex; justify-content: center; }
        .chart-center-text { position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); text-align: center; }
        .chart-center-text h3 { margin: 0; font-weight: 800; font-size: 26px; color: #0f172a;}
        .chart-center-text span { font-size: 12px; color: var(--text-muted); font-weight: 500;}

        /* Modal Image Styling */
        #complaintPhotoImg {
            max-height: 400px;
            object-fit: contain;
            width: 100%;
            border-radius: 8px;
        }

    </style>
</head>
<body>

<div class="wrapper">

    <aside class="sidebar">
        <div class="logo-container">
            <i class="bi bi-bank logo-icon"></i>
            <div class="logo-text">
                <h5>Smart Civic</h5>
                <span>Problem Reporting System</span>
            </div>
        </div>

        <ul class="sidebar-nav">
            <li class="nav-item">
                <a href="#" class="nav-link active">
                    <i class="bi bi-house-door"></i> Dashboard
                </a>
            </li>
            <li class="nav-item">
                <a href="Tech-Task.jsp" class="nav-link">
                    <i class="bi bi-clipboard-check"></i> My Tasks
                </a>
            </li>
            <li class="nav-item">
                <a href="Tech-Upload-Resolution.jsp" class="nav-link">
                    <i class="bi bi-cloud-arrow-up"></i> Upload Resolution
                </a>
            </li>
            <li class="nav-item">
                <a href="Tech-Profile.jsp" class="nav-link">
                    <i class="bi bi-person"></i> Profile
                </a>
            </li>
            <li class="nav-item mt-2">
                <a href="logout.jsp" class="nav-link">
                    <i class="bi bi-box-arrow-right"></i> Logout
                </a>
            </li>
        </ul>

        <div class="tech-info-card">
            <div class="tech-info-item">
                <i class="bi bi-person-badge"></i>
                <div>
                    <span>Technician ID</span>
                    <h6>TECH-<%= techId %></h6>
                </div>
            </div>
            <div class="tech-info-item">
                <i class="bi bi-diagram-3"></i>
                <div>
                    <span>Department</span>
                    <h6><%= techDept %></h6>
                </div>
            </div>
            <div class="tech-info-item">
                <i class="bi bi-telephone"></i>
                <div>
                    <span>Contact</span>
                    <h6>On File</h6>
                </div>
            </div>
        </div>
    </aside>

    <main class="main-content">

        <header class="top-header">
            <div class="header-title-section">
                <i class="bi bi-list fs-3 text-muted" style="cursor: pointer;"></i>
                <div class="header-title">
                    <h4>Welcome, <%= techUser %> 👋</h4>
                    <p>Here's your work overview for today.</p>
                </div>
            </div>

            <div class="user-profile">
                <div class="position-relative">
                    <i class="bi bi-bell fs-5 text-muted"></i>
                    <span class="position-absolute top-0 start-100 translate-middle badge rounded-pill bg-danger" style="font-size: 9px;"><%= pendingCount %></span>
                </div>
                <div class="d-flex align-items-center gap-2 ms-2">
                    <img src="https://ui-avatars.com/api/?name=<%= java.net.URLEncoder.encode(techUser, "UTF-8") %>&background=0D8ABC&color=fff" alt="<%= techUser %>">
                    <div class="admin-text">
                        <h6><%= techUser %></h6>
                        <small>Technician</small>
                    </div>
                    <i class="bi bi-chevron-down ms-1 text-muted" style="font-size:12px;"></i>
                </div>
            </div>
        </header>

        <% if(!dbError.isEmpty()) { %>
        <div class="alert alert-danger"><%= dbError %></div>
        <% } %>

        <div class="row g-4 mb-4">
            <div class="col-lg-3 col-md-6">
                <div class="ui-card">
                    <div class="kpi-container">
                        <div class="kpi-icon" style="background-color: #3b82f6;"><i class="bi bi-clipboard-data"></i></div>
                        <div class="kpi-details">
                            <h6>Total Assigned Tasks</h6>
                            <h2><%= totalAssigned %></h2>
                            <span>All tasks assigned to you</span>
                        </div>
                    </div>
                </div>
            </div>
            <div class="col-lg-3 col-md-6">
                <div class="ui-card">
                    <div class="kpi-container">
                        <div class="kpi-icon" style="background-color: #f59e0b;"><i class="bi bi-hourglass-split"></i></div>
                        <div class="kpi-details">
                            <h6>Pending Tasks</h6>
                            <h2><%= pendingCount %></h2>
                            <span>Awaiting action</span>
                        </div>
                    </div>
                </div>
            </div>
            <div class="col-lg-3 col-md-6">
                <div class="ui-card">
                    <div class="kpi-container">
                        <div class="kpi-icon" style="background-color: #2563eb;"><i class="bi bi-tools"></i></div>
                        <div class="kpi-details">
                            <h6>In Progress</h6>
                            <h2><%= progressCount %></h2>
                            <span>Work in progress</span>
                        </div>
                    </div>
                </div>
            </div>
            <div class="col-lg-3 col-md-6">
                <div class="ui-card">
                    <div class="kpi-container">
                        <div class="kpi-icon" style="background-color: #16a34a;"><i class="bi bi-check-circle"></i></div>
                        <div class="kpi-details">
                            <h6>Completed Tasks</h6>
                            <h2><%= completedCount %></h2>
                            <span>Successfully resolved</span>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="row g-4 align-items-stretch flex-grow-1">
            <div class="col-lg-8 d-flex flex-column">
                <div class="ui-card mb-4">
                    <div class="card-header-flex">
                        <h5 class="card-title">My Assigned Tasks</h5>
                        <button class="btn btn-sm btn-outline-secondary" onclick="window.location.href='Tech-Task.jsp'">View All</button>
                    </div>
                    <div class="table-responsive">
                        <table class="table table-borderless">
                            <thead>
                            <tr>
                                <th>ID</th>
                                <th>Problem</th>
                                <th>Location</th>
                                <th>Status</th>
                                <th>Action</th>
                            </tr>
                            </thead>
                            <tbody>
                            <%
                                for(Map<String, String> t : myTasks) {
                                    String st = t.get("status");
                                    String badgeClass = "badge-pending";
                                    if(st.equalsIgnoreCase("In Progress")) badgeClass = "badge-progress";
                                    else if(st.equalsIgnoreCase("Resolved")) badgeClass = "badge-completed";

                                    // Make location URL safe for Google Maps
                                    String encodedLocation = java.net.URLEncoder.encode(t.get("loc"), "UTF-8");
                            %>
                            <tr>
                                <td class="text-muted fw-bold">#<%= t.get("id") %></td>
                                <td><%= t.get("prob") %></td>
                                <td><%= t.get("loc") %></td>
                                <td><span class="status-badge <%= badgeClass %>"><%= st %></span></td>
                                <td>
                                    <!-- HIDDEN INPUT TO STORE BASE64 SAFELY -->
                                    <input type="hidden" id="photo_data_<%= t.get("id") %>" value="<%= t.get("photo") %>">

                                    <a href="Tech-Upload-Resolution.jsp?taskId=<%= t.get("id") %>" class="btn-update"><i class="bi bi-pencil-square"></i> Update</a>

                                    <!-- Map Integration Button -->
                                    <a href="https://www.google.com/maps/search/?api=1&query=<%= encodedLocation %>" target="_blank" class="btn-map" title="Get Directions">
                                        <i class="bi bi-geo-alt-fill"></i> Map
                                    </a>

                                    <!-- View Photo Button (Triggers JS using ID) -->
                                    <button class="btn-photo" title="View Problem Photo" onclick="showPhotoModal('<%= t.get("id") %>')">
                                        <i class="bi bi-image"></i> Photo
                                    </button>
                                </td>
                            </tr>
                            <% } if(myTasks.isEmpty()) { %>
                            <tr><td colspan="5" class="text-center text-muted py-4">You currently have no tasks assigned.</td></tr>
                            <% } %>
                            </tbody>
                        </table>
                    </div>
                    <div class="mt-2 pt-3 border-top mt-auto">
                        <a href="Tech-Task.jsp" class="text-decoration-none fw-semibold" style="color: #2563eb; font-size:13px;"><i class="bi bi-box-arrow-up-right me-1"></i> View all my tasks</a>
                    </div>
                </div>

                <div class="ui-card flex-grow-1">
                    <h5 class="card-title mb-4">Recent Activity (Placeholder)</h5>

                    <div class="activity-item">
                        <div class="activity-icon" style="background-color: #2563eb;"><i class="bi bi-check-lg"></i></div>
                        <div class="activity-content">
                            <p>You marked a task as In Progress</p>
                            <span>Recently</span>
                        </div>
                    </div>

                    <div class="activity-item">
                        <div class="activity-icon" style="background-color: #16a34a;"><i class="bi bi-upload"></i></div>
                        <div class="activity-content">
                            <p>You uploaded a resolution</p>
                            <span>Recently</span>
                        </div>
                    </div>
                </div>
            </div>

            <div class="col-lg-4 d-flex flex-column">

                <div class="ui-card mb-4">
                    <h5 class="card-title mb-4">Task Status Overview</h5>
                    <div class="chart-wrapper">
                        <canvas id="statusChart"></canvas>
                        <div class="chart-center-text">
                            <h3><%= totalAssigned %></h3>
                            <span>Total</span>
                        </div>
                    </div>
                    <div class="d-flex justify-content-center gap-4 mt-3 pt-3 border-top mt-auto">
                        <div style="font-size: 12px; font-weight: 500; color:#334155;"><span style="display:inline-block; width:8px; height:8px; border-radius:50%; background:#2563eb; margin-right:5px;"></span>In Progress (<%= progressCount %>)</div>
                        <div style="font-size: 12px; font-weight: 500; color:#334155;"><span style="display:inline-block; width:8px; height:8px; border-radius:50%; background:#f59e0b; margin-right:5px;"></span>Pending (<%= pendingCount %>)</div>
                        <div style="font-size: 12px; font-weight: 500; color:#334155;"><span style="display:inline-block; width:8px; height:8px; border-radius:50%; background:#16a34a; margin-right:5px;"></span>Completed (<%= completedCount %>)</div>
                    </div>
                </div>

                <div class="ui-card mb-4">
                    <h5 class="card-title mb-3">Quick Actions</h5>
                    <div class="row g-3 h-100">
                        <div class="col-4">
                            <div class="quick-action-box" onclick="window.location.href='Tech-Task.jsp'">
                                <i class="bi bi-clipboard2-check text-success"></i>
                                <h6>Update Status</h6>
                            </div>
                        </div>
                        <div class="col-4">
                            <div class="quick-action-box" onclick="window.location.href='Tech-Upload-Resolution.jsp'">
                                <i class="bi bi-cloud-arrow-up text-primary"></i>
                                <h6>Upload Fix</h6>
                            </div>
                        </div>
                        <div class="col-4">
                            <div class="quick-action-box" onclick="window.location.href='Tech-Task.jsp'">
                                <i class="bi bi-geo-alt text-purple" style="color: #8b5cf6;"></i>
                                <h6>View Tasks</h6>
                            </div>
                        </div>
                    </div>
                </div>

            </div>
        </div>

    </main>
</div>

<!-- =========================================================
     PHOTO MODAL
========================================================= -->
<div class="modal fade" id="photoModal" tabindex="-1" aria-labelledby="photoModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content">
            <div class="modal-header border-bottom-0 pb-0">
                <h5 class="modal-title fw-bold" id="photoModalLabel">Problem Reference Photo</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body text-center pt-2">
                <p class="text-muted small mb-3">Complaint ID: <span id="modalComplaintId" class="fw-bold text-dark"></span></p>

                <div id="photoContainer" class="bg-light d-flex align-items-center justify-content-center border rounded" style="min-height: 250px;">
                </div>
            </div>
            <div class="modal-footer border-top-0 pt-0">
                <button type="button" class="btn btn-secondary px-4" data-bs-dismiss="modal">Close</button>
            </div>
        </div>
    </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script>

    function showPhotoModal(compId){

        document.getElementById(
            "modalComplaintId"
        ).innerText =
            "#" + compId;


        const container =
            document.getElementById(
                "photoContainer"
            );


        const photoInput =
            document.getElementById(
                "photo_data_" + compId
            );


        if(photoInput == null){

            container.innerHTML =
                "<div class='text-danger'>" +
                "Photo not found" +
                "</div>";

            return;
        }


        let photoData =
            photoInput.value;


        if(photoData == null ||
            photoData.trim() == ""){

            container.innerHTML =
                "<div class='text-muted'>" +
                "<i class='bi bi-image fs-1'></i>" +
                "<p>No image available</p>" +
                "</div>";
        }
        else{

            let imgSrc = "";


            if(photoData.startsWith("data:image")){

                imgSrc = photoData;
            }
            else{

                imgSrc =
                    "data:image/jpeg;base64," +
                    photoData;
            }


            container.innerHTML =

                "<img " +

                "src='" + imgSrc + "' " +

                "class='img-fluid rounded' " +

                "style='max-height:400px;' " +

                "onerror=\"this.parentElement.innerHTML='<div class=\\'text-danger\\'><i class=\\'bi bi-image-fill fs-1\\'></i><br>Image is missing or corrupted.</div>'\">" ;
        }


        let modal =
            new bootstrap.Modal(
                document.getElementById(
                    "photoModal"
                )
            );

        modal.show();
    }

    document.addEventListener("DOMContentLoaded", function() {
        const ctx = document.getElementById('statusChart').getContext('2d');
        new Chart(ctx, {
            type: 'doughnut',
            data: {
                labels: ['In Progress', 'Pending', 'Completed'],
                datasets: [{
                    // Passing dynamic counts from JSP
                    data: [<%= progressCount %>, <%= pendingCount %>, <%= completedCount %>],
                    backgroundColor: [
                        '#2563eb', // Blue
                        '#f59e0b', // Orange
                        '#16a34a'  // Green
                    ],
                    borderWidth: 2,
                    borderColor: '#ffffff',
                    hoverOffset: 4
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                cutout: '75%',
                plugins: {
                    legend: { display: false },
                    tooltip: {
                        callbacks: {
                            label: function(context) {
                                return ' ' + context.label + ': ' + context.raw;
                            }
                        }
                    }
                }
            }
        });
    });

</script>

</body>
</html>