# Workflow 05-publish-composer.yml - Documentación

## 📋 Descripción

Este workflow automatiza la publicación del paquete Composer `edd-war/laravel-autorizacion` utilizando autenticación mediante GitHub Apps y la herramienta `@edd-war/autenticador-token-cli`.

**Método de Autenticación con Fallback:**

1. **Primario (Recomendado)**: GitHub App Token generado con `@edd-war/autenticador-token-cli`
    - Más seguro (expira en ~1 hora)
    - No vinculado a usuarios individuales
2. **Fallback**: Personal Access Token (`GH_PACKAGES_PAT`)
    - Se usa automáticamente si el método primario falla
    - Útil para casos de emergencia o debugging

## 🚀 Triggers

El workflow se ejecuta en dos situaciones:

1. **Automáticamente**: Cuando se publica un GitHub Release (`release: types: [published]`)
2. **Manualmente**: Via `workflow_dispatch` con input de tag/versión

## 🔐 Secrets Requeridos

Para que este workflow funcione correctamente, debes configurar los siguientes secrets en el repositorio:

### Secrets Principales (GitHub App - Recomendado)

| Secret               | Descripción                                             | Cómo Obtenerlo                                                        | Prioridad |
| -------------------- | ------------------------------------------------------- | --------------------------------------------------------------------- | --------- |
| `GH_APP_ID`          | App ID de la GitHub App                                 | Configuración de la GitHub App → "About" section                      | Alta      |
| `GH_APP_CLIENT_ID`   | Client ID de la GitHub App                              | Configuración de la GitHub App → "About" section                      | Alta      |
| `GH_APP_PRIVATE_KEY` | Contenido completo del archivo `.pem` de la private key | Configuración de la GitHub App → "Private keys" → Generar y descargar | Alta      |

### Secret de Fallback

| Secret            | Descripción                                              | Uso                                                      | Prioridad |
| ----------------- | -------------------------------------------------------- | -------------------------------------------------------- | --------- |
| `GH_PACKAGES_PAT` | Personal Access Token con scope `repo` y `read:packages` | Se usa **solo si falla** la autenticación con GitHub App | Fallback  |

> ⚠️ **Nota**: El workflow intentará primero autenticarse con GitHub App. Si falla, usará automáticamente `GH_PACKAGES_PAT` como fallback.

### Cómo Configurar los Secrets

1. Ve a tu repositorio en GitHub
2. Navega a **Settings** → **Secrets and variables** → **Actions**
3. Haz clic en **New repository secret**
4. Agrega cada secret con su valor correspondiente

### Formato del Private Key

Para `GH_APP_PRIVATE_KEY`, copia **TODO** el contenido del archivo `.pem`, incluyendo las líneas de inicio y fin:

```
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA...
(varias líneas de la clave)
-----END RSA PRIVATE KEY-----
```

## 🛠️ Tecnologías Utilizadas

- **Node.js 24**: Para ejecutar `@edd-war/autenticador-token-cli`
- **PHP 8.5**: Para validar y testear el paquete Composer
- **@edd-war/autenticador-token-cli**: Herramienta CLI para generar Installation Access Tokens de GitHub Apps

## 🔒 Ventajas de Usar GitHub Apps

Los Installation Access Tokens generados por GitHub Apps son más seguros que Personal Access Tokens (PATs) porque:

- ✅ **Expiran automáticamente** en ~1 hora
- ✅ **No están vinculados a usuarios individuales** (mejor para CI/CD)
- ✅ **Permisos granulares** a nivel de repositorio/organización
- ✅ **Auditoría mejorada** de accesos y operaciones

## 📦 Flujo del Workflow

1. **Checkout** del código del repositorio
2. **Determina la versión** del release (automático o manual)
3. **Verifica** que el tag existe en Git
4. **Configura Node.js 24** para usar npm/npx
5. **Instala `@edd-war/autenticador-token-cli`** desde GitHub Packages
6. **Configura perfil de GitHub App** creando archivos JSON en `~/.config/autenticador-token/profiles/`
7. **Genera Installation Access Token** usando `token-cli token --format token` (con `continue-on-error: false`)
8. **Fallback a PAT** (solo si paso 7 falla): Usa `GH_PACKAGES_PAT` como alternativa
9. **Enmascara el token** en logs de GitHub Actions con `::add-mask::`
10. **Configura PHP 8.5** con extensiones necesarias
11. **Configura autenticación de Composer** usando el token generado (GitHub App o PAT)
12. **Valida `composer.json`** con `composer validate --strict`
13. **Instala dependencias** de Composer
14. **Ejecuta tests** Pest (con `continue-on-error: false`)
15. **Genera resumen de publicación** en `$GITHUB_STEP_SUMMARY` con:
    - Información del paquete (nombre, versión, estado de tests)
    - Método de autenticación usado (GitHub App o PAT)
    - Instrucciones de instalación (con `token-cli` o PAT tradicional)
    - Configuración del repositorio VCS en `composer.json`
    - Documentación de secrets requeridos

## 📊 Resumen de Publicación

Al finalizar, el workflow genera un resumen completo en la pestaña "Summary" de GitHub Actions que incluye:

- 📦 **Información del paquete**: nombre, versión, descripción, estado de tests
- 🔧 **Instrucciones de instalación**:
    - Opción 1: Usando GitHub App Token (recomendado)
    - Opción 2: Usando PAT tradicional
- 📝 **Notas de seguridad**: comparación de métodos de autenticación
- 🔐 **Secrets requeridos**: tabla de referencia

## 🧪 Tests

El paso de tests ejecuta `vendor/bin/pest` con `continue-on-error: false` porque:

- Si falla, el workflow fallará

## 🔄 Concurrencia

El workflow usa `cancel-in-progress: false` porque:

- Los releases **no deben cancelarse** en progreso
- Garantiza que un release iniciado se complete
- Evita releases parciales o incompletos

## 📚 Recursos Adicionales

- [Documentación de GitHub Apps](https://docs.github.com/en/apps)
- [Installation Access Tokens](https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/generating-an-installation-access-token-for-a-github-app)
- [Composer VCS Repositories](https://getcomposer.org/doc/05-repositories.md#vcs)
- [GitHub Actions Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)

## 🐛 Troubleshooting

### ✅ Workflow usa automáticamente PAT como fallback

Si ves el mensaje "⚠️ GitHub App token falló, usando PAT como fallback...", significa que:

- El workflow intentó autenticarse con GitHub App pero falló
- Automáticamente cambió a usar `GH_PACKAGES_PAT` como alternativa
- El workflow **continuará ejecutándose** normalmente
- En el resumen verás "🔑 Personal Access Token (fallback)" en lugar de "🔐 GitHub App Token"

**Esto NO es un error fatal**, pero si quieres usar GitHub App:

1. Verifica que los secrets `GH_APP_ID`, `GH_APP_CLIENT_ID` y `GH_APP_PRIVATE_KEY` estén configurados correctamente
2. Verifica que la GitHub App tenga permisos suficientes (`contents: read`, `packages: read`)
3. Verifica que la GitHub App esté instalada en el repositorio/organización
4. Revisa los logs del paso "🎫 Generar Installation Access Token" para ver el error específico

### Error: "Could not authenticate against github.com"

**Problema**: Ambos métodos de autenticación fallaron (GitHub App y PAT).

**Solución**:

1. Verifica que `GH_PACKAGES_PAT` esté configurado y tenga los scopes `repo` y `read:packages`
2. Regenera el PAT si es necesario: https://github.com/settings/tokens
3. Verifica que el PAT no haya expirado

### Error: "npm ERR! 404 Not Found - GET https://npm.pkg.github.com/@edd-war/autenticador-token-cli"

**Problema**: El paquete `@edd-war/autenticador-token-cli` no está disponible o no tienes acceso.

**Solución**:

1. Verifica que el paquete esté publicado en GitHub Packages
2. Verifica que `GITHUB_TOKEN` tenga permisos de lectura de packages
3. Verifica que la organización/usuario tenga el paquete visible

### Error: "tag X not found"

**Problema**: El tag especificado no existe en Git.

**Solución**:

1. Crea el tag: `git tag v13.0.0`
2. Push el tag: `git push origin v13.0.0`
3. Vuelve a ejecutar el workflow

## 📄 Licencia

Este workflow es parte del paquete `edd-war/laravel-autorizacion` y está bajo la licencia MIT.
