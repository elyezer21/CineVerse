# CineVerse — Proyecto Final Programación de Software II (UTP)

Plataforma web de películas: catálogo con búsqueda y filtros (API de TMDB), reproductor de tráileres,
registro e inicio de sesión, favoritos por usuario y eliminación de cuenta.

**Tecnologías:** HTML/CSS/JavaScript · JSP (Java) · Apache Tomcat 9 · MySQL (XAMPP) · Maven

---

## Ejecutarlo rápido (para la clase)

### Lo que necesitas instalado (una sola vez)

| Programa | Para qué | Dónde |
|---|---|---|
| **Java JDK 17 o 21** (sirve desde el 11) | Ejecutar la página | <https://adoptium.net> → "Temurin 21 (LTS)", instalador `.msi`. Marca la opción **"Set JAVA_HOME"**. |
| **XAMPP** | La base de datos MySQL | <https://www.apachefriends.org> |

No hace falta instalar Maven ni Tomcat: se descargan solos la primera vez.

### Pasos

1. Descomprime el zip, por ejemplo en `Descargas\CineVerse`.
2. Abre el **XAMPP Control Panel** y pulsa **Start** en **MySQL**.
3. Haz **doble clic en `iniciar-cineverse.bat`**.
4. Espera. Cuando la ventana diga `Tomcat 9.0.98 started on port [8080]`, la página se abre sola en
   **<http://localhost:8080/CineVerse/>**.
5. Para apagarla, cierra la ventana negra.

> **Importante para el día de la presentación:** la primera ejecución descarga unos 30 MB (Maven, Tomcat y
> librerías) y necesita internet. **Ejecútalo una vez en tu casa antes de la clase.** Después arranca en
> segundos, aunque la red de la universidad sea lenta. Ojo: los pósteres y tráileres sí necesitan internet,
> porque vienen de TMDB y YouTube.

**No tienes que crear la base de datos.** La primera vez que se conecta, la página busca MySQL en los puertos
3306 y 3307 y crea sola la base `cineverse` con sus tablas. El script `database/cineverse.sql` queda solo como
respaldo, por si quieres crearla a mano desde phpMyAdmin.

---

## Ejecutarlo desde Visual Studio Code

1. **File → Open Folder…** y elige la carpeta `CineVerse`.
2. Acepta instalar las extensiones recomendadas (**Extension Pack for Java**).
3. Con MySQL encendido en XAMPP, presiona **Ctrl + Shift + B**.
4. Abre **<http://localhost:8080/CineVerse/>** cuando la terminal diga `Tomcat 9.0.98 started on port [8080]`.

- **F5 (Start Debugging)** hace lo mismo y además conecta el depurador de Java.
- Si quedó un Tomcat abierto de una ejecución anterior, la tarea lo cierra sola antes de arrancar.

Desde cualquier terminal dentro de la carpeta también funciona: `mvnw.cmd package cargo:run`

---

## Problemas comunes

| Lo que ves | Solución |
|---|---|
| `No se encontró Java` o `JAVA_HOME not found` | Instala el JDK (ver arriba) marcando "Set JAVA_HOME", cierra la ventana y vuelve a abrir el `.bat`. |
| La página abre, pero registrarse o iniciar sesión dice **"No se pudo conectar a la BD"** | MySQL no está encendido: pulsa **Start** en MySQL en XAMPP y recarga. Para comprobarlo, abre <http://localhost:8080/CineVerse/testdb.jsp>. |
| `Port number 8080 ... is in use` | Otro programa usa el puerto 8080. Suele ser el **Tomcat de XAMPP**: detenlo en el panel. O ejecuta `mvnw.cmd package cargo:run -Dcineverse.port=8081` y entra a <http://localhost:8081/CineVerse/>. |
| `Failed to clean project` / archivos bloqueados en `target` | Quedó un Tomcat abierto. Cierra la ventana anterior o usa la tarea **CineVerse: Detener Tomcat** de VS Code. |
| Se ve la versión vieja de la página | Recarga sin caché con **Ctrl + F5**. |
| Tu MySQL tiene contraseña o usa otro puerto | Define las variables de entorno `CINEVERSE_DB_PASSWORD` o `CINEVERSE_DB_PORT` antes de arrancar (ver `src/main/java/conexion/conexionBD.java`). |

---

## Estructura

```
CineVerse/
├─ iniciar-cineverse.bat       ← doble clic para ejecutar la página (Windows)
├─ pom.xml                     ← configuración Maven (Tomcat 9 vía Cargo)
├─ mvnw / mvnw.cmd / .mvn/     ← Maven Wrapper (no hace falta instalar Maven)
├─ database/cineverse.sql      ← script de la base de datos (opcional: se crea sola)
├─ .vscode/                    ← tareas, depuración y extensiones recomendadas de VS Code
└─ src/main/
   ├─ java/conexion/conexionBD.java   ← conexión a MySQL (detecta el puerto y crea la base)
   └─ webapp/
      ├─ index.html, catalogo.html, reproductor.html, perfil.html,
      │  login.html, registro.html, SobreNosotros.html, testdb.jsp
      ├─ api/  login.jsp · registro.jsp · favoritos.jsp · cuenta.jsp
      ├─ assets/css/cineverse-ui.css · assets/js/cineverse-ui.js   ← estilos y componentes compartidos
      ├─ assets/fotos/ · assets/sin-poster.svg
      └─ WEB-INF/web.xml
```

## Créditos

Proyecto académico de la Universidad Tecnológica de Panamá. Datos e imágenes de películas proporcionados por
[TMDB](https://www.themoviedb.org); este producto usa la API de TMDB, pero no cuenta con el respaldo ni la certificación de TMDB.
