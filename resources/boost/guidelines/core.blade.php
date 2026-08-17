## edd-war/laravel-multitenencia

This package provides multi-tenancy for Laravel REST APIs with a fully Spanish-native API. It is intentionally minimal: it resolves a current tenant per request and runs switch tasks on tenant change — it does not add global query scopes or model isolation by itself.

### Core Concept

- **Current tenant** is bound in the IoC container under `currentTenant` and stored in Laravel `Context` under `tenantId`.
- A **`BuscadorDeInquilinos`** resolves the tenant from the HTTP request (e.g., by domain or subdomain).
- **`TareaDeCambioDeInquilino`** classes mutate the environment when a tenant becomes current (switch DB, prefix cache, etc.) and restore it on forget.

### Working with the Current Tenant

@verbatim
<code-snippet name="Current tenant API" lang="php">
use Eddwar\Multitenencia\Models\Inquilino;

// Make current (fires events, runs all switch tasks)
$inquilino->hacerActual();

// Read
Inquilino::actual();           // returns ?Inquilino
Inquilino::comprobarActual();  // bool — is there an active tenant?
$inquilino->esActual();        // bool

// Forget (restores previous state, runs forget tasks)
Inquilino::olvidarActual();
</code-snippet>
@endverbatim

### Executing Code in a Tenant Context

@verbatim
<code-snippet name="Execute in tenant context" lang="php">
// Run callback as tenant, then restore previous state
$result = $inquilino->execute(function (Inquilino $inquilino) {
    return cache()->get('stats');
});

// Callable for scheduler
$schedule->call($inquilino->callback(fn () => cache()->flush()))->daily();

// Run outside any tenant (propietario context)
use Eddwar\Multitenencia\Propietario;

Propietario::execute(function () {
    Artisan::call('cache:clear');
});
</code-snippet>
@endverbatim

### Eloquent Model Connections

Apply the correct trait to every Eloquent model:

@verbatim
<code-snippet name="Model connection traits" lang="php">
// Models in the tenant database
use Eddwar\Multitenencia\Models\Concerns\UtilizaConexionDelInquilino;

class Post extends Model
{
    use UtilizaConexionDelInquilino;
}

// Models in the propietario (landlord) database
use Eddwar\Multitenencia\Models\Concerns\UtilizaConexionDelPropietario;

class Inquilino extends Model
{
    use UtilizaConexionDelPropietario;
}
</code-snippet>
@endverbatim

### Middleware

Register in `bootstrap/app.php`:

@verbatim
<code-snippet name="Register middleware" lang="php">
->withMiddleware(function (Middleware $middleware) {
    $middleware->web(append: [
        \Eddwar\Multitenencia\Http\Middleware\NecesitaInquilino::class,
        \Eddwar\Multitenencia\Http\Middleware\AsegurarSesionValidaDeInquilino::class,
    ]);
})
</code-snippet>
@endverbatim

- `NecesitaInquilino` — aborts the request if no tenant is current.
- `AsegurarSesionValidaDeInquilino` — prevents session cross-contamination.

### Tenant-Aware Queues

@verbatim
<code-snippet name="Queue tenant awareness" lang="php">
use Illuminate\Contracts\Queue\ShouldQueue;
use Eddwar\Multitenencia\Jobs\InquilinoReconocido;
use Eddwar\Multitenencia\Jobs\InquilinoNoReconocido;

// Job is tenant-aware (automatically restores tenant context)
class ProcessReport implements ShouldQueue, InquilinoReconocido { }

// Job explicitly ignores tenant context
class SyncGlobalData implements ShouldQueue, InquilinoNoReconocido { }
</code-snippet>
@endverbatim

### Artisan Commands

- `php artisan tenants:artisan "migrate --database=inquilino"` — run a command for every tenant.
- `php artisan tenants:artisan "cache:clear" --tenant=1 --tenant=2` — specific tenants.

To make a custom command tenant-aware, use the `InquilinoReconocido` concern with a `{--tenant=*}` option.

### InquilinoCollection Helpers

`Inquilino::all()` returns an `InquilinoCollection` with extra iteration methods:

@verbatim
<code-snippet name="Collection helpers" lang="php">
Inquilino::all()->eachCurrent(function (Inquilino $inquilino) {
    cache()->flush();
});

// Also: mapCurrent(), filterCurrent(), rejectCurrent()
</code-snippet>
@endverbatim

### Events (namespace `Eddwar\Multitenencia\Events`)

- `EventoHaciendoInquilinoActual` — before switch tasks run.
- `EventoInquilinoActualCreado` — after switch tasks + container binding.
- `OlvidandoEventoInquilinoActual` — before forget tasks run.
- `EventoInquilinoActualOlvidado` — after forget tasks + container cleared.
- `EventoInquilinoNoEncontradoParaLaSolicitud` — when finder returns null.

### Important Conventions

- Always use **Spanish** method names — never use English equivalents.
- Publish config and migrations: `php artisan vendor:publish --provider="Eddwar\Multitenencia\Providers\MultitenenciaServiceProvider"`.
- Switch tasks run synchronously on every `hacerActual()` call — keep them fast.
- The current tenant ID is stored in Laravel `Context`, which queue workers read to restore tenant state.
- Octane is supported: the service provider hooks into `RequestReceived`/`RequestTerminated` automatically when `LARAVEL_OCTANE` is set.
