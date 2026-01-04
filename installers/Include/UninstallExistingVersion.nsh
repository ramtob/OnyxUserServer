!ifndef UEV_INCLUDED
!define UEV_INCLUDED

!include "LogicLib.nsh"

Var PrevRoot   ; "HKLM" or "HKCU"
Var PrevDir
Var PrevVer

;==============================================================
; Function: FindExistingInstall

Function FindExistingInstall
  StrCpy $PrevRoot ""
  StrCpy $PrevDir ""
  StrCpy $PrevVer ""

  ; Search for existing install in registry, in both HKLM and HKCU.
  ; Because per-user installs write to HKCU, and per-machine installs write to HKLM,
  ; we have to check both locations.
  ; Try HKLM first
  ClearErrors
  ReadRegStr $PrevDir HKLM "${UNINST_KEY_PATH}" "InstallLocation"
  ${IfNot} ${Errors}
    ReadRegStr $PrevVer HKLM "${UNINST_KEY_PATH}" "DisplayVersion"
    StrCpy $PrevRoot "HKLM"
    Return
  ${EndIf}

  ; Then HKCU
  ClearErrors
  ReadRegStr $PrevDir HKCU "${UNINST_KEY_PATH}" "InstallLocation"
  ${IfNot} ${Errors}
    ReadRegStr $PrevVer HKCU "${UNINST_KEY_PATH}" "DisplayVersion"
    StrCpy $PrevRoot "HKCU"
    Return
  ${EndIf}
FunctionEnd

;==============================================================
; Function: UninstallPreviousInstall

Function UninstallPreviousInstall
  StrCpy $0 "$PrevDir\${UNINST_EXE_NAME}"

  ${IfNot} ${FileExists} "$0"
    MessageBox MB_ICONSTOP "Existing ${PRODUCT_BASE} found at:$\r$\n$PrevDir$\r$\nBut $0 was not found. Cannot auto-uninstall."
    Abort
  ${EndIf}

  ; Silent uninstall. _?= keeps the uninstaller anchored so it can delete itself.
  ExecWait '"$0" /S _?=$PrevDir' $1

  ${If} $1 != 0
    MessageBox MB_ICONSTOP "Uninstall failed (exit code $1). Setup will abort."
    Abort
  ${EndIf}
FunctionEnd

;==============================================================

; Add this macro to .onInit to find and uninstall existing version

!macro FIND_EXISTING_INSTALL
  Call FindExistingInstall
  ${If} $PrevRoot != ""
    StrCpy $0 "${PRODUCT_NAME} is already installed."
    ${If} $PrevVer != ""
      StrCpy $0 "$0$\r$\nInstalled version: $PrevVer"
    ${EndIf}
    StrCpy $0 "$0$\r$\nInstall location: $PrevDir"
    StrCpy $0 "$0$\r$\n$\r$\nDo you want to uninstall it and install version ${APP_VERSION}?"

    MessageBox MB_ICONQUESTION|MB_YESNO "$0" IDYES do_uninstall
      Abort

    do_uninstall:
    Call UninstallPreviousInstall
  ${EndIf}
!macroend

;=============================================================

!endif
