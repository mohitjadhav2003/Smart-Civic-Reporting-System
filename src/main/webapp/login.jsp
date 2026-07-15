<%@ page contentType="text/html;charset=UTF-8" language="java" %>

<!DOCTYPE html>
<html>

<head>

    <title>Smart Civic - Login</title>

    <meta charset="UTF-8">

    <meta name="viewport"
          content="width=device-width, initial-scale=1.0">

    <!-- Bootstrap CSS -->

    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css"
          rel="stylesheet">

    <style>

        body{

            background: #6f7da5;

            height: 100vh;

            display: flex;

            justify-content: center;

            align-items: center;

            font-family: Arial, sans-serif;
        }

        .login-card{

            width: 400px;

            background: white;

            padding: 35px;

            border-radius: 15px;

            box-shadow: 0px 5px 20px rgba(0,0,0,0.3);
        }

        .title{

            text-align: center;

            margin-bottom: 25px;

            color: #203a43;

            font-weight: bold;
        }

        .btn-login{

            width: 100%;

            background-color: #203a43;

            color: white;

            font-weight: bold;

            padding: 10px;
        }

        .btn-login:hover{

            background-color: #162b32;
        }

        .register-link{

            text-align: center;

            margin-top: 15px;
        }

    </style>

</head>

<body>

<div class="login-card">

    <h2 class="title">

        Smart Civic Login

    </h2>

    <form action="login" method="post">

        <!-- Email -->

        <div class="mb-3">

            <label class="form-label">
                Email Address
            </label>

            <input type="email"
                   class="form-control"
                   name="email"
                   placeholder="Enter your email"
                   required>

        </div>

        <!-- Password -->

        <div class="mb-3">

            <label class="form-label">
                Password
            </label>

            <input type="password"
                   class="form-control"
                   name="password"
                   placeholder="Enter your password"
                   required>

        </div>

        <!-- Login Button -->

        <button type="submit"
                class="btn btn-login">

            Login

        </button>

    </form>

    <!-- Register Link -->

    <div class="register-link">

        Don't have an account?

        <a href="register.jsp">

            Register Here

        </a>

    </div>

</div>

</body>

</html>