---
title: Cambiando bases de datos
weight: 3
---

`Eddwar\Multitenencia\Tasks\TareaDelCambioDeBaseDeDatosDelInquilino` puede cambiar el nombre de base de datos configurado en la conexión `inquilino`. El nombre de la base de datos proviene del atributo `base_de_datos` del modelo `Inquilino`.

Para usar esta tarea, agrégala a la clave `tareas_de_cambio_de_inquilino` en el archivo de configuración `multitenencia.php`:

```php
// en config/multitenencia.php

'tareas_de_cambio_de_inquilino' => [
    \Eddwar\Multitenencia\Tasks\TareaDelCambioDeBaseDeDatosDelInquilino::class,
    // otras tareas
],
```

Si deseas cambiar otras propiedades de la conexión de base de datos además del nombre, debes [crear tu propia tarea](/docs/laravel-multitenencia/v4/usando-tareas-para-preparar-el-entorno/creando-tu-propia-tarea/). Puedes revisar el código fuente de `TareaDelCambioDeBaseDeDatosDelInquilino` como referencia.
