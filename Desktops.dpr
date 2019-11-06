program Desktops;

uses Windows, Messages, MyUtils, Tray, Skin, Effects, Bitmap;

{$R Desktops.res}
{$I Commands.inc}

const
  // Resource String
  SAppName = 'Desktops';
  SAppTitle = 'Desktops';
  SAppMenu = 'MainMenu';
  SBtnName = 'DeskButtons';

var
  AppInstance: LongWord;
  AppName: PChar;
  BtnName: PChar;
  Menu: hMenu;
  Form: hWnd;

function DlgDesk(Dlg, iMsg, wParam, lParam: LongWord): LResult; stdcall;
var
  Buffer: String[100];
begin
  Result := LResult(True);
  case iMsg of
  WM_INITDIALOG: begin end;
  WM_COMMAND: case LoWord(wParam) of
  ID_BTN_DESKADD: begin
    GetWindowText(GetDlgItem(Dlg,ID_EDT_DESKPATH),@Buffer,100);
    AddDesk(Buffer); SendMessage(Dlg,WM_CLOSE,0,0);
  end; end;
  WM_CLOSE: EndDialog(Dlg,0);
  end;
  Result := LResult(False);
end;

var
  hListbox: hWnd;

procedure LoadSkinDir;
var
  iCount: Integer;
  StrCount: String;
begin
  SendMessage(hListbox,LB_RESETCONTENT,0,0);
  SetCurrentDirectory(PChar('C:\Meus documentos\Softmaker\Projetos\Desktops\Versão 0.05\'+ AppPath[appSkin]));
  SendMessage(hListbox,LB_DIR,DDL_ARCHIVE or DDL_READWRITE,LongInt(PChar('*.skn'+ #0)));
  iCount := SendMessage(hListbox,LB_GETCOUNT,0,0);
  Str(iCount,StrCount);
end;

function DlgSkin(Dlg, iMsg, wParam, lParam: LongWord): LResult; stdcall;
var
  iList: Integer;
  SkinName: String[65];
begin
  Result := LResult(True);
  case iMsg of
  WM_INITDIALOG: begin
    hListbox := GetDlgItem(Dlg,1001); LoadSkinDir;
  end;
  WM_COMMAND: case LoWord(wParam) of
  1003: begin
    iList := SendMessage(hListbox,LB_GETCURSEL,0,0);
    SendMessage(hListbox,LB_GETTEXT,iList,LongWord(@SkinName));
    ApplySkin(SkinName); LoadSkin(Form,GetSkin);
    SendMessage(Dlg,WM_CLOSE,0,0);
  end; end;
  WM_CLOSE: EndDialog(Dlg,0);
  end;
  Result := LResult(False);
end;

function BtnWndProc(Btn, iMsg, wParam, lParam: LongWord): LongWord; stdcall;
var
  PS: TPaintStruct;
  BtnState: Byte;
  MemDC: hDC;
  Rgn: hRgn;
  R: TRect;
begin
  case iMsg of
  WM_CREATE: begin
    BtnState := 1;       // State Normal
    SetProp(Btn,'BTNSTATE',BtnState);
    SetProp(Btn,'NORMALBMP',0);
    SetProp(Btn,'OVERBMP',0);
    SetProp(Btn,'PRESSBMP',0);
    SetProp(Btn,'BTNRGN',0);
    SetProp(Btn,'EFFECT',0);
  end;
  WM_DESTROY: begin
    Rgn := GetProp(Btn,'BTNRGN');
    if (Rgn <> 0) then DeleteObject(Rgn);
    MemDC := GetProp(Btn,'PRESSBMP');
    if (MemDC <> 0) then DeleteObject(MemDC);
    MemDC := GetProp(Btn,'OVERBMP');
    if (MemDC <> 0) then DeleteObject(MemDC);
    MemDC := GetProp(Btn,'NORMALBMP');
    if (MemDC <> 0) then DeleteObject(MemDC);
    RemoveProp(Btn,'EFFECT');
    RemoveProp(Btn,'BTNSTATE');
    RemoveProp(Btn,'BTNRGN');
    RemoveProp(Btn,'PRESSBMP');
    RemoveProp(Btn,'OVERBMP');
    RemoveProp(Btn,'NORMALBMP');
  end;
  WM_LBUTTONDOWN: begin
    SetCapture(Btn);
    BtnState := 3;      // State Pressed
    SetProp(Btn,'BTNSTATE',BtnState);
    InvalidateRect(Btn,nil,False);
  end;
  WM_LBUTTONUP: begin
    BtnState := GetProp(Btn,'BTNSTATE');
    if (BtnState = 3) then
      PostMessage(GetParent(Btn),WM_COMMAND,GetDlgCtrlId(Btn),0);
    BtnState := 1; ReleaseCapture;
    SetProp(Btn,'BTNSTATE',BtnState);
    InvalidateRect(Btn,nil,False);
  end;
  WM_MOUSEMOVE: begin
    Rgn := GetProp(Btn,'BTNRGN');
    BtnState := GetProp(Btn,'BTNSTATE');
    if (BtnState <> 0) and (Rgn <> 0) then begin
      if PtInRegion(Rgn,LoWord(lParam),HiWord(lParam)) then begin
        if (BtnState = 1) then begin
          if (wParam and (MK_LBUTTON or MK_RBUTTON) = 0)
            then BtnState := 2
            else BtnState := 3;
          SetProp(Btn,'BTNSTATE',BtnState);
          SetCapture(Btn);
          InvalidateRect(Btn,nil,False);
        end;
      end else begin
        BtnState := 1; ReleaseCapture;
        SetProp(Btn,'BTNSTATE',BtnState);
        InvalidateRect(Btn,nil,False);
      end;
    end;
  end;
  WM_PAINT: begin
    BtnState := GetProp(Btn,'BTNSTATE');
    case BtnState of
    1: MemDC := GetProp(Btn,'NORMALBMP');
    2: MemDC := GetProp(Btn,'OVERBMP');
    3: MemDC := GetProp(Btn,'PRESSBMP');
    else MemDC := 0; end;
    if (MemDC <> 0) then begin
      GetWindowRect(Btn,R);
      BeginPaint(Btn,PS);
      BitBlt(PS.hDC,0,0,R.Right-R.Left,R.Bottom-R.Top,MemDC,0,0,SRCCOPY);
      EndPaint(Btn,PS);
    end;
  end; else
    Result := DefWindowProc(Btn,iMsg,wParam,lParam);
  end;
end;

function WindowProc(Wnd, iMsg, wParam, lParam: LongWord): LongWord; stdcall;
var
  PS: TPaintStruct;
  MemDC: hDC;
  Pt: TPoint;
  R: TRect;
begin
  case iMsg of
  WM_CREATE: begin
    Menu := GetSubMenu(LoadMenu(AppInstance,'Popup'),0);
    SetTray(Wnd,'MainIcon','Desktops v0.04');
    SetProp(Wnd,'BACKGROUND',0);
  end;
  WM_CLOSE: begin
    RemoveTray; DestroyMenu(Menu);
    MemDC := GetProp(Wnd,'BACKGROUND');
    if (MemDC <> 0) then DeleteObject(MemDC);
    DestroyWindow(Wnd);
  end;
  WM_DESTROY: begin
    UnRegisterClass(BtnName,AppInstance);
    UnRegisterClass(AppName,AppInstance);
    PostQuitMessage(0);
  end;
  WM_PAINT: begin
    MemDC := GetProp(Wnd,'BACKGROUND');
    if MemDC <> 0 then begin
      GetClientRect(Wnd,R);
      BeginPaint(Wnd,PS);
      BitBlt(PS.hDC,0,0,R.Right,R.Bottom,MemDC,0,0,SRCCOPY);
      EndPaint(Wnd,PS);
    end;
  end;
  WM_SYSTEMTRAY: case lParam of
    WM_LBUTTONDBLCLK: ShowWindow(Wnd,SW_RESTORE);
    WM_RBUTTONUP, WM_CONTEXTMENU: begin
      GetCursorPos(Pt);
      if IsWindowVisible(Wnd) then
        ModifyMenu(Menu,ID_TRAY,MF_BYCOMMAND or MF_STRING,ID_TRAY,PChar('&Esconder'+ #0))
      else
        ModifyMenu(Menu,ID_TRAY,MF_BYCOMMAND or MF_STRING,ID_TRAY,PChar('&Mostrar'+ #0));
      TrackPopupMenu(Menu,0,Pt.x,Pt.y,0,Wnd,nil);
      PostMessage(Wnd,WM_NULL,0,0);
    end; else
      Result := DefWindowProc(Wnd,iMsg,wParam,lParam);
  end;
  WM_NCHITTEST: Result := htCaption;
  WM_COMMAND: case LoWord(wParam) of
    ID_TRAY: if IsWindowVisible(Wnd) then ShowWindow(Wnd,SW_HIDE) else ShowWindow(Wnd,SW_RESTORE);
    ID_EXIT: SendMessage(Wnd,WM_CLOSE,0,0);
    ID_BTN_NEXT: begin NextDesk(Wnd); end;
    ID_BTN_PREV: begin PrevDesk(Wnd); end;
    ID_BTN_DISPLAY: SetWallpaper('C' + GetDesk(GetIndex));
    ID_APPLYSKIN: //DialogBox(AppInstance,'DlgSkin',Wnd,@DlgSkin);
    if GetSkin = 'Compaq.skn' then LoadSkin(Wnd,'Samsung.skn') else LoadSkin(Wnd,'Compaq.skn');
    ID_DLG_DESKADD: DialogBox(AppInstance,'DlgDesk',Wnd,@DlgDesk);
    else
      Result := DefWindowProc(Wnd,iMsg,wParam,lParam);
  end; else
    Result := DefWindowProc(Wnd,iMsg,wParam,lParam);
  end;
end;

function WindowMain(hInst, hPrevInst: LongWord; sCmdLine: String; iCmdShow: Integer): Integer;
var
  WndClass: TWndClassEx;
  Mutex: hWnd;
  Msg: TMsg;
begin
  if not(GetClassInfoEx(0,BtnName,WndClass)) then begin
    with WndClass do begin
      cbSize := SizeOf(TWndClassEx);
      style := 0;
      lpfnWndProc := @BtnWndProc;
      cbClsExtra := 0;
      cbWndExtra := 0;
      hInstance := hInst;
      hIcon := LoadIcon(0,IDI_APPLICATION);
      hCursor := LoadCursor(0,IDC_HAND);
      hbrBackground := COLOR_BACKGROUND;
      lpszMenuName := nil;
      lpszClassName := BtnName;
      hIconSm := LoadIcon(0,IDI_APPLICATION);
    end;
    RegisterClassEx(WndClass);
  end;

  if not(GetClassInfoEx(0,AppName,WndClass)) then begin
    with WndClass do begin
      cbSize := SizeOf(WndClass);
      style := CS_HREDRAW or CS_VREDRAW or CS_CLASSDC or CS_DBLClKS;
      cbClsExtra := 0;
      cbWndExtra := 0;
      hInstance := hInst;
      lpfnWndProc := @WindowProc;
      hIcon := LoadIcon(hInst,'MainIcon');
      hIconSm := LoadIcon(hInst,'MainIcon');
      hCursor := LoadCursor(0,IDC_ARROW);
      hbrBackground := COLOR_BACKGROUND;
      lpszMenuName := PChar(SAppMenu);
      lpszClassName := AppName;
    end;
    RegisterClassEx(WndClass);
  end;

  CreateMutex(nil,True,AppName);
  if GetLastError = ERROR_ALREADY_EXISTS then begin
    ReleaseMutex(Mutex); ExitProcess(0);
  end;
  ReleaseMutex(Mutex);

  Form := CreateWindowEx(WS_EX_TOOLWINDOW,AppName,PChar(SAppTitle),WS_POPUP or WS_SYSMENU,150,150,102,75,0,0,hInst,nil);

  CreateWindow(BtnName,'Next',WS_CHILD or WS_VISIBLE,89,20,11,29,Form,ID_BTN_NEXT,hInst,nil);
  CreateWindow(BtnName,'Prev',WS_CHILD or WS_VISIBLE,0,29,7,11,Form,ID_BTN_PREV,hInst,nil);
  CreateWindow(BtnName,'Display',WS_CHILD or WS_VISIBLE,14,2,60,66,Form,ID_BTN_DISPLAY,hInst,nil);

  SetWindowRgn(Form,BmpToRgn(LoadBitmap(hInst,'Background'),RGB($FF,$00,$FF),$10),False);
  AlignWindow(Form,waBottomRight,10);

  LoadRegister; DefaultSkin(Form,[sbDisplay]);
  LoadSkin(Form,GetSkin);

  if not((sCmdLine = '-h') or (sCmdLine = '-hide') or (sCmdLine = '-hidden')) then begin
    ShowWindow(Form,iCmdShow);
    UpdateWindow(Form);
  end;

  while GetMessage(Msg,0,0,0) do begin
    TranslateMessage(Msg);
    DispatchMessage(Msg);
  end;

  SaveRegister;
  Halt(Msg.wParam);
end;

begin
  AppInstance := hInstance;
  AppName := PChar(SAppName);
  BtnName := PChar(SBtnName);
  WindowMain(AppInstance,0,ParamStr(1),SW_SHOWDEFAULT);
  ExitProcess(0);
end.