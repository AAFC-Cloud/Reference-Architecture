Write-Host "Grabbing VM information from Terraform outputs"
$tf_outputs = terraform output -json | ConvertFrom-Json
$vm_id = $tf_outputs.vm_id.value

Write-Host "Rebooting vm"
az vm restart `
--ids $vm_id
