<%@ page contentType="application/json;charset=UTF-8" language="java" trimDirectiveWhitespaces="true" %>
<%@ page import="conexion.conexionBD" %>
<%@ page import="java.sql.*" %>
<%@ page import="org.json.JSONObject" %>
<%@ page import="org.json.JSONArray" %>
<%

request.setCharacterEncoding("UTF-8"); // Fija la codificacion que interpreta los datos en UTF-8.
response.setCharacterEncoding("UTF-8"); // Fija codificacion de respuesta en UTF-8.
response.setHeader("Access-Control-Allow-Origin", "*");
String metodo = request.getMethod(); // Guarda en la variable "metodo" la peticion HTTP, o sea GET, DELETE, etc.

// El navegador manda "OPTIONS" antes de un DELETE para preguntar si tiene permiso (preflight).
if ("OPTIONS".equalsIgnoreCase(metodo)) {
    response.setHeader("Access-Control-Allow-Methods", "GET, POST, DELETE, OPTIONS");
    response.setHeader("Access-Control-Allow-Headers", "Content-Type, Authorization");
    response.setStatus(200);
    return;
}

// En este try sí la peticion es "GET" entonces toma el parametro "usuarioId"...
// si el usuario devuelve null entonces lanza error 400 e imprime mensaje "Se requiere usuarioId".
try {
    if ("GET".equalsIgnoreCase(metodo)) {

        String userIdStr = request.getParameter("usuarioId");
        if (userIdStr == null) {
            response.setStatus(400);
            out.print("{\"message\":\"Se requiere usuarioId\"}");
            return;
        }

// Convierte usuario en numero entero, luego solicita la conexion a la BD..
// si la conexion falla (null) entonces responde con error 500 e imprime mensaje,
        int userId = Integer.parseInt(userIdStr);
        Connection con = conexionBD.getConexion();
        if (con == null) {
            response.setStatus(500);
            out.print("{\"message\":\"Error de conexión\"}");
            return;
        }

// Primero prepara y ejecuta consulta SQL que llama el "id, titulo," etc de "TMDB".
// de cada "Favoritos" que pertenecen a ese usuario...
// luego "Resultset rs" mantendrá el resultado de la consulta fila por fila.
        PreparedStatement ps = con.prepareStatement(
            "SELECT tmdb_id, titulo, poster_path FROM favoritos WHERE usuario_id = ?");
        ps.setInt(1, userId);
        ResultSet rs = ps.executeQuery();
        
// Recorre cada fila del resultado "rs.next" (avanzando fila por fila) por cada favorito...
// luego crea objeto JSON con los tres datos y luego lo agrega al arreglo..
// al final se obtiene la lista completa de favoritos.
        JSONArray arr = new JSONArray();
        while (rs.next()) {
            JSONObject fav = new JSONObject();
            fav.put("tmdb_id",     rs.getInt("tmdb_id"));
            fav.put("titulo",      rs.getString("titulo"));
            fav.put("poster_path", rs.getString("poster_path"));
            arr.put(fav);
        }

        con.close(); // Cierra la conexion BD
        response.setStatus(200); // Responde con estado 200 ("OK")
        out.print(arr.toString()); // Imprime el arreglo en texto JSON

// Si a peticion es "POST" entonces lee el body de la peticion linea por linea..
// luego concatena todo en un "StringBuilder" y convierte ese texto en un objeto
// para extraer todos los campos mas facilmente.
    } else if ("POST".equalsIgnoreCase(metodo)) {

        StringBuilder sb = new StringBuilder();
        String line;
        while ((line = request.getReader().readLine()) != null) sb.append(line);
        JSONObject body = new JSONObject(sb.toString());
        
// Extrae del "usuarioId" y "movieId" con "getInt" (si falla entonces no existe)..
// el titulo y el poster de la pelicula. "action" es opcional: si viene como "remove"
// se elimina directamente (usado desde perfil.html), sin depender del metodo DELETE
// (bloqueado por el servidor/proxy en este entorno, por eso daba error 405).
        int userId    = body.getInt("usuarioId");
        int movieId   = body.getInt("movieId");
        String titulo = body.optString("movieTitle", "");
        String poster = body.optString("posterPath", "");
        String accion = body.optString("action", "add");

// Solicita la conexion BD, si es null entonces salta error 500 con mensaje "Error de conexion".
        Connection con = conexionBD.getConexion();
        if (con == null) {
            response.setStatus(500);
            out.print("{\"message\":\"Error de conexión\"}");
            return;
        }

        if ("remove".equalsIgnoreCase(accion)) {
            PreparedStatement del = con.prepareStatement(
                "DELETE FROM favoritos WHERE usuario_id = ? AND tmdb_id = ?");
            del.setInt(1, userId);
            del.setInt(2, movieId);
            del.executeUpdate();
            con.close();
            response.setStatus(200);
            out.print("{\"action\":\"removed\"}");
            return;
        }

// Aqui antes de decidir si agregar, primero verifica si esa combinacion de usuario y pelicula..
// ya existe en la tabla "favoritos", si existe aparece, sino entonces no aparecerá.
        PreparedStatement check = con.prepareStatement(
            "SELECT id FROM favoritos WHERE usuario_id = ? AND tmdb_id = ?");
        check.setInt(1, userId);
        check.setInt(2, movieId);
        ResultSet rs = check.executeQuery();

// Si "rs.next" encuentra una fila existente, YA es favorito: no se elimina, solo se informa.
// La eliminación de favoritos se hace con action "remove" (ver arriba),
// usado desde perfil.html con el boton "Eliminar".
        if (rs.next()) {
            response.setStatus(200);
            out.print("{\"action\":\"exists\"}");
        } else {
            PreparedStatement ins = con.prepareStatement(
                "INSERT INTO favoritos (usuario_id, tmdb_id, titulo, poster_path) VALUES (?, ?, ?, ?)");
            ins.setInt(1, userId);
            ins.setInt(2, movieId);
            ins.setString(3, titulo);
            ins.setString(4, poster);
            ins.executeUpdate();
            response.setStatus(200);
            out.print("{\"action\":\"added\"}");
        }

        con.close(); // Cierra conexion con BD

// Si la peticion no es "GET" ni "POST" entonces responde error 405 e imprime mensaje...
    } else {
        response.setStatus(405);
        out.print("{\"message\":\"Método no permitido\"}");
    }

// Este catch agarra cualquier error inespeado en todo el proceso, ya sea SQL, JSON, etc..
// luego lo imprime en consola, para despues responder con error 500 y mostrar mensaje de error.
} catch (Exception e) {
    e.printStackTrace();
    response.setStatus(500);
    out.print(new JSONObject().put("message", "Error: " + e.getMessage()).toString());
}
%>