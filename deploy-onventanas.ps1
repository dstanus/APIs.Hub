# ============================================================
# Deploy API_OnVentanas -> SSPVCM02
# Uso: .\deploy-onventanas.ps1
# ============================================================

$proyecto       = "..\API_OnVentanas\API_OnVentanas.csproj"
$publishDir     = ".\publish_onventanas"
$servidor       = "SSPVCM02"
$destino        = "\\$servidor\c$\inetpub\wwwrootssl\API_OnVentanas"
$backupBase     = "\\$servidor\c$\inetpub\wwwrootssl\_backups\API_OnVentanas"
$appOfflineSrc  = ".\app_offline.htm"
$appOfflineDst  = "$destino\app_offline.htm"
$fecha          = Get-Date -Format "yyyyMMdd_HHmmss"
$backupDir      = "$backupBase\$fecha"

# ── 1. Publish ──────────────────────────────────────────────
Write-Host "[1/6] Publicando en Release..." -ForegroundColor Cyan
dotnet publish $proyecto -c Release -o $publishDir
if ($LASTEXITCODE -ne 0) { Write-Host "ERROR: Publish fallido" -ForegroundColor Red; exit 1 }

# ── 2. Backup (API aun funcionando) ─────────────────────────
Write-Host "[2/6] Haciendo backup -> $backupDir ..." -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
xcopy /E /Y /I "$destino\*" "$backupDir\"
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Backup fallido, abortando deploy" -ForegroundColor Red
    exit 1
}
Write-Host "Backup guardado en: $backupDir" -ForegroundColor Gray

# ── 3. Poner app_offline.htm (API muestra mantenimiento, libera DLLs) ──
Write-Host "[3/6] Activando modo mantenimiento..." -ForegroundColor Cyan
Copy-Item $appOfflineSrc $appOfflineDst -Force

# Esperar a que IIS libere el DLL principal (max 30s)
$dllPath = "$destino\API_OnVentanas.dll"
$liberado = $false
$intentos = 0
Write-Host "Esperando a que IIS libere los DLLs..." -ForegroundColor Gray
while (-not $liberado -and $intentos -lt 30) {
    Start-Sleep -Seconds 1
    $intentos++
    try {
        $stream = [System.IO.File]::Open($dllPath, 'Open', 'ReadWrite', 'None')
        $stream.Close()
        $liberado = $true
    } catch {
        Write-Host "  Intento $intentos/30 - aun bloqueado..." -ForegroundColor Gray
    }
}
if (-not $liberado) {
    Write-Host "ERROR: IIS no libero los DLLs tras 30s, abortando" -ForegroundColor Red
    Remove-Item $appOfflineDst -Force
    exit 1
}
Write-Host "DLLs liberados, continuando..." -ForegroundColor Gray

# ── 4. Copiar ficheros nuevos ────────────────────────────────
Write-Host "[4/6] Copiando ficheros al servidor..." -ForegroundColor Cyan
xcopy /E /Y /I "$publishDir\*" "$destino\"
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Copia fallida, restaurando backup..." -ForegroundColor Red
    xcopy /E /Y /I "$backupDir\*" "$destino\"
    Remove-Item $appOfflineDst -Force
    exit 1
}

# Restaurar web.config con ASPNETCORE_ENVIRONMENT=Production
Invoke-Command -ComputerName $servidor -ScriptBlock {
    $webConfigPath = "C:\inetpub\wwwrootssl\API_OnVentanas\web.config"
    $content = @'
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <location path="." inheritInChildApplications="false">
    <system.webServer>
      <handlers>
        <add name="aspNetCore" path="*" verb="*" modules="AspNetCoreModuleV2" resourceType="Unspecified" />
      </handlers>
      <aspNetCore processPath="dotnet" arguments=".\API_OnVentanas.dll" stdoutLogEnabled="false" stdoutLogFile=".\logs\stdout" hostingModel="inprocess">
        <environmentVariables>
          <environmentVariable name="ASPNETCORE_ENVIRONMENT" value="Production" />
        </environmentVariables>
      </aspNetCore>
    </system.webServer>
  </location>
</configuration>
'@
    Set-Content -Path $webConfigPath -Value $content -Encoding UTF8
}

# ── 5. Quitar app_offline.htm (API vuelve sola) ──────────────
Write-Host "[5/6] Desactivando modo mantenimiento..." -ForegroundColor Cyan
Remove-Item $appOfflineDst -Force

# Limpiar publish local
Remove-Item -Recurse -Force $publishDir

Write-Host ""
Write-Host "Deploy completado: https://net.onventanas.es/API_OnVentanas/scalar/" -ForegroundColor Green
Write-Host "Backup disponible en: $backupDir" -ForegroundColor Gray

# ── 6. Health check ─────────────────────────────────
Write-Host ""
Write-Host "[6/6] Verificando API..." -ForegroundColor Cyan
$healthUrl = "https://net.onventanas.es/API_OnVentanas/api/health"
$intentos  = 0
$ok        = $false
while (-not $ok -and $intentos -lt 10) {
    $intentos++
    try {
        $resp = Invoke-WebRequest -Uri $healthUrl -UseBasicParsing -TimeoutSec 5
        if ($resp.StatusCode -eq 200) {
            Write-Host "API respondiendo correctamente (HTTP 200) -> $healthUrl" -ForegroundColor Green
            $ok = $true
        }
    } catch {
        Write-Host "  Intento $intentos/10 - API aun no responde, esperando 3s..." -ForegroundColor Gray
        Start-Sleep -Seconds 3
    }
}
if (-not $ok) {
    Write-Host "AVISO: La API no respondio al health check tras 10 intentos. Revisa IIS." -ForegroundColor Yellow
}
