param(
    [Parameter(Mandatory = $false)]
    [string] $Repo = "D:\repos\packages\laravel-multitenencia",

    [Parameter(Mandatory = $false)]
    [string[]] $Include = @(
        # =========== #1 ============
        "config"
        "database"
        "resources"
        "scripts"
        "composer.json"
        ".php-cs-fixer.dist.php"
        # =========== #2 ============
        # "phpstan-baseline.neon"
        # "phpstan.neon.dist"
        # "phpunit.xml.dist"
        # "pint.json"
        # "tests"
        # =========== #3 ============
        # "src"
        # =========== #4 ============
        # ".agents"
        # ".github"
        # "docs"
        # ".gitignore"
        # ".gitattributes"
        # "README.md"
        # "RELEASE.md"
        # =========== #5 ============
    ),

    [Parameter(Mandatory = $false)]
    [string] $Out = ".\scratch\contexto-laravel-multitenencia-01.md",
    # [string] $Out = ".\scratch\contexto-laravel-multitenencia-02.md",
    # [string] $Out = ".\scratch\contexto-laravel-multitenencia-03.md",
    # [string] $Out = ".\scratch\contexto-laravel-multitenencia-04.md",

    [Parameter(Mandatory = $false)]
    [string[]] $AllowedExtensions = @(
        ".php",
        ".stub",
        ".json",
        ".dist",
        ".neon",
        ".md",
        ".mjs",
        ".js",
        ".cjs",
        ".yml",
        ".yaml",
        ".xml",
        ".txt",
        ".env.example",
        ".ps1",
        ".sh",
        ".gitignore",
        ".gitattributes"
    ),

    [Parameter(Mandatory = $false)]
    [string[]] $AllowedExtensionlessFiles = @(
        "artisan"
    ),

    [Parameter(Mandatory = $false)]
    [string[]] $ExcludedPrefixes = @(
        ".git/",
        "vendor/",
        "node_modules/",
        "storage/",
        "bootstrap/cache/",
        "public/build/",
        "public/hot",
        "coverage/",
        "scratch/"
    ),

    [Parameter(Mandatory = $false)]
    [string[]] $ExplicitExcludedFiles = @(
        ".env",
        ".env.local",
        ".env.production",
        ".env.testing",
        ".env.staging",
        "auth.json",
        "composer.lock",
        "package-lock.json",
        "storage/logs/laravel.log"
    ),

    [Parameter(Mandatory = $false)]
    [switch] $IncludeGitStatus,

    [Parameter(Mandatory = $false)]
    [switch] $WarnMissingIncludes
)

$repoRoot = (Resolve-Path -LiteralPath $Repo).Path

if ([string]::IsNullOrWhiteSpace($Out)) {
    $Out = Join-Path $repoRoot "scratch\contexto-laravel-multitenencia.md"
}

$outDir = Split-Path -Parent $Out

if (-not (Test-Path -LiteralPath $outDir -PathType Container)) {
    New-Item -ItemType Directory -Path $outDir | Out-Null
}

function ConvertTo-RepoPath {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    $resolved = $Path

    if ([System.IO.Path]::IsPathRooted($Path)) {
        try {
            $resolved = (Resolve-Path -LiteralPath $Path).Path
        }
        catch {
            $resolved = $Path
        }

        if ($resolved.StartsWith($repoRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
            $resolved = $resolved.Substring($repoRoot.Length).TrimStart("\", "/")
        }
    }

    return $resolved.Replace("\", "/").Trim()
}

function Get-FullPathFromRepoPath {
    param(
        [Parameter(Mandatory = $true)]
        [string] $RelativePath
    )

    return Join-Path $repoRoot ($RelativePath.Replace("/", [System.IO.Path]::DirectorySeparatorChar))
}

function Test-IsExcludedPath {
    param(
        [Parameter(Mandatory = $true)]
        [string] $RelativePath
    )

    $normalized = ConvertTo-RepoPath $RelativePath

    foreach ($excludedFile in $ExplicitExcludedFiles) {
        $normalizedExcludedFile = $excludedFile.Replace("\", "/")

        if ($normalized.Equals($normalizedExcludedFile, [System.StringComparison]::OrdinalIgnoreCase)) {
            return $true
        }
    }

    foreach ($prefix in $ExcludedPrefixes) {
        $normalizedPrefix = $prefix.Replace("\", "/")

        if ($normalized.StartsWith($normalizedPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            return $true
        }
    }

    return $false
}

function Test-IsAllowedTextFile {
    param(
        [Parameter(Mandatory = $true)]
        [string] $RelativePath
    )

    $normalized = ConvertTo-RepoPath $RelativePath
    $fileName = [System.IO.Path]::GetFileName($normalized)

    if ($fileName -eq ".env.example") {
        return $true
    }

    if ($AllowedExtensionlessFiles -contains $fileName) {
        return $true
    }

    $extension = [System.IO.Path]::GetExtension($normalized).ToLowerInvariant()

    return $AllowedExtensions -contains $extension
}

function Get-MarkdownFence {
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [AllowEmptyString()]
        [string] $Content
    )

    if ([string]::IsNullOrEmpty($Content)) {
        return '```'
    }

    $regexMatches = [regex]::Matches($Content, '`+')
    $max = 2

    foreach ($match in $regexMatches) {
        if ($match.Value.Length -gt $max) {
            $max = $match.Value.Length
        }
    }

    return ('`' * ($max + 1))
}

function Get-FenceLanguage {
    param(
        [Parameter(Mandatory = $true)]
        [string] $RelativePath
    )

    $normalized = ConvertTo-RepoPath $RelativePath
    $fileName = [System.IO.Path]::GetFileName($normalized)
    $extension = [System.IO.Path]::GetExtension($normalized).ToLowerInvariant()

    if ($fileName -eq ".env.example") {
        return "dotenv"
    }

    switch ($extension) {
        ".php" { return "php" }
        ".js" { return "js" }
        ".jsx" { return "jsx" }
        ".mjs" { return "js" }
        ".cjs" { return "js" }
        ".json" { return "json" }
        ".md" { return "md" }
        ".yml" { return "yaml" }
        ".yaml" { return "yaml" }
        ".xml" { return "xml" }
        ".txt" { return "text" }
        ".ps1" { return "powershell" }
        ".sh" { return "shell" }
        default { return "text" }
    }
}

function Add-FileEntry {
    param(
        [Parameter(Mandatory = $true)]
        [string] $RelativePath,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[string]] $Entries,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.HashSet[string]] $Seen
    )

    $rel = ConvertTo-RepoPath $RelativePath

    if ([string]::IsNullOrWhiteSpace($rel)) {
        return
    }

    if (Test-IsExcludedPath $rel) {
        return
    }

    if (-not (Test-IsAllowedTextFile $rel)) {
        return
    }

    $full = Get-FullPathFromRepoPath $rel

    if (-not (Test-Path -LiteralPath $full -PathType Leaf)) {
        return
    }

    if ($Seen.Add($rel)) {
        $Entries.Add($rel)
    }
}

function Add-DirectoryEntries {
    param(
        [Parameter(Mandatory = $true)]
        [string] $RelativePath,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[string]] $Entries,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.HashSet[string]] $Seen
    )

    $rel = ConvertTo-RepoPath $RelativePath

    if ([string]::IsNullOrWhiteSpace($rel)) {
        return
    }

    if (Test-IsExcludedPath $rel) {
        return
    }

    $full = Get-FullPathFromRepoPath $rel

    if (-not (Test-Path -LiteralPath $full -PathType Container)) {
        return
    }

    $files = Get-ChildItem -LiteralPath $full -Recurse -File -Force

    foreach ($file in $files) {
        $filePath = $file.FullName

        if (-not $filePath.StartsWith($repoRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
            continue
        }

        $fileRel = $filePath.Substring($repoRoot.Length).TrimStart("\", "/").Replace("\", "/")

        Add-FileEntry -RelativePath $fileRel -Entries $Entries -Seen $Seen
    }
}

function Add-IncludeEntry {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[string]] $Entries,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.HashSet[string]] $Seen
    )

    $rel = ConvertTo-RepoPath $Path
    $full = Get-FullPathFromRepoPath $rel

    if (Test-Path -LiteralPath $full -PathType Leaf) {
        Add-FileEntry -RelativePath $rel -Entries $Entries -Seen $Seen
        return
    }

    if (Test-Path -LiteralPath $full -PathType Container) {
        Add-DirectoryEntries -RelativePath $rel -Entries $Entries -Seen $Seen
        return
    }

    if ($WarnMissingIncludes) {
        Write-Warning "No existe o no es accesible: $Path"
    }
}

if ($Include.Count -eq 0) {
    throw "Debes proporcionar al menos una ruta en -Include. Puede ser archivo o directorio."
}

$entries = [System.Collections.Generic.List[string]]::new()
$seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

foreach ($item in $Include) {
    Add-IncludeEntry -Path $item -Entries $entries -Seen $seen
}

$entries = @($entries | Sort-Object)

$parts = [System.Collections.Generic.List[string]]::new()

$parts.Add("# Contexto Laravel para Multi Tenencia")
$parts.Add("")
$parts.Add("Generado: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
$parts.Add("")
$parts.Add("Repositorio: $repoRoot")
$parts.Add("")
$parts.Add("Salida: $Out")
$parts.Add("")
$parts.Add("Archivos incluidos: $($entries.Count)")
$parts.Add("")

$parts.Add("## Entradas solicitadas")
$parts.Add("")
$parts.Add('```text')

foreach ($item in $Include) {
    $parts.Add((ConvertTo-RepoPath $item))
}

$parts.Add('```')
$parts.Add("")

if ($IncludeGitStatus) {
    $parts.Add("## Git status --short -uall")
    $parts.Add("")
    $parts.Add('```text')

    $statusShort = & git -C $repoRoot status --short -uall 2>$null

    foreach ($line in $statusShort) {
        if (-not [string]::IsNullOrWhiteSpace($line) -and -not $line.StartsWith("warning:")) {
            $parts.Add($line)
        }
    }

    $parts.Add('```')
    $parts.Add("")
}

$parts.Add("## Archivos incluidos")
$parts.Add("")
$parts.Add('```text')

foreach ($rel in $entries) {
    $parts.Add($rel)
}

$parts.Add('```')
$parts.Add("")

foreach ($rel in $entries) {
    $full = Get-FullPathFromRepoPath $rel

    if (-not (Test-Path -LiteralPath $full -PathType Leaf)) {
        continue
    }

    try {
        $text = Get-Content -LiteralPath $full -Raw -Encoding utf8 -ErrorAction Stop
    }
    catch {
        $parts.Add("---")
        $parts.Add("")
        $parts.Add("## File: $rel")
        $parts.Add("")
        $parts.Add('```text')
        $parts.Add("[ERROR] No se pudo leer el archivo como UTF-8: $($_.Exception.Message)")
        $parts.Add('```')
        $parts.Add("")
        continue
    }
    if ($null -eq $text) {
        $text = ''
    }

    $language = Get-FenceLanguage $rel
    $fence = Get-MarkdownFence -Content $text

    $parts.Add("---")
    $parts.Add("")
    $parts.Add("## File: $rel")
    $parts.Add("")
    $parts.Add("$fence$language")
    if ([string]::IsNullOrEmpty($text)) {
        $parts.Add("[ARCHIVO VACIO]")
    }
    else {
        $parts.Add($text.TrimEnd())
    }
    $parts.Add($fence)
    $parts.Add("")
}

Set-Content -LiteralPath $Out -Value ($parts -join [System.Environment]::NewLine) -Encoding utf8

Write-Host "Wrote $($entries.Count) files to $Out"
