; ----- sum_demo.nsi -----
!include "MUI2.nsh"

Name "Sum Demo"
OutFile "SumDemo.exe"
RequestExecutionLevel user

var Sum

Section
  ; Push parameters (left-to-right order)
  Push 3
  Push 7
  Push 11
  Call Sum3
  Pop $sum
  MessageBox MB_OK "Sum = $sum"
SectionEnd

Function Sum3
  ; Stack at entry:  top→ 11, 7, 3
  Exch $2       ; $2 = 11
  Exch
  Exch $1       ; $1 = 7
  Exch 2
  Exch $0       ; $0 = 3

  ; Now $0=3, $1=7, $2=11
  IntOp $0 $0 + $1
  IntOp $0 $0 + $2

  Push $0       ; return sum
FunctionEnd
