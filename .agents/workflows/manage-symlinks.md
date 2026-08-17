---
description: Procedimiento estandarizado para crear y mantener enlaces simbólicos relativos entre .agents/skills y resources/boost/skills (o cualquier par de carpetas) garantizando compatibilidad cross-platform (Windows, Linux, Git).
---

# Workflow: Enlaces Simbólicos Relativos (`manage-symlinks`)

Este workflow proporciona la guía paso a paso para crear y verificar enlaces simbólicos (**symlinks**) relativos en este repositorio o paquetes dependientes, asegurando que la fuente canónica siempre resida en `.agents/` y se comparta limpiamente hacia otros consumidores como `resources/boost/`.

---

## 📋 Reglas Fundamentales

1. **Ubicación Canónica**: La fuente de verdad siempre reside en `.agents/` (ej. `.agents/skills/`).
2. **Rutas Relativas**: Siempre usar punteros relativos (`..\..\.agents\skills` o `../../.agents/skills`) para que el repositorio sea 100% portable en Windows, Linux, WSL y GitHub Actions.
3. **No duplicar archivos**: Nunca mantener dos copias físicas del mismo contenido en el árbol del repositorio.

---

## 🛠️ Procedimiento de Enlace

### 1. Migración y Limpieza del Destino
```powershell
# 1. Copiar el contenido a la fuente canónica si no existe allí
Copy-Item -Path "resources/boost/skills/*" -Destination ".agents/skills/" -Recurse -Force

# 2. Eliminar la carpeta destino previa
Remove-Item -Recurse -Force "resources/boost/skills"
```

### 2. Creación del Enlace Simbólico Relativo

**En Windows:**
```powershell
cd resources/boost
cmd /c "mklink /D skills ..\..\.agents\skills"
```

**En Linux / Mac / CI:**
```bash
cd resources/boost
ln -s ../../.agents/skills skills
```

---

## 🧪 Verificación

```powershell
# 1. Comprobar que los archivos son visibles desde el symlink
Get-ChildItem -Path "resources/boost/skills" -Recurse

# 2. Verificar estado de Git
git status -s
```
