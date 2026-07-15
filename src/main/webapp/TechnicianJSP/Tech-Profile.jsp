<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="true" %>
<%
    String techUser = (String) session.getAttribute("techUser");
    if (techUser == null) techUser = "Raj Patel";
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Technician Profile - Smart Civic</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
    <style>
        :root { --sidebar-bg: #0b1727; --main-bg: #f8fafc; --primary-blue: #2563eb; }
        body { background-color: var(--main-bg); font-family: 'Segoe UI', sans-serif; }
        .wrapper { display: flex; min-height: 100vh; }

        /* Sidebar Styling */
        .sidebar { width: 260px; background-color: var(--sidebar-bg); color: white; position: fixed; height: 100vh; display: flex; flex-direction: column; justify-content: space-between; z-index: 1000; }

        /* Fixed Header & Nav spacing */
        .sidebar-top { padding-top: 20px; }
        .logo-container { padding: 10px 25px 20px 25px; }
        .logo-container h5 { font-size: 1.25rem; font-weight: 700; margin: 0; }

        .nav-link { color: #cbd5e1; padding: 12px 25px; text-decoration: none; display: flex; align-items: center; gap: 12px; transition: 0.2s; }
        .nav-link:hover, .nav-link.active { background-color: var(--primary-blue); color: white; }

        /* Tech Details Card */
        .tech-info-card { margin: 20px; background-color: #1e293b; border-radius: 12px; padding: 15px; font-size: 13px; }
        .tech-info-item { display: flex; align-items: center; gap: 10px; margin-bottom: 10px; color: white; }
        .tech-info-item i { color: #94a3b8; }
        .tech-info-item div span { display: block; font-size: 10px; color: #94a3b8; text-transform: uppercase; }

        /* Main Content */
        .main-content { margin-left: 260px; padding: 40px; width: calc(100% - 260px); }
        .ui-card { background: white; border-radius: 16px; padding: 30px; border: 1px solid #e2e8f0; box-shadow: 0 4px 6px rgba(0,0,0,0.02); }
        .avatar-lg { width: 120px; height: 120px; border-radius: 50%; object-fit: cover; border: 4px solid #f8fafc; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
    </style>
</head>
<body>

<div class="wrapper">
    <aside class="sidebar">
        <div class="sidebar-top">
            <div class="logo-container"><h5><i class="bi bi-bank me-2"></i> Smart Civic</h5></div>
            <ul class="nav flex-column">
                <li class="nav-item"><a href="Tech-Admin.jsp" class="nav-link"><i class="bi bi-house-door"></i> Dashboard</a></li>
                <li class="nav-item"><a href="Tech-Task.jsp" class="nav-link"><i class="bi bi-clipboard-check"></i> My Tasks</a></li>
                <li class="nav-item"><a href="Tech-Upload-Resolution.jsp" class="nav-link"><i class="bi bi-cloud-arrow-up"></i> Upload Resolution</a></li>
                <li class="nav-item"><a href="Tech-Profile.jsp" class="nav-link active"><i class="bi bi-person"></i> Profile</a></li>
                <li class="nav-item"><a href="logout.jsp" class="nav-link"><i class="bi bi-box-arrow-right"></i> Logout</a></li>
            </ul>
        </div>

        <div class="tech-info-card">
            <div class="tech-info-item"><i class="bi bi-person-badge"></i><div><span>ID</span><h6>TECH-1024</h6></div></div>
            <div class="tech-info-item"><i class="bi bi-telephone"></i><div><span>Contact</span><h6>9876543210</h6></div></div>
        </div>
    </aside>

    <main class="main-content">
        <div class="row">
            <div class="col-md-4">
                <div class="ui-card text-center">
                    <img src="https://ui-avatars.com/api/?name=<%= java.net.URLEncoder.encode(techUser, "UTF-8") %>&size=200&background=0D8ABC&color=fff" class="avatar-lg mb-3">
                    <h5 class="fw-bold"><%= techUser %></h5>
                    <p class="text-muted">Technician - Maintenance Team</p>
                    <hr>
                    <div class="text-start">
                        <p><i class="bi bi-envelope me-2"></i> raj.patel@smartcivic.gov</p>
                        <p><i class="bi bi-telephone me-2"></i> +91 98765 43210</p>
                    </div>
                </div>
            </div>

            <div class="col-md-8">
                <div class="ui-card">
                    <h5 class="fw-bold mb-4">Edit Profile</h5>
                    <form action="UpdateProfileServlet" method="POST">
                        <div class="row">
                            <div class="col-md-6 mb-3">
                                <label class="form-label fw-bold">Full Name</label>
                                <input type="text" name="name" class="form-control" value="<%= techUser %>" required>
                            </div>
                            <div class="col-md-6 mb-3">
                                <label class="form-label fw-bold">Contact</label>
                                <input type="text" name="phone" class="form-control" value="9876543210">
                            </div>
                        </div>
                        <h6 class="mt-4 mb-3 text-primary fw-bold">Change Password</h6>
                        <div class="mb-3">
                            <label class="form-label fw-bold">Current Password</label>
                            <input type="password" name="oldPass" class="form-control" required>
                        </div>
                        <div class="row">
                            <div class="col-md-6 mb-3">
                                <label class="form-label fw-bold">New Password</label>
                                <input type="password" name="newPass" class="form-control" required>
                            </div>
                            <div class="col-md-6 mb-3">
                                <label class="form-label fw-bold">Confirm Password</label>
                                <input type="password" name="confPass" class="form-control" required>
                            </div>
                        </div>
                        <button type="submit" class="btn btn-primary mt-3 px-4 fw-bold">Save Changes</button>
                    </form>
                </div>
            </div>
        </div>
    </main>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>