!include "MUI2.nsh"

!macro CreateShortcuts dir
 DetailPrint "In macro CreateShortcuts(${dir})"
 CreateDirectory "${dir}\Onyx"
 CreateShortCut "${dir}\Onyx\User Server.lnk" "$INSTDIR\UserServer.exe"
 CreateShortCut "${dir}\Onyx\User Server Config.lnk" "$INSTDIR\UserServerConfig" 
 CreateShortCut "${dir}\Onyx\User Server Maintenance.lnk" "$INSTDIR\Uninstall.exe" 
!macroend

!macro RemoveShortcuts dir
 DetailPrint "In macro RemoveShortcuts(${dir})"
 Delete "${dir}\Onyx\User Server.lnk"
 Delete "${dir}\Onyx\User Server Config.lnk"
 Delete "${dir}\Onyx\User Server Maintenance.lnk"
 RMDir "${dir}\Onyx" 
!macroend

Name "Onyx User Server"
OutFile "UserServer-Setup-step3.exe"
InstallDir "$PROFILE\Onyx\User Server"
RequestExecutionLevel user     ; per-user install (no UAC)
InstallDirRegKey HKCU "Software\Onyx\User Server" "InstallDir"

!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "English"

Section "Install"
  SetOutPath "$INSTDIR"
  ; demo payload
  FileOpen $0 "$INSTDIR\readme.txt" w
  FileWrite $0 "Onyx User Server installed here."
  FileClose $0

  ; Shortcuts (Start Menu + Desktop)
  !insertmacro CreateShortcuts "$SMPROGRAMS"
  !insertmacro CreateShortcuts "$DESKTOP"

  ; Remember install dir for updates
  WriteRegStr HKCU "Software\Onyx\User Server" "InstallDir" "$INSTDIR"

  ; Per-user Apps & Features entry
  WriteRegStr   HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\Onyx User Server" "DisplayName"    "Onyx User Server"
  WriteRegStr   HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\Onyx User Server" "Publisher"       "Onyx"
  WriteRegStr   HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\Onyx User Server" "DisplayVersion"  "0.0.1"
  WriteRegStr   HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\Onyx User Server" "InstallLocation" "$INSTDIR"
  WriteRegExpandStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\Onyx User Server" "UninstallString" "$\"$INSTDIR\Uninstall.exe$\""

  ; Generate Uninstall.exe
  WriteUninstaller "$INSTDIR\Uninstall.exe"
SectionEnd

Section "Uninstall"
  ; Remove shortcuts
  !insertmacro RemoveShortcuts "$SMPROGRAMS"
  !insertmacro RemoveShortcuts "$DESKTOP"

  ; Remove files (keep this minimal for demo)
  Delete "$INSTDIR\readme.txt"
  Delete "$INSTDIR\Uninstall.exe"
  RMDir  "$INSTDIR"

  ; Remove registry
  DeleteRegKey HKCU "Software\Onyx\User Server"
  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\Onyx User Server"
SectionEnd
