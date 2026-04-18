$log = Get-Content "logs/game.log"
$levels = 1..10
foreach ($lvl in $levels) {
    $starts    = ($log | Select-String "event=.game_start. level=$lvl").Count
    $completes = ($log | Select-String "event=.level_complete. level=$lvl").Count
    $rate = if ($starts -gt 0) { int } else { 0 }
    Write-Host "Level $lvl  starts=$starts  completes=$completes  rate=$rate%"
}
