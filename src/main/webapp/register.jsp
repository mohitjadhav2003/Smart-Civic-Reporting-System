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

            font-family: Arial, sans-serif;

            background:
                    linear-gradient(rgba(20,40,90,0.65),
                    rgba(20,40,90,0.65)),
                    url("images/civic-bg.jpg");

            background-size: cover;
            background-position: center;

            height: 100vh;

            display: flex;
            justify-content: center;
            align-items: center;
        }

        .main-container{

            width: 95%;
            max-width: 1400px;

            display: flex;
            align-items: center;
            justify-content: space-between;

            gap: 50px;
        }

        /* LEFT SIDE */

        .left-section{

            width: 50%;
            color: white;
        }

        .left-section h1{

            font-size: 60px;
            font-weight: bold;
            line-height: 1.2;

            margin-bottom: 20px;
        }

        .left-section p{

            font-size: 22px;
            width: 80%;
            line-height: 1.6;
        }

        .feature-box{

            display: flex;
            flex-wrap: wrap;

            gap: 20px;

            margin-top: 40px;
        }

        .feature{

            background: rgba(255,255,255,0.15);

            backdrop-filter: blur(5px);

            border-radius: 15px;

            padding: 20px;

            width: 180px;

            text-align: center;

            transition: 0.3s;
        }

        .feature:hover{

            transform: translateY(-5px);

            background: rgba(255,255,255,0.25);
        }

        .feature i{

            font-size: 40px;
            margin-bottom: 15px;
        }

        .feature h5{

            font-size: 18px;
            font-weight: bold;
        }

        /* RIGHT SIDE */

        .register-card{

            width: 430px;

            background: white;

            border-radius: 20px;

            padding: 40px;

            box-shadow: 0px 5px 30px rgba(0,0,0,0.3);
        }

        .register-title{

            text-align: center;

            color: #1e3c72;

            font-size: 45px;

            font-weight: bold;

            margin-bottom: 30px;
        }

        .form-label{

            font-weight: bold;

            margin-bottom: 8px;
        }

        .input-group-text{

            background: white;
            border-right: none;
        }

        .form-control{

            height: 50px;
            border-left: none;
        }

        .form-control:focus{

            box-shadow: none;
            border-color: #ced4da;
        }

        .register-btn{

            width: 100%;

            height: 50px;

            background: #1e3c72;

            color: white;

            font-size: 20px;

            font-weight: bold;

            border: none;

            border-radius: 10px;

            margin-top: 10px;

            transition: 0.3s;
        }

        .register-btn:hover{

            background: #16325c;
        }

        .login-link{

            text-align: center;

            margin-top: 20px;

            font-size: 18px;
        }

        .login-link a{

            text-decoration: none;
            font-weight: bold;
        }

        /* RESPONSIVE */

        @media(max-width: 1000px){

            .main-container{

                flex-direction: column;
                padding: 30px 0;
            }

            .left-section{

                width: 100%;
                text-align: center;
            }

            .left-section p{

                width: 100%;
            }

            .feature-box{

                justify-content: center;
            }

            .register-card{

                width: 95%;
            }

            .left-section h1{

                font-size: 40px;
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