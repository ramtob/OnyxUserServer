!include "MUI2.nsh"

Name "Onyx User Server"
OutFile "UserServer-Setup-hello.exe"
InstallDir "$PROFILE\Onyx\User Server_test"  ; user-writable default
RequestExecutionLevel user                   ; no admin/UAC

!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_LANGUAGE "English"

Section "Install"
  SetOutPath "$INSTDIR"
  FileOpen $0 "$INSTDIR\hello.txt" w
  FileWrite $0 "Hello from NSIS 👋"
  FileClose $0
SectionEnd
