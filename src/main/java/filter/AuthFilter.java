package filter;

import javax.servlet.*;
import javax.servlet.annotation.WebFilter;
import javax.servlet.http.*;

import java.io.IOException;

@WebFilter("/dashboard.jsp")
public class AuthFilter implements Filter {

    public void doFilter(ServletRequest request,
                         ServletResponse response,
                         FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest req =
                (HttpServletRequest) request;

        HttpServletResponse res =
                (HttpServletResponse) response;

        HttpSession session =
                req.getSession(false);

        if(session == null ||
                session.getAttribute("user") == null) {

            res.sendRedirect("login.jsp");

        } else {

            chain.doFilter(request, response);
        }
    }
}