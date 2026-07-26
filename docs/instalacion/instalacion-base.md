---
title: Instalación base
weight: 1
---

Este paquete se instala mediante Composer:

```bash
composer require edd-war/laravel-multitenencia
```

### Publicar el archivo de configuración

Debes publicar el archivo de configuración:

```bash
php artisan vendor:publish --provider="Eddwar\Multitenencia\Providers\MultitenenciaServiceProvider" --tag="laravel-multitenencia-config"
```

Esto publicará el archivo de configuración en `config/multitenencia.php`. A continuación se muestra un resumen de las claves más importantes:

```php
<?php

use Eddwar\Multitenencia\Actions\AccionHacerColaInquilinoReconocido;
use Eddwar\Multitenencia\Actions\AccionHacerInquilinoActual;
use Eddwar\Multitenencia\Actions\AccionMigrarInquilino;
use Eddwar\Multitenencia\Actions\AccionOlvidarInquilinoActual;
use Eddwar\Multitenencia\Jobs\InquilinoNoReconocido;
use Eddwar\Multitenencia\Jobs\InquilinoReconocido;
use Eddwar\Multitenencia\Models\Inquilino;

return [
    /*
     * Esta clase es responsable de determinar cuál inquilino debe ser el actual
     * para la solicitud dada.
     *
     * Debe extender de `Eddwar\Multitenencia\BuscadorDeInquilinos\BuscadorDeInquilinos`
     */
    'buscador_de_inquilinos' => null,

    /*
     * Campos utilizados por el comando tenants:artisan para filtrar inquilinos.
     */
    'campos_de_busqueda_artisan_para_inquilinos' => ['id'],

    /*
     * Tareas que se ejecutan al cambiar de inquilino.
     * Deben implementar TareaDeCambioDeInquilino.
     */
    'tareas_de_cambio_de_inquilino' => [
        // \Eddwar\Multitenencia\Tasks\TareaDeCacheDePrefijos::class,
        // \Eddwar\Multitenencia\Tasks\TareaDelCambioDeBaseDeDatosDelInquilino::class,
        // \Eddwar\Multitenencia\Tasks\TareaDeCacheDeCambioDeRuta::class,
    ],

    /*
     * Modelo utilizado para almacenar la configuración de los inquilinos.
     * Debe extender Inquilino o implementar EsInquilino.
     */
    'modelo_del_inquilino' => Inquilino::class,

    /*
     * Si hay un inquilino actual al despachar un trabajo, su ID se incluirá
     * automáticamente en el trabajo para restaurarlo al ejecutarlo.
     */
    'colas_reconocen_inquilinos_por_defecto' => true,

    /*
     * Nombre de conexión para la base de datos del inquilino.
     * null usa la conexión por defecto.
     */
    'nombre_de_conexion_de_la_base_de_datos_del_inquilino' => null,

    /*
     * Nombre de conexión para la base de datos del propietario.
     */
    'nombre_de_conexion_de_la_base_de_datos_del_propietario' => null,

    /*
     * Acciones personalizables del paquete.
     * Tu acción personalizada siempre debe extender la acción por defecto.
     */
    'acciones' => [
        'accion_hacer_inquilino_actual'         => AccionHacerInquilinoActual::class,
        'accion_olvidar_inquilino_actual'        => AccionOlvidarInquilinoActual::class,
        'accion_hacer_cola_inquilino_reconocido' => AccionHacerColaInquilinoReconocido::class,
        'migrar_inquilino'                       => AccionMigrarInquilino::class,
    ],

    /*
     * Trabajos que siempre reconocen inquilino (aunque no implementen InquilinoReconocido).
     */
    'trabajos_que_reconocen_inquilinos' => [],

    /*
     * Trabajos que nunca reconocen inquilino (aunque no implementen InquilinoNoReconocido).
     */
    'trabajos_que_no_reconocen_inquilinos' => [],
];
```

### Protección contra abuso entre inquilinos

Para evitar que usuarios de un inquilino accedan a otro usando su sesión, aplica el middleware `AsegurarSesionValidaDeInquilino` en todas las rutas conscientes del inquilino.

Si todas las rutas son conscientes del inquilino, agrégalo al middleware global en `bootstrap/app.php`:

```php
// en `bootstrap/app.php`

return Application::configure(basePath: dirname(__DIR__))
    // ...
    ->withMiddleware(function (Middleware $middleware) {
        $middleware
            ->web(append: [
                \Eddwar\Multitenencia\Http\Middleware\NecesitaInquilino::class,
                \Eddwar\Multitenencia\Http\Middleware\AsegurarSesionValidaDeInquilino::class,
            ]);
    });
```

Si solo algunas rutas son conscientes del inquilino, crea un grupo de middleware:

```php
// en `bootstrap/app.php`

return Application::configure(basePath: dirname(__DIR__))
    // ...
    ->withMiddleware(function (Middleware $middleware) {
        $middleware
            ->group('tenant', [
                \Eddwar\Multitenencia\Http\Middleware\NecesitaInquilino::class,
                \Eddwar\Multitenencia\Http\Middleware\AsegurarSesionValidaDeInquilino::class,
            ]);
    });
```

Luego aplica el grupo a las rutas correspondientes:

```php
// en un archivo de rutas

Route::middleware('tenant')->group(function() {
    // rutas
});
```

### Siguientes pasos

- Para usar una sola base de datos para todos los inquilinos: [usando una sola base de datos](usando-una-sola-base-de-datos.md).
- Para usar bases de datos separadas por inquilino: [usando múltiples bases de datos](usando-multiples-bases-de-datos.md).
