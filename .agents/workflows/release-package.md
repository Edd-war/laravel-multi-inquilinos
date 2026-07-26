---
description: Guía paso a paso para analizar cambios, organizar commits, ejecutar calidad de código (Pest/Pint/PHPStan), incrementar versión semántica y publicar releases en Git/GitHub sin depender de scripts externos.
---

# Workflow: Publicación y Release de Versión (`release-package`)

Este workflow proporciona al agente de código las instrucciones nativas directas para inspeccionar cambios en Git, empaquetar en commits organizados, verificar la calidad del código y publicar el release en GitHub (creación de tag y push).

> **Nota**: Este workflow no depende de scripts interactivos como `publish.ps1` o `publish.sh`. Ejecuta todos los comandos directamente en la shell sin requerir prompts interactivos que bloqueen procesos de fondo.

---

## 🔍 Paso 1: Análisis de Cambios en Git y Plan de Commits

1. Ejecutar `git status` e inspeccionar las modificaciones y archivos nuevos/eliminados.
2. Agrupar los cambios de forma lógica según su objetivo o componente:
    - **`chore`**: Infraestructura, workflows CI/CD, dependencias `composer.json`, herramientas.
    - **`refactor`**: Modificaciones al núcleo en `src/`, traits, modelos, interfaces y sus pruebas asociadas en `pruebas/`.
    - **`docs`**: Actualización de documentación en `docs/`, `README.md`, `CHANGELOG.md`.
    - **`feat` / `fix`**: Nuevas características o corrección de errores de código.
3. Presentar la propuesta de commits agrupados al usuario para confirmación antes de proceder.

---

## 🧪 Paso 2: Verificación y Calidad de Código

Ejecutar las herramientas de validación del paquete de forma secuencial y verificar que todas devuelvan código de salida `0`:

1. **Suite de Pruebas Automatizadas**:
    ```bash
    composer test
    ```
2. **Formateo de Código**:
    ```bash
    composer format
    ```
3. **Análisis Estático**:
    ```bash
    composer analyse
    ```

Si alguna herramienta reporta fallos, resolverlos o detener el flujo hasta contar con luz verde.

---

## 📦 Paso 3: Creación de Commits Organizados

Con las pruebas aprobadas y el plan confirmado por el usuario, realizar staging y commit por cada grupo definido:

```bash
git add <archivos_del_grupo>
git commit -m "<tipo>: <descripcion_del_cambio>"
```

---

## 🏷️ Paso 4: Cálculo e Incremento de Versión Semántica

1. Consultar la versión más reciente en Git:

    ```bash
    git describe --tags --abbrev=0
    ```

    _(Si no existe tag, usar `v13.0.0` como base)._

2. Confirmar con el usuario el tipo de incremento:
    - `patch` — Corrección de errores compatibles (`v13.2.0` → `v13.2.1`).
    - `minor` — Nuevas características o refactorizaciones compatibles (`v13.2.0` → `v13.3.0`).
    - `major` — Cambios rompientes o nueva versión de Laravel (`v13.x` → `v14.0.0`).

---

## 🚀 Paso 5: Creación del Tag y Push a GitHub

1. Crear el tag anotado de la versión calculada:

    ```bash
    git tag -a <nueva_version> -m "Release <nueva_version>"
    ```

2. Hacer push de la rama actual y del nuevo tag a GitHub:
    ```bash
    git push origin main
    git push origin <nueva_version>
    ```

---

## 🏁 Paso 6: Confirmación Post-Release

Informar al usuario la finalización exitosa del release indicando:

1. La nueva versión publicada (ej. `v13.3.0`).
2. Que los siguientes workflows de GitHub Actions se activarán automáticamente si están configurados en el repositorio:
    - **`03-release.yml`** (si existe): Crea la Release oficial en GitHub.
    - **`04-validar-release-composer.yml`** (si existe): Valida el paquete Composer.
    - **`05-publish-composer.yml`** (si existe): Publica en GitHub Packages.
3. Enlace directo al release:
   `https://github.com/Edd-war/laravel-multitenencia/releases/tag/<nueva_version>`
