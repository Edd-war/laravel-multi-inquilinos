---
title: Usando múltiples bases de datos
weight: 3
---

Antes de seguir estas instrucciones, asegúrate de haber completado la [instalación base](instalacion-base.md).

Usa las instrucciones de esta página solo si quieres que cada inquilino tenga su propia base de datos.

## Configurar las conexiones de base de datos

Cuando se usa una base de datos separada por inquilino, la aplicación Laravel necesita dos conexiones: una llamada `propietario`, que apunta a la base de datos que contiene la tabla `inquilinos` e información general del sistema; y otra llamada `inquilino`, que apunta a la base de datos del inquilino actual.

En el archivo de configuración `multitenencia.php`, debes establecer los nombres de conexión:

```php
// en config/multitenencia.php

'nombre_de_conexion_de_la_base_de_datos_del_inquilino' => 'inquilino',

'nombre_de_conexion_de_la_base_de_datos_del_propietario' => 'propietario',
```

A continuación, crea las conexiones en el archivo `config/database.php`:

```php
// en config/database.php

'connections' => [
    'inquilino' => [
        'driver' => 'mysql',
        'database' => null, // El paquete lo asigna dinámicamente
        'host' => '127.0.0.1',
        'username' => 'root',
        'password' => '',
        // Otras opciones si es necesario...
    ],

    'propietario' => [
        'driver' => 'mysql',
        'database' => 'nombre_de_la_base_de_datos_propietario',
        'host' => '127.0.0.1',
        'username' => 'root',
        'password' => '',
        // Otras opciones si es necesario...
    ],
],
```

### Migrar la base de datos del propietario

Con la conexión configurada, podemos migrar la base de datos del propietario.

Primero, publica el archivo de migración:

```bash
php artisan vendor:publish --provider="Eddwar\Multitenencia\Providers\MultitenenciaServiceProvider" --tag="laravel-multitenencia-migrations"
```

Luego ejecuta la migración. El valor de la opción `database` debe ser el nombre de la conexión del propietario:

```bash
php artisan migrate --path=database/migrations/propietario --database=propietario
```

Esto creará la tabla `inquilinos`. Las migraciones propias del propietario deben guardarse en `database/migrations/propietario` y ejecutarse con el comando anterior.

### Cambio automático a la base de datos del inquilino actual

Al hacer que un inquilino sea el "actual", el paquete ejecutará las tareas especificadas en `tareas_de_cambio_de_inquilino` del archivo de configuración `multitenencia.php`.

El paquete incluye `TareaDelCambioDeBaseDeDatosDelInquilino`, que cambia la conexión del inquilino para usar la base de datos cuyo nombre está en el atributo `base_de_datos` del inquilino.

Agrégala a la clave `tareas_de_cambio_de_inquilino`:

```php
// en config/multitenencia.php

/*
 * Estas tareas se ejecutan al hacer que un inquilino sea el actual.
 * Deben implementar Eddwar\Multitenencia\Tasks\TareaDeCambioDeInquilino
 */
'tareas_de_cambio_de_inquilino' => [
    Eddwar\Multitenencia\Tasks\TareaDelCambioDeBaseDeDatosDelInquilino::class,
],
```

El paquete también incluye [otras tareas](/docs/laravel-multitenencia/v4/usando-tareas-para-preparar-el-entorno/descripcion-general/) que puedes agregar opcionalmente. También puedes [crear una tarea personalizada](/docs/laravel-multitenencia/v4/usando-tareas-para-preparar-el-entorno/creando-tu-propia-tarea/).

### Crear bases de datos de inquilinos

Con el cambio automático configurado, puedes migrar las bases de datos de los inquilinos. Como hay muchas formas de hacerlo, el paquete no se encarga de crear las bases de datos. Debes hacerlo en tu propio código. Un buen lugar para activarlo es [al crear un modelo `Inquilino`](/docs/laravel-multitenencia/v4/uso-avanzado/utilizando-un-modelo-de-inquilino-personalizado/).

### Migrar bases de datos de inquilinos

Las migraciones futuras para inquilinos deben guardarse en `database/migrations`.

Para ejecutarlas, usa el comando `tenants:artisan`. Este comando recorre todos los inquilinos, hace a cada uno el actual y ejecuta el comando Artisan en ese contexto:

```bash
php artisan tenants:artisan "migrate --database=inquilino"
```

Si quieres un directorio dedicado para migraciones de inquilinos (`database/migrations/inquilinos`):

```bash
php artisan tenants:artisan "migrate --path=database/migrations/inquilinos --database=inquilino"
```

### Sembrar bases de datos de inquilinos

Para sembrar también la base de datos del inquilino:

```bash
php artisan tenants:artisan "migrate --database=inquilino --seed"
```

En el `DatabaseSeeder`, puedes usar `Inquilino::comprobarActual()` para verificar si el sembrado es para un inquilino o para el propietario:

```php
use Illuminate\Database\Seeder;
use Eddwar\Multitenencia\Models\Inquilino;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        Inquilino::comprobarActual()
           ? $this->runTenantSpecificSeeders()
           : $this->runPropietarioSpecificSeeders();
    }

    public function runTenantSpecificSeeders(): void
    {
        // sembrar datos del inquilino
    }

    public function runPropietarioSpecificSeeders(): void
    {
        // sembrar datos del propietario
    }
}
```

### Preparar modelos

Todos los modelos del proyecto deben usar `UtilizaConexionDelPropietario` o `UtilizaConexionDelInquilino`, según si la tabla subyacente vive en la base de datos del propietario o del inquilino.

### Siguientes pasos

Al usar múltiples inquilinos, probablemente quieras [aislar la caché](/docs/laravel-multitenencia/v4/usando-tareas-para-preparar-el-entorno/prefijando-la-cache/). Esto se realiza mediante clases de tareas que se ejecutan al hacer a un inquilino el actual.
