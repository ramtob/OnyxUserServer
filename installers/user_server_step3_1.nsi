!include "MUI2.nsh"

; --- MultiUser: minimal setup ---
!define MULTIUSER_EXECUTIONLEVEL Highest        ; allow elevation if possible
!define MULTIUSER_MUI                           ; integrate with MUI pages
!define MULTIUSER_INSTALLMODE_COMMANDLINE       ; (optional) /AllUsers or /CurrentUser for silent mode
!define MULTIUSER_USE_PROGRAMFILES64            ; for all-users default to Program Files (64-bit)
!include "MultiUser.nsh"

Name "Onyx User Server"
OutFile "UserServer-Setup-step3_1.exe"

; Enable install logging
!define MUI_INSTFILESPAGE_FINISHHEADER_TEXT "Installation Complete"
!define MUI_INSTFILESPAGE_ABORTHEADER_TEXT "Installation Aborted"
InstallDir $INSTDIR

; We'll let the user pick the folder on the Directory page as usual.
; (Tip: when choosing "All users", pick Program Files; when "Just me", pick a user-writable folder.)

; --- PAGES ---
!insertmacro MULTIUSER_PAGE_INSTALLMODE         ; << adds "All users / Just me" page
; ---- Directory page hooks ----
!define MUI_PAGE_CUSTOMFUNCTION_PRE  DirPage_Pre
!define MUI_PAGE_CUSTOMFUNCTION_LEAVE DirPage_Leave
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "English"

; --- required init hooks for MultiUser ---
Function .onInit
  !insertmacro MULTIUSER_INIT
  SetRegView 64
FunctionEnd

Function un.onInit
  !insertmacro MULTIUSER_UNINIT
  SetRegView 64

  ; Default if file missing
  StrCpy $0 "CurrentUser"

  ; $EXEDIR is the folder containing Uninstall.exe (i.e., $INSTDIR)
  FileOpen $1 "$EXEDIR\install_mode.txt" r
  IfErrors +3
    FileRead $1 $0
    FileClose $1

  ; Normalize and set context
  StrCmp $0 "AllUsers" 0 +2
    SetShellVarContext all
    Goto +2
  SetShellVarContext current
FunctionEnd

Var DirSuffix

Function DirPage_Pre
  ; Decide mode (MultiUser sets $MultiUser.InstallMode to AllUsers/CurrentUser)
  ; This runs even when the scope page is skipped (non-admin) because MULTIUSER_INIT already ran in .onInit
  StrCpy $DirSuffix "\Onyx\User Server"

  StrCmp $MultiUser.InstallMode "AllUsers" 0 +3
    StrCpy $INSTDIR "$PROGRAMFILES64$DirSuffix"
    Return

  ; Current user
  StrCpy $INSTDIR "$LOCALAPPDATA$DirSuffix"
FunctionEnd

Function DirPage_Leave
  ; Just log what the user selected - don't modify $INSTDIR here
  ; as NSIS might override our changes
  
  FileOpen $9 "$TEMP\nsis_debug.txt" a
  FileWrite $9 "=== DirPage_Leave called ===$\r$\n"
  FileWrite $9 "User selected INSTDIR: $INSTDIR$\r$\n"
  FileWrite $9 "Will append suffix during install section$\r$\n"
  FileWrite $9 "=== DirPage_Leave finished ===$\r$\n$\r$\n"
  FileClose $9
FunctionEnd

; -----------------------------------------
; Install Section
; -----------------------------------------
Section "Install"
  ; Ensure the installation directory ends with our suffix
  StrCpy $0 $DirSuffix  ; "\Onyx\User Server"
  StrLen $1 $0          ; Length of suffix
  StrCpy $2 "$INSTDIR" $1 -$1  ; Last N characters of $INSTDIR
  
  DetailPrint "Checking INSTDIR suffix: '$2' vs '$0'"
  
  StrCmp $2 $0 suffix_ok
    ; Suffix not present, append it
    StrCpy $INSTDIR "$INSTDIR$0"
    DetailPrint "Appended suffix - New INSTDIR: $INSTDIR"
  suffix_ok:
  
  SetOutPath "$INSTDIR"
  
  ; Debug output (will show during install files page)
  DetailPrint "Install section started - INSTDIR = $INSTDIR"

  ; demo payload
  FileOpen $0 "$INSTDIR\readme.txt" w
  FileWrite $0 "Onyx User Server installed here."
  FileClose $0

  ; Save install mode for uninstaller: "AllUsers" or "CurrentUser"
  FileOpen $1 "$INSTDIR\install_mode.txt" w
  FileWrite $1 "$MultiUser.InstallMode"
  FileClose $1

  ; Shortcuts (MultiUser sets the right context automatically)
  DetailPrint "SMPROGRAMS = $SMPROGRAMS"
  CreateDirectory "$SMPROGRAMS\Onyx"
  CreateShortCut "$SMPROGRAMS\Onyx\User Server.lnk" "$INSTDIR\readme.txt"
  CreateShortCut "$SMPROGRAMS\Onyx\User Server Config.lnk" "$INSTDIR\UserServerConfig"

  ; Registry: use SHCTX so it goes to HKLM (all-users) or HKCU (just-me)
  WriteRegStr SHCTX "Software\Onyx\User Server" "InstallDir" "$INSTDIR"
  ; Save the mode for the uninstaller: "AllUsers" or "CurrentUser"
  WriteRegStr SHCTX "Software\Onyx\User Server" "InstallMode" "$MultiUser.InstallMode"


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
  DetailPrint "SMPROGRAMS = $SMPROGRAMS"
  Delete "$SMPROGRAMS\Onyx\User Server.lnk"
  Delete "$SMPROGRAMS\Onyx\User Server Config.lnk"
  RMDir  "$SMPROGRAMS\Onyx"

  Delete "$INSTDIR\readme.txt"
  Delete "$INSTDIR\Uninstall.exe"
  Delete "$INSTDIR\install_mode.txt"
  RMDir  "$INSTDIR"

  ; Remove registry (HKLM or HKCU automatically based on how it was installed)
  DeleteRegKey SHCTX "Software\Onyx\User Server"
  DeleteRegKey SHCTX "Software\Microsoft\Windows\CurrentVersion\Uninstall\Onyx User Server"
  ; Remove uninstall keys in both scopes (in case context was changed manually)
  ; DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\Onyx User Server"
  ; DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Onyx User Server"
  ; Remove app keys in both scopes
  ; DeleteRegKey HKCU "Software\Onyx\User Server"
  ; DeleteRegKey HKLM "Software\Onyx\User Server"

SectionEnd
