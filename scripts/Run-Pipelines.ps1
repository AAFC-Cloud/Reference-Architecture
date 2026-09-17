$build_definitions = az pipelines build definition list --org https://dev.azure.com/teamdman --project MyCoreProject
$chosen = $build_definitions | ct pick --query-engine Liquid --query "{{id}} {{name}}" | ConvertFrom-Json
foreach ($build_definition in $chosen) {
    Write-Host "Queuing build for definition: $($build_definition.name) (ID: $($build_definition.id))"
    az pipelines build queue --definition-id $build_definition.id --org https://dev.azure.com/teamdman --project MyCoreProject
}
