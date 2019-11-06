library Samsung732N{skn};

uses
  Windows, MyUtils, Skin, Bitmap;

{$E skn}
{$R Samsung.res}
{$I Commands.inc}

procedure DllSkin(Wnd: hWnd; var SkinStruct: TSkinStruct); export;
var
  hDel: THandle;
  iEffect: Byte;
  MemDC: hDC;
begin
  with SkinStruct do begin
    Form.Width := 108; Form.Height := 102;
    BtnNext.Top := 31; BtnNext.Left := 95;
    BtnNext.Width := 11; BtnNext.Height := 29;
    BtnPrev.Top := 36; BtnPrev.Left := 0;
    BtnPrev.Width := 7; BtnPrev.Height := 11;
    BtnDisplay.Top := 7; BtnDisplay.Left := 14;
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
  iEffect := 1; SetProp(GetDlgItem(Wnd,ID_BTN_DISPLAY),'EFFECT',iEffect);
  DefaultSkin(Wnd,[sbNext,sbPrev]);
end;

exports
  DllSkin;

begin

end.
