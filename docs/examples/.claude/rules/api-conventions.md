# Normas y Convenciones de API y Controladores

## 1. Manejo de Errores: ErrorOr
PROHIBIDO hacer `throw new Exception("Error de negocio")`. 
Utiliza el paquete `ErrorOr`. Todos los handlers de `Mediator` deben retornar `ValueTask<ErrorOr<T>>` o `Task<ErrorOr<T>>`.

```csharp
public async ValueTask<ErrorOr<MyResponse>> Handle(MyQuery request, CancellationToken cancellationToken)
{
    if (!Valido)
        return Error.Validation("MyQuery.Invalid", "La validación falló.");
        
    var data = await connection.QueryAsync<MyResponse>(...);
    if (!data.Any())
        return Error.NotFound("Data.Missing", "No se encontró nada.");
        
    return data.ToList();
}
```

## 2. Peticiones y Respuestas (DTOs)
Usa siempre `record` posicionales para evitar boilerplate. No uses constructores ni getters/setters si no hacen falta lógica en ellos.
```csharp
public record GetItemQuery(string ApiKey, string Tipo) : IRequest<ErrorOr<ItemResponse>>;
public record ItemResponse(int Id, string Nombre);
```

## 3. Validación de Entradas
Toda validación de inputs de usuario o parámetros (`ApiKey`) DEBE hacerse por medio de `FluentValidation`.
```csharp
public class GetItemQueryValidator : AbstractValidator<GetItemQuery>
{
    public GetItemQueryValidator(IAppSettings settings)
    {
        RuleFor(x => x.ApiKey)
            .NotEmpty()
            .Must(settings.ValidateApiKey).WithMessage("API Key inválida");
    }
}
```

## 4. Seguridad
La mayoría (sino todos) los endpoints requieren validar el `ApiKey`. Esta validación siempre debe inyectarse o validarse vía `FluentValidation` en los slices.
