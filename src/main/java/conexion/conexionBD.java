package conexion;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.Statement;

// Esta clase se encarga de que la conexion a la base de datos sea únicamente en este espacio.
// O sea que esa conexion se llama desde aquí en lugar de repetir la configuración en cada uno de los archivos.
//
// Funciona en cualquier PC con XAMPP sin configurar nada:
//   1. Busca MySQL en el puerto 3306 (el normal de XAMPP) y, si no está, en el 3307.
//   2. La primera vez crea sola la base "cineverse" y sus tablas si todavía no existen
//      (lo mismo que hace database/cineverse.sql).
// Usuario root sin contraseña, como trae XAMPP. Si tu MySQL es distinto, define las variables
// de entorno CINEVERSE_DB_PORT, CINEVERSE_DB_USER y CINEVERSE_DB_PASSWORD (o CINEVERSE_DB_URL completa).
public class conexionBD {

    private static final String USUARIO  = valor("CINEVERSE_DB_USER", "root");
    private static final String PASSWORD = valor("CINEVERSE_DB_PASSWORD", "");
    private static final String OPCIONES = "useUnicode=true&characterEncoding=UTF-8&serverTimezone=America/Panama"
            + "&allowPublicKeyRetrieval=true&useSSL=false&connectTimeout=3000";

    // Puerto donde se encontró MySQL y si ya se revisó que existan la base y las tablas
    private static volatile String puertoEncontrado = null;
    private static volatile boolean baseLista = false;

    // Lee primero una propiedad del sistema (-Dclave=...), luego una variable de entorno,
    // y si no existe ninguna usa el valor por defecto.
    private static String valor(String clave, String porDefecto) {
        String v = System.getProperty(clave);
        if (v == null) v = System.getenv(clave);
        return (v == null) ? porDefecto : v;
    }

    public static Connection getConexion() {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");

            // Si se indicó una URL completa, se usa tal cual
            String urlFija = valor("CINEVERSE_DB_URL", null);
            if (urlFija != null) return DriverManager.getConnection(urlFija, USUARIO, PASSWORD);

            if (puertoEncontrado == null || !baseLista) prepararBase();
            return DriverManager.getConnection(
                    "jdbc:mysql://localhost:" + puertoEncontrado + "/cineverse?" + OPCIONES, USUARIO, PASSWORD);
        } catch (Exception e) {
            // Si el driver no carga o la conexión falla, devuelve null
            // y dejamos que cada JSP decida cómo responder.
            System.out.println("=== CineVerse: no se pudo conectar a MySQL. ¿Está encendido en XAMPP? -> " + e.getMessage());
            puertoEncontrado = null;
            baseLista = false;
            return null;
        }
    }

    // Encuentra el puerto de MySQL y crea la base y las tablas si no existen.
    private static synchronized void prepararBase() throws Exception {
        if (puertoEncontrado != null && baseLista) return;
        // Orden de búsqueda: el puerto indicado (si hay), luego 3306 y 3307, sin repetir
        java.util.LinkedHashSet<String> puertos = new java.util.LinkedHashSet<>();
        String indicado = valor("CINEVERSE_DB_PORT", null);
        if (indicado != null) puertos.add(indicado);
        puertos.add("3306");
        puertos.add("3307");
        Exception ultimoError = null;
        for (String puerto : puertos) {
            try (Connection con = DriverManager.getConnection(
                    "jdbc:mysql://localhost:" + puerto + "/?" + OPCIONES, USUARIO, PASSWORD);
                 Statement st = con.createStatement()) {
                st.execute("CREATE DATABASE IF NOT EXISTS cineverse CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci");
                st.execute("USE cineverse");
                st.execute("CREATE TABLE IF NOT EXISTS usuarios ("
                        + " id INT AUTO_INCREMENT PRIMARY KEY,"
                        + " nombre VARCHAR(80) NOT NULL,"
                        + " apellido VARCHAR(80) NOT NULL,"
                        + " email VARCHAR(150) NOT NULL,"
                        + " password VARCHAR(255) NOT NULL,"
                        + " fecha_registro TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,"
                        + " CONSTRAINT uq_usuarios_email UNIQUE (email)"
                        + ") ENGINE=InnoDB");
                st.execute("CREATE TABLE IF NOT EXISTS favoritos ("
                        + " id INT AUTO_INCREMENT PRIMARY KEY,"
                        + " usuario_id INT NOT NULL,"
                        + " tmdb_id INT NOT NULL,"
                        + " titulo VARCHAR(255) NOT NULL,"
                        + " poster_path VARCHAR(255) NULL,"
                        + " fecha_agregado TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,"
                        + " CONSTRAINT uq_favorito UNIQUE (usuario_id, tmdb_id),"
                        + " CONSTRAINT fk_favoritos_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE"
                        + ") ENGINE=InnoDB");
                st.execute("CREATE TABLE IF NOT EXISTS configuracion_usuario ("
                        + " id INT AUTO_INCREMENT PRIMARY KEY,"
                        + " usuario_id INT NOT NULL,"
                        + " clave VARCHAR(60) NOT NULL,"
                        + " valor VARCHAR(255) NULL,"
                        + " CONSTRAINT uq_config UNIQUE (usuario_id, clave),"
                        + " CONSTRAINT fk_config_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE"
                        + ") ENGINE=InnoDB");
                puertoEncontrado = puerto;
                baseLista = true;
                System.out.println("=== CineVerse: MySQL encontrado en el puerto " + puerto + ", base de datos lista ===");
                return;
            } catch (Exception e) {
                ultimoError = e;
            }
        }
        throw ultimoError;
    }
}
