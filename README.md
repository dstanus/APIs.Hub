# APIs.Hub

Repositorio central de orquestación para las APIs de OnVentanas.

Contiene la configuración de .NET Aspire, los scripts de deploy y los recursos compartidos entre proyectos. Las APIs individuales tienen sus propios repositorios y se clonan junto a este.

## Estructura

```
APIs.Hub/
├── Aspire/
│   ├── APIs.AppHost/          # Orquestador Aspire (desarrollo local)
│   └── APIs.ServiceDefaults/  # Configuración compartida (OpenTelemetry, health checks)
├── deploy-onventanas.ps1      # Script de deploy API_OnVentanas -> SSPVCM02
├── deploy-almacen.ps1         # Script de deploy API_Almacen -> SSPVCM02
├── app_offline.htm            # Página de mantenimiento durante el deploy
└── APIs.slnx                  # Solución Visual Studio
```

## Requisitos

- [.NET 10 SDK](https://dotnet.microsoft.com/download)
- Acceso de red a `SSPVCM02`
- APIs clonadas en el mismo nivel que este repo:
  ```
  C:\APIs\
  ├── APIs.Hub\         <- este repo
  ├── API_OnVentanas\   <- https://github.com/dstanus/API_OnVentanas
  └── API_Almacen\      <- https://github.com/dstanus/API_Almacen
  ```

## Desarrollo local con Aspire

Arranca ambas APIs con el dashboard de Aspire:

```bash
dotnet run --project Aspire/APIs.AppHost
```

El dashboard estará disponible en `https://localhost:15888`.

## Deploy a producción

```powershell
# Desplegar API OnVentanas
.\deploy-onventanas.ps1

# Desplegar API Almacen
.\deploy-almacen.ps1
```

Cada script:
1. Publica el proyecto en Release
2. Hace backup de la versión actual en `\\SSPVCM02\..\_backups\`
3. Activa `app_offline.htm` (los clientes ven página de mantenimiento)
4. Espera a que IIS libere los DLLs
5. Copia los nuevos ficheros
6. Elimina `app_offline.htm` (la API vuelve automáticamente)

## Logs

Los logs de producción se envían a [Seq](https://datalust.co/seq) en `http://sspvcm02:5341` y también se guardan en fichero con rotación diaria en `C:\inetpub\wwwrootssl\<API>\logs\`.

## Licencia

MIT © [Daniel Calin Stanus](https://danielstanus.github.io/)
