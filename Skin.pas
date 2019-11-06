unit Skin;

interface

uses
  Windows, MyUtils, Effects, Bitmap;

{$I Commands.inc}

type
  TSkinBody = set of (sbForm,sbNext,sbPrev,sbDisplay);
  TSkinForm = record
    Width, Height: Word;
  end;
  TSkinBtn = record
    Left, Top, Width, Height: Word;
  end;
  TSkinStruct = record
    Form        : TSkinForm;
    BtnNext	: TSkinBtn;
    BtnPrev	: TSkinBtn;
    BtnDisplay	: TSkinBtn;
  end;

  function LoadSkin(Wnd: hWnd; SkinName: String): Boolean;
  procedure DefaultSkin(Wnd: hWnd; SkinBody: TSkinBody);
  procedure SetDisplay(Wnd: hWnd; BmpName: String);

implementation

type
  TSkinProc = procedure(Wnd: hWnd; var SkinStruct: TSkinStruct);

procedure MoveSkinObj(Wnd: hWnd; SkinStruct: TSkinStruct);
begin
  with SkinStruct.Form do SetWindowPos(Wnd,0,0,0,Width,Height,SWP_NOMOVE);
  with SkinStruct.BtnNext do MoveWindow(GetDlgItem(Wnd,ID_BTN_NEXT),Left,Top,Width,Height,False);
  with SkinStruct.BtnPrev do MoveWindow(GetDlgItem(Wnd,ID_BTN_PREV),Left,Top,Width,Height,False);
  with SkinStruct.BtnDisplay do MoveWindow(GetDlgItem(Wnd,ID_BTN_DISPLAY),Left,Top,Width,Height,False);
  AlignWindow(Wnd,waBottomRight,10);
end;

function LoadSkin(Wnd: hWnd; SkinName: String): Boolean;
var
  hDLL: THandle;
  SkinProc: TSkinProc;
  SkinStruct: TSkinStruct;
begin
  Result := False;
  hDLL := LoadLibrary(PChar(AppPath[appSkin] + SkinName));
  if hDLL <> 0 then begin
    SkinProc := GetProcAddress(hDLL,'DllSkin');
    if Assigned(SkinProc) then begin
      SkinProc(Wnd,SkinStruct);
      MoveSkinObj(Wnd,SkinStruct);
      ApplySkin(SkinName);
      FreeLibrary(hDLL);
      Result := True;
    end;
  end else
    DefaultSkin(Wnd,[sbForm,sbNext,sbPrev,sbDisplay]);
end;

procedure DefaultSkin(Wnd: hWnd; SkinBody: TSkinBody);
var
  BtnStrID: String;
  BtnText: String;
  hInst: LongWord;
  hDel: THandle;
  hBmp: hBitmap;
  Bmp: TBitmap;
  hChild: hWnd;
  MemDC: hDC;
  Rgn: hRgn;
begin
  hInst := GetWindowLong(Wnd,GWL_HINSTANCE);
  if (sbForm in SkinBody) then begin
    hDel := GetProp(Wnd,'BACKGROUND');
    if hDel <> 0 then DeleteObject(hDel);
    MemDC := CreateCompatibleDC(0);		// Load Background
    hBmp := LoadBitmap(hInst,'Background');
    GetObject(hBmp,SizeOf(Bmp),@Bmp);
    SelectObject(MemDC,hBmp);
    SetProp(Wnd,'BACKGROUND',MemDC);
    SetWindowRgn(Wnd,BmpToRgn(LoadBitmap(hInst,'Background'),RGB($FF,$00,$FF),$1),True);
    SetWindowPos(Wnd,0,0,0,Bmp.BmWidth,Bmp.BmHeight,SWP_NOMOVE);
  end;
  if (sbDisplay in SkinBody) then begin
    hChild := GetDlgItem(Wnd,ID_BTN_DISPLAY);
    Str(ID_BTN_DISPLAY,BtnStrID);
    BtnText := 'Btn'+ BtnStrID;
    hDel := GetProp(hChild,'NORMALBMP');
    if hDel <> 0 then DeleteObject(hDel);
    hDel := GetProp(hChild,'BTNRGN');
    if hDel <> 0 then DeleteObject(hDel);
    hBmp := LoadBitmap(hInst,PChar(BtnText));
    MemDC := CreateCompatibleDC(0);
    SelectObject(MemDC,hBmp);
    SetProp(hChild,'NORMALBMP',MemDC);
    SetProp(hChild,'OVERBMP',MemDC);
    SetProp(hChild,'PRESSBMP',MemDC);
    Rgn := BmpToRgn(LoadBitmap(hInst,PChar(BtnText)),RGB($FF,$0,$FF),$10);
    if (Rgn <> 0) then begin
      SetWindowRgn(hChild,Rgn,False);
      Rgn := BmpToRgn(LoadBitmap(hInst,PChar(BtnText)),RGB($FF,$0,$FF),$10);
      SetProp(hChild,'BTNRGN',Rgn);
    end;
  end;
  if (sbNext in SkinBody) then begin
    hChild := GetDlgItem(Wnd,ID_BTN_NEXT);
    Str(ID_BTN_NEXT,BtnStrID);                  // Normal
    BtnText := 'Btn'+ BtnStrID;
    hDel := GetProp(hChild,'NORMALBMP');
    if hDel <> 0 then DeleteObject(hDel);
    hDel := GetProp(hChild,'BTNRGN');
    if hDel <> 0 then DeleteObject(hDel);
    hBmp := LoadBitmap(hInst,PChar(BtnText));
    MemDC := CreateCompatibleDC(0);
    SelectObject(MemDC,hBmp);
    SetProp(hChild,'NORMALBMP',MemDC);
    Rgn := BmpToRgn(LoadBitmap(hInst,PChar(BtnText)),RGB($FF,$0,$FF),$10);
    if (Rgn <> 0) then begin
      SetWindowRgn(hChild,Rgn,False);
      Rgn := BmpToRgn(LoadBitmap(hInst,PChar(BtnText)),RGB($FF,$0,$FF),$10);
      SetProp(hChild,'BTNRGN',Rgn);
    end;
    BtnText := 'Btn'+ BtnStrID +'_Over';        // Over
    hDel := GetProp(hChild,'OVERBMP');
    if hDel <> 0 then DeleteObject(hDel);
    hBmp := LoadBitmap(hInst,PChar(BtnText));
    MemDC := CreateCompatibleDC(0);
    SelectObject(MemDC,hBmp);
    SetProp(hChild,'OVERBMP',MemDC);
    BtnText := 'Btn'+ BtnStrID +'_Press';        // Press
    hDel := GetProp(hChild,'PRESSBMP');
    if hDel <> 0 then DeleteObject(hDel);
    hBmp := LoadBitmap(hInst,PChar(BtnText));
    MemDC := CreateCompatibleDC(0);
    SelectObject(MemDC,hBmp);
    SetProp(hChild,'PRESSBMP',MemDC);
  end;
  if (sbPrev in SkinBody) then begin
    hChild := GetDlgItem(Wnd,ID_BTN_PREV);
    Str(ID_BTN_PREV,BtnStrID);                  // Normal
    BtnText := 'Btn'+ BtnStrID;
    hDel := GetProp(hChild,'NORMALBMP');
    if hDel <> 0 then DeleteObject(hDel);
    hDel := GetProp(hChild,'BTNRGN');
    if hDel <> 0 then DeleteObject(hDel);
    hBmp := LoadBitmap(hInst,PChar(BtnText));
    MemDC := CreateCompatibleDC(0);
    SelectObject(MemDC,hBmp);
    SetProp(hChild,'NORMALBMP',MemDC);
    Rgn := BmpToRgn(LoadBitmap(hInst,PChar(BtnText)),RGB($FF,$0,$FF),$10);
    if (Rgn <> 0) then begin
      SetWindowRgn(hChild,Rgn,False);
      Rgn := BmpToRgn(LoadBitmap(hInst,PChar(BtnText)),RGB($FF,$0,$FF),$10);
      SetProp(hChild,'BTNRGN',Rgn);
    end;    
    BtnText := 'Btn'+ BtnStrID +'_Over';        // Over
    hDel := GetProp(hChild,'OVERBMP');
    if hDel <> 0 then DeleteObject(hDel);
    hBmp := LoadBitmap(hInst,PChar(BtnText));
    MemDC := CreateCompatibleDC(0);
    SelectObject(MemDC,hBmp);
    SetProp(hChild,'OVERBMP',MemDC);
    BtnText := 'Btn'+ BtnStrID +'_Press';        // Press
    hDel := GetProp(hChild,'PRESSBMP');
    if hDel <> 0 then DeleteObject(hDel);
    hBmp := LoadBitmap(hInst,PChar(BtnText));
    MemDC := CreateCompatibleDC(0);
    SelectObject(MemDC,hBmp);
    SetProp(hChild,'PRESSBMP',MemDC);
  end;
end;

procedure SetDisplay(Wnd: hWnd; BmpName: String);
var
  hInst: LongWord;
  hBmp: hBitmap;
  Bmp: TBitmap;
  hChild: hWnd;
  TempDC: hDC;
  MemDC: hDC;
  R: TRect;
begin
  hInst := GetWindowLong(Wnd,GWL_HINSTANCE);
  hBmp := LoadImage(hInst,PChar(BmpName),IMAGE_BITMAP,0,0,LR_LOADFROMFILE);
  if hBmp <> 0 then begin
    GetObject(hBmp,SizeOf(Bmp),@Bmp);
    TempDC := CreateCompatibleDC(0);
    SelectObject(TempDC,hBmp);
    hChild := GetDlgItem(Wnd,ID_BTN_DISPLAY);
    MemDC := GetProp(hChild,'NORMALBMP');
    if MemDC <> 0 then begin
      StretchBlt(MemDC,0,0,60,66,TempDC,0,0,Bmp.bmWidth,Bmp.bmHeight,SRCCOPY);
      ApplyEffect(hChild,GetProp(hChild,'EFFECT'),MemDC);
      GetClientRect(hChild,R); InvalidateRect(hChild,@R,False);
      SetProp(hChild,'OVERBMP',MemDC);
      SetProp(hChild,'PRESSBMP',MemDC);
    end;
    DeleteObject(TempDC);
  end;
end;

end.
