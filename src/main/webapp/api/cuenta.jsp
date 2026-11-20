<%@ page contentType="application/json;charset=UTF-8" language="java" trimDirectiveWhitespaces="true" %>
<%@ page import="conexion.conexionBD" %>
<%@ page import="java.sql.*" %>
<%@ page import="org.json.JSONObject" %>
<%

response.setCharacterEncoding("UTF-8"); // Fija codificacion de respuesta en UTF-8.
response.setHeader("Access-Control-Allow-Origin", "*"); // El "*" permite que cualquier origen haga peticiones.
String metodo = request.getMethod(); // Guarda en la variable "metodo" la peticion HTTP, o sea GET, DELETE, etc.

if ("OPTIONS".equalsIgnoreCase(metodo)) { // Sí manda "OPTIONS" entonces se hace el proceso.
	// Cuando manda un "DELETE", el navegador manda peticion ("OPTIONS"), y este pregunta si tiene permiso.
    response.setHeader("Access-Control-Allow-Methods", "POST, DELETE, OPTIONS");
	// Cuando pregunta sí tiene permiso este lo autoriza.
    response.setHeader("Access-Control-Allow-Headers", "Content-Type, Authorization");
    response.setStatus(200); // El valor 200 quiere decir "OK".
    return;
}

// Tomcat no permite que un JSP reciba DELETE (responde 405 "JSPs only permit GET, POST or HEAD"),
// por eso perfil.html envía la eliminación con POST. Se deja DELETE por compatibilidad.
if (!"POST".equalsIgnoreCase(metodo) && !"DELETE".equalsIgnoreCase(metodo)) { // Sí manda otra cosa que no es POST/DELETE entonces..
    response.setStatus(405); // Manda error 405 ("Método no permitido").
    out.print("{\"message\":\"Método no permitido\"}"); // Salta mensaje explicando el error y cortando ejecución.
    return;
}

String usuarioIdParam = request.getParameter("usuarioId"); // Agarra el parámetro "usuarioId"...
System.out.println("=== EliminarCuenta: usuarioId = " + usuarioIdParam + " ==="); // y lo imprime en consola del servidor.

// Este try funciona de manera que sí algún parámetro no llega (es null o vacío)...
// entonces lanza el valor 400 que quiere decir "peticion mal formada".
// e indica mediante mensaje que falta el parámetro "usuarioId".
try {
    if (usuarioIdParam == null || usuarioIdParam.trim().isEmpty()) {
        System.out.println("=== EliminarCuenta: ERROR - falta usuarioId ===");
        response.setStatus(400);
        out.print("{\"message\":\"Falta el parámetro usuarioId\"}");
        return;
    }

    // Convierte el texto en numero entero para usarlo en la consulta SQL.
    int usuarioId = Integer.parseInt(usuarioIdParam.trim());

    // Llama a la conexion BD, si este falla devuelve null e imprime que no hay conexion a la BD...
    // y el navegador responde con el valor 500 ("Error de servidor")..
    // e imprime mensaje de error ("No se puede conectar a la BD").
    Connection con = conexionBD.getConexion();
    if (con == null) {
        System.out.println("=== EliminarCuenta: ERROR - no hay conexion BD ===");
        response.setStatus(500);
        out.print("{\"message\":\"No se pudo conectar a la BD\"}");
        return;
    }

// Este try borra la config del usuario de la tabla, pero si no existe config de usuario..
// entonces no afecta el proceso de eliminacion, solo registaria el error en consola y continuaria.
    try {
        PreparedStatement delConfig = con.prepareStatement(
            "DELETE FROM configuracion_usuario WHERE usuario_id = ?");
        delConfig.setInt(1, usuarioId);
        int c = delConfig.executeUpdate();
        System.out.println("=== EliminarCuenta: config eliminadas = " + c + " ===");
    } catch (Exception ex) {
        // Esta tabla es opcional, si no existe no debe frenar el resto del borrado
        System.out.println("=== EliminarCuenta: tabla configuracion_usuario no afectada: " + ex.getMessage() + " ===");
    }

// Aqui elimina todos los Favoritos que tenga el usuario en la tabla "favoritos".
    PreparedStatement delFavs = con.prepareStatement(
        "DELETE FROM favoritos WHERE usuario_id = ?");
    delFavs.setInt(1, usuarioId);
    int favs = delFavs.executeUpdate();
    System.out.println("=== EliminarCuenta: favoritos eliminados = " + favs + " ===");

// Aqui elimina al usuario completamente de la tabla "usuarios".
    PreparedStatement delUser = con.prepareStatement(
        "DELETE FROM usuarios WHERE id = ?");
    delUser.setInt(1, usuarioId);
    int filas = delUser.executeUpdate();
    System.out.println("=== EliminarCuenta: usuarios eliminados = " + filas + " ===");
    con.close();

// En caso de que hayan mas de un usuario en la tabla "usuarios"...
// entonces responde con 200 ("OK") y lanza mensaje de "Cuenta eliminada correctamente".
// Si no hay usuarios en la tabla entonces responde con 404 ("Not found error")...
// e imprime mensaje de "usuario no encontrado en la BD".
    if (filas > 0) {
        response.setStatus(200);
        out.print("{\"message\":\"Cuenta eliminada correctamente\"}");
    } else {
        response.setStatus(404);
        out.print("{\"message\":\"Usuario no encontrado en la BD\"}");
    }

// En este catch si el usuarioId no es un numero entonces lanza error 400 e imprime mensaje..
// cualquier otro error lanza 500 e imprime mensaje de error.
} catch (NumberFormatException e) {
    System.out.println("=== EliminarCuenta: usuarioId no es numero: " + usuarioIdParam + " ===");
    response.setStatus(400);
    out.print("{\"message\":\"usuarioId inválido\"}");
} catch (Exception e) {
    System.out.println("=== EliminarCuenta: EXCEPCION: " + e.getMessage() + " ===");
    e.printStackTrace();
    response.setStatus(500);
    out.print(new JSONObject().put("message", "Error: " + e.getMessage()).toString());
}
%>