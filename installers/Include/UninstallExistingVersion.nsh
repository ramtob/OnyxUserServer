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

!endif
