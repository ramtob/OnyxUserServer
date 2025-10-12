Var b1
Var b2
Var b3

Section
  Push "C:\src" 
  Push "C:\dst"
  Push "FLAG-YES"
  Call Get3_WithPop
SectionEnd

Function Get3_WithPop
  ; Pop removes from the stack (LIFO). Order: arg3, then arg2, then arg1.
  Pop $b3
  Pop $b2
  Pop $b1
  MessageBox MB_OK "Pop path$\r$\n b1=<$b1>$\r$\n b2=<$b2>$\r$\n b3=<$b3>"
FunctionEnd
