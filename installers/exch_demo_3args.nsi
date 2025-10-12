; ----- exch_demo_3args.nsi -----
!include "MUI2.nsh"

Name "Exch Demo (3 args)"
OutFile "ExchDemo3.exe"
RequestExecutionLevel user

Var a1
Var a2
Var a3

Section
  ; Caller pushes arguments in order (first → last):
  Push "C:\src"         ; arg1
  Push "C:\dst"         ; arg2
  Push "FLAG-YES"       ; arg3 (top of stack)

  Call Get3_WithExch
SectionEnd

Function Get3_WithExch
  ; At entry, stack top→bottom: "FLAG-YES", "C:\dst", "C:\src"

  MessageBox MB_OK "Entry$\r$\n a1=<$a1>$\r$\n a2=<$a2>$\r$\n a3=<$a3>"

  ; 1) Grab arg3 (top) into $a3
  Exch $a3
  MessageBox MB_OK "After Exch $a3$\r$\n a1=<$a1>$\r$\n a2=<$a2>$\r$\n a3=<$a3>"

  ; 2) Bring arg2 to top (swap top two stack items)
  Exch
  ; 3) Grab arg2 into $a2
  Exch $a2
  MessageBox MB_OK "After Exch + Exch $a2$\r$\n a1=<$a1>$\r$\n a2=<$a2>$\r$\n a3=<$a3>"

  ; 4) Bring arg1 to top
  Exch 2
  ; 5) Grab arg1 into $a1
  Exch $a1
  MessageBox MB_OK "Done (Exch path)$\r$\n a1=<$a1>$\r$\n a2=<$a2>$\r$\n a3=<$a3>"
FunctionEnd
