<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="true" %>
<%
    String user = (String) session.getAttribute("user");
    if (user == null) {
        user = "Rahul Sharma";
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Help & Support - Smart Civic</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">

    <style>
        :root {
            --sidebar-bg: #ebf3fa;
            --main-bg: #ffffff;
            --card-bg: #f3f6f9;
            --primary-green: #3bb160;
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

        /* --- Layout & Sidebar --- */
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

        /* --- Main Content --- */
        .main-content { flex-grow: 1; padding: 25px 40px; max-width: calc(100% - 260px); }
        .top-header { display: flex; justify-content: space-between; align-items: center; padding-bottom: 20px; border-bottom: 1px solid #f1f5f9; margin-bottom: 30px; }
        .user-profile { display: flex; align-items: center; gap: 15px; }
        .user-profile img { width: 35px; height: 35px; border-radius: 50%; object-fit: cover; }

        /* --- Help & Support Specific Styles --- */
        .content-panel { border: 1px solid #e2e8f0; border-radius: 16px; padding: 30px; background: white; height: 100%; }

        .section-title { font-size: 18px; font-weight: bold; margin-bottom: 20px; color: #1e293b; }

        /* Accordion Styling */
        .accordion-item { border: 1px solid #e2e8f0; border-radius: 8px !important; margin-bottom: 10px; overflow: hidden; }
        .accordion-button { font-weight: 600; color: #334155; background-color: #f8fafc; padding: 15px 20px; box-shadow: none !important; }
        .accordion-button:not(.collapsed) { color: #2563eb; background-color: #eff6ff; }
        .accordion-body { color: var(--text-muted); font-size: 14.5px; line-height: 1.6; padding: 20px; }

        /* Contact Form */
        .form-label { font-weight: 600; color: #334155; font-size: 14px; }
        .form-control, .form-select { border-radius: 8px; padding: 12px 15px; border: 1px solid #cbd5e1; background-color: #f8fafc; font-size: 14px; }
        .form-control:focus, .form-select:focus { background-color: white; border-color: #3b82f6; box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1); }

        .btn-submit { background-color: #2563eb; color: white; padding: 12px 20px; border-radius: 8px; font-weight: 500; border: none; width: 100%; transition: 0.2s; }
        .btn-submit:hover { background-color: #1d4ed8; }

        /* Contact Info Cards */
        .contact-info-box { display: flex; align-items: center; gap: 15px; padding: 15px; background: #f8fafc; border-radius: 12px; margin-bottom: 15px; border: 1px solid #f1f5f9; }
        .contact-icon { width: 40px; height: 40px; border-radius: 8px; background: #dbeafe; color: #3b82f6; display: flex; align-items: center; justify-content: center; font-size: 18px; flex-shrink: 0; }
        .contact-text h6 { margin: 0 0 3px 0; font-size: 14px; font-weight: bold; color: var(--text-dark); }
        .contact-text p { margin: 0; font-size: 13px; color: var(--text-muted); }

    </style>
</head>
<body>

<div class="wrapper">
    <aside class="sidebar">
        <div class="logo-container">
            <i class="bi bi-shield-check logo-icon"></i>
            <div class="logo-text">
                <h5>Smart Civic</h5>
                <span>Problem Reporting System</span>
            </div>
        </div>

        <a href="add-complaint.jsp" class="nav-btn-add">
            <i class="bi bi-plus-lg"></i> Add Complaint
        </a>

        <ul class="sidebar-nav">
            <li class="nav-item">
                <a href="dashboard.jsp" class="nav-link">
                    <i class="bi bi-file-earmark-text"></i> My Complaints
                </a>
            </li>
            <li class="nav-item">
                <a href="track-status.jsp" class="nav-link">
                    <i class="bi bi-check2-circle"></i> Track Status
                </a>
            </li>
            <li class="nav-item">
                <a href="notifications.jsp" class="nav-link">
                    <i class="bi bi-bell"></i> Notifications
                    <span class="nav-badge">3</span>
                </a>
            </li>
            <li class="nav-item">
                <a href="profile.jsp" class="nav-link">
                    <i class="bi bi-person"></i> Profile
                </a>
            </li>
            <li class="nav-item mt-3">
                <a href="help-support.jsp" class="nav-link active">
                    <i class="bi bi-question-circle"></i> Help & Support
                </a>
            </li>
        </ul>

        <a href="logout.jsp" class="logout-btn">Logout</a>
    </aside>

    <main class="main-content">
        <header class="top-header">
            <h4 class="m-0 fw-bold">Help & Support</h4>
            <div class="user-profile">
                <div class="position-relative">
                    <i class="bi bi-bell fs-5 text-muted"></i>
                </div>
                <div class="d-flex align-items-center gap-2 ms-3">
                    <img src="https://ui-avatars.com/api/?name=<%= java.net.URLEncoder.encode(user, "UTF-8") %>&background=random" alt="<%= user %>">
                    <span class="fw-medium"><%= user %></span>
                </div>
            </div>
        </header>

        <div class="mb-4">
            <h2 class="fw-bold mb-1">How can we help you today?</h2>
            <p class="text-muted">Find answers to common questions or reach out to our support team.</p>
        </div>

        <div class="row g-4">
            <div class="col-lg-7">
                <div class="content-panel">
                    <h5 class="section-title"><i class="bi bi-info-circle me-2"></i> Frequently Asked Questions</h5>

                    <div class="accordion" id="faqAccordion">

                        <div class="accordion-item">
                            <h2 class="accordion-header">
                                <button class="accordion-button" type="button" data-bs-toggle="collapse" data-bs-target="#faq1">
                                    How long does it take to resolve a complaint?
                                </button>
                            </h2>
                            <div id="faq1" class="accordion-collapse collapse show" data-bs-parent="#faqAccordion">
                                <div class="accordion-body">
                                    Resolution times depend on the priority and nature of the issue. High-priority issues (like live wire hazards) are typically addressed within 24 hours. Standard issues like garbage overflow usually take 2-3 business days. You can monitor the exact status in the <strong>Track Status</strong> tab.
                                </div>
                            </div>
                        </div>

                        <div class="accordion-item">
                            <h2 class="accordion-header">
                                <button class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="#faq2">
                                    Can I edit a complaint after submitting it?
                                </button>
                            </h2>
                            <div id="faq2" class="accordion-collapse collapse" data-bs-parent="#faqAccordion">
                                <div class="accordion-body">
                                    Once a complaint is submitted and assigned an ID, it cannot be edited directly by the user to prevent data inconsistency. However, if you need to add more details, you can reply to the issue thread in the Track Status page or contact support with your Complaint ID.
                                </div>
                            </div>
                        </div>

                        <div class="accordion-item">
                            <h2 class="accordion-header">
                                <button class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="#faq3">
                                    What should I do if my issue is marked "Resolved" but it isn't?
                                </button>
                            </h2>
                            <div id="faq3" class="accordion-collapse collapse" data-bs-parent="#faqAccordion">
                                <div class="accordion-body">
                                    If an issue is marked resolved prematurely, please use the "Reopen Ticket" button available inside the specific complaint's details on the Track Status page. This button is available for 7 days after an issue is marked resolved.
                                </div>
                            </div>
                        </div>

                        <div class="accordion-item">
                            <h2 class="accordion-header">
                                <button class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="#faq4">
                                    How do I update my notification preferences?
                                </button>
                            </h2>
                            <div id="faq4" class="accordion-collapse collapse" data-bs-parent="#faqAccordion">
                                <div class="accordion-body">
                                    You can update your email and SMS notification preferences by visiting the <strong>Profile</strong> section and scrolling down to the "Preferences" area.
                                </div>
                            </div>
                        </div>

                    </div>
                </div>
            </div>

            <div class="col-lg-5">
                <div class="content-panel mb-4">
                    <h5 class="section-title"><i class="bi bi-headset me-2"></i> Contact Support</h5>

                    <div class="alert alert-success alert-dismissible fade show d-none" id="supportAlert" role="alert">
                        <i class="bi bi-check-circle me-2"></i> Message sent successfully! Our team will get back to you shortly.
                        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                    </div>

                    <form onsubmit="submitSupport(event)">
                        <div class="mb-3">
                            <label class="form-label">Subject</label>
                            <select class="form-select" required>
                                <option value="" selected disabled>Choose a topic...</option>
                                <option value="technical">Technical Issue with Portal</option>
                                <option value="complaint_escalation">Complaint Escalation</option>
                                <option value="feedback">General Feedback</option>
                                <option value="other">Other</option>
                            </select>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Message</label>
                            <textarea class="form-control" rows="4" placeholder="Describe your issue or query here..." required></textarea>
                        </div>
                        <button type="submit" class="btn btn-submit"><i class="bi bi-send me-2"></i> Send Message</button>
                    </form>
                </div>

                <div class="contact-info-box">
                    <div class="contact-icon"><i class="bi bi-telephone"></i></div>
                    <div class="contact-text">
                        <h6>Toll-Free Helpline</h6>
                        <p>1800-123-4567 (Mon-Sat, 9AM to 6PM)</p>
                    </div>
                </div>

                <div class="contact-info-box">
                    <div class="contact-icon"><i class="bi bi-envelope"></i></div>
                    <div class="contact-text">
                        <h6>Email Support</h6>
                        <p>support@smartcivic.gov</p>
                    </div>
                </div>

            </div>
        </div>
    </main>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>

<script>
    // Simulate sending a support message
    function submitSupport(event) {
        event.preventDefault(); // Prevent page reload

        const form = event.target;
        const alertBox = document.getElementById('supportAlert');

        // Show the success alert
        alertBox.classList.remove('d-none');

        // Clear the form
        form.reset();

        // Auto-hide the alert after 4 seconds
        setTimeout(() => {
            alertBox.classList.add('d-none');
        }, 4000);
    }
</script>

</body>
</html>