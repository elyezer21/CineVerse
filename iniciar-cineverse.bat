@echo off
chcp 65001 >nul
title CineVerse - servidor
cd /d "%~dp0"

echo ============================================================
echo                 CineVerse - Iniciar la pagina
echo ============================================================
echo.

rem 1. Java instalado?
where java >nul 2>nul
if errorlevel 1 (
  if not defined JAVA_HOME (
    echo [ERROR] No se encontro Java.
    echo         Instala el JDK 17 o 21 desde https://adoptium.net y vuelve a intentarlo.
    echo.
    pause
    exit /b 1
  )
)

rem 2. Cierra un Tomcat de CineVerse que haya quedado abierto
powershell -NoProfile -ExecutionPolicy Bypass -File ".vscode\detener-tomcat.ps1"

echo.
echo  - Antes de seguir, enciende MySQL en el panel de XAMPP (boton Start).
echo  - La primera vez se descargan Maven y Tomcat: necesita internet
echo    y puede tardar unos minutos. Las siguientes veces es rapido.
echo  - La pagina se abrira sola en el navegador cuando este lista:
echo        http://localhost:8080/CineVerse/
echo  - Para apagar el servidor, cierra esta ventana.
echo.

rem 3. Abre el navegador en cuanto el servidor responda (espera hasta 6 minutos)
start "" /min powershell -NoProfile -WindowStyle Hidden -Command "for($i=0;$i -lt 180;$i++){try{Invoke-WebRequest -UseBasicParsing 'http://localhost:8080/CineVerse/' -TimeoutSec 2 | Out-Null; Start-Process 'http://localhost:8080/CineVerse/'; break}catch{Start-Sleep -Seconds 2}}"

rem 4. Compila y arranca Tomcat 9 con la pagina
call mvnw.cmd package cargo:run

echo.
echo El servidor se detuvo. Si hubo un error, revisa los mensajes de arriba
echo o la seccion "Problemas comunes" del README.md.
pause
