# Reglas de Arquitectura CQRS & Vertical Slices

En API_OnVentanas utilizamos una aproximación de Vertical Slice Architecture combinada con CQRS. 
En lugar de organizar el código por capas técnicas (Controllers, Repositories, Services), agrupamos el código por **Caso de Uso**.

## 1. La Carpeta Features
Cualquier nueva funcionalidad (endpoint) debe ir en una carpeta dentro de `Features/`. Por ejemplo:
`Features/Consultas/GetPlazoNormales.cs`
`Features/Recargos/GetRecargo.cs`

Dentro de un mismo archivo `.cs` (o agrupado cercanamente) debes definir:
1. El `Record` del Command / Query.
2. El `Validator` de FluentValidation asociado al Command / Query.
3. El `Record` de Respuesta.
4. La clase `Handler` que lo procesa.

## 2. CQRS: Commands vs Queries
- **Queries:** Son peticiones que SOLO leen de la base de datos. NUNCA modifican estado. Se envían usando Dapper de forma asíncrona (`QueryAsync`).
- **Commands:** Son peticiones que modifican estado (INSERT, UPDATE, DELETE). Devuelven `ErrorOr<Success>` o el objeto creado, y se envían con `ExecuteAsync` de Dapper.

## 3. Los Controladores son Tontos
Los controladores (en la raíz `Controllers/`) simplemente exponen las rutas y delegan el trabajo.
Ejemplo:
```csharp
[HttpGet]
public async ValueTask<IActionResult> Get([FromQuery] GetRecargoQuery query)
{
    var result = await _mediator.Send(query);
    return result.Match(
        recargo => Ok(recargo),
        errors => Problem(errors)
    );
}
```

## 4. No usar Repositorios (No Repository Pattern)
Se prohíbe crear interfaces tipo `IRecargoRepository`. Con Dapper, cada Handler es su propio "Bounded Context" capaz de invocar SQL a su antojo. El acoplamiento a Dapper dentro del Handler es aceptado y fomentado aquí por motivos de rendimiento y simplicidad.
