; CopyIfMissing.nsh — Recursively copy SRC → DST, but only files that do NOT already exist in DST.
; Usage:
;   !include "CopyIfMissing.nsh"
;   !insertmacro CopyIfMissing "$INSTDIR\__defaults" "$ConfigDir"

!ifndef CFIM_INCLUDED
!define CFIM_INCLUDED

!include "LogicLib.nsh"

!macro CopyIfMissing SRC DST
  Push "${SRC}"               ; arg1
  Push "${DST}"               ; arg2
  Call CFIM__CopyIfMissing
!macroend

Var CFIM_src
Var CFIM_dst
Var CFIM_h
Var CFIM_name
Var CFIM_srcPath
Var CFIM_dstPath

Function CFIM__CopyIfMissing
  ; args: top→ DST, SRC
  Pop $CFIM_dst
  Pop $CFIM_src

  DetailPrint "==Entering CFIM__CopyIfMissing('$CFIM_src', '$CFIM_dst')"

  GetFullPathName $CFIM_src $CFIM_src
  GetFullPathName $CFIM_dst $CFIM_dst

  ClearErrors
  CreateDirectory "$CFIM_dst"
  ${If} ${Errors}
    DetailPrint "⚠ Could not create '$CFIM_dst'"
  ${EndIf}

  ; kick off recursion
  Push "$CFIM_src"
  Push "$CFIM_dst"
  Call CFIM__Recurse

  DetailPrint "==Exiting CFIM__CopyIfMissing()"
FunctionEnd

Function CFIM__Recurse
  ; args for THIS level
  Pop $CFIM_dst
  Pop $CFIM_src

  FindFirst $CFIM_h $CFIM_name "$CFIM_src\*.*"
  ${DoWhile} $CFIM_name != ""
    ${If} $CFIM_name == "."
    ${OrIf} $CFIM_name == ".."
      ; skip
    ${Else}
      StrCpy $CFIM_srcPath "$CFIM_src\$CFIM_name"
      StrCpy $CFIM_dstPath "$CFIM_dst\$CFIM_name"

      ${If} ${FileExists} "$CFIM_srcPath\*.*"
        ; ----- Directory -----
        ClearErrors
        CreateDirectory "$CFIM_dstPath"
        ${If} ${Errors}
          DetailPrint "⚠ Could not create dir '$CFIM_dstPath'"
        ${EndIf}

        DetailPrint "↳ Enter: '$CFIM_srcPath'"

        ; Save THIS level’s state (we’ll need it after child returns)
        Push $CFIM_h
        Push $CFIM_name
        Push $CFIM_src
        Push $CFIM_dst

        ; Recurse: child pops into same vars
        Push "$CFIM_srcPath"   ; child SRC
        Push "$CFIM_dstPath"   ; child DST
        Call CFIM__Recurse

        ; Restore THIS level’s state (order reversed)
        Pop $CFIM_dst
        Pop $CFIM_src
        Pop $CFIM_name
        Pop $CFIM_h
      ${Else}
        ; ----- File -----
        ${If} ${FileExists} "$CFIM_dstPath"
          DetailPrint "• Skip (exists): $CFIM_dstPath"
        ${Else}
          ClearErrors
          CopyFiles /SILENT "$CFIM_srcPath" "$CFIM_dst"
          ${If} ${Errors}
            DetailPrint "⚠ Copy failed: $CFIM_srcPath → $CFIM_dst"
          ${Else}
            DetailPrint "✓ Copied: $CFIM_srcPath → $CFIM_dstPath"
          ${EndIf}
        ${EndIf}
      ${EndIf}
    ${EndIf}
    FindNext $CFIM_h $CFIM_name
  ${Loop}
  FindClose $CFIM_h
FunctionEnd

!endif
