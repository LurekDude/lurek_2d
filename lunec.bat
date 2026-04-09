@echo off
:: lurekc.bat — Launch a Lurek2D game without a console window.
::
:: Usage:
::   lurekc                        -- show Lurek2D splash screen
::   lurekc path\to\my_game        -- run my_game
::   lurekc examples\hello_world   -- run bundled example
::
:: How it works:
::   `start "" /B` launches lurek2d.exe as a background process.
::   When this batch file exits, the temporary console window disappears
::   and only the game window remains visible.
::
:: Icon: right-click this file -> Create shortcut,
::       then right-click the shortcut -> Properties -> Change Icon
::       and point it at assets\icon.ico
::
start "" /B "%~dp0luna2d.exe" %*
