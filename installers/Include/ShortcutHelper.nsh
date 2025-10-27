!include "FileFunc.nsh"
!insertmacro GetParent

!macro CreateShortcutWithAppID LINK TARGET ICON ARGS APPID DESC
  ${GetParent} "${LINK}" $0
  DetailPrint "Shortcut: ensuring folder: $0"
  CreateDirectory "$0"

  ; Extract the helper script (embedded in installer) to %TEMP%
  SetOutPath "$TEMP"
  File "/oname=$TEMP\SetLnkAppID.ps1" "Include\SetLnkAppID.ps1"

  DetailPrint "→ Create/Update LNK: ${LINK}"
  DetailPrint "   Target: ${TARGET}"
  DetailPrint "   Icon  : ${ICON}"
  DetailPrint "   AppID : ${APPID}"

  nsExec::ExecToStack 'powershell -NoProfile -ExecutionPolicy Bypass -File "$TEMP\SetLnkAppID.ps1" -LinkPath "${LINK}" -Target "${TARGET}" -Icon "${ICON}" -Args "${ARGS}" -AppID "${APPID}" -Desc "${DESC}"'
  Pop $R0   ; exit code
  Pop $R1   ; output
  DetailPrint "   PS exit code: $R0"
  ${If} $R1 != ""
    DetailPrint "   PS output: $R1"
  ${EndIf}
  ${If} $R0 != 0
    DetailPrint "⚠ Failed to set AppUserModelID on: ${LINK}"
  ${Else}
    DetailPrint "✓ Shortcut ready with AppID."
  ${EndIf}
!macroend
