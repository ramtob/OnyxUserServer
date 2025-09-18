!include "MUI2.nsh"

; --- MultiUser: minimal setup ---
!define MULTIUSER_EXECUTIONLEVEL Highest        ; allow elevation if possible
!define MULTIUSER_MUI                           ; integrate with MUI pages
!define MULTIUSER_INSTALLMODE_COMMANDLINE       ; (optional) /AllUsers or /CurrentUser for silent mode
!define MULTIUSER_USE_PROGRAMFILES64            ; for all-users default to Program Files (64-bit)
!include "MultiUser.nsh"

Name "Onyx User Server"
OutFile "UserServer-Setup-step3_1.exe"

; We'll let the user pick the folder on the Directory page as usual.
; (Tip: when choosing "All users", pick Program Files; when "Just me", pick a user-writable folder.)

; --- PAGES ---
!insertmacro MULTIUSER_PAGE_INSTALLMODE         ; << adds "All users / Just me" page
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "English"

; --- required init hooks for MultiUser ---
Function .onInit
  !insertmacro MULTIUSER_INIT
FunctionEnd

Function un.onInit
  !insertmacro MULTIUSER_UNINIT
FunctionEnd

; -----------------------------------------
; Install Section
; -----------------------------------------
Section "Install"
  SetOutPath "$INSTDIR"

  ; demo payload
  FileOpen $0 "$INSTDIR\readme.txt" w
  FileWrite $0 "Onyx User Server installed here."
  FileClose $0

  ; Shortcuts (MultiUser sets the right context automatically)
  CreateDirectory "$SMPROGRAMS\Onyx"
  CreateShortCut "$SMPROGRAMS\Onyx\User Server.lnk" "$INSTDIR\readme.txt"
  CreateShortCut "$SMPROGRAMS\Onyx\User Server Config.lnk" "$INSTDIR\UserServerConfig"

  ; Registry: use SHCTX so it goes to HKLM (all-users) or HKCU (just-me)
  WriteRegStr SHCTX "Software\Onyx\User Server" "InstallDir" "$INSTDIR"

  WriteRegStr        SHCTX "Software\Microsoft\Windows\CurrentVersion\Uninstall\Onyx User Server" "DisplayName"     "Onyx User Server"
  WriteRegStr        SHCTX "Software\Microsoft\Windows\CurrentVersion\Uninstall\Onyx User Server" "Publisher"        "Onyx"
  WriteRegStr        SHCTX "Software\Microsoft\Windows\CurrentVersion\Uninstall\Onyx User Server" "DisplayVersion"   "0.0.1"
  WriteRegStr        SHCTX "Software\Microsoft\Windows\CurrentVersion\Uninstall\Onyx User Server" "InstallLocation"  "$INSTDIR"
  WriteRegExpandStr  SHCTX "Software\Microsoft\Windows\CurrentVersion\Uninstall\Onyx User Server" "UninstallString"  "$\"$INSTDIR\Uninstall.exe$\""

  ; Uninstaller
  WriteUninstaller "$INSTDIR\Uninstall.exe"
SectionEnd

; -----------------------------------------
; Uninstall
; -----------------------------------------
Section "Uninstall"
  Delete "$SMPROGRAMS\Onyx\User Server.lnk"
  Delete "$SMPROGRAMS\Onyx\User Server Config.lnk"
  RMDir  "$SMPROGRAMS\Onyx"

  Delete "$INSTDIR\readme.txt"
  Delete "$INSTDIR\Uninstall.exe"
  RMDir  "$INSTDIR"

  ; Remove registry (HKLM or HKCU automatically based on how it was installed)
  DeleteRegKey SHCTX "Software\Onyx\User Server"
  DeleteRegKey SHCTX "Software\Microsoft\Windows\CurrentVersion\Uninstall\Onyx User Server"
SectionEnd
