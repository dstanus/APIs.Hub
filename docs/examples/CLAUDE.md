# CLAUDE.md - API OnVentanas

## Overview
API centralizada en .NET 10 para la gestión e integración de operaciones de ventanas (plazos, optimización, recargos, festivos y actualizaciones) con bases de datos Prefsuite200 y ERPPVCM.

## Tech Stack
- **.NET 10**, ASP.NET Core Web API
- **Dapper** con SQL Server (Acceso de alto rendimiento, consultas manuales y tipos anónimos)
- **Mediator** (Source-generated, `martinothamar/Mediator`) para patrón CQRS
- **ErrorOr** para manejo funcional de errores (`Result<T>` pattern)
- **FluentValidation** para validación de requests en pipeline
- **AwesomeAssertions** (xUnit) para assertions fluidas en los tests
- **Scalar** para documentación OpenAPI interactiva

## Project Structure
Adoptamos una estructura de **Slices Verticales (Características)** dentro de la solución actual:
- `Controllers/` - Controladores muy finos. Solo envían peticiones al Mediator y mapean respuestas HTTP.
- `Features/` - Aquí vive la lógica real agrupada por dominio. Ej: `Features/Recargos/GetRecargo.cs`. Cada slice contiene su `Query`/`Command`, su `Handler`, su `Validator` y opcionalmente su `DTO`.
- `Configuration/` - Inyección de dependencias y `IAppSettings`.
- `Services/` - Servicios legacy no migrados a CQRS aún.
- `.claude/rules/` - Reglas estrictas de arquitectura y convenciones de código.

## Commands
- Build: `dotnet build`
- Run API: `dotnet run`
- Generar Mediator en tiempo de compilación: Es automático por los Source Generators de C#.

## Architecture Rules
Lee las reglas expandidas en la carpeta `.claude/rules/`:
- Todo el código se organiza en `Features/` orientado a casos de uso.
- **CQRS**: Todo se gestiona mediante Commands (operaciones de escritura) o Queries (operaciones de lectura) manejados por Mediator.
- Los Controladores no tienen lógica de negocio, sólo rutean y devuelven HTTP status codes.

## Code Conventions

### Naming
- Commands: `[Action][Entity]Command` (ej. `UpdateVidrioCommand`)
- Queries: `Get[Entity]Query`, `Get[Entities]Query` (ej. `GetRecargoQuery`)
- Handlers: `[Command/Query]Handler`
- Records y Models de respuesta: `[Entity]Response` o `[Entity]Result`

### Patterns We Use
- Únicamente `Records` inmutables para Queries, Commands y Responses.
- Constructores primarios (Primary constructors) de C# 12+ para Inyección de Dependencias.
- Patrón `ErrorOr<T>` para el manejo de fallos (Evitar lanzar excepciones de lógica de negocio).
- File-scoped namespaces (ej: `namespace API_OnVentanas.Features.Recargos;`)
- Siempre usar `CancellationToken` en operaciones I/O y de SQL (Dapper).

### Patterns We DON'T Use (Never Suggest)
- Crear clases puras (`classes`) con getters y setters para DTOs; usar siempre `records`.
- Lanzar excepciones (`throw new Exception()`) para errores de validación o negocio.
- Uso de `SqlDataAdapter` o `DataTable` para nuevas implementaciones (solo mantenido por legacy en Optimizador).
- Repositorios (Repository Pattern). Dapper va directo en el Handler.

## Validation
- Toda la validación usa `FluentValidation`.
- Nunca validar dentro del controlador o dentro del Handler directamente.
- Si un Request necesita la `ApiKey`, añadir una validación global o explícita en su Validator.

## Testing
- Los tests usan **xUnit** + **AwesomeAssertions** (fork MIT de FluentAssertions, API 100% compatible).
- El using en los ficheros de test es `using AwesomeAssertions;` — nunca `using FluentAssertions;`.
- Mocks mediante **Moq**.

## Git Workflow
- Commits convencionales: `feat:`, `fix:`, `refactor:`, `docs:`, `chore:`.
