; CopyIfMissing.nsh  — Recursively copy SRC → DST, but only files that do NOT already exist.
; Usage in your .nsi:
;   !include "CopyIfMissing.nsh"
;   !insertmacro CopyIfMissing "$INSTDIR\__defaults" "$ConfigDir"

!ifndef CFIM_INCLUDED
!define CFIM_INCLUDED

!include "LogicLib.nsh"

; Public macro (hides the parameter stack from caller)
!macro CopyIfMissing SRC DST
  Push "${SRC}"        ; arg1
  Push "${DST}"        ; arg2
  Call CFIM__CopyIfMissing
!macroend

; ---- private vars (shared names but protected per recursion by push/pop) ----
Var CFIM_src
Var CFIM_dst
Var CFIM_h
Var CFIM_name
Var CFIM_srcPath
Var CFIM_dstPath

; Entry: normalize, ensure root, then recurse
Function CFIM__CopyIfMissing
  Exch $CFIM_dst         ; take DST from stack
  Exch
  Exch $CFIM_src         ; take SRC from stack

  GetFullPathName $CFIM_src $CFIM_src
  GetFullPathName $CFIM_dst $CFIM_dst
  CreateDirectory "$CFIM_dst"

  ; Recurse with these src/dst
  Push "$CFIM_src"
  Push "$CFIM_dst"
  Call CFIM__Recurse
FunctionEnd

; Recurse: enumerate $CFIM_src, copy files if missing into $CFIM_dst
Function CFIM__Recurse
  ; Unpack this level's src/dst
  Exch $CFIM_dst
  Exch
  Exch $CFIM_src

  ; --- Save outer enumeration state (handle + name) ---
  Push $CFIM_h
  Push $CFIM_name

  ; Start enumeration for THIS level
  FindFirst $CFIM_h $CFIM_name "$CFIM_src\*.*"
  ${DoWhile} $CFIM_name != ""
    ${If} $CFIM_name == "."
    ${OrIf} $CFIM_name == ".."
      ; skip
    ${Else}
      StrCpy $CFIM_srcPath "$CFIM_src\$CFIM_name"
      StrCpy $CFIM_dstPath "$CFIM_dst\$CFIM_name"

      ${If} ${FileExists} "$CFIM_srcPath\*.*"
        ; Directory → ensure and recurse
        CreateDirectory "$CFIM_dstPath"
        Push "$CFIM_srcPath"   ; next-level SRC
        Push "$CFIM_dstPath"   ; next-level DST
        Call CFIM__Recurse
      ${Else}
        ; File → copy only if MISSING at destination
        ${IfNot} ${FileExists} "$CFIM_dstPath"
          CreateDirectory "$CFIM_dst"    ; ensure current dest level exists
          CopyFiles /SILENT "$CFIM_srcPath" "$CFIM_dst"
        ${EndIf}
      ${EndIf}
    ${EndIf}
    FindNext $CFIM_h $CFIM_name
  ${Loop}
  FindClose $CFIM_h

  ; --- Restore outer enumeration state ---
  Pop $CFIM_name
  Pop $CFIM_h
FunctionEnd

!endif
