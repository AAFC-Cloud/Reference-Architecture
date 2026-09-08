Write-Host "Grabbing VM information from Terraform outputs"
$tf_outputs = terraform output -json | ConvertFrom-Json
$vm_id = $tf_outputs.vm_id.value

Write-Host "Running" -NoNewline
Write-Host " cloud-init status --wait --long" -ForegroundColor Yellow
az vm run-command invoke `
--ids $vm_id `
--command-id RunShellScript `
--scripts "cloud-init status --wait --long"

.\check-vm-internet.ps1
