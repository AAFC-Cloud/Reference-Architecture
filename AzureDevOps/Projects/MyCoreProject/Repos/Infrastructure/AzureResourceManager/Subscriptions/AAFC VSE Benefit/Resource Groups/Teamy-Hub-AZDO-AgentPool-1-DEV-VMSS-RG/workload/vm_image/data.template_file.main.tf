data "template_file" "main" {
  template = file("./cloud_init/cloud-init.conf")
  vars = {
    GoC-GdC-Root-A-crt         = indent(6, file("./cloud_init/GoC-GdC-Root-A.crt"))
    install_certificates_sh    = indent(6, file("./cloud_init/install_certificates.sh"))
    install_java_sh            = indent(6, file("./cloud_init/install_java.sh"))
    install_dotnet_sh          = indent(6, file("./cloud_init/install_dotnet.sh"))
    install_powershell_sh      = indent(6, file("./cloud_init/install_powershell.sh"))
    install_azure_cli_sh       = indent(6, file("./cloud_init/install_azure_cli.sh"))
    install_terraform_sh       = indent(6, file("./cloud_init/install_terraform.sh"))
    install_docker_sh          = indent(6, file("./cloud_init/install_docker.sh"))
    install_motd_sh            = indent(6, file("./cloud_init/install_motd.sh"))
    install_python_sh          = indent(6, file("./cloud_init/install_python.sh"))
    install_checkov_sh         = indent(6, file("./cloud_init/install_checkov.sh"))
    install_azure_functools_sh = indent(6, file("./cloud_init/install_azure_functools.sh"))
    install_nodejs_sh          = indent(6, file("./cloud_init/install_nodejs.sh"))
  }
}
