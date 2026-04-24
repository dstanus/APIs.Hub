# Acceso a Base de Datos - Dapper

A diferencia de muchos proyectos modernos que usan Entity Framework Core, en API_OnVentanas hemos decidido estandarizar el acceso a datos usando **Dapper** para máxima flexibilidad, rapidez y facilidad a la hora de migrar desde ADO.NET clásico.

## 1. Dapper directo en los Handlers
El handler instancia él mismo el `SqlConnection` en un context `using`, lee la string de `IAppSettings` y ejecuta.
No hay DbContext intermedio.

```csharp
public async ValueTask<ErrorOr<MiRespuesta>> Handle(MiQuery query, CancellationToken ct)
{
    await using var connection = new SqlConnection(_appSettings.ConnectionStringPrefsuite200);
    
    // NUNCA concatenar strings. Usa parametría.
    string sql = "SELECT Id, Referencia FROM MiTabla WHERE Tipo = @Tipo AND Obsoleto = 0";
    
    // Dapper asíncrono
    var resultados = await connection.QueryAsync<MiRespuesta>(
        new CommandDefinition(sql, new { Tipo = query.Tipo }, cancellationToken: ct)
    );
    
    return resultados.ToList();
}
```

## 2. Tipos Anónimos / Dynamic
Para endpoints que simplemente puentean tablas crudas a JSON, siéntete libre de no crear un Record DTO si va a ser gigante, y apoyarte en el `.QueryAsync<dynamic>()` de Dapper, que es perfectamente serializable por `System.Text.Json` devolviendo un array/lista al FrontEnd.
```csharp
var data = await connection.QueryAsync(sql, param);
return data.ToList(); // Si el return type de ErrorOr es List<dynamic>
```
Sin embargo, para nuevo código con lógica, mapear a `records` explícitos (`QueryAsync<MyRecord>`) es recomendable.

## 3. CancellationToken
Usa `CommandDefinition` con `cancellationToken` cuando lances consultas de base de datos que podrían tardar (las de Prefsuite200 son propensas a ello).
