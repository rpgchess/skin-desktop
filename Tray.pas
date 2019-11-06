unit Tray;

interface

uses
  Windows, Messages, ShellAPI;

const
  ID_TRAY = 50;
  WM_SYSTEMTRAY = WM_USER + ID_TRAY;

  procedure SetTray(Handle: hWnd; lpszIcon: PChar; lpszTip: String);
  procedure RemoveTray;

implementation

var
  IconTray: TNotifyIconData;

procedure SetTray(Handle: hWnd; lpszIcon: PChar; lpszTip: String);
var
  hInst: LongWord;
begin
  hInst := GetWindowLong(Handle,GWL_HINSTANCE);
  with IconTray do begin
    cbSize := SizeOf(TNotifyIconData);
    Wnd := Handle;
    uID := ID_TRAY;
    uFlags := NIF_ICON or NIF_TIP or NIF_MESSAGE;
    uCallbackMessage := WM_SYSTEMTRAY;
    hIcon := LoadIcon(hInst,lpszIcon);
    szTip := '';
  end;
  Shell_NotifyIcon(NIM_ADD,@IconTray);
end;

procedure RemoveTray;
begin
  IconTray.uFlags := 0;
  Shell_NotifyIcon(NIM_DELETE,@IconTray);
end;

end.