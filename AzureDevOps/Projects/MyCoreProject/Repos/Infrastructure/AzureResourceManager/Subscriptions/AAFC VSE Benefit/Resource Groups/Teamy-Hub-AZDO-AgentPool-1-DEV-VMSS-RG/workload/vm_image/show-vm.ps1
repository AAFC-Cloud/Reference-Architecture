Write-Host "Grabbing VM information from Terraform outputs"
$tf_outputs = terraform output -json | ConvertFrom-Json
$vm_id = $tf_outputs.vm_id.value

Write-Host "Showing VM"
az vm show `
--ids $vm_id

Write-Host "Showing VM status"
az vm get-instance-view `
--ids $vm_id
