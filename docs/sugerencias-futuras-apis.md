# Sugerencias para Futuras Implementaciones de APIs

> Este documento recoge ideas, patrones y mejoras sugeridas para nuevas versiones de APIs en el ecosistema.
> Basado en la experiencia con API_OnVentanas y APIs.Hub.

---

## 1. Arquitectura y Patrones

### 1.1 CQRS con Mediator (Source-Generated)
- **Sugerencia**: Usar `martinothamar/Mediator` en lugar de `MediatR` para mejor rendimiento en tiempo de compilación.
- **Beneficio**: Elimina reflexión en runtime, genera código en compile-time.
- **Referencia**: Ver ejemplo en `docs/examples/.claude/rules/architecture.md`.

### 1.2 Vertical Slice Architecture
- **Sugerencia**: Organizar código por **feature/caso de uso** en lugar de por capas técnicas.
- **Estructura**: `Features/{Dominio}/{CasoDeUso}.cs` con Query/Command + Handler + Validator + Response juntos.
- **Beneficio**: Código más cohesionado, más fácil de navegar y mantener.

### 1.3 Result Pattern (ErrorOr)
- **Sugerencia**: Usar `ErrorOr<T>` en lugar de excepciones para errores de negocio.
- **Beneficio**: Flujo de control explícito, mejor rendimiento, código más limpio.
- **Ejemplo**:
  ```csharp
  public async ValueTask<ErrorOr<ClienteResponse>> Handle(GetClienteQuery query, CancellationToken ct)
  ```

---

## 2. Acceso a Datos

### 2.1 Dapper vs EF Core
| Escenario | Recomendación |
|-----------|---------------|
| Queries complejas/legacy | Dapper (raw SQL) |
| CRUD simple con migrations | EF Core |
| Alto rendimiento requerido | Dapper |

### 2.2 Patrón de Conexión
- **Sugerencia**: Crear conexiones en `using` dentro de cada Handler, no inyectar `IDbConnection`.
- **Motivo**: Mejor control del ciclo de vida, evita conexiones colgadas.

### 2.3 Dynamic Queries
- **Sugerencia**: Para endpoints que devuelven datos "planos" de una tabla, usar `QueryAsync<dynamic>()` y devolver directamente.
- **Beneficio**: Menos código boilerplate para CRUDs simples.

---

## 3. Validación y Seguridad

### 3.1 FluentValidation Global
- **Sugerencia**: Configurar validador automático en el pipeline de Mediator.
- **Beneficio**: Los controladores quedan completamente limpios de lógica de validación.

### 3.2 API Key con Middleware
- **Sugerencia**: Implementar middleware de `ApiKey` configurable por endpoint (vía atributos o políticas).
- **Opciones**:
  - Header: `X-API-Key`
  - QueryString: `?apiKey=...`
  - JWT para APIs públicas

### 3.3 Rate Limiting
- **Sugerencia**: Integrar `AspNetCoreRateLimit` o la nueva API de rate limiting de .NET 8+.
- **Escenarios**: APIs expuestas a terceros, endpoints costosos.

---

## 4. Testing

### 4.1 Test Stack Recomendado
| Componente | Paquete |
|------------|---------|
| Framework | xUnit |
| Assertions | AwesomeAssertions (fork MIT de FluentAssertions) |
| Mocking | NSubstitute (más moderno que Moq) o Moq |
| Integration | WebApplicationFactory |

### 4.2 Test Organization
- **Sugerencia**: Tests organizados por feature, paralelos a la estructura `Features/`.
- **Naming**: `{FeatureName}Tests/{Scenario}Tests.cs`

### 4.3 Integration Tests
- **Sugerencia**: Usar TestContainers para SQL Server en tests de integración.
- **Beneficio**: Tests verdaderamente aislados y reproducibles.

---

## 5. Documentación y Descubrimiento

### 5.1 Scalar (reemplazo de Swagger)
- **Sugerencia**: Usar `Scalar.AspNetCore` en lugar de Swagger UI.
- **Beneficio**: UI más moderna, mejor experiencia de desarrollo.
- **Alternativa**: `ReDoc` si se prefiere documentación estática.

### 5.2 CLAUDE.md en cada API
- **Sugerencia**: Incluir `CLAUDE.md` en raíz con contexto del proyecto.
- **Contenido**: Tech stack, convenciones, comandos comunes, reglas de arquitectura.

### 5.3 Versionado de API
- **Sugerencia**: Implementar versionado desde el inicio:
  ```
  /api/v1/clientes
  /api/v2/clientes
  ```
- **Opciones**: Header `api-version`, query string, o path.

---

## 6. Observabilidad

### 6.1 Logging Estructurado
- **Sugerencia**: Usar `Serilog` + `Seq` o `ElasticSearch`.
- **Beneficio**: Logs consultables, correlación de requests.

### 6.2 Health Checks
- **Sugerencia**: Implementar `/health` con checks de:
  - Base de datos
  - Servicios externos críticos
  - Disco/Memoria

### 6.3 Métricas (OpenTelemetry)
- **Sugerencia**: Exportar métricas a Prometheus/Grafana.
- **Métricas clave**:
  - Requests por segundo
  - Latencia p99
  - Errores por tipo
  - Conexiones de BD activas

### 6.4 Tracing Distribuido
- **Sugerencia**: Implementar OpenTelemetry con headers de correlación.
- **Beneficio**: Seguimiento de requests entre servicios.

---

## 7. Deployment y DevOps

### 7.1 Docker Multi-Stage
```dockerfile
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
# ... build

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
# ... runtime solo
```

### 7.2 CI/CD Pipeline
- **Sugerencia**: GitHub Actions con:
  1. Build + Test
  2. Análisis SonarQube
  3. Build Docker image
  4. Deploy a staging
  5. Smoke tests
  6. Deploy a prod (con aprobación)

### 7.3 Feature Flags
- **Sugerencia**: Integrar `Microsoft.FeatureManagement`.
- **Beneficio**: Desplegar código sin activar funcionalidad.

---

## 8. Estandares de Código

### 8.1 C# 12+ Features a Adoptar
- Primary constructors
- Collection expressions `[]`
- Inline arrays (para alto rendimiento)
- `required` members

### 8.2 Análisis Estático
- **Sugerencia**: Configurar `.editorconfig` estricto + `StyleCop.Analyzers`.
- **CI**: Fallar build si hay warnings.

### 8.3 Conventional Commits
- **Formato**: `feat:`, `fix:`, `refactor:`, `docs:`, `chore:`, `test:`
- **Beneficio**: Changelogs automáticos, semantic versioning.

---

## 9. Seguridad Avanzada

### 9.1 HTTPS Forzado
- HSTS habilitado
- Redirección automática HTTP → HTTPS

### 9.2 Protección contra ataques comunes
- CSP (Content Security Policy) headers
- CORS restrictivo (no `*` en prod)
- Anti-forgery tokens para endpoints mutables

### 9.3 Secret Management
- **Desarrollo**: User Secrets (`dotnet user-secrets`)
- **Producción**: Azure Key Vault, AWS Secrets Manager, o similar

---

## 10. Mejoras Específicas para APIs.Hub

### 10.1 Aspire Integration (Ya en progreso)
- Service Discovery entre APIs
- Dashboard unificado
- Telemetry centralizada

### 10.2 Shared Libraries
- Crear paquete NuGet interno con:
  - Middlewares comunes (ApiKey, Logging)
  - Extensiones de configuración
  - Helpers de Dapper
  - Validadores base

### 10.3 API Gateway / BFF
- **Sugerencia**: Implementar YARP (Yet Another Reverse Proxy) como gateway.
- **Beneficios**:
  - SSL termination centralizado
  - Rate limiting global
  - Enrutamiento dinámico

### 10.4 Contratos Compartidos
- Definir contratos OpenAPI compartidos.
- Generar clientes TypeScript/C# automáticamente.

---

## Prioridades de Implementación

| Prioridad | Item | Esfuerzo | Impacto |
|-----------|------|----------|---------|
| Alta | Shared Libraries (NuGet) | Medio | Alto |
| Alta | Observabilidad (Logs/Metrics) | Medio | Alto |
| Media | Scalar/OpenAPI mejorado | Bajo | Medio |
| Media | Integration Tests con TestContainers | Medio | Alto |
| Baja | Feature Flags | Bajo | Medio |
| Baja | API Gateway (YARP) | Alto | Medio |

---

*Documento vivo - actualizar conforme se aprendan nuevas lecciones.*
Using Scrutor to automatically register your services with the ASP.NET Core DI container --> https://codewithmukesh.com/blog/scrutor-dotnet-auto-register-dependencies/