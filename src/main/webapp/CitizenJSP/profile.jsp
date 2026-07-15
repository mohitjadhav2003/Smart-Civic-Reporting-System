<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="true" %>
<%@ page import="java.sql.*, utility.DBConnection" %>
<%
    // 1. Session Verification
    Integer citizenId = (Integer) session.getAttribute("citizen_id");

    // If not logged in, redirect to login page securely
    if (citizenId == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    // 2. Initialize variables to prevent null errors
    String userFullName = "";
    String userEmail = "";
    String userPhone = "";
    String userAddress = "";
    String profileImageBase64 = null;
    int totalIssues = 0;
    int resolvedIssues = 0;

    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;

    try {
        conn = DBConnection.getConnection();

        // --- Fetch Personal Details & Profile Image ---
        String userSql = "SELECT full_name, email, mobile, department, profile_image FROM civicuser WHERE user_id = ?";
        pstmt = conn.prepareStatement(userSql);
        pstmt.setInt(1, citizenId);
        rs = pstmt.executeQuery();

        if(rs.next()) {
            userFullName = rs.getString("full_name");
            userEmail = rs.getString("email");
            userPhone = rs.getString("mobile");
            userAddress = rs.getString("department"); // Address ke liye department column

            if(userAddress == null) userAddress = "";

            // Handle Profile Picture (CLOB Database format)
            Clob clob = rs.getClob("profile_image");
            if (clob != null) {
                profileImageBase64 = clob.getSubString(1, (int) clob.length());
            }
        }
        rs.close();
        pstmt.close();

        // --- Fetch Complaint Statistics ---
        String statsSql = "SELECT COUNT(*) as total, SUM(CASE WHEN STATUS='Resolved' THEN 1 ELSE 0 END) as resolved FROM complaints WHERE CITIZEN_ID = ?";
        pstmt = conn.prepareStatement(statsSql);
        pstmt.setInt(1, citizenId);
        rs = pstmt.executeQuery();

        if(rs.next()) {
            totalIssues = rs.getInt("total");
            resolvedIssues = rs.getInt("resolved");
        }

    } catch (Exception e) {
        e.printStackTrace();
    } finally {
        try{ if(rs != null) rs.close(); }catch(Exception e){}
        try{ if(pstmt != null) pstmt.close(); }catch(Exception e){}
        try{ if(conn != null) conn.close(); }catch(Exception e){}
    }

    // 3. Setup Final DP UI
    String avatarSrc = (profileImageBase64 != null && !profileImageBase64.trim().isEmpty())
            ? profileImageBase64
            : "https://ui-avatars.com/api/?name=" + java.net.URLEncoder.encode(userFullName, "UTF-8") + "&background=random&size=150";
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Profile - Smart Civic</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">

    <style>
        :root { --sidebar-bg: #ebf3fa; --main-bg: #ffffff; --card-bg: #f3f6f9; --primary-green: #3bb160; --text-dark: #1e293b; --text-muted: #64748b; }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: var(--main-bg); color: var(--text-dark); margin: 0; overflow-x: hidden; }
        .wrapper { display: flex; min-height: 100vh; }
        .sidebar { width: 260px; background-color: var(--sidebar-bg); padding: 20px 15px; display: flex; flex-direction: column; border-right: 1px solid #e2e8f0; }
        .logo-container { display: flex; align-items: center; gap: 10px; padding: 10px; margin-bottom: 20px; }
        .logo-icon { font-size: 24px; color: #2563eb; }
        .logo-text h5 { margin: 0; font-weight: bold; color: #0f172a; }
        .logo-text span { font-size: 11px; color: var(--text-muted); }
        .nav-btn-add { background-color: var(--primary-green); color: white; border-radius: 8px; padding: 12px 15px; font-weight: 500; display: flex; align-items: center; gap: 10px; text-decoration: none; margin-bottom: 15px; transition: 0.2s; }
        .nav-btn-add:hover { background-color: #2e964f; color: white; }
        .sidebar-nav { list-style: none; padding: 0; margin: 0; flex-grow: 1; }
        .nav-item { margin-bottom: 5px; }
        .nav-link { display: flex; align-items: center; gap: 12px; padding: 10px 15px; color: var(--text-dark); border-radius: 8px; text-decoration: none; font-weight: 500; transition: 0.2s; }
        .nav-link:hover { background-color: rgba(0,0,0,0.03); }
        .nav-link.active { background-color: white; box-shadow: 0 2px 5px rgba(0,0,0,0.05); }
        .nav-link i { font-size: 18px; color: #475569; }
        .nav-badge { background-color: #ef4444; color: white; border-radius: 50%; padding: 2px 6px; font-size: 10px; margin-left: auto; }
        .logout-btn { border: 1px solid #cbd5e1; background: transparent; padding: 10px; border-radius: 8px; text-align: center; color: var(--text-dark); font-weight: 500; text-decoration: none; transition: 0.2s; }
        .logout-btn:hover { background-color: #e2e8f0; }

        .main-content { flex-grow: 1; padding: 25px 40px; max-width: calc(100% - 260px); }
        .top-header { display: flex; justify-content: space-between; align-items: center; padding-bottom: 20px; border-bottom: 1px solid #f1f5f9; margin-bottom: 30px; }
        .user-profile { display: flex; align-items: center; gap: 15px; }
        .user-profile img { width: 35px; height: 35px; border-radius: 50%; object-fit: cover; }

        .content-panel { border: 1px solid #e2e8f0; border-radius: 16px; padding: 30px; background: white; height: 100%; }

        /* Profile DP Styles */
        .profile-avatar-wrapper { position: relative; width: 120px; height: 120px; margin: 0 auto 20px; }
        .profile-avatar { width: 100%; height: 100%; border-radius: 50%; object-fit: cover; border: 4px solid white; box-shadow: 0 4px 10px rgba(0,0,0,0.08); }
        .btn-edit-avatar { position: absolute; bottom: 0; right: 0; background-color: #2563eb; color: white; width: 35px; height: 35px; border-radius: 50%; display: flex; align-items: center; justify-content: center; border: 3px solid white; cursor: pointer; transition: 0.2s; overflow: hidden;}
        .btn-edit-avatar:hover { background-color: #1d4ed8; }
        .file-input-hidden { position: absolute; left: 0; top: 0; opacity: 0; width: 100%; height: 100%; cursor: pointer;}

        .form-label { font-weight: 600; color: #334155; font-size: 14px; }
        .form-control { border-radius: 8px; padding: 12px 15px; border: 1px solid #cbd5e1; background-color: #f8fafc; }
        .form-control:focus { background-color: white; border-color: #3b82f6; box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1); }
        .btn-save { background-color: var(--primary-green); color: white; padding: 10px 25px; border-radius: 8px; font-weight: 500; border: none; transition: 0.2s; }
        .btn-save:hover { background-color: #2e964f; }
        .section-title { font-size: 18px; font-weight: bold; margin-bottom: 20px; padding-bottom: 10px; border-bottom: 1px solid #f1f5f9; }
    </style>
</head>
<body>

<div class="wrapper">
    <aside class="sidebar">
        <div class="logo-container">
            <i class="bi bi-shield-check logo-icon"></i>
            <div class="logo-text"><h5>Smart Civic</h5><span>Problem Reporting System</span></div>
        </div>
        <a href="add-complaint.jsp" class="nav-btn-add"><i class="bi bi-plus-lg"></i> Add Complaint</a>
        <ul class="sidebar-nav">
            <li class="nav-item"><a href="dashboard.jsp" class="nav-link"><i class="bi bi-file-earmark-text"></i> My Complaints</a></li>
            <li class="nav-item"><a href="track-status.jsp" class="nav-link"><i class="bi bi-check2-circle"></i> Track Status</a></li>
            <li class="nav-item"><a href="notifications.jsp" class="nav-link"><i class="bi bi-bell"></i> Notifications <span class="nav-badge">3</span></a></li>
            <li class="nav-item"><a href="profile.jsp" class="nav-link active"><i class="bi bi-person"></i> Profile</a></li>
            <li class="nav-item mt-3"><a href="help-support.jsp" class="nav-link"><i class="bi bi-question-circle"></i> Help & Support</a></li>
        </ul>
        <a href="logout.jsp" class="logout-btn">Logout</a>
    </aside>

    <main class="main-content">
        <header class="top-header">
            <h4 class="m-0 fw-bold">My Profile</h4>
            <div class="user-profile">
                <i class="bi bi-bell fs-5 text-muted"></i>
                <div class="d-flex align-items-center gap-2 ms-3">
                    <img src="<%= avatarSrc %>" alt="<%= userFullName %>">
                    <span class="fw-medium"><%= userFullName %></span>
                </div>
            </div>
        </header>

        <div class="row g-4">

            <div class="col-lg-4">
                <div class="content-panel text-center">

                    <div class="profile-avatar-wrapper">
                        <img id="mainDpDisplay" src="<%= avatarSrc %>" alt="Profile Picture" class="profile-avatar">
                        <div class="btn-edit-avatar" title="Change Picture">
                            <i class="bi bi-camera-fill"></i>
                            <input type="file" id="dpUploadInput" class="file-input-hidden" accept="image/*" onchange="previewImage(event)">
                        </div>
                    </div>

                    <h4 class="fw-bold mb-1"><%= userFullName %></h4>
                    <p class="text-muted small mb-4">Citizen User</p>

                    <div class="d-flex justify-content-center gap-3 mb-4">
                        <div class="text-center">
                            <h5 class="fw-bold m-0 text-primary"><%= totalIssues %></h5>
                            <small class="text-muted">Total Issues</small>
                        </div>
                        <div class="border-end"></div>
                        <div class="text-center">
                            <h5 class="fw-bold m-0 text-success"><%= resolvedIssues %></h5>
                            <small class="text-muted">Resolved</small>
                        </div>
                    </div>

                    <p class="text-muted small text-start">
                        <i class="bi bi-geo-alt me-2"></i> <%= userAddress.isEmpty() ? "Address not updated" : userAddress %><br>
                        <i class="bi bi-envelope me-2 mt-2 d-inline-block"></i> <%= userEmail %><br>
                        <i class="bi bi-telephone me-2 mt-2 d-inline-block"></i> <%= userPhone %>
                    </p>
                </div>
            </div>

            <div class="col-lg-8">
                <div class="content-panel">

                    <div class="alert alert-success alert-dismissible fade show d-none" id="saveAlert" role="alert">
                        <i class="bi bi-check-circle me-2"></i> Profile updated successfully!
                        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                    </div>

                    <h5 class="section-title">Personal Information</h5>
                    <form onsubmit="submitProfileUpdate(event)">
                        <input type="hidden" id="dpBase64Input" name="dpBase64">

                        <div class="row g-3 mb-4">
                            <div class="col-md-6">
                                <label class="form-label">Full Name</label>
                                <input type="text" class="form-control" name="fullName" value="<%= userFullName %>" required>
                            </div>
                            <div class="col-md-6">
                                <label class="form-label">Phone Number</label>
                                <input type="tel" class="form-control" name="phone" value="<%= userPhone %>" required>
                            </div>
                            <div class="col-md-12">
                                <label class="form-label">Email Address (Read Only)</label>
                                <input type="email" class="form-control bg-light" value="<%= userEmail %>" readonly>
                            </div>
                            <div class="col-md-12">
                                <label class="form-label">Residential Address</label>
                                <textarea class="form-control" name="address" rows="2"><%= userAddress %></textarea>
                            </div>
                        </div>

                        <h5 class="section-title mt-5">Change Password</h5>
                        <p class="text-muted small mb-3">Leave blank if you do not want to change the password.</p>
                        <div class="row g-3 mb-4">
                            <div class="col-md-6">
                                <label class="form-label">New Password</label>
                                <input type="password" class="form-control" name="newPassword" placeholder="Enter new password">
                            </div>
                        </div>

                        <div class="text-end mt-4">
                            <button type="button" class="btn btn-light border me-2" onclick="location.reload()">Cancel</button>
                            <button type="submit" class="btn btn-save" id="btnSubmitProfile">Save Changes</button>
                        </div>
                    </form>

                </div>
            </div>
        </div>
    </main>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>

<script>
    // 1. Live Client Side DP Preview (Fast)
    function previewImage(event) {
        var file = event.target.files[0];
        if (file) {
            var reader = new FileReader();
            reader.onload = function(e) {
                // Update Main and Top Display Images instantly
                document.getElementById('mainDpDisplay').src = e.target.result;
                // Add Image Data to Hidden Field for form submission
                document.getElementById('dpBase64Input').value = e.target.result;
            }
            reader.readAsDataURL(file);
        }
    }

    // 2. Heavy Data Form Submission handling
    function submitProfileUpdate(event) {
        event.preventDefault();

        const btn = document.getElementById('btnSubmitProfile');
        btn.innerHTML = '<span class="spinner-border spinner-border-sm me-2"></span> Saving...';
        btn.disabled = true;

        // Use Form Data Protocol rather than URLParams for Heavy CLOB uploads
        const formData = new FormData(event.target);

        fetch('<%=request.getContextPath()%>/UpdateProfileServlet', {
            method: 'POST',
            body: formData
        })
            .then(async response => {
                if (!response.ok) {
                    const errText = await response.text();
                    throw new Error(errText);
                }
                return response.text();
            })
            .then(data => {
                // Show Success Display
                const alertBox = document.getElementById('saveAlert');
                alertBox.classList.remove('d-none');
                window.scrollTo({ top: 0, behavior: 'smooth' });

                btn.innerHTML = 'Save Changes';
                btn.disabled = false;

                // Wait 2 Seconds and Sync UI
                setTimeout(() => { alertBox.classList.add('d-none'); location.reload(); }, 2000);
            })
            .catch(error => {
                alert(error.message || "Error updating profile! Try again with standard text/image limits.");
                btn.innerHTML = 'Save Changes';
                btn.disabled = false;
            });
    }
</script>

</body>
</html>