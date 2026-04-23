var builder = DistributedApplication.CreateBuilder(args);

// ── API OnVentanas ──────────────────────────────────────────────────────────
var apiOnVentanas = builder
    .AddProject<Projects.API_OnVentanas>("api-onventanas")
    .WithExternalHttpEndpoints();

// ── API Almacen ─────────────────────────────────────────────────────────────
var apiAlmacen = builder
    .AddProject<Projects.API_Almacen>("api-almacen")
    .WithExternalHttpEndpoints();

builder.Build().Run();
