# Engine logs frame time at debug level — extract and summarise
Select-String "frame_time" logs/session.log |
    ForEach-Object { ($_ -split "=")[1].Trim().TrimEnd("ms") } |
    Measure-Object -Average -Maximum -Minimum
