$sshKeyPath = Join-Path $PSScriptRoot "ignore\sshkey.pem"

if (-not (Test-Path $sshKeyPath)) {
	throw "SSH private key not found at $sshKeyPath. Run 'terraform apply' first."
}

$tf_outputs = terraform output -json | ConvertFrom-Json
$vm_id = $tf_outputs.vm_id.value

icacls $sshKeyPath /inheritance:r | Out-Null
icacls $sshKeyPath /remove:g "Authenticated Users" "Users" "Everyone" | Out-Null
icacls $sshKeyPath /grant:r "${env:USERNAME}:(R)" | Out-Null

az network bastion ssh `
--name "my-bastion" `
--resource-group "my-bastion-rg" `
--target-resource-id "$vm_id" `
--subscription "my-bastion-subscription" `
--auth-type "ssh-key" `
--username azureuser `
--ssh-key $sshKeyPath

