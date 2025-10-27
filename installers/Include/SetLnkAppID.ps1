# SetLnkAppID.ps1 — create/update a .lnk and set AppUserModelID (Win10/11)
param(
  [Parameter(Mandatory=$true)][string]$LinkPath,
  [Parameter(Mandatory=$true)][string]$Target,
  [string]$Args = "",
  [string]$Icon = "",
  [string]$Desc = "",
  [Parameter(Mandatory=$true)][string]$AppID
)

$ErrorActionPreference = 'Stop'

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Runtime.InteropServices.ComTypes;
using System.Text;

[StructLayout(LayoutKind.Sequential, CharSet=CharSet.Unicode)]
public struct WIN32_FIND_DATAW {
  public uint dwFileAttributes;
  public System.Runtime.InteropServices.ComTypes.FILETIME ftCreationTime;
  public System.Runtime.InteropServices.ComTypes.FILETIME ftLastAccessTime;
  public System.Runtime.InteropServices.ComTypes.FILETIME ftLastWriteTime;
  public uint nFileSizeHigh;
  public uint nFileSizeLow;
  public uint dwReserved0;
  public uint dwReserved1;
  [MarshalAs(UnmanagedType.ByValTStr, SizeConst=260)]
  public string cFileName;
  [MarshalAs(UnmanagedType.ByValTStr, SizeConst=14)]
  public string cAlternateFileName;
}

[ComImport, Guid("00021401-0000-0000-C000-000000000046")]
class ShellLink {}

[ComImport, InterfaceType(ComInterfaceType.InterfaceIsIUnknown), Guid("000214F9-0000-0000-C000-000000000046")]
interface IShellLinkW {
  void GetPath(StringBuilder pszFile, int cchMaxPath, out WIN32_FIND_DATAW pfd, uint fFlags);
  void GetIDList(out IntPtr ppidl);
  void SetIDList(IntPtr pidl);
  void GetDescription(StringBuilder pszName, int cchMaxName);
  void SetDescription([MarshalAs(UnmanagedType.LPWStr)] string pszName);
  void GetWorkingDirectory(StringBuilder pszDir, int cchMaxPath);
  void SetWorkingDirectory([MarshalAs(UnmanagedType.LPWStr)] string pszDir);
  void GetArguments(StringBuilder pszArgs, int cchMaxPath);
  void SetArguments([MarshalAs(UnmanagedType.LPWStr)] string pszArgs);
  void GetHotkey(out short pwHotkey);
  void SetHotkey(short wHotkey);
  void GetShowCmd(out int piShowCmd);
  void SetShowCmd(int iShowCmd);
  void GetIconLocation(StringBuilder pszIconPath, int cchIconPath, out int piIcon);
  void SetIconLocation([MarshalAs(UnmanagedType.LPWStr)] string pszIconPath, int iIcon);
  void SetRelativePath([MarshalAs(UnmanagedType.LPWStr)] string pszPathRel, uint dwReserved);
  void Resolve(IntPtr hwnd, uint fFlags);
  void SetPath([MarshalAs(UnmanagedType.LPWStr)] string pszFile);
}

[ComImport, InterfaceType(ComInterfaceType.InterfaceIsIUnknown), Guid("0000010b-0000-0000-C000-000000000046")]
interface IPersistFile {
  void GetClassID(out Guid pClassID);
  int IsDirty();
  void Load([MarshalAs(UnmanagedType.LPWStr)] string pszFileName, uint dwMode);
  void Save([MarshalAs(UnmanagedType.LPWStr)] string pszFileName, bool fRemember);
  void SaveCompleted([MarshalAs(UnmanagedType.LPWStr)] string pszFileName);
  void GetCurFile([MarshalAs(UnmanagedType.LPWStr)] out string ppszFileName);
}

[ComImport, InterfaceType(ComInterfaceType.InterfaceIsIUnknown), Guid("886D8EEB-8CF2-4446-8D02-CDBA1DBDCF99")]
interface IPropertyStore {
  uint GetCount(out uint cProps);
  uint GetAt(uint iProp, out PROPERTYKEY pkey);
  uint GetValue(ref PROPERTYKEY key, out PROPVARIANT pv);
  uint SetValue(ref PROPERTYKEY key, ref PROPVARIANT pv);
  uint Commit();
}

[StructLayout(LayoutKind.Sequential, Pack=4)]
struct PROPERTYKEY { public Guid fmtid; public uint pid; }

[StructLayout(LayoutKind.Sequential)]
struct PROPVARIANT {
  public ushort vt, w1, w2, w3;
  public IntPtr p;
  public int p2;
}

static class PS {
  public static PROPERTYKEY AUMID = new PROPERTYKEY { fmtid = new Guid("9F4C2855-9F79-4B39-A8D0-E1D42DE1D5F3"), pid = 5 };
  public const ushort VT_LPWSTR = 31;
  public static PROPVARIANT FromString(string s) {
    var pv = new PROPVARIANT();
    pv.vt = VT_LPWSTR;
    pv.p = Marshal.StringToCoTaskMemUni(s);
    return pv;
  }
  public static void Clear(ref PROPVARIANT pv) {
    if (pv.vt == VT_LPWSTR && pv.p != IntPtr.Zero) Marshal.FreeCoTaskMem(pv.p);
    pv.vt = 0;
  }
}

public class LnkUtil {
  public static void Create(string path, string target, string args, string icon, string appid, string desc) {
    var link = (IShellLinkW)new ShellLink();
    link.SetPath(target);
    if (!string.IsNullOrEmpty(args))  link.SetArguments(args);
    if (!string.IsNullOrEmpty(icon))  link.SetIconLocation(icon, 0);
    if (!string.IsNullOrEmpty(desc))  link.SetDescription(desc);

    var store = (IPropertyStore)link;
    var key = PS.AUMID;
    var pv  = PS.FromString(appid);
    store.SetValue(ref key, ref pv);
    store.Commit();
    PS.Clear(ref pv);

    ((IPersistFile)link).Save(path, true);
  }
}
"@

[System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($LinkPath)) | Out-Null
[LnkUtil]::Create($LinkPath, $Target, $Args, $Icon, $AppID, $Desc)
