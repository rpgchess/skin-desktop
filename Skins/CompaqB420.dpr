library CompaqB420{skn};

uses
  Windows, MyUtils, Skin, Bitmap;

{$E skn}
{$R Compaq.res}
{$I Commands.inc}

procedure DllSkin(Wnd: hWnd; var SkinStruct: TSkinStruct); export;
var
  hDel: THandle;
  MemDC: hDC;
begin
  with SkinStruct do begin
    Form.Width := 115; Form.Height := 104;
    BtnNext.Top := 33; BtnNext.Left := 96;
    BtnNext.Width := 11; BtnNext.Height := 29;
    BtnPrev.Top := 38; BtnPrev.Left := 0;
    BtnPrev.Width := 7; BtnPrev.Height := 11;
    BtnDisplay.Top := 9; BtnDisplay.Left := 16;
    BtnDisplay.Width := 60; BtnDisplay.Height := 66;
  end;

  MemDC := CreateCompatibleDC(0);       // Formulário
  SelectObject(MemDC,LoadBitmap(hInstance,'Background'));
  if MemDC <> 0 then begin
    hDel := GetProp(Wnd,'BACKGROUND');
    if hDel <> 0 then DeleteObject(hDel);
    SetProp(Wnd,'BACKGROUND',MemDC);
    SetWindowRgn(Wnd,BmpToRgn(LoadBitmap(hInstance,'Background'),RGB($FF,$00,$FF),$1),True);
  end;
  DefaultSkin(Wnd,[sbNext,sbPrev]);
end;

exports
  DllSkin;

begin

end.
