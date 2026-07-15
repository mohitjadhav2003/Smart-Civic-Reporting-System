package controller;

import utility.DBConnection;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet("/UploadResolutionServlet")
public class UploadResolutionServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    protected void doPost(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session =
                request.getSession();

        String techId =
                (String) session.getAttribute("userId");

        String techUser =
                (String) session.getAttribute("userName");

        String taskId =
                request.getParameter("taskId");

        String notes =
                request.getParameter("notes");

        String photoData =
                request.getParameter("photoData");

        Connection conn = null;

        PreparedStatement ps = null;

        try {

            conn =
                    DBConnection.getConnection();

            String sql =

                    "UPDATE complaints " +
                            "SET " +
                            "status = ?, " +
                            "resolution_notes = ?, " +
                            "resolution_image = ?, " +
                            "resolved_by = ?, " +
                            "resolved_at = SYSDATE " +
                            "WHERE complaint_id = ?";

            ps =
                    conn.prepareStatement(sql);

            ps.setString(
                    1,
                    "Resolved"
            );

            ps.setString(
                    2,
                    notes
            );

            ps.setString(
                    3,
                    photoData
            );

            ps.setString(
                    4,
                    techUser
            );

            ps.setInt(
                    5,
                    Integer.parseInt(taskId)
            );

            int x =
                    ps.executeUpdate();

            if(x > 0){

                session.setAttribute(
                        "successMsg",
                        "Resolution Uploaded Successfully!"
                );
            }
            else{

                session.setAttribute(
                        "errorMsg",
                        "Database Update Failed!"
                );
            }

        }
        catch(Exception e){

            e.printStackTrace();

            session.setAttribute(
                    "errorMsg",
                    e.getMessage()
            );
        }
        finally {

            try {

                if(ps != null)
                    ps.close();

                if(conn != null)
                    conn.close();

            }
            catch(Exception ex){}
        }

        response.sendRedirect(
                "TechnicianJSP/Tech-Upload-Resolution.jsp"
        );
    }
}