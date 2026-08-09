---
name: laravel-multitenencia-development
description: Habilidades y guías para el desarrollo con edd-war/laravel-multitenencia en aplicaciones Laravel.
---

# Desarrollo con `edd-war/laravel-multitenencia`

Esta habilidad proporciona pautas y patrones para la arquitectura multisitio/multitenant utilizando el paquete `edd-war/laravel-multitenencia`.

## Conceptos Clave

1. **Inquilino Actual (`Inquilino::actual()`)**:
   - `Inquilino::actual()` devuelve el modelo `Eddwar\Multitenencia\Models\Inquilino` activo.
   - `Inquilino::comprobarActual()` verifica si hay un inquilino seleccionado en el contexto actual.
   - `Inquilino::olvidarActual()` limpia el contexto del inquilino.

2. **Segregación Landlord / Tenant**:
   - **Landlord (Propietario)**: Base de datos central para inquilinos, dominios y configuraciones globales.
   - **Tenant (Inquilino)**: Base de datos segregada para datos específicos del negocio.

3. **Comandos Artisan Disponibles**:
   - `php artisan tenant:create`: Crea un nuevo sitio tenant.
   - `php artisan tenant:migrate`: Ejecuta migraciones en tenants.
   - `php artisan tenant:rollback`: Revierte migraciones en tenants.
   - `php artisan tenant:migrate:status`: Muestra el estatus de las migraciones tenant por módulo.
   - `php artisan tenants:artisan "comando"`: Ejecuta un comando Artisan de forma iterativa sobre los tenants seleccionados.

## Patrones Recomendados

```php
use Eddwar\Multitenencia\Models\Inquilino;

// Ejecutar código en el contexto de un inquilino específico
Inquilino::find($tenantId)->ejecutar(function () {
    // Código ejecutado con la conexión de base de datos del inquilino
});
```
