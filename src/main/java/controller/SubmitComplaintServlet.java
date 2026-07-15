package controller;

import dao.ComplaintDAO;
import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet("/SubmitComplaintServlet")
public class SubmitComplaintServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {

        // 1. Fetch parameters from AJAX
        String category = request.getParameter("category");
        String description = request.getParameter("description");
        String location = request.getParameter("location");
        String photoData = request.getParameter("photoData");

        // 2. Fetch CITIZEN_ID from Session
        HttpSession session = request.getSession();
        Integer citizenId = (Integer) session.getAttribute("citizen_id");
        if (citizenId == null) {
            citizenId = 46; // Default fallback for testing
        }

        // 3. Call DAO Layer to process database operation
        ComplaintDAO complaintDAO = new ComplaintDAO();
        String trackingId = complaintDAO.insertComplaint(citizenId, category, description, location, photoData);

        // 4. Send Tracking ID or Error message back to AJAX
        response.setContentType("text/plain");
        response.setCharacterEncoding("UTF-8");
        if ("Database Error".equals(trackingId) || "CMP-ERROR".equals(trackingId)) {
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
        }
        response.getWriter().write(trackingId);
    }
}