; ----- exch_demo.nsi -----
!include "MUI2.nsh"

Name "Exch Demo"
OutFile "ExchDemo.exe"
RequestExecutionLevel user

; We'll store parameters into these "variables"
Var demoSrc
Var demoDst

Section
  ; Pretend we're "calling" a function with 2 arguments:
  ; Push in CALLER order: first SRC, then DST, top of stack is last pushed.
  Push "C:\src"
  Push "C:\dst"

  ; Now "call" the function that retrieves them using Exch
  Call ExchDemo_GetArgs
SectionEnd

Function ExchDemo_GetArgs
  ; At this moment the stack (top→bottom) is:  "C:\dst", "C:\src", ...

  MessageBox MB_OK "Step 0:$\r$\ndemoSrc=<$demoSrc>$\r$\ndemoDst=<$demoDst>$\r$\n(We haven't retrieved anything yet.)"

  ; Step 1: grab the top-of-stack (DST) into $demoDst
  Exch $demoDst
  MessageBox MB_OK "Step 1 (Exch $demoDst):$\r$\ndemoSrc=<$demoSrc>$\r$\ndemoDst=<$demoDst>$\r$\n(Now demoDst should be C:\dst.)"

  ; Step 2: swap the top two stack items (a bare Exch)
  Exch
  MessageBox MB_OK "Step 2 (bare Exch):$\r$\ndemoSrc=<$demoSrc>$\r$\ndemoDst=<$demoDst>$\r$\n(We haven't taken SRC yet; this brings C:\src to the top.)"

  ; Step 3: grab the now-top-of-stack (SRC) into $demoSrc
  Exch $demoSrc
  MessageBox MB_OK "Step 3 (Exch $demoSrc):$\r$\ndemoSrc=<$demoSrc>$\r$\ndemoDst=<$demoDst>$\r$\n(Now demoSrc=C:\src and demoDst=C:\dst.)"

  ; Done: we have both "arguments" in variables
FunctionEnd
