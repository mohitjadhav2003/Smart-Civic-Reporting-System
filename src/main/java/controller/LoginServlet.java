package controller;

import dao.UserDAO;
import model.User;

import java.io.IOException;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet("/login")
public class LoginServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    protected void doPost(
            HttpServletRequest request,
            HttpServletResponse response)

            throws ServletException, IOException {

        String email =
                request.getParameter("email");

        String password =
                request.getParameter("password");

        System.out.println(
                email + "," + password
        );

        UserDAO userDAO =
                new UserDAO();

        /* =========================================================
           LOGIN VALIDATION
        ========================================================= */

        boolean isValidUser =
                userDAO.loginUser(
                        email,
                        password
                );

        System.out.println(
                "validation : " + isValidUser
        );

        if(isValidUser){

            /* =====================================================
               GET USER DATA
            ===================================================== */

            User loggedInUser =
                    userDAO.getUserByEmail(email);

            if(loggedInUser != null){

                /* =================================================
                   CREATE SESSION
                ================================================= */

                HttpSession session =
                        request.getSession();

                System.out.println(

                        loggedInUser.getId()
                                + ","
                                + loggedInUser.getName()
                                + ","
                                + loggedInUser.getEmail()
                                + ","
                                + loggedInUser.getRole()
                                + ","
                                + loggedInUser.getDepartment()
                );

                /* =================================================
                   OLD SESSION VARIABLES
                ================================================= */

                session.setAttribute(
                        "citizen_id",
                        loggedInUser.getId()
                );

                session.setAttribute(
                        "user",
                        loggedInUser.getName()
                );

                session.setAttribute(
                        "email",
                        loggedInUser.getEmail()
                );

                session.setAttribute(
                        "role",
                        loggedInUser.getRole()
                );

                session.setAttribute(
                        "profileImage",
                        loggedInUser.getProfileImage()
                );

                /* =================================================
                   NEW COMMON SESSION VARIABLES
                ================================================= */

                session.setAttribute(
                        "userId",
                        String.valueOf(
                                loggedInUser.getId()
                        )
                );

                session.setAttribute(
                        "userName",
                        loggedInUser.getName()
                );

                session.setAttribute(
                        "userDept",
                        loggedInUser.getDepartment()
                );

                session.setAttribute(
                        "userRole",
                        loggedInUser.getRole()
                );

                /* =================================================
                   TECHNICIAN SESSION
                ================================================= */

                if("Technician".equalsIgnoreCase(
                        loggedInUser.getRole())){

                    session.setAttribute(
                            "techId",
                            String.valueOf(
                                    loggedInUser.getId()
                            )
                    );

                    session.setAttribute(
                            "techUser",
                            loggedInUser.getName()
                    );

                    session.setAttribute(
                            "techDept",
                            loggedInUser.getDepartment()
                    );
                }

                System.out.println(
                        "role : "
                                + loggedInUser.getRole()
                );

                /* =================================================
                   ROLE BASED REDIRECT
                ================================================= */

                if("Technician".equalsIgnoreCase(
                        loggedInUser.getRole())){

                    response.sendRedirect(
                            "TechnicianJSP/Tech-Admin.jsp"
                    );
                }

                else if("Admin".equalsIgnoreCase(
                        loggedInUser.getRole())){

                    response.sendRedirect(
                            "AdminJSP/admin-dashboard.jsp"
                    );
                }

                else{

                    System.out.println(
                            "Redirecting Citizen..."
                    );

                    response.sendRedirect(
                            "CitizenJSP/dashboard.jsp"
                    );
                }
            }

            else{

                request.setAttribute(
                        "error",
                        "Profile not found."
                );

                request.getRequestDispatcher(
                        "/login.jsp"
                ).forward(
                        request,
                        response
                );
            }
        }

        else{

            request.setAttribute(
                    "error",
                    "Invalid Email or Password!"
            );

            request.getRequestDispatcher(
                    "/login.jsp"
            ).forward(
                    request,
                    response
            );
        }
    }
}