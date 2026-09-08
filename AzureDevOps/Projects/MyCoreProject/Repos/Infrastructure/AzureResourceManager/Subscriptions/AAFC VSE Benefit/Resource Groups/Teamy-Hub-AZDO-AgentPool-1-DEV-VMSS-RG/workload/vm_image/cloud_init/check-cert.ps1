param(
    [int]
    $WarningPeriod = 90,
    [string[]]
    $CertFiles = @("GoC-GdC-Root-A.crt")
)
# GoC-GdC-Issuing-A1A.crt
# GoC-GdC-Root-A.crt

# For each cert:
# - Get expiry date
# - Check if expired
# - Check if expires in next 90 days

Write-Host -ForegroundColor "Yellow" "Ensuring OpenSSL present in path"
if ($null -eq (Get-Command "openssl.exe" -ErrorAction SilentlyContinue))
{
    $Env:PATH = $Env:PATH + ";$Env:LocalAppData\Programs\Git\mingw64\bin"
}


$today = Get-Date

# Ensure OpenSSL available
if ($null -eq (Get-Command "openssl.exe" -ErrorAction SilentlyContinue)) {
    Write-Host "OpenSSL not found in PATH; attempted to add Git's mingw64 but not available." -ForegroundColor Red
    Write-Host "Please install OpenSSL or add it to PATH and re-run the script." -ForegroundColor Red
    exit 2
}

foreach ($certFile in $CertFiles) {
    if (-not (Test-Path $certFile)) {
        Write-Host "Certificate file not found: $certFile" -ForegroundColor Red
        continue
    }

    Write-Host "Certificate: $certFile"
    try {
        $seconds = [int]($WarningPeriod * 24 * 60 * 60)

        # Check whether cert will expire within the warning period using OpenSSL
        $checkOutput = & openssl.exe x509 -checkend $seconds -noout -in $certFile 2>&1
        $checkExit = $LASTEXITCODE

        # Use ISO-8601 output (assume OpenSSL supports -dateopt iso_8601)
        $isoOutput = & openssl.exe x509 -enddate -noout -dateopt iso_8601 -in $certFile 2>&1
        if ($LASTEXITCODE -ne 0 -or -not $isoOutput) {
            Write-Host "OpenSSL failed to output ISO date for: $certFile" -ForegroundColor Red
            Write-Host ($isoOutput -join "`n") -ForegroundColor DarkRed
            continue
        }

        $isoLine = ($isoOutput -join "`n").Trim()
        $dateStr = $isoLine -replace '^notAfter=', ''
        try {
            $expiryDate = [DateTime]::Parse($dateStr, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::AssumeUniversal)
            $expiryDate = $expiryDate.ToUniversalTime()
        } catch {
            Write-Host "Failed to parse ISO date '$dateStr' for $certFile - $_" -ForegroundColor Red
            continue
        }

        Write-Host "Expiry Date: $($expiryDate.ToString('u'))"

        $daysRemaining = ($expiryDate - $today).Days
        if ($expiryDate -lt $today) {
            Write-Host "Status: EXPIRED ($daysRemaining days ago)" -ForegroundColor Red
        } elseif ($checkExit -ne 0) {
            # openssl -checkend returned non-zero -> expires within $WarningPeriod seconds
            Write-Host "Status: Expiring within $WarningPeriod days ($daysRemaining days left)" -ForegroundColor Yellow
        } else {
            Write-Host "Status: Valid ($daysRemaining days left)" -ForegroundColor Green
        }
        Write-Host ""
    } catch {
        Write-Host "Error processing certificate file: $certFile - $_" -ForegroundColor Red
    }
}