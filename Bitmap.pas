unit Bitmap;

interface

uses
  Windows;

  function BmpToRgn(BmpHandle: hBitmap; TransColor: TColorRef; Tolerance: Byte): hRgn;

implementation

function BmpToRgn(BmpHandle: hBitmap; TransColor: TColorRef; Tolerance: Byte): hRgn;
const
  ALLOC_UNIT = 100;
var
  B: Byte;
  LR,LG,LB: Byte;
  HR,HG,HB: Byte;
  X,Y,X0: LongInt;
  MaxRects: DWord;
  pBits32: Pointer;
  MemDC,TempDC: hDC;
  BmpInfo: TBitmapInfo;
  hOldObj,hOldObj1: hGDIObj;
  Bmp,Bmp32: TBitmap;
  hBmp32: hBitmap;
  pData: PRgnData;
  hData: hGlobal;
  p32: PByte;
  p: PLongInt;
  pR: PRect;
  Rgn: hRgn;
begin
  Result := 0;
  if (BmpHandle <> 0) then begin
    MemDC := CreateCompatibleDC(0);
    if (MemDC <> 0) then begin
      GetObject(BmpHandle,SizeOf(Bmp),@Bmp);
      with BmpInfo.bmiHeader do begin
        biSize          := SizeOf(BitmapInfoHeader);
        biWidth         := Bmp.bmWidth;
        biHeight        := Bmp.bmHeight;
        biPlanes        := 1;
        biBitCount      := 32;
        biCompression   := BI_RGB;
        biSizeImage     := 0;
        biXPelsPerMeter := 0;
        biYPelsPerMeter := 0;
        biClrUsed       := 0;
        biClrImportant  := 0;
      end;
      hBmp32 := CreateDIBSection(MemDC,BmpInfo,DIB_RGB_COLORS,pBits32,0,0);
      if (hBmp32 <> 0) then begin
        hOldObj := SelectObject(MemDC,hBmp32);
        TempDC := CreateCompatibleDC(0);
        hOldObj1 := SelectObject(TempDC,BmpHandle);
        BitBlt(MemDC,0,0,Bmp.bmWidth,Bmp.bmHeight,TempDC,0,0,SRCCOPY);
        SelectObject(TempDC,hOldObj1);
        DeleteObject(TempDC);
        GetObject(hBmp32,SizeOf(Bmp32),@Bmp32);
        while (Bmp32.bmWidthBytes mod 4) > 0 do
          Inc(Bmp32.bmWidthBytes);
        MaxRects := ALLOC_UNIT;
        hData := GlobalAlloc(GMEM_MOVEABLE,SizeOf(TRgnDataHeader) + (SizeOf(TRect) * MaxRects));
        pData := GlobalLock(hData);
        pData^.rdh.dwSize := SizeOf(TRgnDataHeader);
        pData^.rdh.iType := RDH_RECTANGLES;
        pData^.rdh.nCount := 0;
        pData^.rdh.nRgnSize := 0;
        SetRect(pData^.rdh.rcBound,MaxInt,MaxInt,0,0);
        LR := GetRValue(TransColor);
        LG := GetGValue(TransColor);
        LB := GetBValue(TransColor);
        if (LR + Tolerance > $FF) then HR := $FF
          else HR := LR + Tolerance;
        if (LG + Tolerance > $FF) then HG := $FF
          else HG := LG + Tolerance;
        if (LB + Tolerance > $FF) then HB := $FF
          else HB := LB + Tolerance;
        p32 := Bmp32.bmBits;
        Inc(PChar(p32),LongInt(bmp32.bmHeight - 1) * LongInt(bmp32.bmWidthBytes));
        for Y := 0 to Bmp.bmHeight-1 do begin
          X := -1;
          while (X+1 < Bmp.bmWidth) do begin
            Inc(X);
            X0 := X;
            p := PLongInt(p32);
            Inc(PChar(p), X * SizeOf(LongInt));
            while (X < Bmp.bmWidth) do begin
              B := GetBValue(p^);
              if (B >= LR) and (B <= HR) then begin
                B := GetGValue(p^);
                if (B >= LG) and (B <= HG) then begin
                  B := GetRValue(p^);
                  if (B >= LB) and (B <= HB) then
                    Break;
                end;
              end;
              Inc(PChar(P),SizeOf(LongInt));
              Inc(X);
            end;
            if (X > X0) then begin
              if (pData^.rdh.nCount >= MaxRects) then begin
                GlobalUnlock(hData);
                Inc(MaxRects,ALLOC_UNIT);
                hData := GlobalReAlloc(hData,SizeOf(TRgnDataHeader) + SizeOf(TRect) * MaxRects,GMEM_MOVEABLE);
                pData := GlobalLock(hData);
              end;
              {$R-}
              pr := @pData^.Buffer[pData^.rdh.nCount * SizeOf(TRect)];
              {$R+}
              SetRect(pr^,X0,Y,X,Y+1);
              if (X0 < pData^.rdh.rcBound.Left) then
                pData^.rdh.rcBound.Left := X0;
              if (Y < pData^.rdh.rcBound.Top) then
                pData^.rdh.rcBound.Top := Y;
              if (X > pData^.rdh.rcBound.Right) then
                pData^.rdh.rcBound.Left := X;
              if (Y+1 > pData^.rdh.rcBound.Bottom) then
                pData^.rdh.rcBound.Bottom := Y+1;
              Inc(pData^.rdh.nCount);
              if (pData^.rdh.nCount = 2000) then begin
                Rgn := ExtCreateRegion(nil,SizeOf(TRgnDataHeader) + (SizeOf(TRect)*MaxRects),pData^);
                if (Result <> 0) then begin
                  CombineRgn(Result,Result,Rgn,RGN_OR);
                  DeleteObject(Rgn);
                end else
                  Result := Rgn;
                pData^.rdh.nCount := 0;
                SetRect(pData^.rdh.rcBound,MaxInt,MaxInt,0,0);
              end;
            end;
          end;
          Dec(PChar(p32),Bmp32.bmWidthBytes);
        end;
        Rgn := ExtCreateRegion(nil,SizeOf(TRgnDataHeader) + (SizeOf(TRect) * MaxRects),pData^);
        if (Result <> 0) then begin
          CombineRgn(Result,Result,Rgn,RGN_OR);
          DeleteObject(Rgn);
        end else
          Result := Rgn;
        GlobalFree(hData);
        SelectObject(MemDc,hOldObj);
        DeleteObject(hBmp32);
      end;
      DeleteDC(MemDC);
    end;
    DeleteObject(BmpHandle);
  end;
end;

end.