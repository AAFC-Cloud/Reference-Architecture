$query = [Console]::In.ReadToEnd() | ConvertFrom-Json

try {
  $timeZone = [System.TimeZoneInfo]::FindSystemTimeZoneById($query.timezone_id)
}
catch {
  $timeZone = [System.TimeZoneInfo]::FindSystemTimeZoneById($query.timezone_windows_id)
}

$currentTimeToronto = [System.TimeZoneInfo]::ConvertTime([System.DateTimeOffset]::UtcNow, $timeZone)
$startTime = [System.TimeSpan]::Parse($query.working_hours_start)
$endTime = [System.TimeSpan]::Parse($query.working_hours_end)
$isWeekday = $currentTimeToronto.DayOfWeek -notin @([System.DayOfWeek]::Saturday, [System.DayOfWeek]::Sunday)
$isWithinWorkingHours = $isWeekday -and $currentTimeToronto.TimeOfDay -ge $startTime -and $currentTimeToronto.TimeOfDay -le $endTime

@{
  desired_idle = if ($isWithinWorkingHours) { '1' } else { '0' }
} | ConvertTo-Json -Compress