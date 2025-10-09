; CopyIfMissing.nsh
; Recursively copy SRC → DST, but only for files that do NOT already exist in DST.
; Usage (in your .nsi):
;   !include "CopyIfMissing.nsh"
;   !insertmacro CopyIfMissing "C:\path\to\src" "C:\path\to\dst"
; or with variables:
;   !insertmacro CopyIfMissing "$SomeSrcDir" "$SomeDstDir"

!ifndef CFIM_INCLUDED
!define CFIM_INCLUDED

!include "LogicLib.nsh"
;!include "FileFunc.nsh" ; for ${GetFullPathName}

; Public macro (hides the stack from your script)
!macro CopyIfMissing SRC DST
  Push "${SRC}"
  Push "${DST}"
  Call CFIM__CopyIfMissing
!macroend

; ---------- Implementation (prefixed to avoid name collisions) ----------
Var CFIM_h
Var CFIM_name
Var CFIM_src
Var CFIM_dst
Var CFIM_srcPath
Var CFIM_dstPath

; Entry point: normalize paths, ensure root, then recurse
Function CFIM__CopyIfMissing
  ; Stack (top→bottom): DST, SRC
  Exch $CFIM_dst            ; $CFIM_dst = DST
  Exch
  Exch $CFIM_src            ; $CFIM_src = SRC

  GetFullPathName $CFIM_src $CFIM_src
  GetFullPathName $CFIM_dst $CFIM_dst
  CreateDirectory "$CFIM_dst"

  ; Recurse with current src/dst
  Push "$CFIM_src"
  Push "$CFIM_dst"
  Call CFIM__Recurse
FunctionEnd

; Recurse into subdirs, copy files only if missing
Function CFIM__Recurse
  ; Stack (top→bottom): DST, SRC
  Exch $CFIM_dst
  Exch
  Exch $CFIM_src

  FindFirst $CFIM_h $CFIM_name "$CFIM_src\*.*"
  ${DoWhile} $CFIM_name != ""
    ${If} $CFIM_name == "." 
    ${OrIf} $CFIM_name == ".."
      ; skip
    ${Else}
      StrCpy $CFIM_srcPath "$CFIM_src\$CFIM_name"
      StrCpy $CFIM_dstPath "$CFIM_dst\$CFIM_name"

      ${If} ${FileExists} "$CFIM_srcPath\*.*"
        ; directory → ensure and recurse
        CreateDirectory "$CFIM_dstPath"
        Push "$CFIM_srcPath"
        Push "$CFIM_dstPath"
        Call CFIM__Recurse
      ${Else}
        ; file → copy only if missing
        ${IfNot} ${FileExists} "$CFIM_dstPath"
          CreateDirectory "$CFIM_dst"   ; ensure current level exists
          ; CopyFiles copies to a *folder* (keeps filename)
          CopyFiles /SILENT "$CFIM_srcPath" "$CFIM_dst"
        ${EndIf}
      ${EndIf}
    ${EndIf}
    FindNext $CFIM_h $CFIM_name
  ${Loop}
  FindClose $CFIM_h
FunctionEnd

!endif
