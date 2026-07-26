---
title: Guía de actualización
weight: 2
---

En la versión `4.x` se introdujo el concepto de contrato para el Inquilino, de modo que cualquier modelo pueda implementar la interfaz.

El primer paso es actualizar la versión del paquete:

```bash
composer require edd-war/laravel-multitenencia:^4.0
```

### Trait `UsesTenantModel` eliminado

Elimina cualquier referencia al trait anterior `Eddwar\Models\Concerns\UsesTenantModel`, ya que la instancia correcta del inquilino ahora se resuelve mediante `app(EsInquilino::class)`.

### Buscador de inquilinos

Si utilizas el buscador incluido en el paquete, no es necesario ningún cambio. Si usas un buscador personalizado, debes cambiar el valor de retorno del método `buscarParaPeticion` a `?EsInquilino`. Ejemplo:

```php
use Illuminate\Http\Request;
use Eddwar\Multitenencia\Contracts\EsInquilino;
use Eddwar\Multitenencia\BuscadorDeInquilinos\BuscadorDeInquilinos;

class TuBuscadorPersonalizado extends BuscadorDeInquilinos
{
    public function buscarParaPeticion(Request $request): ?EsInquilino
    {
        // ...
    }
}
```

### Tareas de cambio

El mismo cambio aplica para cualquier tarea personalizada, ya que la interfaz `TareaDeCambioDeInquilino` ahora es:

```php
public function hacerActual(EsInquilino $inquilino): void;
```

Por lo tanto, debes reemplazar el parámetro `Tenant $tenant` por `EsInquilino $inquilino` en el método.
