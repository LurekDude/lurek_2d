; Luna2D NSIS Installer Script
; =============================================================================
;
; Requirements:
;   - NSIS 3.x (https://nsis.sourceforge.io/Download)
;   - Built release binary at:  build\release\luna.exe
;   - Icon at:                  assets\icon.ico
;   - Run from workspace root:  makensis tools\installer.nsi
;
; Usage:
;   makensis tools\installer.nsi
;
; Output:
;   dist\luna2d-<Version>-setup.exe
; =============================================================================

!define APP_NAME     "Luna2D"
!define APP_VERSION  "0.4.0"
!define APP_PUBLISHER "Luna2D Project"
!define APP_URL      "https://github.com/yourname/luna2d"
!define APP_EXE      "luna.exe"
!define APP_ICON     "..\assets\icon.ico"

; Output installer filename
!define OUT_FILE     "..\dist\luna2d-${APP_VERSION}-setup.exe"

; ── NSIS Settings ────────────────────────────────────────────────────────────
Name                "${APP_NAME} ${APP_VERSION}"
OutFile             "${OUT_FILE}"
InstallDir          "$PROGRAMFILES64\${APP_NAME}"
InstallDirRegKey    HKLM "Software\${APP_NAME}" "Install_Dir"
RequestExecutionLevel admin

; Compression
SetCompressor       /SOLID lzma

; Nice installer visuals
!include "MUI2.nsh"

!define MUI_ICON    "${APP_ICON}"
!define MUI_UNICON  "${APP_ICON}"
!define MUI_WELCOMEFINISHPAGE_BITMAP_NOSTRETCH
!define MUI_ABORTWARNING

; Pages
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

; Uninstall pages
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

; Language
!insertmacro MUI_LANGUAGE "English"

; ── Version Info ─────────────────────────────────────────────────────────────
VIProductVersion "${APP_VERSION}.0"
VIAddVersionKey "ProductName"      "${APP_NAME}"
VIAddVersionKey "ProductVersion"   "${APP_VERSION}"
VIAddVersionKey "CompanyName"      "${APP_PUBLISHER}"
VIAddVersionKey "FileDescription"  "${APP_NAME} Installer"
VIAddVersionKey "FileVersion"      "${APP_VERSION}"
VIAddVersionKey "LegalCopyright"   "MIT Licence"

; ── Install Sections ─────────────────────────────────────────────────────────
Section "Engine (required)" SecEngine
    SectionIn RO  ; cannot be deselected

    SetOutPath "$INSTDIR"

    ; Core binary
    File "..\build\release\luna.exe"

    ; Engine assets
    SetOutPath "$INSTDIR\assets"
    File /nonfatal "..\assets\splash.png"
    File /nonfatal "..\assets\icon.png"
    File /nonfatal "..\assets\icon.ico"

    ; Example games
    SetOutPath "$INSTDIR\examples\hello_world"
    File "..\examples\hello_world\main.lua"
    SetOutPath "$INSTDIR\examples\physics_demo"
    File "..\examples\physics_demo\main.lua"
    SetOutPath "$INSTDIR\examples\sprites"
    File "..\examples\sprites\main.lua"

    ; Docs
    SetOutPath "$INSTDIR"
    File "..\README.md"
    File "..\LICENSE"

    ; Lunasome standard libraries — install each module subdirectory
    SetOutPath "$INSTDIR\library"
    File /nonfatal "..\library\README.md"
    SetOutPath "$INSTDIR\library\battle"       ; File /r recurses into subdirs when given a dir path
    File "..\library\battle\*.lua"
    SetOutPath "$INSTDIR\library\cardgame"
    File "..\library\cardgame\*.lua"
    SetOutPath "$INSTDIR\library\combat"
    File "..\library\combat\*.lua"
    SetOutPath "$INSTDIR\library\crafting"
    File "..\library\crafting\*.lua"
    SetOutPath "$INSTDIR\library\dialog"
    File "..\library\dialog\*.lua"
    SetOutPath "$INSTDIR\library\doll"
    File "..\library\doll\*.lua"
    SetOutPath "$INSTDIR\library\economy"
    File "..\library\economy\*.lua"
    SetOutPath "$INSTDIR\library\inventory"
    File "..\library\inventory\*.lua"
    SetOutPath "$INSTDIR\library\item"
    File "..\library\item\*.lua"
    SetOutPath "$INSTDIR\library\province_map"
    File "..\library\province_map\*.lua"
    SetOutPath "$INSTDIR\library\quest"
    File "..\library\quest\*.lua"
    SetOutPath "$INSTDIR\library\stats"
    File "..\library\stats\*.lua"

    ; API docs (Markdown reference + LuaCATS stubs for IDE autocompletion)
    SetOutPath "$INSTDIR\docs"
    File /nonfatal "..\docs\API\lua-api.md"
    File /nonfatal "..\docs\API\luna.lua"
    WriteRegStr   HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "DisplayName"          "${APP_NAME} ${APP_VERSION}"
    WriteRegStr   HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "DisplayVersion"       "${APP_VERSION}"
    WriteRegStr   HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "Publisher"            "${APP_PUBLISHER}"
    WriteRegStr   HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "URLInfoAbout"         "${APP_URL}"
    WriteRegStr   HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "InstallLocation"      "$INSTDIR"
    WriteRegStr   HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "UninstallString"      "$INSTDIR\uninstall.exe"
    WriteRegStr   HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "DisplayIcon"          "$INSTDIR\${APP_EXE}"
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "NoModify"             1
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "NoRepair"             1

    ; Register Install_Dir
    WriteRegStr   HKLM "Software\${APP_NAME}" "Install_Dir" "$INSTDIR"

    ; Write uninstaller
    WriteUninstaller "$INSTDIR\uninstall.exe"

    ; Add to PATH (current user)
    EnVar::SetHKCU
    EnVar::AddValue "PATH" "$INSTDIR"

SectionEnd

; ── .lunar File Association ──────────────────────────────────────────────────
; Registers the .lunar extension so double-clicking a game package opens it
; with the Luna2D engine automatically.
Section ".lunar File Association" SecFileAssoc
    ; Map .lunar extension → ProgID
    WriteRegStr HKCR ".lunar"                         ""           "Luna2DGame"
    WriteRegStr HKCR ".lunar"                         "Content Type" "application/x-lunar-game"

    ; ProgID display name and icon
    WriteRegStr HKCR "Luna2DGame"                    ""            "Luna2D Game"
    WriteRegStr HKCR "Luna2DGame\DefaultIcon"        ""            "$INSTDIR\${APP_EXE},0"

    ; Open verb: pass the .lunar file as the first argument to luna.exe
    WriteRegStr HKCR "Luna2DGame\shell\open"         ""            "Open with Luna2D"
    WriteRegStr HKCR "Luna2DGame\shell\open\command" ""            '"$INSTDIR\${APP_EXE}" "%1"'

    ; Notify Windows that file associations have changed
    System::Call 'Shell32::SHChangeNotify(i 0x8000000, i 0, i 0, i 0)'
SectionEnd

Section "Start Menu Shortcuts" SecStartMenu
    CreateDirectory "$SMPROGRAMS\${APP_NAME}"
    CreateShortcut  "$SMPROGRAMS\${APP_NAME}\${APP_NAME}.lnk"             "$INSTDIR\${APP_EXE}"  ""                                      "$INSTDIR\${APP_EXE}"
    CreateShortcut  "$SMPROGRAMS\${APP_NAME}\API Reference.lnk"           "$INSTDIR\docs\lua-api.md"
    CreateShortcut  "$SMPROGRAMS\${APP_NAME}\Uninstall ${APP_NAME}.lnk"   "$INSTDIR\uninstall.exe"
SectionEnd

Section "Desktop Shortcut" SecDesktop
    CreateShortcut "$DESKTOP\${APP_NAME}.lnk" "$INSTDIR\${APP_EXE}" "" "$INSTDIR\${APP_EXE}"
SectionEnd

; ── Uninstall Section ─────────────────────────────────────────────────────────
Section "Uninstall"
    ; Remove from PATH
    EnVar::SetHKCU
    EnVar::DeleteValue "PATH" "$INSTDIR"

    ; Remove files
    Delete "$INSTDIR\luna.exe"
    Delete "$INSTDIR\uninstall.exe"
    Delete "$INSTDIR\README.md"
    Delete "$INSTDIR\LICENSE"

    RMDir /r "$INSTDIR\assets"
    RMDir /r "$INSTDIR\examples"
    RMDir /r "$INSTDIR\library"
    RMDir /r "$INSTDIR\docs"
    RMDir    "$INSTDIR"

    ; Remove shortcuts
    Delete "$SMPROGRAMS\${APP_NAME}\*.*"
    RMDir  "$SMPROGRAMS\${APP_NAME}"
    Delete "$DESKTOP\${APP_NAME}.lnk"

    ; Remove .lunar file association
    DeleteRegKey HKCR ".lunar"
    DeleteRegKey HKCR "Luna2DGame"

    ; Remove registry keys
    DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}"
    DeleteRegKey HKLM "Software\${APP_NAME}"

    ; Notify Windows that file associations have changed
    System::Call 'Shell32::SHChangeNotify(i 0x8000000, i 0, i 0, i 0)'
SectionEnd
