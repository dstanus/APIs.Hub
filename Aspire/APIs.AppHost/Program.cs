var builder = DistributedApplication.CreateBuilder(args);

// ── APIs ejecutadas desde los ejecutables publicados en IIS ─────────────────

// API OnVentanas (publicado en wwwrootssl)
var apiOnVentanas = builder
    .AddExecutable("api-onventanas", "C:\\inetpub\\wwwrootssl\\API_OnVentanas\\API_OnVentanas.exe", "C:\\inetpub\\wwwrootssl\\API_OnVentanas")
    .WithEnvironment("OTEL_EXPORTER_OTLP_ENDPOINT", "http://localhost:18889")
    .WithExternalHttpEndpoints();

// API Almacen (publicado en wwwrootssl)
var apiAlmacen = builder
    .AddExecutable("api-almacen", "C:\\inetpub\\wwwrootssl\\API_Almacen\\API_Almacen.exe", "C:\\inetpub\\wwwrootssl\\API_Almacen")
    .WithEnvironment("OTEL_EXPORTER_OTLP_ENDPOINT", "http://localhost:18889")
    .WithExternalHttpEndpoints();

builder.Build().Run();
