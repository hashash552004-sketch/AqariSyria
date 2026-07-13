$jobId = 83917270524
$url = "https://api.github.com/repos/hashash552004-sketch/AqariSyria/actions/jobs/$jobId"
$job = Invoke-RestMethod -Uri $url
foreach ($step in $job.steps) {
    if ($step.conclusion -eq "failure") {
        Write-Host "Failed step: $($step.name) ($($step.number))" -ForegroundColor Red
        Write-Host ($step | ConvertTo-Json -Depth 5)
    }
}
