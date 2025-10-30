; --- icons for the wizard windows (MUI-aware) (this is the way to set the icons when we use MUI ) ---
!define APP_ICON_FILE_NAME    "onyx_user_server_icon.ico"
!define APP_ICON_SOURCE_PATH  "..\installers\assets\${APP_ICON_FILE_NAME}"
!define APP_ICON_TARGET_PATH  "$INSTDIR\${APP_ICON_FILE_NAME}"
!define MUI_ICON       "${APP_ICON_SOURCE_PATH}"
!define MUI_UNICON     "${APP_ICON_SOURCE_PATH}"

!include "MUI2.nsh"

; --- MultiUser: minimal setup ---
!define MULTIUSER_EXECUTIONLEVEL Highest        ; allow elevation if possible
!define MULTIUSER_MUI                           ; integrate with MUI pages
!define MULTIUSER_INSTALLMODE_COMMANDLINE       ; (optional) /AllUsers or /CurrentUser for silent mode
!define MULTIUSER_USE_PROGRAMFILES64            ; for all-users default to Program Files (64-bit)
!include "MultiUser.nsh"
!include "Include\CopyIfMissing.nsh"
; !include "Include\ShortcutHelper.nsh"

; The APP_VERSION number should be passed as a command-line argument for compilation
; E.g. "makensis /DVERSION=0.9.3 installers\user_server.nsi"
!ifndef APP_VERSION 
  !define APP_VERSION "0.0.0"
!endif

!ifndef APP_DIST_DIR
  !define APP_DIST_DIR "..\dist"
!endif

!define COMPANY_NAME        "Onyx"
!define APP_NAME            "User Server"
!define APP_NAME_NO_SPACES  "UserServer"
!define PARENT_FOLDER_NAME  "User Server"
!define CONFIG_FOLDER_NAME  "UserServerConfig"
!define PRODUCT_NAME        "${COMPANY_NAME} ${APP_NAME}"
!define PRODUCT_NAME_WITH_VERSION        "${PRODUCT_NAME} ${APP_VERSION}"      ; shows in UI/Apps list
!define INST_KEY_PATH       "Software\${PRODUCT_NAME_WITH_VERSION}"
!define UNINST_KEY_PATH     "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME_WITH_VERSION}"

Name "${PRODUCT_NAME_WITH_VERSION}"
OutFile "${APP_NAME}-Setup-${APP_VERSION}.exe"
BrandingText "Installing ${PRODUCT_NAME_WITH_VERSION}"
!include "Include\UninstallCustomPage.nsh"

; Constants for setting unique AppUserModelID for shortcuts of each app version
; !define APP_AUMID_BASE "${COMPANY_NAME}.${APP_NAME_NO_SPACES}"
; !define APP_AUMID "${APP_AUMID_BASE}.${APP_VERSION}"

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
; Uninstaller pages
!insertmacro MUI_UNPAGE_CONFIRM
UninstPage custom un.PageRemoveConfig_Create un.PageRemoveConfig_Leave
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "English"

; --- required init hooks for MultiUser ---
Function .onInit
  !insertmacro MULTIUSER_INIT
  SetRegView 64
  ; MessageBox MB_OK "EXEDIR = $EXEDIR"
FunctionEnd

Function un.onInit
  !insertmacro MULTIUSER_UNINIT
  SetRegView 64

  ; Default if file missing
  StrCpy $0 "CurrentUser"

  ; $EXEDIR is the folder containing Uninstall.exe (i.e., $INSTDIR)
  FileOpen $1 "$INSTDIR\install_mode.txt" r
  IfErrors mode_file_error
    FileRead $1 $0
    FileClose $1
    Goto set_context
    
  mode_file_error:
    ; If file doesn't exist, default to CurrentUser as safest option
    ; (We can't reliably detect AllUsers vs CurrentUser from path alone)
    StrCpy $0 "CurrentUser"
    ; Log to file since DetailPrint won't show in un.onInit
    FileOpen $9 "$TEMP\uninstall_debug.txt" w
    FileWrite $9 "Warning: install_mode.txt not found, defaulting to CurrentUser mode$\r$\n"
    FileClose $9
  
  set_context:
  ; Log the detected mode to file for debugging
  FileOpen $9 "$TEMP\uninstall_debug.txt" a
  FileWrite $9 "Detected install mode: '$0'$\r$\n"
  
  ; Set shell context based on install mode
  StrCmp $0 "AllUsers" set_allusers set_currentuser
  
  set_allusers:
    SetShellVarContext all
    FileWrite $9 "Set shell context to: all$\r$\n"
    FileWrite $9 "SMPROGRAMS will be: $SMPROGRAMS$\r$\n"
    Goto context_done
    
  set_currentuser:
    SetShellVarContext current  
    FileWrite $9 "Set shell context to: current$\r$\n"
    FileWrite $9 "SMPROGRAMS will be: $SMPROGRAMS$\r$\n"
    
  context_done:
    FileWrite $9 "un.onInit completed$\r$\n$\r$\n"
    FileClose $9
    
  ; Optional: Show debug info immediately (comment out for production)
  ; MessageBox MB_OK "Uninstall Debug:$\nMode: $0$\nSMPROGRAMS: $SMPROGRAMS$\n$\nCheck $TEMP\uninstall_debug.txt for details"
  ; MessageBox MB_OK "EXEDIR = $EXEDIR"
FunctionEnd

Var DirSuffix

Function DirPage_Pre
  ; Decide mode (MultiUser sets $MultiUser.InstallMode to AllUsers/CurrentUser)
  ; This runs even when the scope page is skipped (non-admin) because MULTIUSER_INIT already ran in .onInit
  StrCpy $DirSuffix "\${PARENT_FOLDER_NAME}\${APP_NAME}_${APP_VERSION}"

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

!macro CreateShortcuts
  ; Start Menu Shortcuts
  DetailPrint "==Creating shortcut $SMPROGRAMS\${PRODUCT_NAME}"
  ; A shortcut to the desktop parent shortcuts directory. Will not be removed by the uninstaller.
  CreateShortCut "$SMPROGRAMS\${PRODUCT_NAME}.lnk" "$DESKTOP\${PARENT_FOLDER_NAME}" "" "${APP_ICON_TARGET_PATH}"
  ; CreateDirectory "$SMPROGRAMS\${PRODUCT_NAME_WITH_VERSION}"
  ; CreateShortCut "$SMPROGRAMS\${PRODUCT_NAME_WITH_VERSION}\${APP_NAME}.lnk" "$INSTDIR\UserServer.txt" "" "${APP_ICON_TARGET_PATH}"
  ; CreateShortCut "$SMPROGRAMS\${PRODUCT_NAME_WITH_VERSION}\${APP_NAME} Config.lnk" "$ConfigDir"

  ; Desktop Shortcuts
  DetailPrint "==Creating shortcuts under $DESKTOP\${PARENT_FOLDER_NAME}"
  CreateDirectory "$DESKTOP\${PARENT_FOLDER_NAME}" ; Base directory - will not be rmeoved by uninstaller
  CreateDirectory "$DESKTOP\${PARENT_FOLDER_NAME}\${PRODUCT_NAME_WITH_VERSION}"
  CreateShortCut  "$DESKTOP\${PARENT_FOLDER_NAME}\${PRODUCT_NAME_WITH_VERSION}\${APP_NAME}.lnk" "$INSTDIR\UserServer.txt" "" "${APP_ICON_TARGET_PATH}"
  CreateShortCut  "$DESKTOP\${PARENT_FOLDER_NAME}\${PRODUCT_NAME_WITH_VERSION}\${APP_NAME} Config.lnk" "$ConfigDir"
!macroend

!macro RemoveShortcuts
  DetailPrint "Removing shortcuts under $SMPROGRAMS\${PRODUCT_NAME_WITH_VERSION}"
  Delete "$SMPROGRAMS\${PRODUCT_NAME_WITH_VERSION}\${APP_NAME}.lnk"
  Delete "$SMPROGRAMS\${PRODUCT_NAME_WITH_VERSION}\${APP_NAME} Config.lnk"
  RMDir  "$SMPROGRAMS\${PRODUCT_NAME_WITH_VERSION}"
  ; OPTIONAL (if we created the desktop folder)
  DetailPrint "Removing shortcuts under $DESKTOP\${PARENT_FOLDER_NAME}"
  Delete "$DESKTOP\${PARENT_FOLDER_NAME}\${PRODUCT_NAME_WITH_VERSION}\${APP_NAME}.lnk"
  Delete "$DESKTOP\${PARENT_FOLDER_NAME}\${PRODUCT_NAME_WITH_VERSION}\${APP_NAME} Config.lnk"
  RMDir  "$DESKTOP\${PARENT_FOLDER_NAME}\${PRODUCT_NAME_WITH_VERSION}"
!macroend

Var ConfigDir

!macro LocateConfigDir
  ; compute ConfigDir: sibling of $INSTDIR
  StrCpy $ConfigDir "$INSTDIR\.."
  GetFullPathName $ConfigDir $ConfigDir
  StrCpy $ConfigDir "$ConfigDir\${CONFIG_FOLDER_NAME}"
  DetailPrint "Local Config Directory is '$ConfigDir'"
!macroend
  
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
  DetailPrint "==Install section started - INSTDIR = $INSTDIR"

  ; --- 4.1 Copy app payload ---
  SetOverwrite ifnewer                 ; safer for updates
  DetailPrint "==Copying code files from ${APP_DIST_DIR}"
  File /r "${APP_DIST_DIR}\*.*"  ; demo payload
  File "${APP_ICON_SOURCE_PATH}" ; app icon

  ; Save install mode for uninstaller: "AllUsers" or "CurrentUser"
  FileOpen $1 "$INSTDIR\install_mode.txt" w
  FileWrite $1 "$MultiUser.InstallMode"
  FileClose $1

  ; Start Configuration Dir

  ; stage defaults: embed at compile-time, extract at install-time
  DetailPrint "==Copying config files to temporary directory '$INSTDIR\__defaults'"
  SetOutPath "$INSTDIR\__defaults"
  File /r "..\defaults\*.*"

  !insertmacro LocateConfigDir
  CreateDirectory "$ConfigDir"

  ; copy only missing files (recursively) from staged defaults → ConfigDir
  DetailPrint "==Copying config files (only files that are missing)"
  !insertmacro CopyIfMissing "$INSTDIR\__defaults" "$ConfigDir"

  ; Remove the staged defaults to keep install dir clean
  DetailPrint "==Removeing the temporary directory '$INSTDIR\__defaults'"
  RMDir /r "$INSTDIR\__defaults"

  ; End Configuration Dir

  ; Shortcuts (MultiUser sets the right context automatically)
  !insertmacro CreateShortcuts

  DetailPrint "==Updating Registry"
  ; Registry: use SHCTX so it goes to HKLM (all-users) or HKCU (just-me)
  WriteRegStr SHCTX "${INST_KEY_PATH}" "InstallDir" "$INSTDIR"
  ; Save the mode for the uninstaller: "AllUsers" or "CurrentUser"
  WriteRegStr SHCTX "${INST_KEY_PATH}" "InstallMode" "$MultiUser.InstallMode"


  WriteRegStr       SHCTX "${UNINST_KEY_PATH}" "DisplayName"      "${PRODUCT_NAME_WITH_VERSION}"
  WriteRegStr       SHCTX "${UNINST_KEY_PATH}" "Publisher"        "${COMPANY_NAME}"
  WriteRegStr       SHCTX "${UNINST_KEY_PATH}" "DisplayVersion"   "${APP_VERSION}"
  WriteRegStr       SHCTX "${UNINST_KEY_PATH}" "InstallLocation"  "$INSTDIR"
  WriteRegStr       SHCTX "${UNINST_KEY_PATH}" "DisplayIcon"      "${APP_ICON_TARGET_PATH}"
  WriteRegStr       SHCTX "${UNINST_KEY_PATH}" "UninstallString"  "$\"$INSTDIR\Uninstall.exe$\""

  ; Uninstaller
  DetailPrint "==Creating uninstaller"
  WriteUninstaller "$INSTDIR\Uninstall.exe"

  MessageBox MB_YESNO "Open the configuration folder now?" IDNO +2
    ExecShell "open" "$ConfigDir"
SectionEnd

; -----------------------------------------
; Uninstall
; -----------------------------------------
Section "Uninstall"
  DetailPrint "=== Uninstall Section Started ==="
  DetailPrint "SMPROGRAMS = $SMPROGRAMS"
  DetailPrint "INSTDIR = $INSTDIR"
  
  ; Remove Start Menu shortcuts
  !insertmacro RemoveShortcuts

  ; Remove installed code files
  DetailPrint "==Removing files from: $INSTDIR"
  RMDir /r "$INSTDIR"

  ; Optionally remove config files
  !insertmacro LocateConfigDir
  ; If user checked the corresponding checkbox
  ${If} $UnRemoveCfg == ${BST_CHECKED}
    DetailPrint "==Removing config folder: $ConfigDir"
    RMDir /r "$ConfigDir"
  ${Else}
    DetailPrint "==Keeping config folder: $ConfigDir"
  ${EndIf}

  ; Remove registry keys using SHCTX (automatically uses correct hive)
  DetailPrint "==Removing registry keys"
  DeleteRegKey SHCTX "${INST_KEY_PATH}"
  DeleteRegKey SHCTX "${UNINST_KEY_PATH}"
  
  DetailPrint "=== Uninstall Section Completed ==="
SectionEnd
