# All errors in a session
Select-String "\[ERROR\]" logs/session.log

# Warning frequency (top 10 most common)
Select-String "\[WARN\]" logs/session.log |
    ForEach-Object { ($_ -split "]")[-1].Trim() } |
    Group-Object | Sort-Object -Property Count -Descending |
    Select-Object -First 10
