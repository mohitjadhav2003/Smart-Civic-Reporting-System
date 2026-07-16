<%@ page contentType="text/html;charset=UTF-8" language="java" %>

<!DOCTYPE html>
<html lang="en">

<head>

    <meta charset="UTF-8">

    <meta name="viewport"
          content="width=device-width, initial-scale=1.0">

    <title>Smart Civic Registration</title>

    <!-- Bootstrap -->

    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css"
          rel="stylesheet">

    <!-- Bootstrap Icons -->

    <link rel="stylesheet"
          href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">

    <style>

        *{
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body{

            font-family: 'Segoe UI', Arial, sans-serif;

            /* Set to match the solid slate blue background from the image */
            background-color: #72809d;

            height: 100vh;

            display: flex;
            justify-content: center;
            align-items: center;
        }

        .main-container{

            width: 90%;
            max-width: 1100px;

            display: flex;
            align-items: center;
            justify-content: space-between;

            gap: 40px;
        }

        /* LEFT SIDE */

        .left-section{

            width: 55%;
            color: white;
        }

        .left-section h1{

            font-size: 48px;
            font-weight: bold;
            line-height: 1.2;

            margin-bottom: 15px;
        }

        .left-section p{

            font-size: 18px;
            width: 90%;
            line-height: 1.5;
            color: #f0f2f5;
        }

        .feature-box{

            display: flex;
            flex-wrap: wrap;

            gap: 15px;

            margin-top: 35px;
            /* Limits width so the 4th item naturally falls to the next line */
            max-width: 480px;
        }

        .feature{

            background: rgba(255,255,255,0.1);

            border: 1px solid rgba(255,255,255,0.3);

            border-radius: 12px;

            padding: 20px;

            width: 140px;
            height: 130px;

            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;

            text-align: center;

            transition: 0.3s;
        }

        .feature:hover{

            background: rgba(255,255,255,0.15);
        }

        .feature i{

            font-size: 32px;
            margin-bottom: 12px;
        }

        .feature h5{

            font-size: 13px;
            font-weight: bold;
            margin: 0;
        }

        /* RIGHT SIDE */

        .register-card{

            width: 400px;

            background: white;

            border-radius: 16px;

            padding: 40px;

            box-shadow: 0px 10px 30px rgba(0,0,0,0.15);
        }

        .register-title{

            text-align: center;

            color: #1a3668;

            font-size: 32px;

            font-weight: bold;

            margin-bottom: 25px;
        }

        .form-label{

            font-weight: bold;
            font-size: 13px;
            margin-bottom: 6px;
            color: #222;
        }

        .input-group{
            border: 1px solid #d1d5db;
            border-radius: 6px;
            background: white;
            overflow: hidden;
        }

        .input-group-text{
            background: transparent;
            border: none;
            color: #6b7280;
            padding-right: 10px;
        }

        .form-control{
            height: 45px;
            border: none;
            background: transparent;
            font-size: 14px;
            padding-left: 0;
        }

        .form-control:focus{
            box-shadow: none;
        }

        .input-group:focus-within{
            border-color: #1a3668;
        }

        .register-btn{

            width: 100%;

            height: 48px;

            background: #1a3668;

            color: white;

            font-size: 16px;

            font-weight: bold;

            border: none;

            border-radius: 6px;

            margin-top: 15px;

            transition: 0.3s;
        }

        .register-btn:hover{

            background: #12264a;
        }

        .login-link{

            text-align: center;

            margin-top: 20px;

            font-size: 13px;
            color: #555;
        }

        .login-link a{

            text-decoration: none;
            font-weight: bold;
            color: #1a3668;
        }

        /* RESPONSIVE */

        @media(max-width: 1000px){

            .main-container{

                flex-direction: column;
                padding: 30px 0;
                height: auto;
            }

            body {
                height: auto;
                min-height: 100vh;
                padding: 20px 0;
            }

            .left-section{

                width: 100%;
                text-align: center;
            }

            .left-section p{
                width: 100%;
                margin: 0 auto;
            }

            .feature-box{

                justify-content: center;
                max-width: 100%;
            }

            .register-card{

                width: 90%;
                max-width: 400px;
            }

            .left-section h1{

                font-size: 38px;
            }
        }

    </style>

</head>

<body>

<div class="main-container">

    <!-- LEFT SECTION -->

    <div class="left-section">

        <h1>
            Smart Civic <br>
            Problem Reporting System
        </h1>

        <p>
            Report civic issues around you and help
            improve your city with smart digital solutions.
        </p>

        <div class="feature-box">

            <div class="feature">

                <i class="bi bi-trash"></i>

                <h5>Garbage Issue</h5>

            </div>

            <div class="feature">

                <i class="bi bi-lightbulb"></i>

                <h5>Street Light</h5>

            </div>

            <div class="feature">

                <i class="bi bi-droplet"></i>

                <h5>Water Leakage</h5>

            </div>

            <div class="feature">

                <i class="bi bi-cone-striped"></i>

                <h5>Road Damage</h5>

            </div>

        </div>

    </div>

    <!-- RIGHT SECTION -->

    <div class="register-card">

        <h2 class="register-title">

            Registration

        </h2>

        <form action="register" method="post">

            <!-- Name -->

            <div class="mb-3">

                <label class="form-label">
                    Full Name
                </label>

                <div class="input-group">

                    <span class="input-group-text">

                        <i class="bi bi-person-fill"></i>

                    </span>

                    <input type="text"
                           class="form-control"
                           name="name"
                           placeholder="Enter your name"
                           required>

                </div>

            </div>

            <!-- Email -->

            <div class="mb-3">

                <label class="form-label">
                    Email Address
                </label>

                <div class="input-group">

                    <span class="input-group-text">

                        <i class="bi bi-envelope-fill"></i>

                    </span>

                    <input type="email"
                           class="form-control"
                           name="email"
                           placeholder="Enter your email"
                           required>

                </div>

            </div>

            <!-- Password -->

            <div class="mb-3">

                <label class="form-label">
                    Password
                </label>

                <div class="input-group">

                    <span class="input-group-text">

                        <i class="bi bi-lock-fill"></i>

                    </span>

                    <input type="password"
                           class="form-control"
                           name="password"
                           placeholder="Enter password"
                           required>

                </div>

            </div>

            <!-- Mobile -->

            <div class="mb-3">

                <label class="form-label">
                    Mobile Number
                </label>

                <div class="input-group">

                    <span class="input-group-text">

                        <i class="bi bi-telephone-fill"></i>

                    </span>

                    <input type="text"
                           class="form-control"
                           name="mobile"
                           placeholder="Enter mobile number"
                           pattern="[0-9]{10}"
                           maxlength="10"
                           required>

                </div>

            </div>

            <!-- Button -->

            <button type="submit"
                    class="register-btn">

                Register

            </button>

        </form>

        <!-- Login -->

        <div class="login-link">

            Already have an account?

            <a href="login.jsp">

                Login Here

            </a>

        </div>

    </div>

</div>

</body>

</html>