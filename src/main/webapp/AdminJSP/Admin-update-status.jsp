<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="true" %>
<%@ page import="java.sql.*, java.util.*, utility.DBConnection, java.text.SimpleDateFormat" %>
<%
    // Fetch the admin user from the session, default to "Admin" if null
    String adminUser = (String) session.getAttribute("adminUser");
    if (adminUser == null) {
        adminUser = "Admin";
    }

    // =========================================================
    // --- BACKEND LOGIC FOR SEARCH & UPDATE ---
    // =========================================================
    String successMsg = "";
    String errorMsg = "";

    // 1. Handle Update Request (POST)
    if ("POST".equalsIgnoreCase(request.getMethod()) && request.getParameter("comp_id") != null) {
        String cId = request.getParameter("comp_id");
        String newStatus = request.getParameter("new_status");
        String newTech = request.getParameter("new_tech");

        Connection updateConn = null;
        try {
            updateConn = DBConnection.getConnection();
            PreparedStatement psUpdate = updateConn.prepareStatement("UPDATE complaints SET STATUS = ?, ASSIGNED_TO = ? WHERE COMPLAINT_ID = ?");
            psUpdate.setString(1, newStatus);
            psUpdate.setString(2, (newTech != null && !newTech.trim().isEmpty()) ? newTech : null);
            psUpdate.setString(3, cId);

            int rows = psUpdate.executeUpdate();
            if(rows > 0) {
                successMsg = "Status updated successfully! Users have been notified.";
            } else {
                errorMsg = "Failed to update complaint. ID not found.";
            }
            psUpdate.close();
        } catch (Exception e) {
            errorMsg = "Update Error: " + e.getMessage();
        } finally {
            if(updateConn != null) try{ updateConn.close(); }catch(Exception e){}
        }
    }

    // 2. Handle Search Request (GET/POST)
    String searchIdRaw = request.getParameter("searchId");
    String searchId = "";
    if (searchIdRaw != null && !searchIdRaw.trim().isEmpty()) {
        // Extract only numbers if user types "CMP-124"
        searchId = searchIdRaw.replaceAll("[^0-9]", "");
    }

    Map<String, String> ticket = new HashMap<>();
    List<Map<String, String>> techList = new ArrayList<>();

    Connection fetchConn = null;
    try {
        fetchConn = DBConnection.getConnection();

        // Fetch Technicians for Dropdown
        ResultSet rsTech = fetchConn.createStatement().executeQuery("SELECT USER_ID, FULL_NAME, DEPARTMENT FROM civicuser WHERE ROLE = 'Technician'");
        while(rsTech.next()) {
            Map<String, String> t = new HashMap<>();
            t.put("id", rsTech.getString("USER_ID"));
            t.put("name", rsTech.getString("FULL_NAME") + " (" + (rsTech.getString("DEPARTMENT")!=null ? rsTech.getString("DEPARTMENT") : "General") + ")");
            techList.add(t);
        }
        rsTech.close();

        // Fetch Searched Ticket Details
        if (!searchId.isEmpty()) {
            PreparedStatement psSearch = fetchConn.prepareStatement(
                    "SELECT c.*, u.FULL_NAME as CITIZEN_NAME FROM complaints c LEFT JOIN civicuser u ON c.CITIZEN_ID = u.USER_ID WHERE c.COMPLAINT_ID = ?"
            );
            psSearch.setString(1, searchId);
            ResultSet rsS = psSearch.executeQuery();

            if (rsS.next()) {
                ticket.put("id", rsS.getString("COMPLAINT_ID"));
                ticket.put("cat", rsS.getString("PROBLEM_CATEGORY"));
                ticket.put("status", rsS.getString("STATUS") != null ? rsS.getString("STATUS") : "Pending");
                ticket.put("citizen", rsS.getString("CITIZEN_NAME") != null ? rsS.getString("CITIZEN_NAME") : "Unknown User");
                ticket.put("location", rsS.getString("LOCATION_ADDRESS"));
                ticket.put("assigned", rsS.getString("ASSIGNED_TO"));
                ticket.put("desc", rsS.getString("DESCRIPTION"));

                Timestamp ts = rsS.getTimestamp("CREATED_AT");
                if (ts != null) {
                    ticket.put("date", new SimpleDateFormat("dd MMM yyyy, hh:mm a").format(ts));
                } else {
                    ticket.put("date", "Unknown Date");
                }
            } else if (errorMsg.isEmpty() && successMsg.isEmpty()){
                errorMsg = "No complaint found with ID: " + searchIdRaw;
            }
            rsS.close();
            psSearch.close();
        }
    } catch (Exception e) {
        errorMsg = "Database Error: " + e.getMessage();
    } finally {
        if(fetchConn != null) try{ fetchConn.close(); }catch(Exception e){}
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Update Status - Admin Panel</title>
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
        .sidebar { width: 260px; background-color: var(--sidebar-bg); color: white; padding: 20px 0; display: flex; flex-direction: column; position: fixed; height: 100vh; overflow-y: auto; }
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
        .card-title { font-weight: 700; font-size: 18px; margin: 0 0 20px 0; color: #0f172a;}

        .search-tool { display: flex; gap: 10px; margin-bottom: 30px; }
        .search-tool input { flex-grow: 1; padding: 12px 20px; border-radius: 8px; border: 1px solid #cbd5e1; background: #f8fafc; font-size: 15px;}
        .search-tool input:focus { background: white; border-color: var(--primary-blue); box-shadow: 0 0 0 3px rgba(37,99,235,0.1); outline: none;}
        .search-tool button { padding: 0 25px; border-radius: 8px; font-weight: 600; }

        .ticket-snapshot { background-color: #f8fafc; border: 1px solid #e2e8f0; border-radius: 10px; padding: 20px; margin-bottom: 30px;}
        .snapshot-grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 15px; }
        .snapshot-label { color: var(--text-muted); font-size: 12px; text-transform: uppercase; font-weight: 600; letter-spacing: 0.5px; margin-bottom: 5px;}
        .snapshot-value { color: #0f172a; font-weight: 600; font-size: 14.5px; margin: 0;}

        .status-badge { padding: 4px 10px; border-radius: 6px; font-size: 12px; font-weight: 600; display: inline-block;}
        .badge-resolved { background-color: #dcfce7; color: #16a34a; }
        .badge-progress { background-color: #ffedd5; color: #ea580c; }
        .badge-pending { background-color: #fee2e2; color: #dc2626; }

        .form-label { font-weight: 600; color: #334155; font-size: 14px; margin-bottom: 8px;}
        .form-select, .form-control { border-radius: 8px; padding: 12px 15px; border: 1px solid #cbd5e1; background-color: #f8fafc; font-size: 14.5px; }
        .form-select:focus, .form-control:focus { background-color: white; border-color: var(--primary-blue); box-shadow: 0 0 0 3px rgba(37,99,235,0.1); }
        .btn-update { background-color: var(--primary-blue); color: white; padding: 12px 30px; border-radius: 8px; font-weight: 600; border: none; width: 100%; transition: 0.2s;}
        .btn-update:hover { background-color: #1d4ed8; }

        .timeline { border-left: 2px solid #e2e8f0; margin-left: 15px; padding-left: 25px; position: relative; }
        .timeline-step { margin-bottom: 25px; position: relative; }
        .timeline-step:last-child { margin-bottom: 0; }
        .timeline-step::before { content: ''; position: absolute; left: -33px; top: 0; width: 14px; height: 14px; border-radius: 50%; background: white; border: 3px solid #cbd5e1; }
        .timeline-step.completed::before { background: var(--primary-green); border-color: #bbf7d0; box-shadow: 0 0 0 3px #dcfce7;}
        .timeline-step.active::before { background: var(--primary-blue); border-color: #bfdbfe; box-shadow: 0 0 0 3px #dbeafe; }
        .timeline-step h6 { font-weight: 700; margin: 0 0 4px 0; color: #0f172a; font-size: 14.5px;}
        .timeline-step p { margin: 0 0 6px 0; font-size: 13.5px; color: var(--text-muted); line-height: 1.5;}
        .timeline-date { font-size: 11.5px; color: #94a3b8; font-weight: 500; display: flex; align-items: center; gap: 5px;}
        .timeline-user { font-size: 12px; font-weight: 600; color: #475569; display: inline-flex; align-items: center; gap: 5px; background: #f1f5f9; padding: 2px 8px; border-radius: 4px; margin-bottom: 6px;}
    </style>
</head>
<body>

<div class="wrapper">

    <aside class="sidebar">
        <div class="logo-container">
            <i class="bi bi-bank2 logo-icon"></i>
            <div class="logo-text"><h5>Smart Civic</h5><span>Problem Reporting System</span></div>
        </div>

        <ul class="sidebar-nav">
            <li class="nav-item"><a href="admin-dashboard.jsp" class="nav-link"><i class="bi bi-house-door"></i> Dashboard</a></li>
            <li class="nav-item"><a href="Admin-total-users.jsp" class="nav-link"><i class="bi bi-people"></i> Total Users</a></li>
            <li class="nav-item"><a href="Admin-total-complaints.jsp" class="nav-link"><i class="bi bi-journal-text"></i> Total Complaints</a></li>
            <li class="nav-item"><a href="Admin-pending-complaints.jsp" class="nav-link"><i class="bi bi-hourglass-split"></i> Pending Complaints</a></li>
            <li class="nav-item"><a href="Admin-manage-complaints.jsp" class="nav-link"><i class="bi bi-card-checklist"></i> Manage Complaints</a></li>
            <li class="nav-item"><a href="Admin-update-status.jsp" class="nav-link active"><i class="bi bi-arrow-clockwise"></i> Update Status</a></li>
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
                <h4 class="m-0 fw-bold">Status Update Hub</h4>
            </div>

            <div class="user-profile">
                <div class="position-relative"><i class="bi bi-bell fs-5 text-muted"></i></div>
                <div class="d-flex align-items-center gap-2">
                    <img src="https://ui-avatars.com/api/?name=<%= java.net.URLEncoder.encode(adminUser, "UTF-8") %>&background=0D8ABC&color=fff" alt="<%= adminUser %>">
                    <div class="admin-text d-none d-md-block">
                        <h6><%= adminUser %></h6>
                        <small>Administrator</small>
                    </div>
                </div>
            </div>
        </header>

        <div class="row g-4">

            <div class="col-xl-7">
                <div class="admin-card">
                    <h5 class="card-title">Search Complaint</h5>

                    <!-- SERVER RESPONSE ALERTS -->
                    <% if(!successMsg.isEmpty()) { %>
                    <div class="alert alert-success alert-dismissible fade show mb-4"><i class="bi bi-check-circle-fill me-2"></i> <%= successMsg %><button type="button" class="btn-close" data-bs-dismiss="alert"></button></div>
                    <% } %>
                    <% if(!errorMsg.isEmpty()) { %>
                    <div class="alert alert-danger alert-dismissible fade show mb-4"><i class="bi bi-exclamation-triangle-fill me-2"></i> <%= errorMsg %><button type="button" class="btn-close" data-bs-dismiss="alert"></button></div>
                    <% } %>

                    <!-- SEARCH FORM -->
                    <form method="GET" action="Admin-update-status.jsp">
                        <div class="search-tool">
                            <input type="text" name="searchId" placeholder="Enter Complaint ID (e.g., CMP-124)" value="<%= searchIdRaw != null ? searchIdRaw : "" %>" required>
                            <button class="btn btn-dark" type="submit"><i class="bi bi-search me-2"></i> Find</button>
                        </div>
                    </form>

                    <% if(!ticket.isEmpty()) {
                        String st = ticket.get("status");
                        String badgeClass = "badge-pending";
                        if("Resolved".equalsIgnoreCase(st)) badgeClass = "badge-resolved";
                        else if("In Progress".equalsIgnoreCase(st)) badgeClass = "badge-progress";
                    %>
                    <h5 class="card-title mt-4 border-top pt-4">Ticket Details: #CMP-<%= ticket.get("id") %></h5>

                    <div class="ticket-snapshot">
                        <div class="snapshot-grid">
                            <div>
                                <div class="snapshot-label">Subject</div>
                                <p class="snapshot-value"><%= ticket.get("cat") %></p>
                            </div>
                            <div>
                                <div class="snapshot-label">Current Status</div>
                                <span class="status-badge <%= badgeClass %>"><%= st %></span>
                            </div>
                            <div>
                                <div class="snapshot-label">Reported By</div>
                                <p class="snapshot-value"><i class="bi bi-person me-1 text-muted"></i> <%= ticket.get("citizen") %></p>
                            </div>
                            <div>
                                <div class="snapshot-label">Location</div>
                                <p class="snapshot-value"><i class="bi bi-geo-alt me-1 text-muted"></i> <%= ticket.get("location") %></p>
                            </div>
                        </div>
                    </div>

                    <!-- UPDATE FORM -->
                    <form method="POST" action="Admin-update-status.jsp?searchId=<%= ticket.get("id") %>">
                        <input type="hidden" name="comp_id" value="<%= ticket.get("id") %>">

                        <div class="row g-4 mb-4">
                            <div class="col-md-6">
                                <label class="form-label">Update Status To <span class="text-danger">*</span></label>
                                <select name="new_status" class="form-select" required>
                                    <option value="Pending" <%= "Pending".equalsIgnoreCase(st) ? "selected" : "" %>>Pending</option>
                                    <option value="In Progress" <%= "In Progress".equalsIgnoreCase(st) ? "selected" : "" %>>In Progress</option>
                                    <option value="Resolved" <%= "Resolved".equalsIgnoreCase(st) ? "selected" : "" %>>Resolved</option>
                                    <option value="Rejected">Rejected / Invalid</option>
                                </select>
                            </div>
                            <div class="col-md-6">
                                <label class="form-label">Assign Technician</label>
                                <select name="new_tech" class="form-select">
                                    <option value="">-- Unassigned --</option>
                                    <% for(Map<String, String> t : techList) { %>
                                    <option value="<%= t.get("id") %>" <%= t.get("id").equals(ticket.get("assigned")) ? "selected" : "" %>>
                                        <%= t.get("name") %>
                                    </option>
                                    <% } %>
                                </select>
                            </div>
                            <div class="col-12">
                                <label class="form-label">Internal Notes / Public Response</label>
                                <textarea class="form-control" rows="4" placeholder="Enter details about the resolution, delays, or instructions for the technician..."><%= ticket.get("desc") != null ? ticket.get("desc") : "" %></textarea>
                            </div>
                            <div class="col-12">
                                <div class="form-check">
                                    <input class="form-check-input" type="checkbox" id="notifyUser" checked style="cursor: pointer; border-color: #cbd5e1;">
                                    <label class="form-check-label text-dark fw-medium" for="notifyUser" style="cursor: pointer; font-size: 14px;">
                                        Send email/SMS notification to the user about this update.
                                    </label>
                                </div>
                            </div>
                        </div>

                        <button type="submit" class="btn-update">
                            <i class="bi bi-save me-2"></i> Save Status Update
                        </button>
                    </form>
                    <% } else if(searchIdRaw == null || searchIdRaw.isEmpty()) { %>
                    <div class="text-center py-5 text-muted">
                        <i class="bi bi-search" style="font-size: 30px;"></i>
                        <p class="mt-3">Enter a Complaint ID above to view and update its details.</p>
                    </div>
                    <% } %>

                </div>
            </div>

            <!-- TIMELINE SECTION (Visible only if ticket is found) -->
            <div class="col-xl-5">
                <div class="admin-card">
                    <h5 class="card-title border-bottom pb-3 mb-4">
                        Lifecycle Log <%= ticket.containsKey("id") ? ": #CMP-" + ticket.get("id") : "" %>
                    </h5>

                    <% if(!ticket.isEmpty()) { %>
                    <div class="timeline">
                        <div class="timeline-step active">
                            <div class="timeline-user"><i class="bi bi-person-gear"></i> Admin (You)</div>
                            <h6>Current Status: <%= ticket.get("status") %></h6>
                            <p>Ticket is currently marked as <%= ticket.get("status") %> in the system.</p>
                            <span class="timeline-date"><i class="bi bi-clock"></i> Just Now</span>
                        </div>

                        <div class="timeline-step completed">
                            <div class="timeline-user"><i class="bi bi-person"></i> <%= ticket.get("citizen") %></div>
                            <h6>Complaint Filed</h6>
                            <p><%= ticket.get("desc") %></p>
                            <span class="timeline-date"><i class="bi bi-clock"></i> <%= ticket.get("date") %></span>
                        </div>
                    </div>
                    <% } else { %>
                    <p class="text-muted text-center py-4">Search for a complaint to view its history.</p>
                    <% } %>
                </div>
            </div>

        </div>
    </main>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>

<script>
    // Optional: Auto-hide alerts after a few seconds
    document.addEventListener("DOMContentLoaded", function() {
        setTimeout(function() {
            let alerts = document.querySelectorAll('.alert');
            alerts.forEach(alert => {
                let bsAlert = new bootstrap.Alert(alert);
                bsAlert.close();
            });
        }, 5000);
    });
</script>

</body>
</html>