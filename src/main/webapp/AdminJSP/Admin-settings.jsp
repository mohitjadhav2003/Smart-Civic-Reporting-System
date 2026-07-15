<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="true" %>
<%
  // Fetch the admin user from the session, default to "Admin" if null
  String adminUser = (String) session.getAttribute("adminUser");
  if (adminUser == null) {
    adminUser = "Admin";
  }
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>System Settings - Admin Panel</title>
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
      --primary-red: #dc2626;
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
      z-index: 1000;
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

    /* Cards & Layout */
    .admin-card {
      background-color: white;
      border-radius: 12px;
      padding: 24px;
      border: none;
      box-shadow: 0 2px 10px rgba(0,0,0,0.02);
      height: 100%;
    }

    .card-title { font-weight: 700; font-size: 18px; margin: 0; color: #0f172a;}
    .card-subtitle { font-size: 13.5px; color: var(--text-muted); margin-top: 5px; }

    /* Settings Vertical Menu */
    .settings-menu { display: flex; flex-direction: column; gap: 8px; }
    .settings-link {
      display: flex; align-items: center; gap: 12px;
      padding: 14px 20px; border-radius: 8px;
      color: #475569; font-weight: 600; font-size: 14.5px;
      text-decoration: none; background: #f8fafc;
      transition: 0.2s; border: 1px solid transparent;
      cursor: pointer;
    }
    .settings-link i { font-size: 18px; }
    .settings-link:hover { background: #f1f5f9; color: var(--primary-blue); }
    .settings-link.active {
      background: #eff6ff; color: var(--primary-blue);
      border-color: #bfdbfe;
    }

    /* Form Styling */
    .form-label { font-weight: 600; font-size: 13px; color: #334155; }
    .form-control, .form-select { border-radius: 8px; background-color: #f8fafc; border-color: #e2e8f0; font-size: 14px; padding: 10px 15px;}
    .form-control:focus, .form-select:focus { background-color: white; border-color: var(--primary-blue); box-shadow: 0 0 0 3px rgba(37,99,235,0.1); }

    .btn-save { background-color: var(--primary-blue); color: white; padding: 10px 25px; border-radius: 8px; font-weight: 600; border: none; transition: 0.2s;}
    .btn-save:hover { background-color: #1d4ed8; }

    .btn-danger-soft { background: #fee2e2; border: none; color: #dc2626; padding: 10px 25px; border-radius: 8px; font-weight: 600; transition: 0.2s;}
    .btn-danger-soft:hover { background: #f87171; color: white; }

    /* Avatar Upload */
    .avatar-upload { display: flex; align-items: center; gap: 20px; margin-bottom: 25px; }
    .avatar-upload img { width: 80px; height: 80px; border-radius: 50%; object-fit: cover; border: 3px solid #f8fafc; box-shadow: 0 4px 10px rgba(0,0,0,0.05); }
    .btn-outline-upload { border: 1px solid #cbd5e1; background: white; color: #475569; padding: 6px 15px; border-radius: 6px; font-size: 13px; font-weight: 600;}
    .btn-outline-upload:hover { background: #f1f5f9; }

    /* Custom Switches */
    .form-switch .form-check-input { width: 40px; height: 20px; cursor: pointer; border-color: #cbd5e1; }
    .form-switch .form-check-input:checked { background-color: var(--primary-blue); border-color: var(--primary-blue); }
    .switch-label h6 { margin: 0; font-size: 14px; font-weight: 600; color: #0f172a;}
    .switch-label small { color: var(--text-muted); font-size: 12px; }

    /* Divider */
    .settings-divider { height: 1px; background-color: #f1f5f9; margin: 30px 0; }

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
      <li class="nav-item"><a href="Admin-complaint-categories.jsp" class="nav-link"><i class="bi bi-grid"></i> Complaint Categories</a></li>
      <li class="nav-item"><a href="Admin-analytics.jsp" class="nav-link"><i class="bi bi-bar-chart"></i> Analytics</a></li>
      <li class="nav-item"><a href="Admin-reports.jsp" class="nav-link"><i class="bi bi-file-earmark-bar-graph"></i> Reports</a></li>
      <li class="nav-item mt-4"><a href="Admin-settings.jsp" class="nav-link active"><i class="bi bi-gear"></i> Settings</a></li>
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
        <h4 class="m-0 fw-bold">System Settings & Configuration</h4>
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

    <div class="alert alert-success alert-dismissible fade show d-none mb-4" id="settingsAlert" role="alert">
      <i class="bi bi-check-circle-fill me-2"></i> Settings saved successfully!
      <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
    </div>

    <div class="row g-4">

      <div class="col-xl-3 col-lg-4">
        <div class="admin-card p-3">
          <div class="settings-menu nav flex-column nav-pills" id="v-pills-tab" role="tablist" aria-orientation="vertical">

            <button class="settings-link active" id="v-pills-general-tab" data-bs-toggle="pill" data-bs-target="#v-pills-general" type="button" role="tab">
              <i class="bi bi-sliders"></i> General System
            </button>

            <button class="settings-link" id="v-pills-profile-tab" data-bs-toggle="pill" data-bs-target="#v-pills-profile" type="button" role="tab">
              <i class="bi bi-person-badge"></i> Admin Profile
            </button>

            <button class="settings-link" id="v-pills-security-tab" data-bs-toggle="pill" data-bs-target="#v-pills-security" type="button" role="tab">
              <i class="bi bi-shield-lock"></i> Security & Passwords
            </button>

            <button class="settings-link" id="v-pills-notifications-tab" data-bs-toggle="pill" data-bs-target="#v-pills-notifications" type="button" role="tab">
              <i class="bi bi-bell"></i> Notification Alerts
            </button>

          </div>
        </div>
      </div>

      <div class="col-xl-9 col-lg-8">
        <div class="admin-card">
          <div class="tab-content" id="v-pills-tabContent">

            <div class="tab-pane fade show active" id="v-pills-general" role="tabpanel">
              <h4 class="card-title">General Settings</h4>
              <p class="card-subtitle">Manage core system information and global behaviors.</p>
              <div class="settings-divider"></div>

              <form onsubmit="saveSettings(event)">
                <div class="row g-4">
                  <div class="col-md-6">
                    <label class="form-label">System Platform Name</label>
                    <input type="text" class="form-control" value="Smart Civic PRS" required>
                  </div>
                  <div class="col-md-6">
                    <label class="form-label">City / Jurisdiction Name</label>
                    <input type="text" class="form-control" value="Metropolis City Council" required>
                  </div>
                  <div class="col-md-6">
                    <label class="form-label">Public Support Email</label>
                    <input type="email" class="form-control" value="support@smartcivic.gov" required>
                  </div>
                  <div class="col-md-6">
                    <label class="form-label">Public Support Helpline (Toll-Free)</label>
                    <input type="text" class="form-control" value="1800-123-4567" required>
                  </div>
                </div>

                <div class="settings-divider"></div>
                <h5 class="fw-bold mb-3" style="font-size: 15px;">System Status</h5>

                <div class="d-flex align-items-center justify-content-between bg-light p-3 border rounded-3">
                  <div class="switch-label">
                    <h6>Maintenance Mode</h6>
                    <small>Turn this on to block citizens from logging in while you perform system updates.</small>
                  </div>
                  <div class="form-check form-switch m-0 p-0 d-flex align-items-center">
                    <input class="form-check-input m-0" type="checkbox" role="switch" id="maintenanceMode">
                  </div>
                </div>

                <div class="mt-4 pt-2 text-end">
                  <button type="submit" class="btn-save"><i class="bi bi-check2-circle me-1"></i> Save Changes</button>
                </div>
              </form>
            </div>

            <div class="tab-pane fade" id="v-pills-profile" role="tabpanel">
              <h4 class="card-title">My Profile</h4>
              <p class="card-subtitle">Update your administrative account details.</p>
              <div class="settings-divider"></div>

              <form onsubmit="saveSettings(event)">
                <div class="avatar-upload">
                  <img src="https://ui-avatars.com/api/?name=<%= java.net.URLEncoder.encode(adminUser, "UTF-8") %>&background=0D8ABC&color=fff" alt="Avatar">
                  <div>
                    <button type="button" class="btn-outline-upload me-2"><i class="bi bi-camera me-1"></i> Change Photo</button>
                    <button type="button" class="btn btn-link text-danger text-decoration-none p-0 fs-6">Remove</button>
                    <div class="text-muted small mt-1">JPG, GIF or PNG. Max size of 800K</div>
                  </div>
                </div>

                <div class="row g-4">
                  <div class="col-md-6">
                    <label class="form-label">Full Name</label>
                    <input type="text" class="form-control" value="<%= adminUser %>" required>
                  </div>
                  <div class="col-md-6">
                    <label class="form-label">Role Title</label>
                    <input type="text" class="form-control bg-light" value="System Administrator" disabled>
                  </div>
                  <div class="col-md-6">
                    <label class="form-label">Email Address</label>
                    <input type="email" class="form-control" value="admin@smartcivic.gov" required>
                  </div>
                  <div class="col-md-6">
                    <label class="form-label">Phone Number</label>
                    <input type="text" class="form-control" value="+91 99887 76655">
                  </div>
                </div>

                <div class="mt-4 pt-2 text-end">
                  <button type="submit" class="btn-save"><i class="bi bi-check2-circle me-1"></i> Update Profile</button>
                </div>
              </form>
            </div>

            <div class="tab-pane fade" id="v-pills-security" role="tabpanel">
              <h4 class="card-title">Security Settings</h4>
              <p class="card-subtitle">Ensure your administrative account stays secure.</p>
              <div class="settings-divider"></div>

              <form onsubmit="saveSettings(event)">
                <h5 class="fw-bold mb-3" style="font-size: 15px;">Change Password</h5>
                <div class="row g-4">
                  <div class="col-12">
                    <label class="form-label">Current Password</label>
                    <input type="password" class="form-control" style="max-width: 400px;" required>
                  </div>
                  <div class="col-md-6">
                    <label class="form-label">New Password</label>
                    <input type="password" class="form-control" required>
                    <small class="text-muted mt-1 d-block">Must be at least 8 characters long.</small>
                  </div>
                  <div class="col-md-6">
                    <label class="form-label">Confirm New Password</label>
                    <input type="password" class="form-control" required>
                  </div>
                </div>

                <div class="settings-divider"></div>
                <h5 class="fw-bold mb-3" style="font-size: 15px;">Multi-Factor Authentication (MFA)</h5>

                <div class="d-flex align-items-center justify-content-between bg-light p-3 border rounded-3 mb-4">
                  <div class="switch-label">
                    <h6>Require OTP via SMS on Login</h6>
                    <small>Adds an extra layer of security when accessing the admin panel.</small>
                  </div>
                  <div class="form-check form-switch m-0 p-0 d-flex align-items-center">
                    <input class="form-check-input m-0" type="checkbox" role="switch" id="mfaToggle" checked>
                  </div>
                </div>

                <div class="mt-4 pt-2 d-flex justify-content-between">
                  <button type="button" class="btn-danger-soft"><i class="bi bi-box-arrow-right me-1"></i> Terminate All Other Sessions</button>
                  <button type="submit" class="btn-save"><i class="bi bi-shield-check me-1"></i> Update Security</button>
                </div>
              </form>
            </div>

            <div class="tab-pane fade" id="v-pills-notifications" role="tabpanel">
              <h4 class="card-title">System Alerts</h4>
              <p class="card-subtitle">Control which alerts are sent to your admin email or phone.</p>
              <div class="settings-divider"></div>

              <form onsubmit="saveSettings(event)">
                <h5 class="fw-bold mb-3" style="font-size: 15px;">Email Notifications</h5>

                <div class="d-flex align-items-center justify-content-between mb-3 pb-3 border-bottom">
                  <div class="switch-label">
                    <h6>New Complaint Filed</h6>
                    <small>Get an email whenever a citizen files a new issue.</small>
                  </div>
                  <div class="form-check form-switch m-0 p-0">
                    <input class="form-check-input m-0" type="checkbox" role="switch" checked>
                  </div>
                </div>

                <div class="d-flex align-items-center justify-content-between mb-3 pb-3 border-bottom">
                  <div class="switch-label">
                    <h6>High Priority Issue Detected</h6>
                    <small>Receive immediate alerts for hazardous complaints (e.g. Live Wires).</small>
                  </div>
                  <div class="form-check form-switch m-0 p-0">
                    <input class="form-check-input m-0" type="checkbox" role="switch" checked>
                  </div>
                </div>

                <div class="d-flex align-items-center justify-content-between mb-3 pb-3 border-bottom">
                  <div class="switch-label">
                    <h6>Weekly Automated Report</h6>
                    <small>Receive a PDF summary of the system performance every Sunday.</small>
                  </div>
                  <div class="form-check form-switch m-0 p-0">
                    <input class="form-check-input m-0" type="checkbox" role="switch">
                  </div>
                </div>

                <h5 class="fw-bold mt-5 mb-3" style="font-size: 15px;">SMS Notifications</h5>

                <div class="d-flex align-items-center justify-content-between mb-3 pb-3 border-bottom">
                  <div class="switch-label">
                    <h6>Critical Server Errors</h6>
                    <small>Get a text message if the database or system goes down.</small>
                  </div>
                  <div class="form-check form-switch m-0 p-0">
                    <input class="form-check-input m-0" type="checkbox" role="switch" checked>
                  </div>
                </div>

                <div class="mt-4 pt-2 text-end">
                  <button type="submit" class="btn-save"><i class="bi bi-check2-circle me-1"></i> Save Preferences</button>
                </div>
              </form>
            </div>

          </div>
        </div>
      </div>

    </div>

  </main>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>

<script>
  // Simulate saving the settings forms
  function saveSettings(event) {
    event.preventDefault(); // Prevent page reload

    // Find the submit button within the form that was triggered
    const btn = event.target.querySelector('button[type="submit"]');
    const alertBox = document.getElementById('settingsAlert');

    // Save original text and show loading state
    const originalText = btn.innerHTML;
    btn.innerHTML = '<span class="spinner-border spinner-border-sm me-2" role="status"></span> Saving...';
    btn.disabled = true;

    // Simulate a processing time
    setTimeout(() => {
      // Restore button
      btn.innerHTML = originalText;
      btn.disabled = false;

      // Show Success Alert
      alertBox.classList.remove('d-none');
      window.scrollTo({ top: 0, behavior: 'smooth' });

      // Hide alert after 4 seconds
      setTimeout(() => {
        alertBox.classList.add('d-none');
      }, 4000);

      // If they changed passwords, clear the fields
      if(event.target.querySelector('input[type="password"]')) {
        event.target.reset();
      }

    }, 800);
  }
</script>

</body>
</html>