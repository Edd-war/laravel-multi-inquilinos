---
title: Preparación de instalación
weight: 0
---

# Preparación de instalación

Este paquete está orientado a **Laravel 13.x** y **PHP 8.5+**.

## Decisión previa a la instalación

Antes de instalar el paquete, define cuál de estos escenarios se aplica a tu aplicación:

- **Una sola base de datos compartida**: todos los inquilinos comparten la misma base de datos. La separación se maneja a nivel de columnas/modelos.
- **Una base de datos por inquilino**: cada inquilino tiene su propia base de datos. El paquete cambia dinámicamente la conexión al inquilino activo.

Una vez tomada la decisión, sigue las instrucciones de instalación correspondientes en la sección siguiente.

## Instalación básica

```bash
composer require edd-war/laravel-multitenencia
```

## Publicar configuración

```bash
php artisan vendor:publish --provider="Eddwar\Multitenencia\Providers\MultitenenciaServiceProvider" --tag="laravel-multitenencia-config"
```

Esto creará el archivo `config/multitenencia.php` en tu aplicación.

## Configuración mínima obligatoria

Después de publicar la configuración, define al menos:

```php
// config/multitenencia.php

'buscador_de_inquilinos' => \Eddwar\Multitenencia\BuscadorDeInquilinos\BuscadorDeInquilinosDeDominio::class,

'modelo_del_inquilino' => \Eddwar\Multitenencia\Models\Inquilino::class,

'tareas_de_cambio_de_inquilino' => [
    // Para múltiples bases de datos, agrega:
    // \Eddwar\Multitenencia\Tasks\TareaDelCambioDeBaseDeDatosDelInquilino::class,
],
```

## Siguientes pasos

- Si usas **una sola base de datos**: ve a [Usando una sola base de datos](instalacion/usando-una-sola-base-de-datos.md).
- Si usas **múltiples bases de datos**: ve a [Usando múltiples bases de datos](instalacion/usando-multiples-bases-de-datos.md).
