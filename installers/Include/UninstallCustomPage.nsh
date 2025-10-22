!ifndef UNCS_INCLUDED
!define UNCS_INCLUDED

!include "MUI2.nsh"
!include "nsDialogs.nsh"
!include "LogicLib.nsh"

Var UnRemoveCfg       ; will hold BST_CHECKED / BST_UNCHECKED
Var UN_H_CHK          ; handle to the checkbox control

Function un.PageRemoveConfig_Create
  nsDialogs::Create 1018
  Pop $0
  ${If} $0 == error
    Abort
  ${EndIf}

  ${NSD_CreateLabel} 0 0 100% 22u \
    "Do you also want to remove the user configuration folder?"
  ${NSD_CreateLabel} 0 16u 100% 22u \
    "(This resets settings. Leave unchecked to keep your configuration.)"

  ${NSD_CreateCheckbox} 0 44u 100% 12u \
    "DELETE ${APP_NAME} CONFIGURATION"
  Pop $UN_H_CHK
  ${NSD_Uncheck} $UN_H_CHK    ; default = unchecked

  nsDialogs::Show
FunctionEnd

Function un.PageRemoveConfig_Leave
  ${NSD_GetState} $UN_H_CHK $UnRemoveCfg
FunctionEnd

!endif

