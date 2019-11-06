unit MyUtils;

interface

uses
  Windows, Registry;//, Graphics;

type
  TWndAlign = (waTopLeft,waTopRight,waBottomLeft,waBottomRight);
  TSetRegInfo = set of (regNumber,regSkin,regIcon);
  TAppPaths = (appSkin);

  TRegInfo = record
    Skin  : String;
    Icon  : String;
    Number: Byte;
  end;

const
  AppPath: array [TAppPaths] of String = (
   { 0 } 'Skins\'
  );
  // Cursor
  function GetIndex: Byte;
  procedure NextDesk(Wnd: hWnd);
  procedure PrevDesk(Wnd: hWnd);
  // Skin
  procedure ApplySkin(SkinName: String);
  function GetSkin: String;
  // Desktop
  procedure AddDesk(FileName: String);
  procedure RemoveDesk(Index: Byte);
  function GetDesk(Number: Byte): String;
  procedure SetWallpaper(sWallpaper: String);
  // Register
  procedure LoadRegister;
  procedure SaveRegister;
  // Utilities
//  procedure MakeThumb;
  procedure AlignWindow(Wnd: hWnd; Align: TWndAlign; Space: Byte);
  function GradColor(BeginColor, EndColor: TColorRef; iPercent: Byte): TColorRef;
  function GradColor2(BeginColor, EndColor: TColorRef; iPercent: Byte): TColorRef;

implementation

uses
  Skin;

type
  TShellTrayAlign = (staLeft,staTop,staRight,staBottom);

const
  MAX_DESK = 10;

var
  Desk  : array [1..MAX_DESK+1] of String;
  RegInfo: TRegInfo;
  iDesk: Byte;

function MyMulDiv(a,b,c : integer): longint; assembler;
asm
  MOV	eax, a
  IMUL	b
  IDIV	c
end;

function GradColor2(BeginColor, EndColor: LongWord; iPercent: Byte): TColorRef;
var
  RGBDiff: array[0..2] of Integer;
  RGBFrom: array[0..2] of Byte;
  R,G,B: Byte;
begin
  RGBFrom[0] := BeginColor and $000000FF;
  RGBFrom[1] := (BeginColor shr 8) and $000000FF;
  RGBFrom[2] := (BeginColor shr 16) and $000000FF;
  RGBDiff[0] := (EndColor and $000000FF) - RGBFrom[0];
  RGBDiff[1] := ((EndColor shr 8) and $000000FF) - RGBFrom[1];
  RGBDiff[2] := ((EndColor shr 16) and $000000FF) - RGBFrom[2];
  R := RGBFrom[0] + MyMulDiv(iPercent,RGBDiff[0],$FF);
  G := RGBFrom[1] + MyMulDiv(iPercent,RGBDiff[1],$FF);
  B := RGBFrom[2] + MyMulDiv(iPercent,RGBDiff[2],$FF);
  Result := RGB(R,G,B);
end;

function GradColor(BeginColor, EndColor: LongWord; iPercent: Byte): TColorRef;
var
  ER,EG,EB: Integer;
  BR,BG,BB: Byte;
  R,G,B: Byte;
begin
  BR := GetRValue(BeginColor); ER := GetRValue(EndColor) - BR;
  BG := GetGValue(BeginColor); EG := GetGValue(EndColor) - BG;
  BB := GetBValue(BeginColor); EB := GetBValue(EndColor) - BB;
  R := BR + MulDiv(iPercent,ER,255);
  G := BG + MulDiv(iPercent,EG,255);
  B := BB + MulDiv(iPercent,EB,255);
  Result := RGB(R,G,B);
end;

function GetResolution: TPoint;
var
  TempPt: TPoint;
begin
  TempPt.x := GetSystemMetrics(SM_CXSCREEN);
  TempPt.y := GetSystemMetrics(SM_CYSCREEN);
  Result := TempPt;
end;

function GetShellTrayAlign: TShellTrayAlign;
var
  Align: TShellTrayAlign;
  ShellTrayRect: TRect;
  Screen: TPoint;
begin
  Screen := GetResolution;
  GetWindowRect(FindWindow('shell_traywnd',nil),ShellTrayRect);
  with ShellTrayRect do begin
    if (Top > (Screen.y div 2)) then Align := staBottom
    else if (Left > (Screen.x div 2)) then Align := staRight
    else if (Right < Bottom) then Align := staLeft
    else  Align := staTop;
  end;
  Result := Align;
end;

procedure AlignWindow(Wnd: hWnd; Align: TWndAlign; Space: Byte);
var
  R, RWnd: TRect;
  Screen: TPoint;
begin
  Screen := GetResolution;
  GetClientRect(Wnd,RWnd);
  GetWindowRect(FindWindow('shell_traywnd',nil),R);
  with Screen do
    case GetShellTrayAlign of
    staLeft: case Align of
      waTopLeft: SetWindowPos(Wnd,0,R.Right+Space,0+Space,0,0,SWP_NOSIZE);
      waTopRight: SetWindowPos(Wnd,0,X-RWnd.Right-Space,0+Space,0,0,SWP_NOSIZE);
      waBottomLeft: SetWindowPos(Wnd,0,R.Right+Space,Y-RWnd.Bottom-Space,0,0,SWP_NOSIZE);
      waBottomRight: SetWindowPos(Wnd,0,X-RWnd.Right-Space,Y-RWnd.Bottom-Space,0,0,SWP_NOSIZE);
      end;
    staTop: case Align of
      waTopLeft: SetWindowPos(Wnd,0,0+Space,R.Bottom+Space,0,0,SWP_NOSIZE);
      waTopRight: SetWindowPos(Wnd,0,X-RWnd.Right-Space,R.Bottom+Space,0,0,SWP_NOSIZE);
      waBottomLeft: SetWindowPos(Wnd,0,0+Space,Y-RWnd.Bottom-Space,0,0,SWP_NOSIZE);
      waBottomRight: SetWindowPos(Wnd,0,X-RWnd.Right-Space,Y-RWnd.Bottom-Space,0,0,SWP_NOSIZE);
      end;
    staRight: case Align of
      waTopLeft: SetWindowPos(Wnd,0,0+Space,0+Space,0,0,SWP_NOSIZE);
      waTopRight: SetWindowPos(Wnd,0,R.Left-RWnd.Right-Space,0+Space,0,0,SWP_NOSIZE);
      waBottomLeft: SetWindowPos(Wnd,0,0+Space,Y-RWnd.Bottom-Space,0,0,SWP_NOSIZE);
      waBottomRight: SetWindowPos(Wnd,0,R.Left-RWnd.Right-Space,Y-RWnd.Bottom-Space,0,0,SWP_NOSIZE);
      end;
    staBottom: case Align of
      waTopLeft: SetWindowPos(Wnd,0,0+Space,0+Space,0,0,SWP_NOSIZE);
      waTopRight: SetWindowPos(Wnd,0,X-RWnd.Right-Space,0+Space,0,0,SWP_NOSIZE);
      waBottomLeft: SetWindowPos(Wnd,0,0+Space,R.Top-RWnd.Bottom-Space,0,0,SWP_NOSIZE);
      waBottomRight: SetWindowPos(Wnd,0,X-RWnd.Right-Space,R.Top-RWnd.Bottom-Space,0,0,SWP_NOSIZE);
      end;
    end;
end;

procedure GetRegInfo;
var
  StrNumber: String;
  Reg: TRegistry;
  i: Byte;
begin
  Reg := TRegistry.Create;
  with RegInfo do
    try
      Reg.RootKey := HKEY_LOCAL_MACHINE;
      Number := 0; Skin := ''; Icon := '';
      if Reg.OpenKey('\Software\SoftMaker\Desktops\',True) then begin
        if Reg.ValueExists('Number')
          then Number := Reg.ReadInteger('Number')
          else Reg.WriteInteger('Number',0);
        if Reg.ValueExists('Skin')
          then Skin := Reg.ReadString('Skin')
          else Reg.WriteString('Skin','');
        if Reg.ValueExists('Icon')
          then Icon := Reg.ReadString('Icon')
          else Reg.WriteString('Icon','');
        if not((Number < 1) and (Number > MAX_DESK)) then
          for i := 1 to Number do begin
            Str(i,StrNumber);
            Desk[i] := Reg.ReadString('Desk'+ StrNumber);
          end;
      end;
    finally
      Reg.CloseKey;
      Reg.Free;
    end;
end;

procedure SetRegInfo;
var
  StrNumber: String;
  Reg: TRegistry;
  i: Byte;
begin
  Reg := TRegistry.Create;
  with RegInfo do
    try
      Reg.RootKey := HKEY_LOCAL_MACHINE;
      if Reg.OpenKey('\Software\SoftMaker\Desktops\',True) then begin
        Reg.WriteInteger('Number',Number);
        Reg.WriteString('Skin',Skin);
        Reg.WriteString('Icon',Icon);
        if not((Number < 1) and (Number > MAX_DESK)) then
          for i := 1 to Number do begin
            Str(i,StrNumber);
            Reg.WriteString('Desk'+ StrNumber,Desk[i]);
          end;
      end;
    finally
      Reg.CloseKey;
      Reg.Free;
    end;
end;

function GetDesk(Number: Byte): String;
begin
  if not((Number < 1) and (Number > MAX_DESK)) then Result := Desk[Number] else Result := '';
end;

procedure LoadRegister;
begin
  GetRegInfo;
end;

procedure SaveRegister;
begin
  SetRegInfo;
end;

procedure ApplySkin(SkinName: String);
begin
  RegInfo.Skin := SkinName;
end;

function GetSkin: String;
begin
  Result := RegInfo.Skin;
end;

function GetIndex: Byte;
begin
  Result := iDesk;
end;

procedure AddDesk(FileName: String);
begin
  Inc(RegInfo.Number);
  Desk[RegInfo.Number] := FileName;
end;

procedure RemoveDesk(Index: Byte);
var
  i: Byte;
begin
  if not((RegInfo.Number < 1) and (RegInfo.Number > MAX_DESK)) then begin
    Desk[Index] := Desk[Index+1];
    for i := 1 to RegInfo.Number do
      Desk[Index+i] := Desk[Index+i+1];
    Dec(RegInfo.Number);
  end;
end;

procedure NextDesk(Wnd: hWnd);
var
  hInst: LongWord;
begin
  Inc(iDesk);
  if (iDesk > RegInfo.Number) then iDesk := 1;
  SetDisplay(Wnd,'C' + Desk[iDesk] + #0);
end;

procedure PrevDesk(Wnd: hWnd);
begin
  Dec(iDesk);
  if (iDesk < 1) then iDesk := RegInfo.Number;
  SetDisplay(Wnd,'C' + Desk[iDesk] + #0);
end;

procedure SetWallpaper(sWallpaper: String);
var
  Reg: TRegistry;
begin
  Reg := TRegistry.Create ;
  with reg do
    try
      RootKey := HKEY_CURRENT_USER;
      if OpenKey ('\Control Panel\Desktop', False) then begin
        WriteString ('Wallpaper',sWallPaper);
        WriteString ('WallpaperStyle','0');
        WriteString ('TileWallpaper','0');
      end;
    finally
      Free;
    end;
  SystemParametersInfo(SPI_SETDESKWALLPAPER,0,pChar(sWallpaper),SPIF_UPDATEINIFILE or SPIF_SENDCHANGE);
end;

initialization
  iDesk := 0;

end.
