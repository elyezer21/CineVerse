# Cierra el Tomcat de CineVerse que haya quedado abierto.
# Busca procesos de Java que sean Tomcat (Catalina/Cargo) o que ocupen los puertos 8080, 8000 u 8205.
$ids = @()
$ids += Get-CimInstance Win32_Process -Filter "Name='java.exe' OR Name='javaw.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -match 'catalina|cargo' } |
        Select-Object -ExpandProperty ProcessId
$ids += Get-NetTCPConnection -LocalPort 8080,8000,8205 -ErrorAction SilentlyContinue |
        Select-Object -ExpandProperty OwningProcess
$ids = $ids | Where-Object { $_ -gt 0 } | Sort-Object -Unique
$cerrados = 0
foreach ($id in $ids) {
    $p = Get-Process -Id $id -ErrorAction SilentlyContinue
    if ($p -and ($p.ProcessName -eq 'java' -or $p.ProcessName -eq 'javaw')) {
        Write-Host "Cerrando Tomcat anterior: $($p.ProcessName) (PID $($p.Id))"
        Stop-Process -Id $p.Id -Force
        $cerrados++
    } elseif ($p) {
        Write-Host "Puerto ocupado por $($p.ProcessName) (PID $($p.Id)); no es Java, no se cierra."
    }
}
if ($cerrados -eq 0) { Write-Host "No habia ningun Tomcat abierto." }
Start-Sleep -Seconds 2
exit 0
