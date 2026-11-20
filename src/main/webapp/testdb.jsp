<%@ page contentType="text/html;charset=UTF-8" language="java" trimDirectiveWhitespaces="true" %>
<%@ page import="conexion.conexionBD" %>
<%@ page import="java.sql.Connection" %>
<%

// Pide conexion con la BD
try {
    Connection con = conexionBD.getConexion();
// si la conexion NO es null entonces imprime mensaje de Éxito.
    if (con != null) {
        out.println("<h1>Conexion exitosa con cineverse</h1>");
        con.close(); // Cierra conexion con la BD
// si la conexion ES null entonces imprime mensaje de Error.
    } else {
        out.println("<h1>Error al conectar</h1>");
    }
// si hay error inesperado entonces imprime un encabezado de error..
// y ademas imprime el mensaje especifico de la excepcion.
} catch (Exception e) {
    out.println("<h1>Error:</h1>");
    out.println(e.getMessage());
}
%>