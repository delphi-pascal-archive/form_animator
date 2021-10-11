unit GlBitmap;

interface

uses
  Windows,Classes,OpenGl,GlCanvas,Graphics;

type
  TGlBitmap=class(TGraphic)
  private
    FWidth,FHeight:Integer;
    FCanvas:TGlCanvas;
    FPixelFormat: TGlPixelFormat;
    procedure SetPixelFormat(const Value: TGlPixelFormat);
  protected
    procedure Allocate;
    procedure Unallocate;
    function Allocated:Boolean;

    function GetEmpty:Boolean;override;

    function GetHeight:Integer;override;
    function GetWidth:Integer;override;
    procedure SetHeight(Value:Integer);override;
    procedure SetWidth(Value:Integer);override;
  public
    constructor Create;override;

    procedure Draw(ACanvas:TCanvas;const Rect:TRect);overload;override;
    procedure Draw(DestDC:HDC;const DestRect:TRect);reintroduce;overload;
    procedure StretchDraw(SrcRect:TRect;DestDC:HDC;DestRect:TRect);
    procedure SubDraw(SrcRect:TRect;DestDC:HDC;DestX,DestY:Integer);overload;
    procedure SubDraw(SrcX,SrcY,Width,Height:Integer;DestDC:HDC;DestX,DestY:Integer);overload;

    procedure LoadFromStream(Stream:TStream);override;
    procedure SaveToStream(Stream:TStream);override;
    procedure LoadFromClipboardFormat(AFormat:Word;AData:THandle;APalette:HPALETTE);override;
    procedure SaveToClipboardFormat(var AFormat:Word;var AData:THandle;var APalette:HPALETTE);override;

    property Canvas:TGlCanvas read FCanvas;

    property PixelFormat:TGlPixelFormat read FPixelFormat write SetPixelFormat;

    destructor Destroy;override;
  end;

implementation

{ TGlBitmap }

procedure TGlBitmap.Allocate;
begin
  if not (Empty or Allocated) then
    case FCanvas.GetCanvasType of
      ctMemoryBitmap:TDIBCanvas(FCanvas).CreateContext(FWidth,FHeight,PixelFormat);
      ctPBuffer:TPBufferCanvas(FCanvas).CreateContext(FWidth,FHeight,PixelFormat);
    end;
end;

function TGlBitmap.Allocated: Boolean;
begin
  Result:=False;
  case FCanvas.GetCanvasType of
    ctMemoryBitmap:;
    ctPBuffer:Result:=TPBufferCanvas(FCanvas).PBufferARB<>0;
  end;
end;

constructor TGlBitmap.Create;
begin
  inherited;
  FPixelFormat:=TGlPixelFormat.Create;
  if GNullWindowedCanvas.ARB_pbuffer_Present then
    FCanvas:=TPBufferCanvas.Create
  else
    FCanvas:=TDIBCanvas.Create;
end;

destructor TGlBitmap.Destroy;
begin
  Unallocate;
  FCanvas.Destroy;
  FPixelFormat.Destroy;
  inherited;
end;

procedure TGlBitmap.Draw(ACanvas: TCanvas; const Rect: TRect);
begin
  Draw(ACanvas.Handle,Rect);
end;

procedure TGlBitmap.Draw(DestDC: HDC; const DestRect: TRect);
begin
  StretchDraw(Rect(0,0,FWidth,FHeight),DestDC,DestRect);
end;

function TGlBitmap.GetEmpty: Boolean;
begin
  Result:=(FWidth=0) or (FHeight=0);
end;

function TGlBitmap.GetHeight: Integer;
begin
  Result:=FHeight;
end;

function TGlBitmap.GetWidth: Integer;
begin
  Result:=FWidth;
end;

procedure TGlBitmap.LoadFromClipboardFormat(AFormat: Word; AData: THandle;
  APalette: HPALETTE);
begin
  inherited;

end;

procedure TGlBitmap.LoadFromStream(Stream: TStream);
begin
  inherited;

end;

procedure TGlBitmap.SaveToClipboardFormat(var AFormat: Word;
  var AData: THandle; var APalette: HPALETTE);
begin
  inherited;

end;

procedure TGlBitmap.SaveToStream(Stream: TStream);
begin
  inherited;

end;

procedure TGlBitmap.SetHeight(Value: Integer);
begin
  if FHeight<>Value then begin
    Unallocate;
    FHeight:=Value;
    Allocate;
  end;
end;

procedure TGlBitmap.SetPixelFormat(const Value: TGlPixelFormat);
begin
  FPixelFormat := Value;
end;

procedure TGlBitmap.SetWidth(Value: Integer);
begin
  if FWidth<>Value then begin
    Unallocate;
    FWidth:=Value;
    Allocate;
  end;
end;

procedure TGlBitmap.StretchDraw(SrcRect: TRect; DestDC: HDC;
  DestRect: TRect);
var
  w,h,n:Integer;
  BMI:TBitmapInfo;
  Bits:Pointer;
begin
  if Empty then
    Exit;
  FCanvas.Lock;
  try
    w:=SrcRect.Right-SrcRect.Left;
    h:=SrcRect.Bottom-SrcRect.Top;
    case FCanvas.GetCanvasType of
      ctPBuffer:begin
        ZeroMemory(@BMI,SizeOf(BMI));
        with BMI.bmiHeader do begin
          biSize:=SizeOf(TBitmapInfoHeader);
          biWidth:=w;
          biHeight:=h;
          biPlanes:=1;
          biBitCount:=24;
          biCompression:=BI_RGB;
        end;
        n:=Align32(w*24)*h;
        WinGetMem(Bits,n);
        glReadPixels(SrcRect.Left,FHeight-SrcRect.Top-h,w,h,GL_BGR,GL_UNSIGNED_BYTE,Bits);
        if (w=DestRect.Right-DestRect.Left) and (h=DestRect.Bottom-DestRect.Top) then
          SetDIBitsToDevice(DestDC,DestRect.Left,DestRect.Top,w,h,0,0,0,h,Bits,BMI,DIB_RGB_COLORS)
        else
          StretchDIBits(DestDC,DestRect.Left,DestRect.Top,DestRect.Right-DestRect.Left,DestRect.Bottom-DestRect.Top,0,0,w,h,Bits,BMI,DIB_RGB_COLORS,SRCCOPY);
        WinFreeMem(Bits);
      end;
      ctMemoryBitmap:with TPBufferCanvas(FCanvas) do begin
        if (w=DestRect.Right-DestRect.Left) and (h=DestRect.Bottom-DestRect.Top) then
          BitBlt(DestDC,DestRect.Left,DestRect.Top,w,h,DC,SrcRect.Left,SrcRect.Top,SRCCOPY)
        else
          StretchBlt(DestDC,DestRect.Left,DestRect.Top,DestRect.Right-DestRect.Left,DestRect.Bottom-DestRect.Top,DC,SrcRect.Left,SrcRect.Top,w,h,SRCCOPY);
        GdiFlush;  
      end;
    end;
  finally
    FCanvas.Unlock;
  end;
end;

procedure TGlBitmap.SubDraw(SrcRect: TRect; DestDC: HDC; DestX,
  DestY: Integer);
begin
  StretchDraw(SrcRect,DestDC,Bounds(DestX,DestY,SrcRect.Right-SrcRect.Left,SrcRect.Bottom-SrcRect.Top));
end;

procedure TGlBitmap.SubDraw(SrcX, SrcY, Width, Height: Integer;
  DestDC: HDC; DestX, DestY: Integer);
begin
  StretchDraw(Bounds(SrcX,SrcY,Width,Height),DestDC,Bounds(DestX,DestY,Width,Height));
end;

procedure TGlBitmap.Unallocate;
begin
  if Allocated then
    case FCanvas.GetCanvasType of
      ctMemoryBitmap:TPBufferCanvas(FCanvas).DestroyContext;
      ctPBuffer:TPBufferCanvas(FCanvas).DestroyContext;
    end;
end;

initialization
  TPicture.RegisterFileFormat('.glb','GL bitmaps',TGLBitmap);
end.
