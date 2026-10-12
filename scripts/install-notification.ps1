$ErrorActionPreference = 'Stop'
$appId = 'EnglishSongClub.PagesWatchdog'
$shortcutPath = Join-Path ([Environment]::GetFolderPath('Programs')) 'English Song Club Pages Watchdog.lnk'
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
$shortcut.Arguments = "-NoProfile -WindowStyle Hidden -File `"$(Join-Path $PSScriptRoot 'watch-mirror.ps1')`""
$shortcut.WindowStyle = 7
$shortcut.Description = 'English Song Club website health check'
$shortcut.Save()
if (!('MirrorNotificationIdentity' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class MirrorNotificationIdentity {
    [StructLayout(LayoutKind.Sequential)] public struct Key { public Guid format; public uint id; }
    [StructLayout(LayoutKind.Explicit, Size=24)] public struct Value {
        [FieldOffset(0)] public ushort type;
        [FieldOffset(8)] public IntPtr text;
    }
    [ComImport, Guid("886D8EEB-8CF2-4446-8D02-CDBA1DBDCF99"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface Store {
        [PreserveSig] int GetCount(out uint count);
        [PreserveSig] int GetAt(uint index, out Key key);
        [PreserveSig] int GetValue(ref Key key, out Value value);
        [PreserveSig] int SetValue(ref Key key, ref Value value);
        [PreserveSig] int Commit();
    }
    [DllImport("shell32.dll", CharSet=CharSet.Unicode)]
    static extern int SHGetPropertyStoreFromParsingName(string path, IntPtr context, uint flags, ref Guid iid, out Store store);
    public static void Register(string path, string appId) {
        Guid iid = new Guid("886D8EEB-8CF2-4446-8D02-CDBA1DBDCF99");
        Store store;
        Marshal.ThrowExceptionForHR(SHGetPropertyStoreFromParsingName(path, IntPtr.Zero, 2, ref iid, out store));
        Key key = new Key { format = new Guid("9F4C2855-9F79-4B39-A8D0-E1D42DE1D5F3"), id = 5 };
        Value value = new Value { type = 31, text = Marshal.StringToCoTaskMemUni(appId) };
        try {
            Marshal.ThrowExceptionForHR(store.SetValue(ref key, ref value));
            Marshal.ThrowExceptionForHR(store.Commit());
        } finally { Marshal.FreeCoTaskMem(value.text); Marshal.ReleaseComObject(store); }
    }
}
'@
}
[MirrorNotificationIdentity]::Register($shortcutPath, $appId)
$notificationKey = "HKCU:\Software\Classes\AppUserModelId\$appId"
New-Item -Path $notificationKey -Force | Out-Null
New-ItemProperty -LiteralPath $notificationKey -Name DisplayName -Value 'English Song Club website sync' -PropertyType ExpandString -Force | Out-Null
[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType=WindowsRuntime] | Out-Null
[Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType=WindowsRuntime] | Out-Null
$notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($appId)
$xml = New-Object Windows.Data.Xml.Dom.XmlDocument
$xml.LoadXml("<toast><visual><binding template='ToastGeneric'><text>Notification channel check</text></binding></visual></toast>")
$toast = [Windows.UI.Notifications.ToastNotification]::new($xml)
$toast.Tag = 'setup-test'
$toast.Group = 'EnglishSongClub'
$toast.SuppressPopup = $true
$notifier.Show($toast)
$history = [Windows.UI.Notifications.ToastNotificationManager]::History.GetHistory($appId)
$found = @($history | Where-Object Tag -eq 'setup-test').Count
[Windows.UI.Notifications.ToastNotificationManager]::History.Remove('setup-test', 'EnglishSongClub', $appId)
if ($found -ne 1) { throw 'Notification channel readback failed' }
Write-Output 'Notification identity registered; silent notification readback passed and test removed.'
