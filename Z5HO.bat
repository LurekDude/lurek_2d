@echo off
:: lunec.bat — Launch a Luna2D game without a console window.
::
:: Usage:
::   lunec                        -- show Luna2D splash screen
::   lunec path\to\my_game        -- run my_game
::   lunec examples\hello_world   -- run bundled example
::
:: How it works:
::   `start "" /B` launches luna2d.exe as a background process.
::   When this batch file exits, the temporary console window disappears
::   and only the game window remains visible.
::
:: Icon: right-click this file -> Create shortcut,
::       then right-click the shortcut -> Properties -> Change Icon
::       and point it at assets\icon.ico
::
start "" /B "%~dp0luna2d.exe" %*
