---
title: Usando una sola base de datos
weight: 2
---

Antes de seguir estas instrucciones, asegúrate de haber completado la [instalación base](instalacion-base.md).

Usa las instrucciones de esta página solo si quieres usar una única base de datos para todos los inquilinos.

### Migrar la base de datos

Con la conexión de base de datos configurada, podemos ejecutar las migraciones.

Primero, publica y ejecuta la migración:

```bash
php artisan vendor:publish --provider="Eddwar\Multitenencia\Providers\MultitenenciaServiceProvider" --tag="laravel-multitenencia-migrations"
php artisan migrate --path=database/migrations/propietario
```

Esto creará la tabla `inquilinos`, que almacena la configuración por inquilino.

### Siguientes pasos

Al usar múltiples inquilinos con una sola base de datos, probablemente quieras [aislar la caché](/docs/laravel-multitenencia/v4/usando-tareas-para-preparar-el-entorno/prefijando-la-cache/) o usar sistemas de archivos separados por inquilino. Esto se realiza mediante [clases de tareas](/docs/laravel-multitenencia/v4/usando-tareas-para-preparar-el-entorno/descripcion-general/) que se ejecutan al hacer a un inquilino el actual.

El paquete también tiene opción de [hacer que las colas reconozcan inquilinos](/docs/laravel-multitenencia/v4/uso-basico/haciendo-que-las-colas-reconozcan-inquilinos/).
