# APIs.Hub

Repositorio central de orquestación para las APIs de OnVentanas.

Contiene la configuración de .NET Aspire, los scripts de deploy y los recursos compartidos entre proyectos. Las APIs individuales tienen sus propios repositorios y se clonan junto a este en el mismo nivel de carpeta.

## Estructura del workspace

```
<raíz>/
├── APIs.Hub/                  <- este repo
│   ├── Aspire/
│   │   ├── APIs.AppHost/          # Orquestador Aspire (desarrollo local)
│   │   └── APIs.ServiceDefaults/  # Configuración compartida (OpenTelemetry, health checks)
│   ├── deploy-almacen.ps1         # Script de deploy API_Almacen -> SSPVCM02
│   ├── deploy-onventanas.ps1      # Script de deploy API_OnVentanas -> SSPVCM02
│   ├── app_offline.htm            # Página de mantenimiento durante el deploy
│   └── APIs.slnx                  # Solución Visual Studio
├── API_Almacen/               <- https://github.com/dstanus/API_Almacen
└── API_OnVentanas/            <- https://github.com/dstanus/API_OnVentanas
```

> Los scripts de deploy se ejecutan desde `APIs.Hub\` y referencian los proyectos con rutas relativas (`..\..\`).

## Requisitos

- [.NET 10 SDK](https://dotnet.microsoft.com/download)
- Acceso de red a `SSPVCM02` (UNC `\\SSPVCM02\c$\...`)
- PowerShell con permisos para `Invoke-Command` remoto contra `SSPVCM02`
- Las tres carpetas clonadas al mismo nivel (ver estructura arriba)

## Desarrollo local con Aspire

Arranca ambas APIs con el dashboard de Aspire:

```bash
dotnet run --project Aspire/APIs.AppHost
```

El dashboard estará disponible en `https://localhost:15888`.

Las APIs quedan accesibles en los puertos asignados por Aspire y con hot-reload activo.

## Deploy a producción

Los scripts se ejecutan desde la carpeta `APIs.Hub\`:

```powershell
# Desplegar API_Almacen
.\deploy-almacen.ps1

# Desplegar API_OnVentanas
.\deploy-onventanas.ps1
```

### Pasos que ejecuta cada script

| Paso | Descripción |
|------|-------------|
| 1/6 | `dotnet publish` en Release hacia carpeta local temporal |
| 2/6 | Backup de la versión actual en `\\SSPVCM02\..\_backups\<API>\<fecha>` |
| 3/6 | Copia `app_offline.htm` al destino (IIS muestra mantenimiento y libera DLLs) |
| 4/6 | Copia los ficheros publicados al servidor. Si falla, restaura el backup automáticamente |
| 5/6 | Elimina `app_offline.htm` (la API vuelve a estar disponible) |
| 6/6 | Health check: llama a `/health` hasta 10 veces con 3s de espera entre intentos |

### Rollback manual

Si algo va mal después del deploy, el backup está en:

```
\\SSPVCM02\c$\inetpub\wwwrootssl\_backups\<API>\<yyyyMMdd_HHmmss>\
```

Copia su contenido de vuelta a `\\SSPVCM02\c$\inetpub\wwwrootssl\<API>\` y elimina `app_offline.htm` si existe.

## URLs de producción

| API | Scalar UI | Health |
|-----|-----------|--------|
| API_Almacen | https://net.onventanas.es/API_Almacen/scalar/ | https://net.onventanas.es/API_Almacen/health |
| API_OnVentanas | https://net.onventanas.es/API_OnVentanas/scalar/ | https://net.onventanas.es/API_OnVentanas/health |

## Logs

Los logs de producción se envían a [Seq](https://datalust.co/seq) en `http://sspvcm02:5341` y también se guardan en fichero con rotación diaria en:

```
C:\inetpub\wwwrootssl\<API>\logs\
```

## Licencia

MIT © [Daniel Calin Stanus](https://danielstanus.github.io/)
