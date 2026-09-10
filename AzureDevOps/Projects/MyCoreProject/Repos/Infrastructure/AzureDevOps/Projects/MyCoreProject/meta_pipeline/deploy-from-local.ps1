if (-not (Test-Path -Path Env:\AZDO_PERSONAL_ACCESS_TOKEN)) {
    # You can dot-source this file and it will persist the variable
    # This can help when iterating and running the script multiple times
    # The `-MaskInput` flag requires powershell core (pwsh)
    $env:AZDO_PERSONAL_ACCESS_TOKEN=Read-Host -MaskInput "Enter PAT"
}
terraform apply