<%@ page language="java"
         contentType="text/html; charset=UTF-8"
         pageEncoding="UTF-8"
         session="true" %>

<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
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
   SUCCESS / ERROR MESSAGE
========================================================= */

    String successMsg =
            (String) session.getAttribute(
                    "successMsg"
            );

    String errorMsg =
            (String) session.getAttribute(
                    "errorMsg"
            );

    session.removeAttribute("successMsg");

    session.removeAttribute("errorMsg");


/* =========================================================
   FETCH ACTIVE TASKS
========================================================= */

    Connection conn = null;

    PreparedStatement ps = null;

    ResultSet rs = null;

    List<Map<String,String>> taskList =
            new ArrayList<Map<String,String>>();

    try{

        conn =
                DBConnection.getConnection();


        String sql =

                "SELECT " +

                        "complaint_id, " +

                        "problem_category, " +

                        "status " +

                        "FROM complaints " +

                        "WHERE assigned_to = ? " +

                        "AND LOWER(status) != 'resolved' " +

                        "ORDER BY complaint_id DESC";


        ps =
                conn.prepareStatement(sql);

        ps.setString(
                1,
                techId
        );

        rs =
                ps.executeQuery();


        while(rs.next()){

            Map<String,String> m =
                    new HashMap<String,String>();


            m.put(
                    "id",
                    rs.getString("complaint_id")
            );


            m.put(
                    "problem",
                    rs.getString("problem_category")
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

            if(rs != null)
                rs.close();

            if(ps != null)
                ps.close();

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
        Upload Resolution - Smart Civic
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

            justify-content: space-between;

            z-index: 1000;
        }

        .sidebar-top {

            padding-top: 25px;
        }

        .logo-container {

            padding: 0 25px 30px 25px;
        }

        .nav-link {

            color: #cbd5e1;

            padding: 12px 25px;

            text-decoration: none;

            display: flex;

            align-items: center;

            gap: 12px;

            transition: 0.2s;
        }

        .nav-link:hover,
        .nav-link.active {

            background-color: var(--primary-blue);

            color: white;
        }

        .tech-info-card {

            margin: 20px;

            background-color: #1e293b;

            border-radius: 12px;

            padding: 15px;

            font-size: 13px;
        }

        .tech-info-item {

            display: flex;

            align-items: center;

            gap: 10px;

            margin-bottom: 10px;

            color: white;
        }

        .tech-info-item i {

            color: #94a3b8;
        }

        .tech-info-item div span {

            display: block;

            font-size: 10px;

            color: #94a3b8;

            text-transform: uppercase;
        }

        .main-content {

            margin-left: 260px;

            padding: 40px;

            width: calc(100% - 260px);

            display: flex;

            justify-content: center;
        }

        .ui-card {

            background: white;

            border-radius: 16px;

            padding: 30px;

            border: 1px solid #e2e8f0;

            width: 100%;

            max-width: 600px;

            box-shadow: 0 4px 6px rgba(0,0,0,0.02);
        }

        .camera-box {

            border: 2px dashed #cbd5e1;

            border-radius: 12px;

            padding: 15px;

            text-align: center;

            background: #f8fafc;

            margin-bottom: 15px;
        }

        #cameraPreview {

            width: 100%;

            border-radius: 8px;

            background: #000;

            display: none;
        }

        #capturedPhoto {

            width: 100%;

            border-radius: 8px;

            display: none;

            border: 2px solid #16a34a;
        }

    </style>

</head>

<body>

<div class="wrapper">

    <aside class="sidebar">

        <div class="sidebar-top">

            <div class="logo-container">

                <h5>

                    <i class="bi bi-bank me-2"></i>

                    Smart Civic

                </h5>

            </div>

            <ul class="nav flex-column">

                <li class="nav-item">

                    <a href="Tech-Admin.jsp"
                       class="nav-link">

                        <i class="bi bi-house-door"></i>

                        Dashboard

                    </a>

                </li>

                <li class="nav-item">

                    <a href="Tech-Task.jsp"
                       class="nav-link">

                        <i class="bi bi-clipboard-check"></i>

                        My Tasks

                    </a>

                </li>

                <li class="nav-item">

                    <a href="Tech-Upload-Resolution.jsp"
                       class="nav-link active">

                        <i class="bi bi-cloud-arrow-up"></i>

                        Upload Resolution

                    </a>

                </li>

                <li class="nav-item">

                    <a href="Tech-Profile.jsp"
                       class="nav-link">

                        <i class="bi bi-person"></i>

                        Profile

                    </a>

                </li>

                <li class="nav-item">

                    <a href="../logout.jsp"
                       class="nav-link">

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

                <i class="bi bi-building"></i>

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

            <h4 class="fw-bold mb-4">

                <i class="bi bi-cloud-check text-primary me-2"></i>

                Upload Resolution

            </h4>


            <% if(successMsg != null){ %>

            <div class="alert alert-success">

                <%= successMsg %>

            </div>

            <% } %>


            <% if(errorMsg != null){ %>

            <div class="alert alert-danger">

                <%= errorMsg %>

            </div>

            <% } %>


            <form action="<%= request.getContextPath() %>/UploadResolutionServlet"
                  method="POST">

                <div class="mb-3">

                    <label class="form-label fw-bold">

                        Select Task ID

                    </label>

                    <select name="taskId"
                            class="form-select"
                            required>

                        <option value="">

                            Choose an active task...

                        </option>

                        <%

                            for(Map<String,String> t : taskList){
                        %>

                        <option value="<%= t.get("id") %>">

                            #<%= t.get("id") %>
                            -
                            <%= t.get("problem") %>

                        </option>

                        <%
                            }
                        %>

                    </select>

                </div>

                <div class="mb-3">

                    <label class="form-label fw-bold">

                        Resolution Evidence

                    </label>

                    <div class="camera-box">

                        <video id="cameraPreview"
                               autoplay
                               playsinline></video>

                        <img id="capturedPhoto">

                        <canvas id="photoCanvas"
                                class="d-none"></canvas>

                        <div class="mt-3">

                            <button type="button"
                                    id="btnStart"
                                    class="btn btn-sm btn-outline-primary"
                                    onclick="startCamera()">

                                <i class="bi bi-camera"></i>

                                Start Camera

                            </button>

                            <button type="button"
                                    id="btnCapture"
                                    class="btn btn-sm btn-success d-none"
                                    onclick="capturePhoto()">

                                <i class="bi bi-camera-fill"></i>

                                Capture

                            </button>

                            <button type="button"
                                    id="btnRetake"
                                    class="btn btn-sm btn-warning d-none"
                                    onclick="startCamera()">

                                <i class="bi bi-arrow-clockwise"></i>

                                Retake

                            </button>

                        </div>

                    </div>

                    <input type="hidden"
                           name="photoData"
                           id="photoData"
                           required>

                </div>

                <div class="mb-4">

                    <label class="form-label fw-bold">

                        Resolution Notes

                    </label>

                    <textarea name="notes"
                              class="form-control"
                              rows="3"
                              placeholder="Explain how you resolved the issue..."
                              required></textarea>

                </div>

                <button type="submit"
                        class="btn btn-primary w-100 py-2 fw-bold shadow-sm">

                    Submit Resolution

                </button>

            </form>

        </div>

    </main>

</div>

<script>

    const video =
        document.getElementById(
            'cameraPreview'
        );

    const canvas =
        document.getElementById(
            'photoCanvas'
        );

    const photo =
        document.getElementById(
            'capturedPhoto'
        );

    const photoDataInput =
        document.getElementById(
            'photoData'
        );


    async function startCamera(){

        try{

            const stream =
                await navigator.mediaDevices.getUserMedia(
                    {
                        video:true
                    }
                );

            video.srcObject =
                stream;

            video.style.display =
                'block';

            photo.style.display =
                'none';

            document.getElementById(
                'btnStart'
            ).classList.add('d-none');

            document.getElementById(
                'btnCapture'
            ).classList.remove('d-none');

            document.getElementById(
                'btnRetake'
            ).classList.add('d-none');

        }
        catch(err){

            alert(
                "Camera access denied!"
            );
        }
    }


    function capturePhoto(){

        canvas.width =
            video.videoWidth;

        canvas.height =
            video.videoHeight;

        canvas
            .getContext('2d')
            .drawImage(
                video,
                0,
                0
            );


        const data =
            canvas.toDataURL(
                'image/jpeg'
            );


        photo.src =
            data;

        photo.style.display =
            'block';

        video.style.display =
            'none';

        photoDataInput.value =
            data;


        document.getElementById(
            'btnCapture'
        ).classList.add('d-none');

        document.getElementById(
            'btnRetake'
        ).classList.remove('d-none');


        video.srcObject
            .getTracks()
            .forEach(track => track.stop());
    }

</script>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>

</body>

</html>