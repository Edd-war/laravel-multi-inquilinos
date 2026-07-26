---
title: Switching route cache paths
weight: 3
---

Laravel comes with [route caching](https://laravel.com/docs/master/routing#route-caching) out of the box. By default
all routes are cached, which means that the application will only load the routes once. This is great if your routes
are static. However, if you're using dynamic routes, for example different routes for different tenants, you'll need
to keep a separate route cache for each tenant.

The `Eddwar\Multitenencia\Tasks\TareaDeCacheDeCambioDeRuta` can switch the configured `APP_ROUTES_CACHE` environment variable to a tenant specific value.

To use this task, you should uncomment it in the `switch_tenant_tasks` section of the `multitenencia` config file.

```php
// in config/multitenencia.php

'tareas_de_cambio_de_inquilino' => [
    \Eddwar\Multitenencia\Tasks\TareaDeCacheDeCambioDeRuta::class,
    // otras tareas
],
```

## A route cache for each tenant

In the default scenario, all tenants have different routes. The package creates a route cache file for each tenant: `bootstrap/cache/routes-v7-tenant-{$tenant->id}.php`.

**Lo más importante**, debes usar `php artisan tenants:artisan route:cache` para cachear las rutas en lugar del comando `route:cache` por defecto de Laravel. Esto asegura que se genere un archivo de caché de rutas diferente para cada inquilino.

## Route cache shared across the tenants

It's the scenario where all tenants use the same routes. The package creates a shared route cache file for all tenants: `bootstrap/cache/routes-v7-tenants.php`.

To enable the feature you should set to `true` the `shared_routes_cache` section of the `multitenencia` config file.

```php
// in config/multitenencia.php

'cache_de_rutas_compartido' => true,
```

**Lo más importante**, debes usar `php artisan tenants:artisan route:cache --tenant=TU-TENANT-ID` para cachear las rutas en lugar del comando `route:cache` por defecto de Laravel. Esto asegura que se genere el archivo de caché correcto.
