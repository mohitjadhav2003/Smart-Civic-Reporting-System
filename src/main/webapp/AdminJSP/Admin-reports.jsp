<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="true" %>
<%@ page import="java.util.*, java.sql.*, utility.DBConnection" %>
<%
    // Fetch the admin user from the session, default to "Admin" if null
    String adminUser = (String) session.getAttribute("adminUser");
    if (adminUser == null) {
        adminUser = "Admin";
    }

    // =========================================================
    // --- BACKEND LOGIC: FETCH DATA FROM DATABASE FOR EXPORT ---
    // =========================================================
    List<String[]> reportData = new ArrayList<>();
    String[] reportHeaders = null;
    String requestedFormat = "";
    String reportTitle = "";
    String dbError = "";

    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String reportType = request.getParameter("reportType");
        requestedFormat = request.getParameter("format");

        Connection exportConn = null;
        Statement stmt = null;
        ResultSet rsExp = null;

        try {
            exportConn = DBConnection.getConnection();
            stmt = exportConn.createStatement();

            // 1. If User requests the 'User Directory'
            if ("users".equals(reportType)) {
                reportTitle = "System User Directory";
                reportHeaders = new String[]{"User ID", "Full Name", "Email", "Mobile", "Role", "Department"};
                rsExp = stmt.executeQuery("SELECT USER_ID, FULL_NAME, EMAIL, MOBILE, ROLE, DEPARTMENT FROM civicuser ORDER BY USER_ID DESC");
                while(rsExp.next()) {
                    reportData.add(new String[]{
                            rsExp.getString("USER_ID"),
                            rsExp.getString("FULL_NAME"),
                            rsExp.getString("EMAIL"),
                            rsExp.getString("MOBILE"),
                            rsExp.getString("ROLE"),
                            rsExp.getString("DEPARTMENT") != null ? rsExp.getString("DEPARTMENT") : "N/A"
                    });
                }
            }
            // 2. If User requests 'Complaints Data'
            else if ("complaints_all".equals(reportType) || "complaints_pending".equals(reportType)) {
                reportTitle = "complaints_all".equals(reportType) ? "All Complaints Master List" : "Pending Complaints List";
                reportHeaders = new String[]{"Complaint ID", "Category", "Description", "Location", "Status"};

                String q = "SELECT COMPLAINT_ID, PROBLEM_CATEGORY, DESCRIPTION, LOCATION_ADDRESS, STATUS FROM complaints";
                if("complaints_pending".equals(reportType)) {
                    q += " WHERE LOWER(STATUS) = 'pending'"; // Only fetch pending
                }
                q += " ORDER BY COMPLAINT_ID DESC";

                rsExp = stmt.executeQuery(q);
                while(rsExp.next()) {
                    reportData.add(new String[]{
                            rsExp.getString("COMPLAINT_ID"),
                            rsExp.getString("PROBLEM_CATEGORY"),
                            rsExp.getString("DESCRIPTION"),
                            rsExp.getString("LOCATION_ADDRESS"),
                            rsExp.getString("STATUS")
                    });
                }
            }
        } catch(Exception e) {
            dbError = "Error fetching data from database: " + e.getMessage();
            e.printStackTrace();
        } finally {
            if(rsExp != null) try{ rsExp.close(); }catch(Exception e){}
            if(stmt != null) try{ stmt.close(); }catch(Exception e){}
            if(exportConn != null) try{ exportConn.close(); }catch(Exception e){}
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Reports & Exports - Admin Panel</title>

    <!-- CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">

    <!-- ================= EXPORT LIBRARIES (NO JAR NEEDED!) ================= -->
    <!-- SheetJS for Excel and CSV Export -->
    <script src="https://cdn.jsdelivr.net/npm/xlsx/dist/xlsx.full.min.js"></script>
    <!-- jsPDF & AutoTable for PDF Export -->
    <script src="https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/jspdf-autotable/3.5.31/jspdf.plugin.autotable.min.js"></script>
    <!-- ===================================================================== -->

    <style>
        :root {
            --sidebar-bg: #0b1727;
            --main-bg: #f4f7fe;
            --primary-blue: #2563eb;
            --primary-green: #16a34a;
            --primary-orange: #ea580c;
            --primary-purple: #7c3aed;
            --primary-red: #dc2626;
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
        .card-title { font-weight: 700; font-size: 16px; margin: 0; color: #0f172a;}
        .card-subtitle { font-size: 13.5px; color: var(--text-muted); margin-bottom: 20px; }
        .stat-box { display: flex; align-items: center; gap: 15px; }
        .stat-icon { width: 55px; height: 55px; border-radius: 12px; display: flex; align-items: center; justify-content: center; font-size: 24px; }
        .stat-details h6 { margin: 0; color: var(--text-muted); font-size: 13px; font-weight: 600;}
        .stat-details h2 { margin: 2px 0; font-weight: 800; font-size: 26px; }
        .bg-blue-soft { background-color: #dbeafe; color: var(--primary-blue); }
        .bg-green-soft { background-color: #dcfce7; color: var(--primary-green); }
        .bg-purple-soft { background-color: #f3e8ff; color: var(--primary-purple); }
        .form-label { font-weight: 600; font-size: 13px; color: #334155; }
        .form-control, .form-select { border-radius: 8px; background-color: #f8fafc; border-color: #e2e8f0; font-size: 14px; padding: 10px 15px;}
        .form-control:focus, .form-select:focus { background-color: white; border-color: var(--primary-blue); box-shadow: 0 0 0 3px rgba(37,99,235,0.1); }
        .format-selector { display: flex; gap: 15px; margin-top: 5px; }
        .format-radio { display: none; }
        .format-label { display: flex; align-items: center; gap: 8px; padding: 10px 20px; border: 1px solid #cbd5e1; border-radius: 8px; cursor: pointer; transition: 0.2s; font-weight: 600; font-size: 13.5px; color: #475569; background: white; }
        .format-radio:checked + .format-label { border-color: var(--primary-blue); background: #eff6ff; color: var(--primary-blue); }
        .btn-generate { background-color: var(--primary-blue); color: white; padding: 10px 25px; border-radius: 8px; font-weight: 600; border: none; transition: 0.2s;}
        .btn-generate:hover { background-color: #1d4ed8; }
        .table { margin-bottom: 0; font-size: 14px; }
        .table th { border-bottom: 2px solid #f1f5f9; color: var(--text-muted); font-weight: 600; padding: 15px 12px; text-transform: uppercase; font-size: 12px; letter-spacing: 0.5px;}
        .table td { vertical-align: middle; padding: 15px 12px; color: #334155; font-weight: 500; border-bottom: 1px solid #f8fafc;}
        .report-info h6 { margin: 0; font-size: 14.5px; font-weight: 600; color: #0f172a;}
        .report-info small { color: var(--text-muted); font-size: 12px; }
        .file-icon { width: 36px; height: 36px; border-radius: 8px; display:flex; align-items:center; justify-content:center; font-size:18px; }
        .icon-pdf { background-color: #fee2e2; color: #dc2626; }
        .icon-csv { background-color: #dbeafe; color: #2563eb; }
        .icon-xls { background-color: #dcfce7; color: #16a34a; }
        .btn-download { background: #f1f5f9; border: none; color: #475569; padding: 6px 12px; border-radius: 6px; transition: 0.2s; font-size: 13px; font-weight: 600;}
        .btn-download:hover { background: var(--primary-blue); color: white; }
        .pagination { margin: 0; }
        .page-link { border: none; color: #475569; font-size: 14px; font-weight: 500; border-radius: 6px; margin: 0 2px;}
        .page-item.active .page-link { background-color: var(--primary-blue); color: white; }
    </style>
</head>
<body>

<div class="wrapper">

    <!-- Sidebar -->
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
            <li class="nav-item"><a href="Admin-update-status.jsp" class="nav-link"><i class="bi bi-arrow-clockwise"></i> Update Status</a></li>
            <li class="nav-item"><a href="Admin-user-management.jsp" class="nav-link"><i class="bi bi-person-gear"></i> User Management</a></li>
            <li class="nav-item"><a href="Admin-complaint-categories.jsp" class="nav-link"><i class="bi bi-grid"></i> Complaint Categories</a></li>
            <li class="nav-item"><a href="Admin-analytics.jsp" class="nav-link"><i class="bi bi-bar-chart"></i> Analytics</a></li>
            <li class="nav-item"><a href="Admin-reports.jsp" class="nav-link active"><i class="bi bi-file-earmark-bar-graph"></i> Reports</a></li>
            <li class="nav-item mt-4"><a href="Admin-settings.jsp" class="nav-link"><i class="bi bi-gear"></i> Settings</a></li>
        </ul>

        <div class="logout-container">
            <a href="../logout.jsp" class="logout-btn"><i class="bi bi-box-arrow-right"></i> Logout</a>
        </div>
    </aside>

    <!-- Main Content -->
    <main class="main-content">
        <header class="top-header">
            <div class="d-flex align-items-center gap-3">
                <i class="bi bi-list fs-3" style="cursor: pointer;"></i>
                <h4 class="m-0 fw-bold">Custom Reports & Exports</h4>
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

        <% if(!dbError.isEmpty()) { %>
        <div class="alert alert-danger shadow-sm border-0"><i class="bi bi-exclamation-triangle-fill me-2 fs-5"></i><strong>Error:</strong> <%= dbError %></div>
        <% } %>

        <div class="row g-4 mb-4">
            <div class="col-xl-4 col-md-6"><div class="admin-card stat-box py-3"><div class="stat-icon bg-blue-soft"><i class="bi bi-cloud-download"></i></div><div class="stat-details"><h6>Total Reports Exported</h6><h2>342</h2></div></div></div>
            <div class="col-xl-4 col-md-6"><div class="admin-card stat-box py-3"><div class="stat-icon bg-green-soft"><i class="bi bi-calendar2-check"></i></div><div class="stat-details"><h6>Automated Reports (Weekly)</h6><h2>4</h2></div></div></div>
            <div class="col-xl-4 col-md-6"><div class="admin-card stat-box py-3"><div class="stat-icon bg-purple-soft"><i class="bi bi-hdd-network"></i></div><div class="stat-details"><h6>System Storage Used</h6><h2>1.2 GB</h2></div></div></div>
        </div>

        <div class="row g-4 mb-4">
            <div class="col-xl-12">
                <div class="admin-card">
                    <h5 class="card-title">Generate Custom Report</h5>
                    <p class="card-subtitle">Select your parameters to build a custom data export.</p>

                    <!-- Alert Box -->
                    <div class="alert alert-success alert-dismissible fade show d-none" id="reportAlert" role="alert">
                        <i class="bi bi-check-circle-fill me-2"></i> Report generated successfully! Your download will begin shortly.
                        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                    </div>

                    <!-- REPORT GENERATION FORM (POST request to same page) -->
                    <form action="Admin-reports.jsp" method="POST" onsubmit="generateReport()" class="mt-2">
                        <div class="row g-4">
                            <div class="col-md-4">
                                <label class="form-label">Report Data Type <span class="text-danger">*</span></label>
                                <select class="form-select" name="reportType" required>
                                    <option value="" selected disabled>Select Data Module...</option>
                                    <option value="complaints_all">All Complaints Master List</option>
                                    <option value="complaints_pending">Pending/Overdue Complaints</option>
                                    <option value="users">User Directory & Roles</option>
                                </select>
                            </div>

                            <div class="col-md-3">
                                <label class="form-label">Date Range (From)</label>
                                <input type="date" name="dateFrom" class="form-control">
                            </div>

                            <div class="col-md-3">
                                <label class="form-label">Date Range (To)</label>
                                <input type="date" name="dateTo" class="form-control">
                            </div>

                            <div class="col-12">
                                <label class="form-label">Export Format <span class="text-danger">*</span></label>
                                <div class="format-selector">
                                    <input type="radio" name="format" id="fmtPdf" class="format-radio" value="pdf">
                                    <label for="fmtPdf" class="format-label"><i class="bi bi-file-earmark-pdf text-danger fs-5"></i> PDF Document</label>

                                    <input type="radio" name="format" id="fmtCsv" class="format-radio" value="csv" checked>
                                    <label for="fmtCsv" class="format-label"><i class="bi bi-filetype-csv text-primary fs-5"></i> CSV File</label>

                                    <input type="radio" name="format" id="fmtExcel" class="format-radio" value="excel">
                                    <label for="fmtExcel" class="format-label"><i class="bi bi-file-earmark-excel text-success fs-5"></i> Excel Sheet</label>
                                </div>
                            </div>

                            <div class="col-12">
                                <label class="form-label d-block">Additional Options</label>
                                <div class="form-check form-check-inline">
                                    <input class="form-check-input" type="checkbox" id="incCharts">
                                    <label class="form-check-label text-dark" for="incCharts">Include Summary Charts (PDF Only)</label>
                                </div>
                                <div class="form-check form-check-inline">
                                    <input class="form-check-input" type="checkbox" id="incNotes" checked>
                                    <label class="form-check-label text-dark" for="incNotes">Include Internal Admin Notes</label>
                                </div>
                            </div>

                            <div class="col-12 mt-4 pt-3 border-top">
                                <button type="submit" class="btn-generate" id="btnGenerate">
                                    <i class="bi bi-gear-fill me-2"></i> Build & Download Report
                                </button>
                                <button type="button" class="btn btn-light border ms-2">Save as Template</button>
                            </div>
                        </div>
                    </form>
                </div>
            </div>
        </div>

        <div class="row g-4 mb-4">
            <div class="col-xl-12">
                <div class="admin-card">
                    <div class="card-header-flex">
                        <h5 class="card-title">Recent Generated Reports</h5>
                        <div class="search-box" style="width: 250px;">
                            <i class="bi bi-search"></i>
                            <input type="text" class="form-control form-control-sm" placeholder="Search archive...">
                        </div>
                    </div>

                    <div class="table-responsive mt-2">
                        <table class="table table-hover align-middle">
                            <thead>
                            <tr>
                                <th style="width: 50px;">Format</th>
                                <th>Report Name & Details</th>
                                <th>Date Generated</th>
                                <th>Generated By</th>
                                <th>Size</th>
                                <th class="text-end">Action</th>
                            </tr>
                            </thead>
                            <tbody>
                            <tr>
                                <td><div class="file-icon icon-csv"><i class="bi bi-filetype-csv"></i></div></td>
                                <td>
                                    <div class="report-info">
                                        <h6>All Complaints Master List (May)</h6>
                                        <small>Data Range: 01 May 2024 - 20 May 2024</small>
                                    </div>
                                </td>
                                <td>Today, 10:45 AM</td>
                                <td><span class="text-dark fw-medium"><%= adminUser %></span></td>
                                <td>245 KB</td>
                                <td class="text-end"><button class="btn-download"><i class="bi bi-download me-1"></i> Download</button></td>
                            </tr>
                            <tr>
                                <td><div class="file-icon icon-pdf"><i class="bi bi-file-earmark-pdf"></i></div></td>
                                <td>
                                    <div class="report-info">
                                        <h6>Weekly Performance Summary</h6>
                                        <small>Automated System Report</small>
                                    </div>
                                </td>
                                <td>Yesterday, 08:00 AM</td>
                                <td><span class="text-muted"><i class="bi bi-robot"></i> System</span></td>
                                <td>1.2 MB</td>
                                <td class="text-end"><button class="btn-download"><i class="bi bi-download me-1"></i> Download</button></td>
                            </tr>
                            <tr>
                                <td><div class="file-icon icon-xls"><i class="bi bi-file-earmark-excel"></i></div></td>
                                <td>
                                    <div class="report-info">
                                        <h6>User Directory Backup</h6>
                                        <small>Full database export including roles.</small>
                                    </div>
                                </td>
                                <td>15 May 2024</td>
                                <td><span class="text-dark fw-medium">Vikram Patel</span></td>
                                <td>890 KB</td>
                                <td class="text-end"><button class="btn-download"><i class="bi bi-download me-1"></i> Download</button></td>
                            </tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </div>
    </main>
</div>

<!-- ========================================================================= -->
<!-- HIDDEN TABLE: Used to temporarily store the database data for the Library -->
<!-- ========================================================================= -->
<% if(reportHeaders != null && !reportData.isEmpty()) { %>
<table id="hiddenExportTable" class="d-none">
    <thead>
    <tr>
        <% for(String h : reportHeaders) { %> <th><%= h %></th> <% } %>
    </tr>
    </thead>
    <tbody>
    <% for(String[] row : reportData) { %>
    <tr>
        <% for(String cell : row) { %> <td><%= cell != null ? cell : "" %></td> <% } %>
    </tr>
    <% } %>
    </tbody>
</table>
<% } %>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>

<script>
    // 1. Loading UI change when form is submitted
    function generateReport() {
        const btn = document.getElementById('btnGenerate');
        btn.innerHTML = '<span class="spinner-border spinner-border-sm me-2" role="status"></span> Compiling Data...';
        // The form will natively submit to the backend.
    }

    // 2. Logic to execute AFTER the page reloads with the hidden Data Table
    document.addEventListener("DOMContentLoaded", function() {
        <% if(reportHeaders != null && !reportData.isEmpty()) { %>
        try {
            var format = '<%= requestedFormat %>';
            var title = '<%= reportTitle %>';
            var table = document.getElementById("hiddenExportTable");

            // --- EXCEL OR CSV EXPORT (Using SheetJS) ---
            if(format === 'excel' || format === 'csv') {
                var wb = XLSX.utils.table_to_book(table, {sheet: "Report Data"});
                var extension = format === 'excel' ? '.xlsx' : '.csv';
                var filename = title.replace(/\s+/g, '_') + extension;

                // Triggers the download
                XLSX.writeFile(wb, filename);
            }
            // --- PDF EXPORT (Using jsPDF & AutoTable) ---
            else if(format === 'pdf') {
                window.jsPDF = window.jspdf.jsPDF;
                var doc = new jsPDF('p', 'pt', 'a4'); // Portrait, points, A4

                doc.setFontSize(16);
                doc.text("Smart Civic - " + title, 14, 25);

                doc.autoTable({
                    html: '#hiddenExportTable',
                    startY: 35,
                    theme: 'striped',
                    headStyles: { fillColor: [37, 99, 235] } // Primary Blue
                });

                // Triggers the download
                doc.save(title.replace(/\s+/g, '_') + '.pdf');
            }

            // Show Success Alert on Screen
            var alertBox = document.getElementById('reportAlert');
            alertBox.classList.remove('d-none');
            window.scrollTo({ top: 0, behavior: 'smooth' });

            // Hide alert after 5 seconds
            setTimeout(() => { alertBox.classList.add('d-none'); }, 5000);

        } catch (err) {
            alert("Error building file. Make sure you are connected to the internet for the export libraries to work.");
            console.error(err);
        }
        <% } else if(reportHeaders != null && reportData.isEmpty()) { %>
        // If query ran but 0 results found
        alert("No data found in the database for the selected report parameters.");
        <% } %>
    });
</script>

</body>
</html>