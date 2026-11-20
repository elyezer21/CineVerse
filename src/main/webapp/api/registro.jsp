<%@ page contentType="application/json;charset=UTF-8" language="java" trimDirectiveWhitespaces="true" %>
<%@ page import="conexion.conexionBD" %>
<%@ page import="java.sql.*" %>
<%@ page import="org.json.JSONObject" %>
<%@ page import="org.mindrot.jbcrypt.BCrypt" %>
<%

request.setCharacterEncoding("UTF-8"); // Fija la codificacion que interpreta los datos en UTF-8
response.setCharacterEncoding("UTF-8"); // Fija codificacion de respuesta en UTF-8.

// Solo se aceptan peticiones POST (el formulario de registro envía POST).
if (!"POST".equalsIgnoreCase(request.getMethod())) {
    response.setStatus(405);
    out.print("{\"message\":\"Método no permitido\"}");
    return;
}

//En este try los datos del body llegan como JSON, luego lo concatena todo hasta rehacer el texto del body.
// y convierte los datos en un objeto.
try {
    StringBuilder sb = new StringBuilder();
    String line;
    while ((line = request.getReader().readLine()) != null) sb.append(line);
    JSONObject body = new JSONObject(sb.toString());

// Extrae del JSON los datos que el usuario llenó en el formulario de registro.
    String nombre   = body.optString("nombre", "").trim();
    String apellido = body.optString("apellido", "").trim();
    String email    = body.optString("email", "").trim().toLowerCase();
    String password = body.optString("password", "");

// Valida también en el servidor (las mismas reglas que registro.html),
// así nadie puede saltarse la validación del navegador.
    String error = null;
    if (nombre.length() < 2)                             error = "El nombre debe tener al menos 2 caracteres";
    else if (apellido.length() < 2)                      error = "El apellido debe tener al menos 2 caracteres";
    else if (!email.matches("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$")) error = "Ingresa un email válido";
    else if (password.length() < 8)                      error = "La contraseña debe tener al menos 8 caracteres";

    if (error != null) {
        response.setStatus(400);
        out.print(new JSONObject().put("message", error).toString());
        return;
    }

// Conecta con la BD, si este falla entonces responde con 500 e imprime mensaje de error.
    Connection con = conexionBD.getConexion();
    if (con == null) {
        response.setStatus(500);
        out.print("{\"message\":\"Sin conexión a la base de datos\"}");
        return;
    }

    try {
// Antes de crear una cuenta, primero verifica si ya hay un usuario registrado con el mismo email.
        PreparedStatement check = con.prepareStatement(
            "SELECT id FROM usuarios WHERE email = ?");
        check.setString(1, email);
        ResultSet rs = check.executeQuery();
 // si ya existe un usuario con mismo email entonces responde error 400 e imprime mensaje de error.
        if (rs.next()) {
            response.setStatus(400);
            out.print("{\"message\":\"El correo ya está registrado\"}");
            return;
        }

// Si el correo no existía entonces guarda el usuario. La contraseña se guarda
// como hash BCrypt (nunca en texto plano).
        PreparedStatement ps = con.prepareStatement(
            "INSERT INTO usuarios (nombre, apellido, email, password) VALUES (?, ?, ?, ?)");
        ps.setString(1, nombre);
        ps.setString(2, apellido);
        ps.setString(3, email);
        ps.setString(4, BCrypt.hashpw(password, BCrypt.gensalt()));
        ps.executeUpdate();

        response.setStatus(200); // Responde con 200 ("OK")
        out.print("{\"message\":\"Cuenta creada exitosamente\"}"); // Imprime mensaje de éxito.
    } finally {
        con.close(); // Cierra conexion BD siempre
    }

} catch (Exception e) { // Toma cualquier error inesperado
    e.printStackTrace(); // Imprime en consola para depurar
    response.setStatus(500); // Responde error 500
    out.print(new JSONObject().put("message", "Error: " + e.getMessage()).toString());
}
%>
