unit Effects;

interface

uses
  Windows, MyUtils;

{$I Commands.inc}

  procedure ApplyEffect(Wnd: hWnd; iEffect: Byte; DC: hDC);

implementation

procedure Transparent(Wnd: hWnd; DC: hDC; iPercent: Byte);
var
  i,j: Word;
  TempDC: hDC;
  Bmp: TBitmap;
  hBmp: hBitmap;
  hInst: LongWord;
begin
  hInst := GetWindowLong(Wnd,GWL_HINSTANCE);
  hBmp := LoadBitmap(hInst,'DisEffect');
  if hBmp <> 0 then begin
    GetObject(hBmp,SizeOf(Bmp),@Bmp);
    TempDC := CreateCompatibleDC(0);
    SelectObject(TempDC,hBmp);
    for i := 0 to Bmp.bmWidth do
      for j := 0 to Bmp.bmHeight do
        SetPixel(DC,i,j,GradColor(GetPixel(DC,i,j),GetPixel(TempDC,i,j),iPercent));
    DeleteObject(TempDC);
    CloseHandle(hBmp);
  end;
end;

procedure ApplyEffect(Wnd: hWnd; iEffect: Byte; DC: hDC);
begin
  case iEffect of
  0: Exit;
  1: Transparent(Wnd,DC,85);
  end;
end;

end.