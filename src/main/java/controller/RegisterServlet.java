package controller;

import dao.UserDAO;
import model.User;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

import java.io.IOException;

@WebServlet("/register")
public class RegisterServlet extends HttpServlet {

    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("text/html");

        String name = request.getParameter("name");
        String email = request.getParameter("email");
        String password = request.getParameter("password");
        String mobile = request.getParameter("mobile");

        System.out.println("Inside Register Servlet:");
        System.out.println(name + " | " +
                email + " | " +
                password + " | " +
                mobile);

        User user =
                new User(name, email, password, mobile);

        UserDAO dao = new UserDAO();

        // Check Duplicate User
        boolean userExists =
                dao.checkUserExists(email, mobile);

        if(userExists) {

            response.getWriter()
                    .println("Email or Mobile Already Exists");

        } else {

            boolean status =
                    dao.registerUser(user);

            System.out.println("Registration Status : "
                    + status);

            if(status) {

                response.sendRedirect("login.jsp");

            } else {

                response.getWriter()
                        .println("Registration Failed");
            }
        }
    }
}