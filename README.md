# Un paquete de multitenencia sin opiniones para Laravel

[![Pruebas](https://github.com/Edd-war/laravel-multitenencia/actions/workflows/run-tests.yml/badge.svg)](https://github.com/Edd-war/laravel-multitenencia/actions/workflows/run-tests.yml)

Este paquete permite que una aplicación Laravel sea consciente del inquilino actual. La filosofía del paquete es que solo debe proporcionar lo esencial para habilitar la multitenencia.

El paquete puede determinar qué inquilino debe ser el actual para cada solicitud. También permite definir qué debe suceder al cambiar de inquilino. Funciona para proyectos que necesitan una o múltiples bases de datos por inquilino.

Incluye utilidades como: hacer que los trabajos en cola reconozcan inquilinos, ejecutar un comando Artisan para cada inquilino, establecer conexiones de base de datos dinámicamente, y mucho más.

---

## Requisitos

- **PHP 8.5+**
- **Laravel 13.x**

---

## Instalación

```bash
composer require edd-war/laravel-multitenencia
```

### Publicar configuración

```bash
php artisan vendor:publish --provider="Eddwar\Multitenencia\Providers\MultitenenciaServiceProvider" --tag="laravel-multitenencia-config"
```

### Publicar migraciones

```bash
php artisan vendor:publish --provider="Eddwar\Multitenencia\Providers\MultitenenciaServiceProvider" --tag="laravel-multitenencia-migrations"
```

---

## Uso mínimo

### 1. Configurar el buscador de inquilinos

```php
// config/multitenencia.php

'buscador_de_inquilinos' => \Eddwar\Multitenencia\BuscadorDeInquilinos\BuscadorDeInquilinosDeDominio::class,
```

### 2. Obtener el inquilino actual

```php
use Eddwar\Multitenencia\Models\Inquilino;

Inquilino::actual();        // ?Inquilino
Inquilino::comprobarActual(); // bool
Inquilino::olvidarActual();
```

### 3. Ejecutar un comando para cada inquilino

```bash
php artisan tenants:artisan "migrate --database=inquilino"
php artisan tenants:artisan "migrate --database=inquilino --seed" --tenant=123
```

### 4. Comandos de migración dedicados

```bash
php artisan tenant:migrate
php artisan tenant:rollback
php artisan tenant:migrate:status
```

---

## Calidad de código

```bash
composer format    # Formatear código con Laravel Pint
composer analyse   # Análisis estático con PHPStan/Larastan
composer test      # Ejecutar suite de pruebas con Pest
```

---

## Pruebas

Debes crear las siguientes bases de datos MySQL locales para ejecutar la suite de pruebas:

- `laravel_mt_propietario`
- `laravel_mt_tenant_1`
- `laravel_mt_tenant_2`

```bash
composer test
```

---

## Documentación

La documentación completa se encuentra en la carpeta [docs](docs).

---

## Historial de cambios

Consulta el [CHANGELOG](CHANGELOG.md) para ver los cambios recientes.

---

## Licencia

La Licencia MIT (MIT). Consulta el [archivo de licencia](LICENSE.md) para más información.
