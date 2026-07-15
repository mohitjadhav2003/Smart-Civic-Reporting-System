<%@ page language="java"
         contentType="text/html; charset=UTF-8"
         pageEncoding="UTF-8"
         session="true" %>

<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="utility.DBConnection" %>

<%

    /* =========================================================
       SESSION
    ========================================================= */

    String techId =
            (String) session.getAttribute("userId");

    String techUser =
            (String) session.getAttribute("userName");

    String techDept =
            (String) session.getAttribute("userDept");

    if (techUser == null)
        techUser = "Raj Patel";

    if (techId == null)
        techId = "43";

    if (techDept == null)
        techDept = "Water Department";


/* =========================================================
   UPDATE STATUS LOGIC
========================================================= */

    String taskIdParam =
            request.getParameter("taskId");

    String statusParam =
            request.getParameter("status");

    String notesParam =
            request.getParameter("notes");


    Connection conn = null;

    PreparedStatement psUpdate = null;

    PreparedStatement psTasks = null;

    PreparedStatement psLog = null;

    ResultSet rsTasks = null;

    List<Map<String,String>> taskList =
            new ArrayList<Map<String,String>>();

    String successMsg = "";

    String errorMsg = "";


    try{

/* =========================================================
   DATABASE CONNECTION
========================================================= */

        conn =
                DBConnection.getConnection();


/* =========================================================
   UPDATE TASK STATUS
========================================================= */

        if(taskIdParam != null &&
                statusParam != null){

            String updateSql =

                    "UPDATE complaints " +
                            "SET status = ? " +
                            "WHERE complaint_id = ?";


            psUpdate =
                    conn.prepareStatement(updateSql);

            psUpdate.setString(
                    1,
                    statusParam
            );

            psUpdate.setInt(
                    2,
                    Integer.parseInt(taskIdParam)
            );


            int updated =
                    psUpdate.executeUpdate();


/* =========================================================
   INSERT LOG
========================================================= */

            if(updated > 0){

                try{

                    String logSql =

                            "INSERT INTO complaint_logs " +
                                    "(" +
                                    "log_id, " +
                                    "complaint_id, " +
                                    "technician_id, " +
                                    "status, " +
                                    "notes, " +
                                    "created_at" +
                                    ") " +

                                    "VALUES " +

                                    "(" +
                                    "complaint_logs_seq.NEXTVAL, " +
                                    "?, ?, ?, ?, SYSDATE" +
                                    ")";


                    psLog =
                            conn.prepareStatement(logSql);

                    psLog.setInt(
                            1,
                            Integer.parseInt(taskIdParam)
                    );

                    psLog.setString(
                            2,
                            techId
                    );

                    psLog.setString(
                            3,
                            statusParam
                    );

                    psLog.setString(
                            4,
                            notesParam
                    );

                    psLog.executeUpdate();

                }
                catch(Exception ex){}


                successMsg =
                        "Task updated successfully.";
            }
            else{

                errorMsg =
                        "Task update failed.";
            }
        }


/* =========================================================
   FETCH TASKS
========================================================= */

        String taskSql =

                "SELECT " +
                        "COMPLAINT_ID, " +
                        "PROBLEM_CATEGORY, " +
                        "LOCATION_ADDRESS, " +
                        "STATUS, " +
                        "CREATED_AT " +

                        "FROM complaints " +

                        "WHERE assigned_to = ? " +

                        "ORDER BY complaint_id DESC";


        psTasks =
                conn.prepareStatement(taskSql);

        psTasks.setString(
                1,
                techId
        );

        rsTasks =
                psTasks.executeQuery();


        SimpleDateFormat sdf =
                new SimpleDateFormat(
                        "dd MMM yyyy"
                );


/* =========================================================
   FETCH ROWS
========================================================= */

        while(rsTasks.next()){

            Map<String,String> m =
                    new HashMap<String,String>();


            m.put(
                    "id",
                    rsTasks.getString("COMPLAINT_ID")
            );


            m.put(
                    "problem",
                    rsTasks.getString("PROBLEM_CATEGORY")
            );


            m.put(
                    "location",
                    rsTasks.getString("LOCATION_ADDRESS")
            );


            m.put(
                    "status",
                    rsTasks.getString("STATUS")
            );


            Timestamp ts =
                    rsTasks.getTimestamp(
                            "CREATED_AT"
                    );

            String formattedDate = "";

            if(ts != null){

                formattedDate =
                        sdf.format(ts);
            }

            m.put(
                    "date",
                    formattedDate
            );


            taskList.add(m);
        }

    }
    catch(Exception e){

        errorMsg =
                e.getMessage();

        e.printStackTrace();
    }
    finally{

        try{

            if(rsTasks != null)
                rsTasks.close();

            if(psTasks != null)
                psTasks.close();

            if(psUpdate != null)
                psUpdate.close();

            if(psLog != null)
                psLog.close();

            if(conn != null)
                conn.close();

        }
        catch(Exception ex){}
    }

%>

<!DOCTYPE html>

<html lang="en">

<head>

    <meta charset="UTF-8">

    <title>
        My Tasks - Smart Civic
    </title>

    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css"
          rel="stylesheet">

    <link rel="stylesheet"
          href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">

    <style>

        :root {

            --sidebar-bg: #0b1727;

            --main-bg: #f8fafc;

            --primary-blue: #2563eb;
        }

        body {

            background-color: var(--main-bg);

            font-family: 'Segoe UI', sans-serif;
        }

        .wrapper {

            display: flex;

            min-height: 100vh;
        }

        .sidebar {

            width: 260px;

            background-color: var(--sidebar-bg);

            color: white;

            position: fixed;

            height: 100vh;

            display: flex;

            flex-direction: column;

            z-index: 1000;
        }

        .sidebar-nav {

            flex-grow: 1;

            padding: 10px 15px;
        }

        .nav-link {

            color: #cbd5e1;

            padding: 12px 15px;

            text-decoration: none;

            display: flex;

            align-items: center;

            gap: 12px;

            margin-bottom: 5px;
        }

        .nav-link:hover,
        .nav-link.active {

            background-color: var(--primary-blue);

            color: white;

            border-radius: 8px;
        }

        .tech-info-card {

            padding: 20px;

            background-color: #1e293b;

            font-size: 13px;

            margin-top: auto;
        }

        .tech-info-item {

            display: flex;

            align-items: center;

            gap: 10px;

            margin-bottom: 10px;

            color: white;
        }

        .main-content {

            margin-left: 260px;

            padding: 25px 35px;

            width: calc(100% - 260px);
        }

        .ui-card {

            background: white;

            border-radius: 12px;

            padding: 24px;

            border: 1px solid #e2e8f0;
        }

        .status-badge {

            padding: 5px 12px;

            border-radius: 6px;

            font-size: 11.5px;

            font-weight: 600;
        }

        .badge-progress {

            background-color: #dbeafe;

            color: #2563eb;
        }

        .badge-pending {

            background-color: #ffedd5;

            color: #ea580c;
        }

        .badge-resolved {

            background-color: #dcfce7;

            color: #16a34a;
        }

    </style>

</head>

<body>

<div class="wrapper">

    <aside class="sidebar">

        <div class="sidebar-top">

            <div class="p-4">

                <h5>

                    <i class="bi bi-bank me-2"></i>

                    Smart Civic

                </h5>

            </div>

            <ul class="nav flex-column sidebar-nav">

                <li class="nav-item">
                    <a href="Tech-Admin.jsp" class="nav-link">
                        <i class="bi bi-house-door"></i>
                        Dashboard
                    </a>
                </li>

                <li class="nav-item">
                    <a href="Tech-Task.jsp" class="nav-link active">
                        <i class="bi bi-clipboard-check"></i>
                        My Tasks
                    </a>
                </li>

                <li class="nav-item">
                    <a href="Tech-Upload-Resolution.jsp" class="nav-link">
                        <i class="bi bi-cloud-arrow-up"></i>
                        Upload Resolution
                    </a>
                </li>

                <li class="nav-item">
                    <a href="Tech-Profile.jsp" class="nav-link">
                        <i class="bi bi-person"></i>
                        Profile
                    </a>
                </li>

                <li class="nav-item">
                    <a href="../logout.jsp" class="nav-link">
                        <i class="bi bi-box-arrow-right"></i>
                        Logout
                    </a>
                </li>

            </ul>

        </div>

        <div class="tech-info-card">

            <div class="tech-info-item">

                <i class="bi bi-person-badge"></i>

                <div>

                    <span>ID</span>

                    <h6>

                        TECH-<%= techId %>

                    </h6>

                </div>

            </div>

            <div class="tech-info-item">

                <i class="bi bi-telephone"></i>

                <div>

                    <span>Department</span>

                    <h6>

                        <%= techDept %>

                    </h6>

                </div>

            </div>

        </div>

    </aside>

    <main class="main-content">

        <div class="ui-card">

            <div class="d-flex justify-content-between align-items-center mb-4">

                <h4 class="fw-bold m-0">

                    <i class="bi bi-clipboard-check text-primary me-2"></i>

                    My Assigned Tasks

                </h4>

            </div>


            <% if(!successMsg.equals("")){ %>

            <div class="alert alert-success">

                <%= successMsg %>

            </div>

            <% } %>


            <% if(!errorMsg.equals("")){ %>

            <div class="alert alert-danger">

                <%= errorMsg %>

            </div>

            <% } %>


            <table class="table table-hover">

                <thead>

                <tr>

                    <th>Task ID</th>

                    <th>Problem</th>

                    <th>Location</th>

                    <th>Assigned On</th>

                    <th>Status</th>

                    <th>Action</th>

                </tr>

                </thead>

                <tbody>

                <%

                    for(Map<String,String> t : taskList){

                        String statusClass =
                                "badge-pending";

                        if(t.get("status").equalsIgnoreCase("In Progress")){

                            statusClass =
                                    "badge-progress";
                        }

                        else if(t.get("status").equalsIgnoreCase("Resolved")){

                            statusClass =
                                    "badge-resolved";
                        }
                %>

                <tr>

                    <td class="fw-bold">

                        #<%= t.get("id") %>

                    </td>

                    <td>

                        <%= t.get("problem") %>

                    </td>

                    <td>

                        <%= t.get("location") %>

                    </td>

                    <td>

                        <%= t.get("date") %>

                    </td>

                    <td>

                        <span class="status-badge <%= statusClass %>">

                            <%= t.get("status") %>

                        </span>

                    </td>

                    <td>

                        <button class="btn btn-sm btn-primary"
                                data-bs-toggle="modal"
                                data-bs-target="#updateModal<%= t.get("id") %>">

                            Update

                        </button>

                    </td>

                </tr>


                <!-- =====================================================
                     UPDATE MODAL
                ====================================================== -->

                <div class="modal fade"
                     id="updateModal<%= t.get("id") %>"
                     tabindex="-1">

                    <div class="modal-dialog">

                        <div class="modal-content">

                            <div class="modal-header">

                                <h5 class="modal-title">

                                    Update Task Status

                                </h5>

                                <button type="button"
                                        class="btn-close"
                                        data-bs-dismiss="modal"></button>

                            </div>

                            <div class="modal-body">

                                <form method="POST">

                                    <input type="hidden"
                                           name="taskId"
                                           value="<%= t.get("id") %>">

                                    <div class="mb-3">

                                        <label class="form-label">

                                            Change Status

                                        </label>

                                        <select name="status"
                                                class="form-select">

                                            <option value="In Progress">

                                                In Progress

                                            </option>

                                            <option value="Resolved">

                                                Resolved

                                            </option>

                                        </select>

                                    </div>

                                    <div class="mb-3">

                                        <label class="form-label">

                                            Notes

                                        </label>

                                        <textarea name="notes"
                                                  class="form-control"
                                                  rows="3"></textarea>

                                    </div>

                                    <button type="submit"
                                            class="btn btn-success">

                                        Save Changes

                                    </button>

                                </form>

                            </div>

                        </div>

                    </div>

                </div>

                <%
                    }
                %>

                </tbody>

            </table>

        </div>

    </main>

</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>

</body>

</html>