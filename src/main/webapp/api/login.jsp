<%@ page contentType="application/json;charset=UTF-8" language="java" trimDirectiveWhitespaces="true" %>
<%@ page import="conexion.conexionBD" %>
<%@ page import="java.sql.*" %>
<%@ page import="org.json.JSONObject" %>
<%@ page import="org.mindrot.jbcrypt.BCrypt" %>
<%

request.setCharacterEncoding("UTF-8"); // Fija la codificacion que interpreta los datos en UTF-8
response.setCharacterEncoding("UTF-8"); // Fija codificacion de respuesta en UTF-8.

// Solo se aceptan peticiones POST (el formulario de login envía POST).
if (!"POST".equalsIgnoreCase(request.getMethod())) {
    response.setStatus(405);
    out.print("{\"message\":\"Método no permitido\"}");
    return;
}

// En este try los datos del body llegan como JSON, luego lo concatena todo hasta rehacer el texto del body.
try {
    StringBuilder sb = new StringBuilder();
    String line;
    while ((line = request.getReader().readLine()) != null) sb.append(line);

// Convierte el texto en objeto y extrae el "email" y el "password" desde el formulario del LOGIN
    JSONObject body = new JSONObject(sb.toString());
    String email    = body.optString("email", "").trim();
    String password = body.optString("password", "");

    if (email.isEmpty() || password.isEmpty()) {
        response.setStatus(400);
        out.print("{\"message\":\"Ingresa tu correo y contraseña\"}");
        return;
    }

// Conecta con la BD, si esta falla entonces responde error 500 e imprime el mensaje..
    Connection con = conexionBD.getConexion();
    if (con == null) {
        response.setStatus(500);
        out.print("{\"message\":\"No se pudo conectar a la BD\"}");
        return;
    }

    try {
        // Busca al usuario solo por email; la contraseña se compara aparte con BCrypt.
        PreparedStatement ps = con.prepareStatement(
            "SELECT id, nombre, password FROM usuarios WHERE email = ?");
        ps.setString(1, email);
        ResultSet rs = ps.executeQuery();

        boolean valido = false;
        int idUsuario = 0;
        String nombre = "";

        if (rs.next()) {
            idUsuario = rs.getInt("id");
            nombre    = rs.getString("nombre");
            String guardada = rs.getString("password");

            if (guardada != null && guardada.startsWith("$2")) {
                // Contraseña guardada como hash BCrypt (cuentas nuevas)
                valido = BCrypt.checkpw(password, guardada);
            } else if (guardada != null && guardada.equals(password)) {
                // Cuenta vieja con la contraseña en texto plano: se acepta
                // y se convierte a BCrypt para que quede protegida.
                valido = true;
                PreparedStatement up = con.prepareStatement(
                    "UPDATE usuarios SET password = ? WHERE id = ?");
                up.setString(1, BCrypt.hashpw(password, BCrypt.gensalt()));
                up.setInt(2, idUsuario);
                up.executeUpdate();
            }
        }

// Si las credenciales son correctas responde 200 con el id y el nombre del usuario.
// Si no, responde error 401 e imprime mensaje de error.
        if (valido) {
            JSONObject res = new JSONObject();
            res.put("message", "Login exitoso");
            res.put("id", idUsuario);
            res.put("nombre", nombre);
            response.setStatus(200);
            out.print(res.toString());
        } else {
            response.setStatus(401);
            out.print("{\"message\":\"Correo o contraseña incorrectos\"}");
        }
    } finally {
        con.close(); // Cierra conexion BD siempre, aunque ocurra un error
    }

} catch (Exception e) { // Toma cualquier error inesperado
    e.printStackTrace(); // Imprime en consola para depurar
    response.setStatus(500); // Responde error 500
    out.print(new JSONObject().put("message", "Error: " + e.getMessage()).toString());
}
%>
