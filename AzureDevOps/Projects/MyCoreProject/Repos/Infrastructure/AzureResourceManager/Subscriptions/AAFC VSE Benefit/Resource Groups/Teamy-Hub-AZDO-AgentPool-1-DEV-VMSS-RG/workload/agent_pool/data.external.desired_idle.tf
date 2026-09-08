data "external" "desired_idle" {
  program = [
    "pwsh",
    "-NoLogo",
    "-NoProfile",
    "-File",
    "${path.module}/scripts/get-desired-idle.ps1",
  ]

  query = {
    timezone_id         = "America/Toronto"
    timezone_windows_id = "Eastern Standard Time"
    working_hours_start = "07:30"
    working_hours_end   = "16:30"
  }
}
