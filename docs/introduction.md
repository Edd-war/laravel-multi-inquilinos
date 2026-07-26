---
title: Introducción
weight: 1
---

Este paquete permite que una aplicación Laravel sea consciente del inquilino actual. La filosofía del paquete es que solo debe proporcionar lo esencial para habilitar la multitenencia.

El paquete puede determinar qué inquilino debe ser el actual para cada solicitud. También permite definir qué debe suceder al cambiar el inquilino actual. Funciona tanto para proyectos de multitenencia con una sola base de datos como con múltiples bases de datos.

Antes de comenzar con el paquete, recomendamos ver [esta charla de Tom Schlick sobre estrategias de multitenencia](https://tomschlick.com/laracon-2017-multi-tenancy-talk/).

El paquete incluye utilidades como: hacer que los trabajos en cola reconozcan inquilinos, ejecutar un comando Artisan para cada inquilino, establecer conexiones de base de datos de forma dinámica por inquilino, y mucho más.
