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
    <title>Report an Issue - Smart Civic</title>
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

        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: var(--main-bg); color: var(--text-dark); margin: 0; overflow-x: hidden; }
        .wrapper { display: flex; min-height: 100vh; }
        .sidebar { width: 260px; background-color: var(--sidebar-bg); padding: 20px 15px; display: flex; flex-direction: column; border-right: 1px solid #e2e8f0; }
        .logo-container { display: flex; align-items: center; gap: 10px; padding: 10px; margin-bottom: 20px; }
        .logo-icon { font-size: 24px; color: #2563eb; }
        .logo-text h5 { margin: 0; font-weight: bold; color: #0f172a; }
        .logo-text span { font-size: 11px; color: var(--text-muted); }
        .nav-btn-add { background-color: #2e964f; color: white; border-radius: 8px; padding: 12px 15px; font-weight: bold; display: flex; align-items: center; gap: 10px; text-decoration: none; margin-bottom: 15px; transition: 0.2s; box-shadow: 0 4px 10px rgba(59, 177, 96, 0.2); }
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

        .content-panel { border: 1px solid #e2e8f0; border-radius: 16px; padding: 35px; background: white; max-width: 900px;}
        .form-label { font-weight: 600; color: #334155; font-size: 14px; margin-bottom: 8px;}
        .form-text { font-size: 12px; color: var(--text-muted); }
        .form-control, .form-select { border-radius: 8px; padding: 12px 15px; border: 1px solid #cbd5e1; background-color: #f8fafc; font-size: 15px; }
        .form-control:focus, .form-select:focus { background-color: white; border-color: #3b82f6; box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1); }
        .btn-submit { background-color: var(--primary-green); color: white; padding: 12px 30px; border-radius: 8px; font-weight: bold; border: none; transition: 0.2s; font-size: 16px; }
        .btn-submit:hover { background-color: #2e964f; transform: translateY(-1px); }
        .location-btn { position: absolute; right: 15px; top: 40px; background: none; border: none; color: #3b82f6; font-weight: 500; }
        .location-btn:disabled { color: #94a3b8; cursor: not-allowed; }

        .camera-container { border: 2px solid #cbd5e1; border-radius: 12px; padding: 15px; background-color: #f8fafc; text-align: center; }
        #cameraPreview { width: 100%; max-width: 500px; border-radius: 8px; background-color: #000; display: none; }
        #capturedPhoto { width: 100%; max-width: 500px; border-radius: 8px; display: none; border: 2px solid var(--primary-green); }
        .camera-controls { margin-top: 15px; display: flex; justify-content: center; gap: 10px; }
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
            <li class="nav-item"><a href="profile.jsp" class="nav-link"><i class="bi bi-person"></i> Profile</a></li>
            <li class="nav-item mt-3"><a href="help-support.jsp" class="nav-link"><i class="bi bi-question-circle"></i> Help & Support</a></li>
        </ul>

        <a href="logout.jsp" class="logout-btn"><i class="bi bi-box-arrow-right me-2"></i> Logout</a>
    </aside>

    <main class="main-content">
        <header class="top-header">
            <h4 class="m-0 fw-bold">Report a New Issue</h4>
            <div class="user-profile">
                <div class="position-relative"><i class="bi bi-bell fs-5 text-muted"></i></div>
                <div class="d-flex align-items-center gap-2 ms-3">
                    <img src="https://ui-avatars.com/api/?name=<%= java.net.URLEncoder.encode(user, "UTF-8") %>&background=random" alt="<%= user %>">
                    <span class="fw-medium"><%= user %></span>
                </div>
            </div>
        </header>

        <div class="content-panel">
            <div class="alert alert-success alert-dismissible fade show d-none" id="successAlert" role="alert">
                <h5 class="alert-heading"><i class="bi bi-check-circle-fill me-2"></i> Complaint Submitted Successfully!</h5>
                <p class="mb-0">Your tracking ID is <strong id="trackingIdDisplay"></strong>. You can check the status in the "Track Status" tab.</p>
                <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
            </div>

            <form id="complaintForm" onsubmit="submitComplaint(event)">
                <h5 class="fw-bold mb-4 border-bottom pb-2">Issue Details</h5>
                <div class="row g-4 mb-4">
                    <div class="col-md-6">
                        <label class="form-label">Category <span class="text-danger">*</span></label>
                        <select class="form-select" id="categoryInput" required>
                            <option value="" selected disabled>Select the type of issue</option>
                            <option value="Garbage Overflow">Garbage Overflow & Cleaning</option>
                            <option value="Street Light">Street Light Not Working</option>
                            <option value="Water Leakage">Water Leakage / Supply Issue</option>
                            <option value="Road Damage">Road Damage / Potholes</option>
                            <option value="Sewage Blockage">Drainage / Sewage Blockage</option>
                            <option value="Other">Other</option>
                        </select>
                    </div>

                    <div class="col-md-6">
                        <label class="form-label">Priority Level</label>
                        <select class="form-select" id="priorityInput">
                            <option value="Low">Low (Minor inconvenience)</option>
                            <option value="Medium" selected>Medium (Standard issue)</option>
                            <option value="High">High (Safety hazard / Urgent)</option>
                        </select>
                    </div>

                    <div class="col-12 position-relative">
                        <label class="form-label">Location / Landmark <span class="text-danger">*</span></label>
                        <input type="text" class="form-control pe-5" id="locationInput" placeholder="Enter street name, sector, or nearest landmark" required>
                        <button type="button" class="location-btn" id="locateBtn" onclick="getLocation()" title="Use current location">
                            <i class="bi bi-crosshair"></i> Locate Me
                        </button>
                    </div>

                    <div class="col-12">
                        <label class="form-label">Description <span class="text-danger">*</span></label>
                        <textarea class="form-control" id="descriptionInput" rows="4" placeholder="Please describe the problem in detail..." required></textarea>
                    </div>
                </div>

                <h5 class="fw-bold mb-3 border-bottom pb-2">Photo Evidence</h5>
                <div class="camera-container mb-4">
                    <video id="cameraPreview" autoplay playsinline></video>
                    <img id="capturedPhoto" alt="Captured Issue">
                    <canvas id="photoCanvas" class="d-none"></canvas>
                    <input type="hidden" id="photoData">

                    <div class="camera-controls">
                        <button type="button" class="btn btn-primary" id="btnStartCamera" onclick="startCamera()"><i class="bi bi-camera-video me-1"></i> Start Camera</button>
                        <button type="button" class="btn btn-success d-none" id="btnCapturePhoto" onclick="capturePhoto()"><i class="bi bi-camera me-1"></i> Take Photo</button>
                        <button type="button" class="btn btn-warning d-none" id="btnRetakePhoto" onclick="retakePhoto()"><i class="bi bi-arrow-counterclockwise me-1"></i> Retake</button>
                    </div>
                </div>

                <div class="d-flex justify-content-end gap-3 mt-5">
                    <button type="reset" class="btn btn-light border px-4 py-2 fw-medium" onclick="resetForm()">Clear Form</button>
                    <button type="submit" class="btn btn-submit" id="submitBtn"><i class="bi bi-send me-2"></i> Submit Complaint</button>
                </div>
            </form>
        </div>
    </main>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script>

    /* =========================================================
       LIVE LOCATION FUNCTION
    ========================================================= */

    async function getLocation() {

        const locationInput =
            document.getElementById(
                'locationInput'
            );

        const locateBtn =
            document.getElementById(
                'locateBtn'
            );

        const originalBtnHTML =
            locateBtn.innerHTML;


        /* =========================================================
           CHECK GEOLOCATION SUPPORT
        ========================================================= */

        if (!navigator.geolocation) {

            alert(
                "Geolocation is not supported in your browser."
            );

            return;
        }


        /* =========================================================
           BUTTON LOADING
        ========================================================= */

        locateBtn.innerHTML =
            '<span class="spinner-border spinner-border-sm"></span> Locating...';

        locateBtn.disabled = true;


        /* =========================================================
           GET CURRENT POSITION
        ========================================================= */

        navigator.geolocation.getCurrentPosition(

            /* =========================================================
               SUCCESS
            ========================================================= */

            async function(position) {

                try {

                    const latitude =
                        position.coords.latitude;

                    const longitude =
                        position.coords.longitude;


                    console.log(
                        "Latitude:",
                        latitude
                    );

                    console.log(
                        "Longitude:",
                        longitude
                    );


                    /* =========================================================
                       REVERSE GEOCODING API
                    ========================================================= */

                    const apiURL =
                        "https://nominatim.openstreetmap.org/reverse?format=jsonv2"
                        + "&lat=" + latitude
                        + "&lon=" + longitude;


                    const response =
                        await fetch(apiURL, {

                            method: "GET",

                            headers: {

                                "Accept":
                                    "application/json"
                            }
                        });


                    const data =
                        await response.json();


                    console.log(data);


                    /* =========================================================
                       FINAL ADDRESS
                    ========================================================= */

                    let finalAddress = "";


                    if (
                        data &&
                        data.display_name
                    ) {

                        finalAddress =
                            data.display_name;

                    }
                    else {

                        finalAddress =
                            "Latitude: "
                            + latitude
                            + ", Longitude: "
                            + longitude;
                    }


                    /* =========================================================
                       SET LOCATION IN INPUT
                    ========================================================= */

                    locationInput.value =
                        finalAddress;


                    /* =========================================================
                       SAVE LATITUDE & LONGITUDE
                    ========================================================= */

                    locationInput.setAttribute(
                        "data-latitude",
                        latitude
                    );

                    locationInput.setAttribute(
                        "data-longitude",
                        longitude
                    );


                    /* =========================================================
                       RESET BUTTON
                    ========================================================= */

                    locateBtn.innerHTML =
                        originalBtnHTML;

                    locateBtn.disabled =
                        false;

                }
                catch(error) {

                    console.log(error);

                    alert(
                        "Unable to fetch address from GPS."
                    );

                    locateBtn.innerHTML =
                        originalBtnHTML;

                    locateBtn.disabled =
                        false;
                }

            },


            /* =========================================================
               ERROR FUNCTION
            ========================================================= */

            function(error) {

                let message =
                    "Location access denied.";


                if(error.code === 1) {

                    message =
                        "Please allow location permission.";

                }
                else if(error.code === 2) {

                    message =
                        "Location unavailable.";

                }
                else if(error.code === 3) {

                    message =
                        "Location request timeout.";
                }


                alert(message);

                locateBtn.innerHTML =
                    originalBtnHTML;

                locateBtn.disabled =
                    false;
            },


            /* =========================================================
               OPTIONS
            ========================================================= */

            {
                enableHighAccuracy: true,
                timeout: 15000,
                maximumAge: 0
            }

        );
    }



    /* =========================================================
       CAMERA LOGIC
    ========================================================= */

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

    const btnStart =
        document.getElementById(
            'btnStartCamera'
        );

    const btnCapture =
        document.getElementById(
            'btnCapturePhoto'
        );

    const btnRetake =
        document.getElementById(
            'btnRetakePhoto'
        );

    let currentStream = null;


    async function startCamera() {

        try {

            const stream =
                await navigator.mediaDevices.getUserMedia({

                    video: {
                        facingMode: "environment"
                    }

                });


            currentStream = stream;

            video.srcObject = stream;

            video.style.display =
                'inline-block';

            photo.style.display =
                'none';

            btnStart.style.display =
                'none';

            btnCapture.classList.remove(
                'd-none'
            );

            btnRetake.classList.add(
                'd-none'
            );

        }
        catch (err) {

            alert(
                "Could not access camera."
            );
        }
    }


    function capturePhoto() {

        const context =
            canvas.getContext('2d');


        canvas.width =
            video.videoWidth;

        canvas.height =
            video.videoHeight;


        context.drawImage(
            video,
            0,
            0,
            canvas.width,
            canvas.height
        );


        const imageData =
            canvas.toDataURL(
                'image/png'
            );


        photoDataInput.value =
            imageData;


        photo.setAttribute(
            'src',
            imageData
        );


        stopCamera();


        video.style.display =
            'none';

        photo.style.display =
            'inline-block';

        btnCapture.classList.add(
            'd-none'
        );

        btnRetake.classList.remove(
            'd-none'
        );
    }


    function stopCamera() {

        if (currentStream) {

            currentStream.getTracks().forEach(

                track => track.stop()

            );

            currentStream = null;
        }
    }


    function retakePhoto() {

        photoDataInput.value = '';

        startCamera();
    }


    function resetForm() {

        stopCamera();

        video.style.display = 'none';

        photo.style.display = 'none';

        photoDataInput.value = '';

        btnStart.style.display =
            'inline-block';

        btnCapture.classList.add(
            'd-none'
        );

        btnRetake.classList.add(
            'd-none'
        );
    }



    /* =========================================================
       SUBMIT COMPLAINT
    ========================================================= */

    function submitComplaint(event) {

        event.preventDefault();


        if(photoDataInput.value === '') {

            if(
                !confirm(
                    "You haven't attached a photo. Do you want to submit anyway?"
                )
            ) {

                return;
            }
        }


        const submitBtn =
            document.getElementById(
                'submitBtn'
            );


        submitBtn.innerHTML =
            '<span class="spinner-border spinner-border-sm me-2"></span> Submitting...';

        submitBtn.disabled = true;


        const categoryStr =
            document.getElementById(
                "categoryInput"
            ).value;


        const priorityStr =
            document.getElementById(
                "priorityInput"
            ).value;


        const descStr =
            document.getElementById(
                "descriptionInput"
            ).value;


        const finalDescription =
            "[Priority: "
            + priorityStr
            + "] "
            + descStr;


        const formData =
            new URLSearchParams();


        formData.append(
            "category",
            categoryStr
        );

        formData.append(
            "description",
            finalDescription
        );

        formData.append(
            "location",
            document.getElementById(
                "locationInput"
            ).value
        );

        formData.append(
            "photoData",
            photoDataInput.value
        );


        /* =========================================================
           LATITUDE & LONGITUDE SEND
        ========================================================= */

        formData.append(
            "latitude",
            document.getElementById(
                "locationInput"
            ).getAttribute(
                "data-latitude"
            )
        );

        formData.append(
            "longitude",
            document.getElementById(
                "locationInput"
            ).getAttribute(
                "data-longitude"
            )
        );


        /* =========================================================
           SEND TO SERVLET
        ========================================================= */

        fetch(
            '<%=request.getContextPath()%>/SubmitComplaintServlet',

            {

                method: 'POST',

                headers: {

                    'Content-Type':
                        'application/x-www-form-urlencoded'
                },

                body:
                    formData.toString()
            }

        )

            .then(response => response.text())

            .then(data => {

                document.getElementById(
                    'trackingIdDisplay'
                ).innerText = data;


                const alertBox =
                    document.getElementById(
                        'successAlert'
                    );


                alertBox.classList.remove(
                    'd-none'
                );


                window.scrollTo({

                    top: 0,

                    behavior: 'smooth'
                });


                document.getElementById(
                    'complaintForm'
                ).reset();


                resetForm();


                submitBtn.innerHTML =
                    '<i class="bi bi-send me-2"></i> Submit Complaint';


                submitBtn.disabled =
                    false;


                setTimeout(() => {

                    alertBox.classList.add(
                        'd-none'
                    );

                }, 6000);

            })

            .catch(error => {

                console.log(error);

                alert(
                    "Server Error! Please try again."
                );


                submitBtn.innerHTML =
                    '<i class="bi bi-send me-2"></i> Submit Complaint';


                submitBtn.disabled =
                    false;
            });
    }

</script>
</body>
</html>