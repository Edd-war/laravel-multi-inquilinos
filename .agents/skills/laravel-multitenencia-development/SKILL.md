---
name: laravel-multitenencia-development
description: Desarrollar y trabajar con las funcionalidades de Laravel Multitenencia de Eddwar, incluyendo buscadores de inquilinos, el inquilino actual, tareas de cambio, configuraciones multi-base de datos, colas y comandos Artisan conscientes del inquilino.
---

# Laravel Multitenencia Development

## When to use this skill

Use this skill when working with multi-tenant Laravel applications using `edd-war/laravel-multitenencia`: determining the current tenant per request, isolating databases or caches per tenant, making queued jobs and artisan commands tenant-aware, or designing propietario/tenant migration strategies.

## Core Concepts

- **Intentionally minimal**: the package resolves a current tenant and runs tasks on switch — it does not add global query scopes or model isolation by itself.
- **Current tenant** is bound in the IoC container under the key `currentTenant` and written to Laravel `Context` under the key `tenantId`.
- A **`BuscadorDeInquilinos`** resolves the tenant from the current HTTP request (e.g. by domain).
- **`TareaDeCambioDeInquilino`** classes mutate the environment when a tenant becomes current (switch DB, prefix cache, etc.) and restore it when forgotten.
- Models on the propietario DB use `UtilizaConexionDelPropietario`; models on the tenant DB use `UtilizaConexionDelInquilino`.

## Setup

```bash
composer require edd-war/laravel-multitenencia
php artisan vendor:publish --provider="Eddwar\Multitenencia\Providers\MultitenenciaServiceProvider" --tag="laravel-multitenencia-config"
php artisan vendor:publish --provider="Eddwar\Multitenencia\Providers\MultitenenciaServiceProvider" --tag="laravel-multitenencia-migrations"
```

Register middleware in `bootstrap/app.php`:

```php
->withMiddleware(function (Middleware $middleware) {
    $middleware->web(append: [
        \Eddwar\Multitenencia\Http\Middleware\NecesitaInquilino::class,
        \Eddwar\Multitenencia\Http\Middleware\AsegurarSesionValidaDeInquilino::class,
    ]);
})
```

## Configuring a Tenant Finder

Set the finder class in `config/multitenencia.php`:

```php
'buscador_de_inquilinos' => \Eddwar\Multitenencia\BuscadorDeInquilinos\BuscadorDeInquilinosDeDominio::class,
```

`BuscadorDeInquilinosDeDominio` looks up the tenant by matching `$request->getHost()` against a `dominio` column on the inquilinos table.

To use a custom finder, extend `BuscadorDeInquilinos` and implement `buscarParaPeticion`:

```php
use Illuminate\Http\Request;
use Eddwar\Multitenencia\Contracts\EsInquilino;
use Eddwar\Multitenencia\BuscadorDeInquilinos\BuscadorDeInquilinos;

class SubBuscadorDeInquilinosDeDominio extends BuscadorDeInquilinos
{
    public function buscarParaPeticion(Request $request): ?EsInquilino
    {
        $subdomain = explode('.', $request->getHost())[0];

        return app(EsInquilino::class)::whereSubdomain($subdomain)->first();
    }
}
```

## Working with the Current Tenant

```php
use Eddwar\Multitenencia\Models\Inquilino;

// Make a tenant current (fires events, runs tasks)
$inquilino->hacerActual();

// Read the current tenant
Inquilino::actual();        // returns ?Inquilino
app('currentTenant');       // same, via container

// Check and forget
Inquilino::comprobarActual();  // bool
$inquilino->esActual();        // bool
Inquilino::olvidarActual();    // runs forget tasks
```

## Executing Code for a Tenant or Propietario

`execute()` makes the tenant current, runs the callable, then restores the previous state:

```php
$result = $inquilino->execute(function (Inquilino $inquilino) {
    return cache()->get('stats');
});
```

`callback()` returns a closure — useful for the scheduler:

```php
$schedule->call($inquilino->callback(fn () => cache()->flush()))->daily();
```

To run code **outside** any tenant context, use `Propietario`:

```php
use Eddwar\Multitenencia\Propietario;

Propietario::execute(function () {
    Artisan::call('cache:clear');
});
```

`InquilinoCollection` adds iteration helpers: `eachCurrent`, `mapCurrent`, `filterCurrent`, `rejectCurrent`.

```php
Inquilino::all()->eachCurrent(function (Inquilino $inquilino) {
    cache()->flush();
});
```

## Multi-Database Setup

Define a `inquilino` connection (with `database => null`) and a `propietario` connection in `config/database.php`:

```php
'connections' => [
    'inquilino' => [
        'driver'   => 'mysql',
        'database' => null,
        'host'     => '127.0.0.1',
        'username' => 'root',
        'password' => '',
    ],

    'propietario' => [
        'driver'   => 'mysql',
        'database' => 'name_of_propietario_db',
        'host'     => '127.0.0.1',
        'username' => 'root',
        'password' => '',
    ],
],
```

Set the connection names in `config/multitenencia.php`:

```php
'nombre_de_conexion_de_la_base_de_datos_del_inquilino'   => 'inquilino',
'nombre_de_conexion_de_la_base_de_datos_del_propietario' => 'propietario',
```

Apply the correct connection trait to every Eloquent model:

```php
// Models whose table lives in the tenant DB
use Eddwar\Multitenencia\Models\Concerns\UtilizaConexionDelInquilino;

class Post extends Model
{
    use UtilizaConexionDelInquilino;
}

// Models whose table lives in the propietario DB
use Eddwar\Multitenencia\Models\Concerns\UtilizaConexionDelPropietario;

class Inquilino extends Model
{
    use UtilizaConexionDelPropietario;
}
```

## Switch Tenant Tasks

Tasks run every time `hacerActual()` or `olvidarActual()` is called. Register them in `config/multitenencia.php`:

```php
'tareas_de_cambio_de_inquilino' => [
    \Eddwar\Multitenencia\Tasks\TareaDelCambioDeBaseDeDatosDelInquilino::class,
    // \Eddwar\Multitenencia\Tasks\TareaDeCacheDePrefijos::class,
    // \Eddwar\Multitenencia\Tasks\TareaDeCacheDeCambioDeRuta::class,
],
```

Built-in tasks:

- **`TareaDelCambioDeBaseDeDatosDelInquilino`** — sets the `inquilino` connection's `database` to `$inquilino->base_de_datos` and purges the connection. Required for multi-DB.
- **`TareaDeCacheDePrefijos`** — overrides `cache.prefix` to `tenant_{$inquilino->id}`. Works with memory-based stores (Redis, APC).
- **`TareaDeCacheDeCambioDeRuta`** — switches `APP_ROUTES_CACHE` to a per-tenant file (`bootstrap/cache/routes-v7-tenant-{id}.php`), or a shared file when `'cache_de_rutas_compartido' => true`.

To create a custom task, implement `TareaDeCambioDeInquilino`:

```php
use Eddwar\Multitenencia\Contracts\EsInquilino;
use Eddwar\Multitenencia\Tasks\TareaDeCambioDeInquilino;

class SwitchStorageDiskTask implements TareaDeCambioDeInquilino
{
    public function hacerActual(EsInquilino $inquilino): void
    {
        config(['filesystems.disks.s3.bucket' => $inquilino->bucket]);
    }

    public function olvidarActual(): void
    {
        config(['filesystems.disks.s3.bucket' => config('filesystems.default_bucket')]);
    }
}
```

Tasks can receive constructor parameters via array config:

```php
'tareas_de_cambio_de_inquilino' => [
    \App\Tasks\YourTask::class => ['key' => 'value'],
],
```

## Middleware

- **`NecesitaInquilino`** — aborts the request (throws `ExcepcionNoHayInquilinoActual`) if no tenant is current. Apply to all tenant routes.
- **`AsegurarSesionValidaDeInquilino`** — stores the first-seen tenant ID in the session and aborts with 401 if a different tenant ID is detected later. Prevents session cross-contamination.

## Custom Tenant Model

Set `modelo_del_inquilino` in `config/multitenencia.php` and point it to your own class:

```php
'modelo_del_inquilino' => \App\Models\MiInquilino::class,
```

To use an existing model (e.g. a Jetstream `Team`) as a tenant, implement `EsInquilino` with the `ImplementaInquilino` trait:

```php
use Eddwar\Multitenencia\Contracts\EsInquilino;
use Eddwar\Multitenencia\Models\Concerns\ImplementaInquilino;
use Eddwar\Multitenencia\Models\Concerns\UtilizaConexionDelPropietario;

class Team extends JetstreamTeam implements EsInquilino
{
    use UtilizaConexionDelPropietario;
    use ImplementaInquilino;
}
```

Use a `creating` hook to provision a database when a tenant is created:

```php
protected static function booted(): void
{
    static::creating(fn (Inquilino $inquilino) => $inquilino->createDatabase());
}
```

## Migrations & Seeding

**Propietario** migrations live in `database/migrations/propietario`. Run them once:

```bash
php artisan migrate --path=database/migrations/propietario --database=propietario
```

**Tenant** migrations run for every tenant via `tenants:artisan`:

```bash
php artisan tenants:artisan "migrate --database=inquilino"
php artisan tenants:artisan "migrate --database=inquilino --seed" --tenant=123
```

In seeders, branch on `Inquilino::comprobarActual()`:

```php
public function run(): void
{
    Inquilino::comprobarActual()
        ? $this->runTenantSpecificSeeders()
        : $this->runPropietarioSpecificSeeders();
}
```

Programmatic migrations use `AccionMigrarInquilino`:

```php
use Eddwar\Multitenencia\Actions\AccionMigrarInquilino;

app(AccionMigrarInquilino::class)->fresh()->seed()->execute($inquilino);
```

## Artisan Commands

`tenants:artisan` loops over all tenants (or the specified ones) and runs a command for each:

```bash
php artisan tenants:artisan "migrate --database=inquilino"
php artisan tenants:artisan "cache:clear" --tenant=1 --tenant=2
```

To make your own commands tenant-aware, add the `InquilinoReconocido` concern and a `{--tenant=*}` option:

```php
use Illuminate\Console\Command;
use Eddwar\Multitenencia\Commands\Concerns\InquilinoReconocido;

class SendReports extends Command
{
    use InquilinoReconocido;

    protected $signature = 'reports:send {--tenant=*}';

    public function handle(): void
    {
        $this->line('Sending for tenant: ' . Inquilino::actual()->nombre);
    }
}
```

Omitting `--tenant` runs the command for every tenant. The command instance is reused across tenants — reset any state at the top of `handle()`.

## Tenant-Aware Queues

Enable globally in `config/multitenencia.php`:

```php
'colas_reconocen_inquilinos_por_defecto' => true,
```

Or mark individual jobs with the `InquilinoReconocido` interface:

```php
use Illuminate\Contracts\Queue\ShouldQueue;
use Eddwar\Multitenencia\Jobs\InquilinoReconocido;

class ProcessReport implements ShouldQueue, InquilinoReconocido
{
    public function handle(): void { /* ... */ }
}
```

Opt out per job with `InquilinoNoReconocido`:

```php
use Eddwar\Multitenencia\Jobs\InquilinoNoReconocido;

class SyncGlobalData implements ShouldQueue, InquilinoNoReconocido
{
    public function handle(): void { /* ... */ }
}
```

Or list classes in config:

```php
'trabajos_que_reconocen_inquilinos'     => [\App\Jobs\ProcessReport::class],
'trabajos_que_no_reconocen_inquilinos'  => [\App\Jobs\SyncGlobalData::class],
```

For closures dispatched to the queue, pass the tenant explicitly:

```php
$inquilino = Inquilino::actual();

dispatch(function () use ($inquilino) {
    $inquilino->execute(function () {
        // tenant context is active here
    });
});
```

If a tenant-aware job fires but the tenant cannot be resolved, `ExcepcionInquilinoActualNoReconocidoEnTrabajoEnCola` is thrown and the job is deleted from the queue.

Jobs that do **not** recognize the tenant force `olvidarActual()` before execution — no previous tenant context leaks into non-tenant-aware jobs.

## Events

All events live in the `Eddwar\Multitenencia\Events` namespace and carry `public EsInquilino $tenant` except where noted:

| Event                                        | When                                                        |
| -------------------------------------------- | ----------------------------------------------------------- |
| `EventoHaciendoInquilinoActual`              | Before switch tasks run                                     |
| `EventoInquilinoActualCreado`                | After switch tasks + container binding                      |
| `OlvidandoEventoInquilinoActual`             | Before forget tasks run                                     |
| `EventoInquilinoActualOlvidado`              | After forget tasks + container cleared                      |
| `EventoInquilinoNoEncontradoParaLaSolicitud` | When the finder returns `null` (carries `Request $request`) |

## Performance

- Switch tasks run synchronously on every `hacerActual()` / `olvidarActual()` call — keep them fast.
- `cache_de_rutas_compartido` avoids generating one routes file per tenant when routes are identical across tenants.
- Octane is supported out of the box: the service provider hooks into `RequestReceived` / `RequestTerminated` events automatically when `LARAVEL_OCTANE` is set.
- The current tenant is stored in Laravel `Context` (`tenantId`), which queue workers read to restore tenant state before processing a job.
