<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%
    // Session ko invalidate (destroy) karna
    session.invalidate();

    // User ko wapas login page par redirect karna
    response.sendRedirect("login.jsp");
%>