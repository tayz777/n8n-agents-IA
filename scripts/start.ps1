$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$envPath = Join-Path $projectRoot '.env'
$envExamplePath = Join-Path $projectRoot '.env.example'

function Invoke-Docker {
    param(
        [Parameter(Mandatory = $true)]
        [string[]] $Arguments,
        [Parameter(Mandatory = $true)]
        [string] $FailureMessage
    )

    # Windows PowerShell 5.1 transforme parfois un simple avertissement écrit
    # sur stderr par Docker en erreur PowerShell. Le code de sortie reste la
    # source fiable pour savoir si la commande a réussi.
    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        & docker @Arguments
        $exitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousPreference
    }

    if ($exitCode -ne 0) {
        throw $FailureMessage
    }
}

Push-Location $projectRoot

try {
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        throw 'Docker est introuvable. Installez ou démarrez Docker Desktop.'
    }

    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = 'SilentlyContinue'
    try {
        docker info *> $null
        $dockerInfoExitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousPreference
    }
    if ($dockerInfoExitCode -ne 0) { throw 'Docker ne répond pas. Démarrez Docker Desktop puis réessayez.' }

    if (-not (Test-Path -LiteralPath $envPath)) {
        $content = [System.IO.File]::ReadAllText($envExamplePath)
        $keyBytes = New-Object byte[] 32
        $randomGenerator = [System.Security.Cryptography.RandomNumberGenerator]::Create()
        try {
            $randomGenerator.GetBytes($keyBytes)
        } finally {
            $randomGenerator.Dispose()
        }
        $encryptionKey = -join ($keyBytes | ForEach-Object { $_.ToString('x2') })
        $content = $content.Replace('GENERATED_BY_START_SCRIPT', $encryptionKey)
        [System.IO.File]::WriteAllText(
            $envPath,
            $content,
            [System.Text.UTF8Encoding]::new($false)
        )
        Write-Host 'Fichier .env local créé avec une clé de chiffrement aléatoire.'
    }

    Invoke-Docker -Arguments @('compose', 'config', '--quiet') -FailureMessage 'La configuration Docker Compose est invalide.'
    Invoke-Docker -Arguments @('compose', 'up', '-d', '--wait', 'n8n') -FailureMessage 'n8n n’a pas démarré correctement.'
    Invoke-Docker -Arguments @('compose', '--profile', 'setup', 'run', '--rm', 'init-owner') -FailureMessage 'Le compte propriétaire n’a pas pu être initialisé.'

    $hostPort = '5678'
    $portLine = Get-Content -LiteralPath $envPath | Where-Object { $_ -match '^N8N_HOST_PORT=' } | Select-Object -First 1
    if ($portLine) { $hostPort = ($portLine -split '=', 2)[1].Trim() }

    Write-Host ''
    Write-Host "n8n est prêt : http://localhost:$hostPort"
    Write-Host 'Compte par défaut : admin@local.test / Admin123'
} finally {
    Pop-Location
}
