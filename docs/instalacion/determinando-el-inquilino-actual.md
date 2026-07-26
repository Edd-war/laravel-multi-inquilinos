---
title: Determinando el inquilino actual
weight: 4
---

Por cada solicitud, el paquete puede determinar cuál inquilino debe estar activo. Esto se realiza mediante un `BuscadorDeInquilinos`. El paquete incluye `BuscadorDeInquilinosDeDominio`, que busca un `Inquilino` cuyo atributo `dominio` coincida con el hostname de la solicitud actual.

Para usar ese buscador, especifica su nombre de clase en la clave `buscador_de_inquilinos` del archivo de configuración `multitenencia.php`:

```php
// en multitenencia.php

/*
 * Esta clase es responsable de determinar cuál inquilino debe ser el actual
 * para la solicitud dada.
 *
 * Debe extender de `Eddwar\Multitenencia\BuscadorDeInquilinos\BuscadorDeInquilinos`
 */
'buscador_de_inquilinos' => Eddwar\Multitenencia\BuscadorDeInquilinos\BuscadorDeInquilinosDeDominio::class,
```

Si deseas determinar el inquilino actual de otra manera, puedes [crear un buscador personalizado](/docs/laravel-multitenencia/v4/uso-basico/determinando-automaticamente-el-inquilino-actual/).
