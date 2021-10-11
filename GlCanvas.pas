unit GlCanvas;

interface

uses
  SysUtils,Classes,Opengl,Windows,Contnrs,SyncObjs,Graphics,TLS,GlFont;

type
  HPBUFFERARB=Integer;

  TGlCanvas=class;

  TGlWindowedCanvasManager=class(TTLSObject)
  private
    FSection:TCriticalSection;
    FList:TObjectList;
  public
    constructor Create;

    procedure LockCanvas(c:TGlCanvas);

    procedure UnLockCanvas(c:TGlCanvas);

    destructor Destroy;override;
  end;

  EGlError=class(Exception)
  public
    constructor CreateCode(e:Cardinal);
  end;

  TGlColor=packed record
    R,G,B,A:glFloat;
  end;

  TGlSwapMethod=(smUndefined,smCopy,smExchange);
  TGlAcceleration=(aDontCare,aFull,aGeneric,aNone);

  TGlPixelFormat=class(TPersistent)
  private
    FDoubleBuffered: Boolean;
    FDesiredDepthBits: Byte;
    FDesiredAlphaBits: Byte;
    FDesiredStencilBits: Byte;
    FDesiredSwapMethod: TGlSwapMethod;
    FOnChange: TNotifyEvent;
    FDesiredAcceleration: TGlAcceleration;
    FDesiredAntialiasingLevel: Byte;

    procedure SetDesiredAlphaBits(const Value: Byte);             
    procedure SetDesiredDepthBits(const Value: Byte);             
    procedure SetDoubleBuffered(const Value: Boolean);            
    procedure SetDesiredStencilBits(const Value: Byte);           
    procedure SetDesiredSwapMethod(const Value: TGlSwapMethod);
    procedure SetDesiredAcceleration(const Value: TGlAcceleration);
    procedure SetDesiredAntialiasingLevel(const Value: Byte);
    procedure SetOnChange(const Value: TNotifyEvent);
  protected
    procedure doChange;
  public
    constructor Create;

    procedure Assign(Source:TPersistent);override;

    property OnChange:TNotifyEvent read FOnChange write SetOnChange;
  published
    property DesiredAlphaBits:Byte read FDesiredAlphaBits write SetDesiredAlphaBits;               //Desired alpha bits
    property DesiredDepthBits:Byte read FDesiredDepthBits write SetDesiredDepthBits;               //Desired depth bits
    property DesiredStencilBits:Byte read FDesiredStencilBits write SetDesiredStencilBits;         //Desired double buffer
    property DoubleBuffered:Boolean read FDoubleBuffered write SetDoubleBuffered;                  //Desired stencil bits
    property DesiredSwapMethod:TGlSwapMethod read FDesiredSwapMethod write SetDesiredSwapMethod;   //Desired swap method (not all methods are supported by drivers)
    property DesiredAcceleration:TGlAcceleration read FDesiredAcceleration write SetDesiredAcceleration;
    property DesiredAntialiasingLevel:Byte read FDesiredAntialiasingLevel write SetDesiredAntialiasingLevel;
  end;

  TCanvasType=(ctWindow,ctMemoryBitmap,ctPBuffer);

  TGlCanvas=class
  private
    FSection:TCriticalSection;
    FPFD:TPixelFormatDescriptor;
    FLockCount:Cardinal;
    FGlExtensions,FWGLExtensions:string;
    FFont: TGlFont;

    function GetAlphaBits: Byte;virtual;
    function GetColorBits: Byte;virtual;
    function GetDepthBits: Byte;virtual;
    function GetDoubleBuffered: Boolean;virtual;
    function GetStencilBits: Byte;virtual;
    function GetSwapMethod: TGlSwapMethod;virtual;
    procedure SetFont(const Value: TGlFont);
    function GetAcceleration: TGlAcceleration;
    function GetAntiAliasingLevel: Byte;
  protected
    FGLRC:HGLRC;
    FDC:HDC;
    glAddSwapHintRectWIN:procedure(x,y:Glint;width,height:GLsizei);stdcall;
    wglGetExtensionsStringARB:function(DC:HDC):PChar;stdcall;

    procedure ShareLists(Format:TGlPixelFormat);virtual;

    procedure MakeCurrent;virtual;
    procedure UnMakeCurrent;virtual;

    procedure CreateContext(Format:TGlPixelFormat);virtual;
    procedure DestroyContext;virtual;

    procedure MakePFD(Format:TGlPixelFormat);
  public
    GL_ARB_texture_non_power_of_two_Present:Boolean;

    constructor Create;

    class function GetCanvasType:TCanvasType;virtual;abstract;
    function GetDisplayListOwner:TGlCanvas;virtual;

    property SupportedGLExtensions:string read FGLExtensions;
    property SupportedWGlExtensions:string read FWGLExtensions;

    function LoadExtension(Name:string;ProcNames:array of string;ProcAddresses:array of PPointer):Boolean;  //Use to load non-standard gl or wgl extensions
    function IsExtensionSupported(Name:string):Boolean;
    function IsGLExtensionSupported(Name:string):Boolean;
    function IsWGLExtensionSupported(Name:string):Boolean;

    property ColorBits:Byte read GetColorBits;                  //Actual color bits
    property AlphaBits:Byte read GetAlphaBits;                  //Actual alpha bits
    property DepthBits:Byte read GetDepthBits;                  //Actual depth bits
    property StencilBits:Byte read GetStencilBits;              //Actual stencil bits
    property DoubleBuffered:Boolean read GetDoubleBuffered;     //If actually double buffered
    property SwapMethod:TGlSwapMethod read GetSwapMethod;       //Actual swap method
    property Acceleration:TGlAcceleration read GetAcceleration; //Type of acceleration (none, generic, full, unknown)
    property AntiAliasingLevel:Byte read GetAntiAliasingLevel;  //Antialiasing level

    property Font:TGlFont read FFont write SetFont;             //GL font

    procedure MakeViewPort(Rect:TRect;ClientHeight:Integer;ClipRect:PRect=nil;BorderWidth:Integer=0);overload;
    procedure MakeViewPort(Width,Height:Integer);overload;

    procedure Lock;       //Use before painting on the canvas
    procedure Unlock;     //MUST be called after each call to Lock

    destructor Destroy;override;
  end;

  TGlWindowedCanvas=class(TGlCanvas)
  private
  protected
  public
    class function GetCanvasType:TCanvasType;override;

    procedure CreateContext(Handle:HWND;Format:TGlPixelFormat);reintroduce;overload;virtual;//DO NOT CALL DIRECTLY (used internally)
    procedure DestroyContext(Handle:HWND);reintroduce;virtual;                              //DO NOT CALL DIRECTLY (used internally)

    destructor Destroy;override;
  end;

  TNullWindowedCanvas=class(TGlWindowedCanvas)
  private
    FWND:HWND;
    FGLRC2:HGLRC;
    FAtom:ATOM;

    wglGetPixelFormatAttribivARB:function(DC:HDC;iPixelFormat,iLayerPlane:Integer;nAttributes:UINT;const piAttributes,piValues:PInteger):BOOL;stdcall;
    wglGetPixelFormatAttribfvARB:function(DC:HDC;iPixelFormat,iLayerPlane:Integer;nAttributes:UINT;const piAttributes,piValues:PInteger;pfValues:PSingle):BOOL;stdcall;
    wglChoosePixelFormatARB:function(DC:HDC;const piAttribIList:PInteger;const pfAttribFList:PSingle;nMaxFormats:UINT;piFormats:PInteger;nNumFormats:PUINT):BOOL;stdcall;

    wglCreatePbufferARB:function(DC:HDC;iPixelFormat,iWidth,iHeight:Integer;const piAttribList:PInteger):HPBUFFERARB;stdcall;
    wglGetPbufferDCARB:function(hPbuffer:HPBUFFERARB):HDC;stdcall;
    wglReleasePbufferDCARB:function(hPbuffer:HPBUFFERARB;DC:HDC):Integer;stdcall;
    wglDestroyPbufferARB:function(hPbuffer:HPBUFFERARB):BOOL;stdcall;
    wglQueryPbufferARB:function(hPbuffer:HPBUFFERARB;iAttribute:Integer;piValue:PInteger):BOOL;stdcall;
  protected
  public
    ARB_extensions_string_Present,ARB_pbuffer_Present,ARB_pixel_format_Present,ARB_multisample_Present:Boolean;

    property DC:HDC read FDC;

    constructor Create;

    procedure CreateContext(Handle:HWND;Format:TGlPixelFormat);override;
    procedure DestroyContext(Handle:HWND);override;

    destructor Destroy;override;
  end;

  TPBufferCanvas=class(TGlCanvas)
  private
    FPBufferARB:HPBUFFERARB;
  public
    class function GetCanvasType:TCanvasType;override;

    property DC:HDC read FDC;
    property PBufferARB:HPBUFFERARB read FPBufferARB;

    procedure CreateContext(Width,Height:Integer;Format:TGlPixelFormat);reintroduce;overload;virtual; //DO NOT CALL DIRECTLY (used internally)
    procedure DestroyContext;override;                                                                //DO NOT CALL DIRECTLY (used internally)
  end;

  TNullDIBCanvas=class;

  TDIBCanvas=class(TGlCanvas)
  private
    FDIB:HBITMAP;
    FBits:Pointer;
    FOldDC:HDC;
    FOwner:TNullDIBCanvas;
  protected
    procedure ShareLists(Format:TGlPixelFormat);override;

    procedure MakeCurrent;override;
    procedure UnMakeCurrent;override;
  public
    class function GetCanvasType:TCanvasType;override;
    function GetDisplayListOwner:TGlCanvas;override;

    procedure CreateContext(Width,Height:Integer;Format:TGlPixelFormat);reintroduce;overload;virtual; //DO NOT CALL DIRECTLY (used internally)
    procedure DestroyContext;override;                                                                //DO NOT CALL DIRECTLY (used internally)
  end;

  TNullDIBCanvas=class(TDIBCanvas)
  private
    FGLRC2:HGLRC;
  protected
    procedure ShareLists(Format:TGlPixelFormat);override;
  public
    constructor Create(Format:TGlPixelFormat);

    destructor Destroy;override;
  end;

  TPixelFormatMapCost=function(ID,Desired,Proposed:Integer;CanvasType:TCanvasType):Integer;

var
  GCanvasManager:TGlWindowedCanvasManager;
  GNullWindowedCanvas:TNullWindowedCanvas=nil;
  GNullDIBCanvasList:TObjectList=nil;

const
  WGL_NUMBER_PIXEL_FORMATS_ARB      = $2000;
  WGL_DRAW_TO_WINDOW_ARB            = $2001;
  WGL_DRAW_TO_BITMAP_ARB            = $2002;
  WGL_DRAW_TO_PBUFFER_ARB           = $202D;
  WGL_ACCELERATION_ARB              = $2003;
  WGL_NEED_PALETTE_ARB              = $2004;
  WGL_NEED_SYSTEM_PALETTE_ARB       = $2005;
  WGL_SWAP_LAYER_BUFFERS_ARB        = $2006;
  WGL_SWAP_METHOD_ARB	              = $2007;
  WGL_NUMBER_OVERLAYS_ARB           = $2008;
  WGL_NUMBER_UNDERLAYS_ARB          = $2009;
  WGL_TRANSPARENT_ARB	              = $200A;
  WGL_TRANSPARENT_RED_VALUE_ARB     = $2037;
  WGL_TRANSPARENT_GREEN_VALUE_ARB   = $2038;
  WGL_TRANSPARENT_BLUE_VALUE_ARB    = $2039;
  WGL_TRANSPARENT_ALPHA_VALUE_ARB   = $203A;
  WGL_TRANSPARENT_INDEX_VALUE_ARB   = $203B;
  WGL_SHARE_DEPTH_ARB               = $200C;
  WGL_SHARE_STENCIL_ARB             = $200D;
  WGL_SHARE_ACCUM_ARB		            = $200E;
  WGL_SUPPORT_GDI_ARB		            = $200F;
  WGL_SUPPORT_OPENGL_ARB	          = $2010;
  WGL_DOUBLE_BUFFER_ARB 	          = $2011;
  WGL_STEREO_ARB		                = $2012;
  WGL_PIXEL_TYPE_ARB		            = $2013;
  WGL_COLOR_BITS_ARB		            = $2014;
  WGL_RED_BITS_ARB		              = $2015;
  WGL_RED_SHIFT_ARB		              = $2016;
  WGL_GREEN_BITS_ARB		            = $2017;
  WGL_GREEN_SHIFT_ARB		            = $2018;
  WGL_BLUE_BITS_ARB		              = $2019;
  WGL_BLUE_SHIFT_ARB		            = $201A;
  WGL_ALPHA_BITS_ARB		            = $201B;
  WGL_ALPHA_SHIFT_ARB		            = $201C;
  WGL_ACCUM_BITS_ARB		            = $201D;
  WGL_ACCUM_RED_BITS_ARB	          = $201E;
  WGL_ACCUM_GREEN_BITS_ARB	        = $201F;
  WGL_ACCUM_BLUE_BITS_ARB	          = $2020;
  WGL_ACCUM_ALPHA_BITS_ARB	        = $2021;
  WGL_DEPTH_BITS_ARB		            = $2022;
  WGL_STENCIL_BITS_ARB		          = $2023;
  WGL_AUX_BUFFERS_ARB		            = $2024;

  WGL_SAMPLE_BUFFERS_ARB	          = $2041;
  WGL_SAMPLES_ARB		                = $2042;

  WGL_NO_ACCELERATION_ARB           = $2025;
  WGL_GENERIC_ACCELERATION_ARB      = $2026;
  WGL_FULL_ACCELERATION_ARB         = $2027;

  WGL_SWAP_EXCHANGE_ARB             = $2028;
  WGL_SWAP_COPY_ARB                 = $2029;
  WGL_SWAP_UNDEFINED_ARB            = $202A;

  WGL_TYPE_RGBA_ARB                 = $202B;
  WGL_TYPE_COLORINDEX_ARB           = $202C;

  GL_INTENSITY                      = $8049;
  GL_BGR                            = $80E0;
  GL_BGRA                           = $80E1;

  GL_TEXTURE_3D                     = $806F;

  GL_PROXY_TEXTURE_1D               = $8063;
  GL_PROXY_TEXTURE_2D               = $8064;
  GL_PROXY_TEXTURE_3D               = $8070;

  GL_UNPACK_SKIP_IMAGES             = $806D;
  GL_PACK_SKIP_IMAGES               = $806B;

  GL_PACK_IMAGE_HEIGHT              = $806C;
  GL_UNPACK_IMAGE_HEIGHT            = $806E;

  GL_MULTISAMPLE_ARB                = $809D;

function Align32(x:Integer):Integer;
function NextPowerOfTwo(x:Integer):Integer;

procedure WinGetMem(var P:Pointer;Size:DWord);
procedure WinFreeMem(P:Pointer);

procedure Initialize;
procedure Finalize;

procedure glCheckError;

function ColorToGlColor(c:TColor):TGlColor;

function ChoosePixelFormatEx(DC:HDC;Format:TGlPixelFormat;CanvasType:TCanvasType;MapCost:TPixelFormatMapCost=nil):Integer;

implementation

{$J+}

function Align32(x:Integer):Integer;
begin
  if x mod 32=0 then
    Result:=x div 8
  else
    Result:=(1+x div 32)*4;
end;

function NextPowerOfTwo(x:Integer):Integer;
begin
  Assert(x>0);
  Result:=1;
  while Result<x do
    Result:=2*Result;
end;

procedure WinGetMem(var p:Pointer;Size:Cardinal);
begin
  p:=VirtualAlloc(nil,Size,MEM_COMMIT or MEM_RESERVE,PAGE_READWRITE);
  if not Assigned(p) then
    RaiseLastOSError;
end;

procedure WinFreeMem(p:Pointer);
begin
  if not VirtualFree(p,0,MEM_RELEASE) then
    RaiseLastOSError;
end;

procedure Initialize;
begin
  GCanvasManager:=TGlWindowedCanvasManager.Create;
  GNullWindowedCanvas:=TNullWindowedCanvas.Create;
  GNullDIBCanvasList:=TObjectList.Create(True);
end;

procedure Finalize;
begin
  GNullDIBCanvasList.Free;
  GNullWindowedCanvas.Free;
  GCanvasManager.Free;
end;

procedure glCheckError;
var
  e:Cardinal;
begin
  e:=glGetError;
  if e<>GL_NO_ERROR then
    raise EGlError.CreateCode(e);
end;

function ColorToGlColor(c:TColor):TGlColor;
begin
  c:=ColorToRGB(c);
  Result.R:=Byte(c)/$FF;
  Result.G:=Byte(c shr 8)/$FF;
  Result.B:=Byte(c shr 16)/$FF;
  Result.A:=Byte(c shr 24)/$FF;
end;

function DefaultMapCost(ID,Desired,Proposed:Integer;CanvasType:TCanvasType):Integer;
begin
  Result:=0;
  case ID of
    0..2:if (ID=Integer(CanvasType)) and (Proposed=0) then Result:=$1000000;
    3..4:if Desired<>Proposed then Result:=$1000000;
    5:Result:=Abs(Desired-Proposed);
    6:if Desired<>0 then Result:=256*Abs(Desired-Proposed);
    7..9:if Proposed<Desired then begin if Proposed=0 then Result:=$10000 else Result:=Desired-Proposed end;
    10:if Desired<>0 then Result:=Abs(Proposed-Desired);
    11:Result:=Abs(Desired-Proposed);
    12:if Proposed<Desired then Result:=Desired-Proposed;
  end;
end;

function ChoosePixelFormatEx(DC:HDC;Format:TGlPixelFormat;CanvasType:TCanvasType;MapCost:TPixelFormatMapCost=nil):Integer;
const
  NFlags=13;
  NMaxFormats=$1000;
  Flags:array[0..NFlags-1] of Integer=(WGL_DRAW_TO_WINDOW_ARB,
                                       WGL_DRAW_TO_BITMAP_ARB,
                                       WGL_DRAW_TO_PBUFFER_ARB,

                                       WGL_PIXEL_TYPE_ARB,
                                       WGL_SUPPORT_OPENGL_ARB,
                                       WGL_DOUBLE_BUFFER_ARB,
                                       WGL_ACCELERATION_ARB,

                                       WGL_DEPTH_BITS_ARB,
                                       WGL_ALPHA_BITS_ARB,
                                       WGL_STENCIL_BITS_ARB,

                                       WGL_SWAP_METHOD_ARB,

                                       WGL_SAMPLE_BUFFERS_ARB,
                                       WGL_SAMPLES_ARB);
  FloatParams:array[0..0] of Single=(0);
var
  a,b,c,d,e,f:Integer;
  IntegerParams:array[0..2*NFlags] of Integer;
  IntegerFlags:array[0..NFlags] of Integer;
  Formats:array[0..NMaxFormats-1] of Integer;
  FlagMap:array[0..NFlags] of Integer;

  function GetFlagValue(ID:Integer):Integer;
  begin
    Result:=0;
    with Format do
      case ID of
        0..2:Result:=Integer(ID=Integer(CanvasType));
        3:Result:=WGL_TYPE_RGBA_ARB;
        4:Result:=Integer(GL_TRUE);
        5:Result:=Integer(FDoubleBuffered);
        6:case FDesiredAcceleration of
          aFull:Result:=WGL_FULL_ACCELERATION_ARB;
          aGeneric:Result:=WGL_GENERIC_ACCELERATION_ARB;
          aNone:Result:=WGL_NO_ACCELERATION_ARB;
        end;
        7:Result:=FDesiredDepthBits;
        8:Result:=FDesiredAlphaBits;
        9:Result:=FDesiredStencilBits;
        10:case FDesiredSwapMethod of
//          smUndefined:Result:=WGL_SWAP_UNDEFINED_ARB;      well... why set it!?
          smCopy:Result:=WGL_SWAP_COPY_ARB;
          smExchange:Result:=WGL_SWAP_EXCHANGE_ARB;
        end;
        11:Result:=Integer(FDesiredAntialiasingLevel>0);
        12:Result:=FDesiredAntialiasingLevel;
      end;
  end;
  
  function ValidFlag(ID:Integer):Boolean;
  begin
    Result:=True;
    case ID of
      11,12:Result:=GNullWindowedCanvas.ARB_multisample_Present;
    end;
  end;

  procedure DisplayFormat(Index:Integer);
  const
    n=11;
    T:array[0..n] of Integer=(WGL_COLOR_BITS_ARB,
                              WGL_DEPTH_BITS_ARB,
                              WGL_ALPHA_BITS_ARB,
                              WGL_STENCIL_BITS_ARB,
                              WGL_DOUBLE_BUFFER_ARB,
                              WGL_SWAP_METHOD_ARB,
                              WGL_ACCELERATION_ARB,
                              WGL_SUPPORT_OPENGL_ARB,
                              WGL_DRAW_TO_PBUFFER_ARB,
                              WGL_SAMPLE_BUFFERS_ARB,
                              WGL_SAMPLES_ARB,
                              WGL_ACCELERATION_ARB);
    U:array[0..n] of string=('WGL_COLOR_BITS_ARB',
                             'WGL_DEPTH_BITS_ARB',
                             'WGL_ALPHA_BITS_ARB',
                             'WGL_STENCIL_BITS_ARB',
                             'WGL_DOUBLE_BUFFER_ARB',
                             'WGL_SWAP_METHOD_ARB',
                             'WGL_ACCELERATION_ARB',
                             'WGL_SUPPORT_OPENGL_ARB',
                             'WGL_DRAW_TO_PBUFFER_ARB',
                             'WGL_SAMPLE_BUFFERS_ARB',
                             'WGL_SAMPLES_ARB',
                             'WGL_ACCELERATION_ARB');
  var
    a:Integer;
    V:array[0..n] of Integer;
    s:string;
  begin
    if not GNullWindowedCanvas.wglGetPixelFormatAttribivARB(DC,Index,0,High(T)+1,@T,@V) then
      raise EGlError.Create('Cannot query pixel format attrib');
    s:='';
    for a:=0 to n do
      s:=s+U[a]+' = '+IntToStr(V[a])+#13;
    MessageBox(0,PChar(s),nil,0);
  end;

begin
  if not Assigned(MapCost) then
    MapCost:=@DefaultMapCost;
  Result:=-1;
  with GNullWindowedCanvas do begin
    if not ARB_pixel_format_Present then
      Exit;
    ZeroMemory(@IntegerParams,SizeOf(IntegerParams));
    c:=0;
    for a:=0 to NFlags-1 do begin
      b:=GetFlagValue(a);
      if (b<>0) and ValidFlag(a) then begin
        IntegerParams[c]:=Flags[a];
        IntegerParams[c+1]:=b;
        Inc(c,2);
      end;
    end;
    if not wglChoosePixelFormatARB(DC,@IntegerParams,@FloatParams,NMaxFormats,@Formats,@a) then
      RaiseLastOSError;
    if a>0 then
      Result:=Formats[0]
    else begin
      d:=0;
      for a:=0 to NFlags-1 do
        if ValidFlag(a) then begin
          IntegerFlags[d]:=Flags[a];
          IntegerParams[d+NFlags]:=GetFlagValue(a);
          FlagMap[d]:=a;
          Inc(d);
        end;
      b:=0;
      if not wglChoosePixelFormatARB(DC,@b,@FloatParams,NMaxFormats,@Formats,@a) then
        RaiseLastOSError;
      c:=$10000;
      for b:=0 to a-1 do begin
        if not wglGetPixelFormatAttribivARB(DC,Formats[b],0,d,@IntegerFlags,@IntegerParams) then
          RaiseLastOSError;
        f:=0;
        for e:=0 to d-1 do
          f:=f+MapCost(FlagMap[e],IntegerParams[e+NFlags],IntegerParams[e],CanvasType);
        if f<c then begin
          Result:=Formats[b];
          c:=f;
        end;
      end;
//      MessageBox(0,PChar('ID : '+IntToStr(Result)+'  Cost: '+IntToStr(c)),nil,0);
//      DisplayFormat(Result);
    end;
  end;
end;

{ TGlWindowedCanvasManager }

constructor TGlWindowedCanvasManager.Create;
begin
  inherited;
  FSection:=TCriticalSection.Create;
  FList:=TObjectList.Create(True);
end;

destructor TGlWindowedCanvasManager.Destroy;
var
  a:Integer;
begin
  try
    for a:=0 to FList.Count-1 do
      with TObjectStack(FList[a]) do
        Assert(Count=0,'Canvas not unlocked');
  finally
    FList.Destroy;
    FSection.Destroy;
    inherited;
  end;
end;

procedure TGlWindowedCanvasManager.LockCanvas(c: TGlCanvas);
begin
  if Value=nil then begin
    Value:=TObjectStack.Create;
    FSection.Enter;
    try
      FList.Add(TObject(Value));
    finally
      FSection.Leave;
    end;
  end;
  with TObjectStack(Value) do begin
    if (Count=0) or (Peek<>c) then
      c.MakeCurrent;
    Push(c);
  end;
end;

procedure TGlWindowedCanvasManager.UnLockCanvas(c: TGlCanvas);
begin
  Assert(Value<>nil,'Attempt to unlock non-locked canvas');
  with TObjectStack(Value) do begin
    Assert((Count>0) and (Pop=c),'Attempt to unlock non-locked canvas');
    if Count=0 then
      c.UnMakeCurrent
    else begin
      if Peek<>c then begin
        c.UnMakeCurrent;
        with TGlWindowedCanvas(Peek) do
          wglMakeCurrent(FDC,FGLRC);
      end;
    end;
  end;
end;

{ EGlError }

constructor EGlError.CreateCode(e: Cardinal);
var
  s:string;
begin
  case e of
    GL_INVALID_ENUM:s:='Invalid enum value (GL_INVALID_ENUM)';
    GL_INVALID_VALUE:s:='Value out of range (GL_INVALID_VALUE)';
    GL_INVALID_OPERATION:s:='Operation not allowed (GL_INVALID_OPERATION)';
    GL_STACK_OVERFLOW:s:='Stack overflow (GL_STACK_OVERFLOW)';
    GL_STACK_UNDERFLOW:s:='Stack underflow (GL_STACK_UNDERFLOW)';
    GL_OUT_OF_MEMORY:s:='Out of memory (GL_OUT_OF_MEMORY)';
  else
    s:=Format('Unknown error ($%x)',[e]);
  end;
  inherited Create(s);
end;

{ TGlPixelFormat }

procedure TGlPixelFormat.Assign(Source: TPersistent);
begin
  inherited;
  if (FDoubleBuffered<>TGlPixelFormat(Source).FDoubleBuffered) or
     (FDesiredDepthBits<>TGlPixelFormat(Source).FDesiredDepthBits) or
     (FDesiredAlphaBits<>TGlPixelFormat(Source).FDesiredAlphaBits) or
     (FDesiredStencilBits<>TGlPixelFormat(Source).FDesiredStencilBits) or
     (FDesiredSwapMethod<>TGlPixelFormat(Source).FDesiredSwapMethod) then begin
    FDoubleBuffered:=TGlPixelFormat(Source).FDoubleBuffered;
    FDesiredDepthBits:=TGlPixelFormat(Source).FDesiredDepthBits;
    FDesiredAlphaBits:=TGlPixelFormat(Source).FDesiredAlphaBits;
    FDesiredStencilBits:=TGlPixelFormat(Source).FDesiredStencilBits;
    FDesiredSwapMethod:=TGlPixelFormat(Source).FDesiredSwapMethod;
    doChange;
  end;
end;

constructor TGlPixelFormat.Create;
begin
  inherited;
end;

procedure TGlPixelFormat.doChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TGlPixelFormat.SetDesiredAcceleration(
  const Value: TGlAcceleration);
begin
  if Value<>FDesiredAcceleration then begin
    FDesiredAcceleration := Value;
    doChange;
  end;
end;

procedure TGlPixelFormat.SetDesiredAlphaBits(const Value: Byte);
begin
  if Value<>FDesiredAlphaBits then begin
    FDesiredAlphaBits := Value;
    doChange;
  end;
end;

procedure TGlPixelFormat.SetDesiredAntialiasingLevel(const Value: Byte);
begin
  if Value<>FDesiredAntialiasingLevel then begin
    FDesiredAntialiasingLevel := Value;
    doChange;
  end;
end;

procedure TGlPixelFormat.SetDesiredDepthBits(const Value: Byte);
begin
  if Value<>FDesiredDepthBits then begin
    FDesiredDepthBits := Value;
    doChange;
  end;
end;

procedure TGlPixelFormat.SetDesiredStencilBits(const Value: Byte);
begin
  if Value<>FDesiredStencilBits then begin
    FDesiredStencilBits := Value;
    doChange;
  end;
end;

procedure TGlPixelFormat.SetDesiredSwapMethod(const Value: TGlSwapMethod);
begin
  if Value<>FDesiredSwapMethod then begin
    FDesiredSwapMethod := Value;
    doChange;
  end;
end;

procedure TGlPixelFormat.SetDoubleBuffered(const Value: Boolean);
begin
  if Value<>FDoubleBuffered then begin
    FDoubleBuffered := Value;
    doChange;
  end;
end;

procedure TGlPixelFormat.SetOnChange(const Value: TNotifyEvent);
begin
  FOnChange := Value;
end;

{ TGlCanvas }

constructor TGlCanvas.Create;
begin
  inherited;
  FFont:=TGlFont.Create(Self);//GetDisplayListOwner);
  FSection:=TCriticalSection.Create;
end;

procedure TGlCanvas.CreateContext(Format: TGlPixelFormat);
begin
  Assert(FGLRC=0,'Context already created');
  FGLRC:=wglCreateContext(FDC);
  if FGLRC=0 then
    RaiseLastOSError;
  ShareLists(Format);
  Lock;
  try
    FGLExtensions:=AnsiLowerCase(glGetString(GL_EXTENSIONS));
    LoadExtension('',['wglGetExtensionsStringARB'],[@@wglGetExtensionsStringARB]);
    if Assigned(wglGetExtensionsStringARB) then
      FWGLExtensions:=AnsiLowerCase(wglGetExtensionsStringARB(FDC));
    GL_ARB_texture_non_power_of_two_Present:=IsExtensionSupported('GL_ARB_texture_non_power_of_two');
    //LoadExtension('GL_WIN_swap_hint',['glAddSwapHintRectWIN'],[@@glAddSwapHintRectWIN]);
  finally
    Unlock;
  end;
end;

destructor TGlCanvas.Destroy;
begin

  inherited;
end;

procedure TGlCanvas.DestroyContext;
begin
  FSection.Enter;
  try
    try
      if (FGLRC<>0) and not wglDeleteContext(FGLRC) then
        RaiseLastOSError;
    finally
      FGLRC:=0;
    end;
  finally
    FSection.Leave;
  end;
end;

function TGlCanvas.GetAcceleration: TGlAcceleration;
begin
    Result:=aDontCare;
//  if GNullWindowedCanvas.ARB_pixel_format_Present then
//    Result:=aDontCare
end;

function TGlCanvas.GetAlphaBits: Byte;
begin
  Result:=FPFD.cAlphaBits;
end;

function TGlCanvas.GetAntiAliasingLevel: Byte;
begin
  Result:=0;
end;

function TGlCanvas.GetColorBits: Byte;
begin
  Result:=FPFD.cColorBits;
end;

function TGlCanvas.GetDepthBits: Byte;
begin
  Result:=FPFD.cDepthBits;
end;

function TGlCanvas.GetDoubleBuffered: Boolean;
begin
  Result:=FPFD.dwFlags and PFD_DOUBLEBUFFER=PFD_DOUBLEBUFFER;
end;

function TGlCanvas.GetStencilBits: Byte;
begin
  Result:=FPFD.cStencilBits;
end;

function TGlCanvas.GetSwapMethod: TGlSwapMethod;
begin
  Result:=smUndefined;
  if FPFD.dwFlags and PFD_SWAP_COPY=PFD_SWAP_COPY then
    Result:=smCopy;
  if FPFD.dwFlags and PFD_SWAP_EXCHANGE=PFD_SWAP_EXCHANGE then
    Result:=smExchange;
end;

function TGlCanvas.IsExtensionSupported(Name: string): Boolean;
begin
  Result:=IsGlExtensionSupported(Name) or IsWGlExtensionSupported(Name);
end;

function TGlCanvas.IsGLExtensionSupported(Name: string): Boolean;
begin
  Result:=Pos(AnsiLowerCase(Name),FGLExtensions)>0;
end;

function TGlCanvas.IsWGLExtensionSupported(Name: string): Boolean;
begin
  Result:=Pos(AnsiLowerCase(Name),FWGLExtensions)>0;
end;

function TGlCanvas.LoadExtension(Name: string; ProcNames: array of string;
  ProcAddresses: array of PPointer): Boolean;
var
  a:Integer;
begin
  Lock;
  try
    Assert(High(ProcNames)=High(ProcAddresses),'Dimensions mismatch');
    Result:=IsExtensionSupported(Name) or (Name='');
    for a:=0 to High(ProcNames) do 
      ProcAddresses[a]^:=wglGetProcAddress(PChar(ProcNames[a]));
  finally
    Unlock;
  end;
end;

procedure TGlCanvas.Lock;
begin
  FSection.Enter;
  Assert(FGLRC<>0,'Context not created');
  Inc(FLockCount);
  GCanvasManager.LockCanvas(Self);
end;

procedure TGlCanvas.MakeCurrent;
begin
  if not wglMakeCurrent(FDC,FGLRC) then
    RaiseLastOSError;
end;

procedure TGlCanvas.MakeViewPort(Rect: TRect; ClientHeight: Integer;
  ClipRect: PRect; BorderWidth: Integer);
begin
  glViewport(Rect.Left,ClientHeight-Rect.Bottom,Rect.Right-Rect.Left,Rect.Bottom-Rect.Top);
  if Assigned(ClipRect) then
    with ClipRect^ do begin
      if Assigned(glAddSwapHintRectWIN) then
        glAddSwapHintRectWIN(Left,ClientHeight-Bottom,Right-Left,Bottom-Top)
      else begin
        glScissor(Left,ClientHeight-Bottom,Right-Left,Bottom-Top);
        glEnable(GL_SCISSOR_TEST);
      end;
    end;
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity;
  with Rect do
    gluOrtho2D(Rect.Left,Rect.Right,Rect.Bottom,Rect.Top);
end;

procedure TGlCanvas.MakePFD(Format:TGlPixelFormat);
var
  c:Integer;
begin
  FPFD.nSize:=SizeOf(FPFD);
  FPFD.nVersion:=1;
  FPFD.dwFlags:=PFD_SUPPORT_OPENGL;
  case GetCanvasType of
    ctWindow:FPFD.dwFlags:=FPFD.dwFlags or PFD_DRAW_TO_WINDOW;
    ctMemoryBitmap:FPFD.dwFlags:=FPFD.dwFlags or PFD_DRAW_TO_BITMAP or PFD_SUPPORT_GDI;
    ctPBuffer:Assert(False,'Invalid use of MakePFD: cannot use standard method for PBuffer canvas');
  end;
  FPFD.iPixelType:=PFD_TYPE_RGBA or PFD_MAIN_PLANE;
  with Format do
    try
      if Assigned(Format) and DoubleBuffered then
        FPFD.dwFlags:=FPFD.dwFlags or PFD_DOUBLEBUFFER;
      if Assigned(Format) and (FDesiredDepthBits=0) then
        FPFD.dwFlags:=FPFD.dwFlags or PFD_DEPTH_DONTCARE;
      if Assigned(Format) then
        case FDesiredSwapMethod of
          smCopy:FPFD.dwFlags:=FPFD.dwFlags or PFD_SWAP_COPY;
          smExchange:FPFD.dwFlags:=FPFD.dwFlags or PFD_SWAP_EXCHANGE;
        end;
      FPFD.cColorBits:=GetDeviceCaps(FDC,BITSPIXEL);
      if Assigned(Format) then begin
        FPFD.cDepthBits:=FDesiredDepthBits;
        FPFD.cAlphaBits:=FDesiredAlphaBits;
        FPFD.cStencilBits:=FDesiredStencilBits;
      end;
      c:=0;
      if Assigned(GNullWindowedCanvas) and GNullWindowedCanvas.ARB_pixel_format_Present then
        c:=ChoosePixelFormatEx(FDC,Format,GetCanvasType);
      if c<=0 then
        c:=ChoosePixelFormat(FDC,@FPFD);
      if c<=0 then
        RaiseLastOSError;
      if not Windows.SetPixelFormat(FDC,c,@FPFD) then
        RaiseLastOSError;
      if not DescribePixelFormat(FDC,c,SizeOf(FPFD),FPFD) then
        RaiseLastOSError;
    except
      ZeroMemory(@FPFD,SizeOf(FPFD));
      raise;
    end;
end;

procedure TGlCanvas.MakeViewPort(Width, Height: Integer);
begin
  MakeViewPort(Rect(0,0,Width,Height),Height);
end;

procedure TGlCanvas.SetFont(const Value: TGlFont);
begin
  FFont := Value;
end;

procedure TGlCanvas.Unlock;
begin
  try
    Assert(FLockCount>0,'Canvas not locked');
    GCanvasManager.UnLockCanvas(Self);
  finally
    Dec(FLockCount);
    FSection.Leave;
  end;
end;

procedure TGlCanvas.UnMakeCurrent;
begin
  glCheckError;
  glFlush;
  if (FLockCount=1) and DoubleBuffered then begin
    if not SwapBuffers(FDC) then
      RaiseLastOSError;
  end;
  if FLockCount=1 then
    glFinish;
  if not wglMakeCurrent(FDC,0) then
    RaiseLastOSError;
end;

function TGlCanvas.GetDisplayListOwner: TGlCanvas;
begin
  Result:=GNullWindowedCanvas;
end;

procedure TGlCanvas.ShareLists(Format: TGlPixelFormat);
begin
  if Assigned(GNullWindowedCanvas) and not wglShareLists(GNullWindowedCanvas.FGLRC2,FGLRC) then
    RaiseLastOSError;
end;

{ TGlWindowedCanvas }

procedure TGlWindowedCanvas.CreateContext(Handle: HWND; Format: TGlPixelFormat);
begin
  FDC:=GetDC(Handle);
  if FDC=0 then
    RaiseLastOSError;
  MakePFD(Format);
  inherited CreateContext(Format);
end;

destructor TGlWindowedCanvas.Destroy;
begin
  Assert(FLockCount=0,'Canvas not unlocked');
  FSection.Destroy;
  FFont.Destroy;
  inherited;
end;

procedure TGlWindowedCanvas.DestroyContext(Handle: HWND);
begin
  FSection.Enter;
  try
    ZeroMemory(@FPFD,Sizeof(FPFD));
    inherited DestroyContext;
    if ReleaseDC(Handle,FDC)=0 then
      RaiseLastOSError;
    FDC:=0;
  finally
    FSection.Leave;
  end;
end;

class function TGlWindowedCanvas.GetCanvasType: TCanvasType;
begin
  Result:=ctWindow;
end;

{ TNullWindowedCanvas }

function NullWndProc(WND:HWND;uMsg:UINT;wParam:WPARAM;lParam:LPARAM):LRESULT;stdcall;
begin
  Result:=DefWindowProc(WND,uMsg,wParam,lParam);
end;

constructor TNullWindowedCanvas.Create;
var
  WCE:TWndClassEx;
begin
  inherited Create;
  ZeroMemory(@WCE,SizeOf(WCE));
  WCE.cbSize:=SizeOf(WCE);
  WCE.style:=CS_GLOBALCLASS or CS_OWNDC;
  WCE.lpfnWndProc:=@NullWndProc;
  WCE.hInstance:=HInstance;
  WCE.lpszClassName:='Null Gl window class';
  FAtom:=RegisterClassEx(WCE);
  if FAtom=0 then
    RaiseLastOSError;
  FWND:=CreateWindowEx(0,'Null Gl window class',nil,WS_CLIPSIBLINGS,0,0,1,1,0,0,HInstance,nil);
  if FWND=0 then
    RaiseLastOSError;
  CreateContext(FWND,nil);
end;

procedure TNullWindowedCanvas.CreateContext(Handle: HWND;
  Format: TGlPixelFormat);
begin
  inherited;
  FGLRC2:=wglCreateContext(FDC);
  if FGLRC2=0 then
    RaiseLastOSError;
  if not wglShareLists(FGLRC2,FGLRC) then
    RaiseLastOSError;
  Lock;
  ARB_extensions_string_Present:=Assigned(@wglGetExtensionsStringARB);
  ARB_pbuffer_Present:=LoadExtension('WGL_ARB_pbuffer',
                                     ['wglCreatePbufferARB','wglGetPbufferDCARB','wglReleasePbufferDCARB','wglDestroyPbufferARB','wglQueryPbufferARB'],
                                     [@@wglCreatePbufferARB,@@wglGetPbufferDCARB,@@wglReleasePbufferDCARB,@@wglDestroyPbufferARB,@@wglQueryPbufferARB]);
  ARB_pixel_format_Present:=LoadExtension('WGL_ARB_pixel_format',
                                          ['wglGetPixelFormatAttribivARB','wglGetPixelFormatAttribfvARB','wglChoosePixelFormatARB'],
                                          [@@wglGetPixelFormatAttribivARB,@@wglGetPixelFormatAttribfvARB,@@wglChoosePixelFormatARB]);
  ARB_multisample_Present:=IsExtensionSupported('ARB_multisample');
  Unlock;
end;

destructor TNullWindowedCanvas.Destroy;
begin
  DestroyContext(FWND);
  if not DestroyWindow(FWND) then
    RaiseLastOSError;
  if not UnregisterClass('Null Gl window class',HInstance) then
    RaiseLastOSError;
  inherited;
end;

procedure TNullWindowedCanvas.DestroyContext(Handle: HWND);
begin
  inherited;
  if not wglDeleteContext(FGLRC2) then
    RaiseLastOSError;
end;

{ TPBufferCanvas }

procedure TPBufferCanvas.CreateContext(Width, Height: Integer;
  Format: TGlPixelFormat);
var
  n:Integer;
  DC:HDC;
const
  EmptyIntegerParams:Integer=0;
begin
  GNullWindowedCanvas.Lock;
  try
    DC:=wglGetCurrentDC;
    n:=ChoosePixelFormatEx(DC,Format,ctPBuffer);
    if (n=-1) or not GNullWindowedCanvas.ARB_pbuffer_Present then
      raise EGlError.Create('Could not find required pixel format matching your system capabilities. Please update your graphic hardware drivers to continue using this feature.');
    FPBufferARB:=GNullWindowedCanvas.wglCreatePbufferARB(DC,n,Width,Height,@EmptyIntegerParams);
    if FPBufferARB=0 then
      raise EGlError.Create('Could not allocate sufficient graphic memory for off-screen use. Please update your graphic hardware drivers to continue using this feature.');
    FDC:=GNullWindowedCanvas.wglGetPbufferDCARB(FPBufferARB);
    if FDC=0 then
      raise EGlError.Create('Could not allocate sufficient graphic memory for off-screen use. Please update your graphic hardware drivers to continue using this feature.');
    inherited CreateContext(Format);
  finally
    GNullWindowedCanvas.UnLock;
  end;
end;

procedure TPBufferCanvas.DestroyContext;
begin
  FSection.Enter;
  try
    ZeroMemory(@FPFD,Sizeof(FPFD));
    try
      if (FDC<>0) and (GNullWindowedCanvas.wglReleasePbufferDCARB(FPBufferARB,FDC)<>1) then
        raise EGlError.Create('Error while releasing PBufferARB device context: '+SysErrorMessage(GetLastError));
    finally
      FDC:=0;
      try
        if (FPBufferARB<>0) and not GNullWindowedCanvas.wglDestroyPbufferARB(FPBufferARB) then
          raise EGlError.Create('Error while destroying PBufferARB: '+SysErrorMessage(GetLastError));
      finally
        FPBufferARB:=0;
      end;
    end;
    inherited DestroyContext;
  finally
    FSection.Leave;
  end;
end;

class function TPBufferCanvas.GetCanvasType: TCanvasType;
begin
  Result:=ctPBuffer;
end;

{ TDIBCanvas }

procedure TDIBCanvas.CreateContext(Width, Height: Integer;
  Format: TGlPixelFormat);
var
  BMI:TBitmapInfo;
  DC:HDC;
begin
  DC:=GetDC(GetDesktopWindow);
  if DC=0 then
    RaiseLastOSError;
  FDC:=CreateCompatibleDC(DC);
  if FDC=0 then
    RaiseLastOSError;
  ZeroMemory(@BMI,SizeOf(BMI));
  with BMI.bmiHeader do begin
    biSize:=SizeOf(TBitmapInfoHeader);
    biWidth:=Width;
    biHeight:=Height;
    biPlanes:=1;
    biBitCount:=32;
    biCompression:=BI_RGB;
  end;
  FDIB:=CreateDIBSection(FDC,BMI,DIB_RGB_COLORS,FBits,0,0);
  if FDIB=0 then
    RaiseLastOSError;
  FOldDC:=SelectObject(FDC,FDIB);
  if FOldDC=0 then
    RaiseLastOSError;
  MakePFD(Format);
  inherited CreateContext(Format);
  if SelectObject(FOldDC,FDIB)<>0 then
    RaiseLastOSError;
end;

procedure TDIBCanvas.DestroyContext;
begin
  if not DeleteDC(FDC) then
    RaiseLastOSError;
  FDC:=0;
  if not DeleteObject(FDIB) then
    RaiseLastOSError;
  FDIB:=0;
end;

class function TDIBCanvas.GetCanvasType: TCanvasType;
begin
  Result:=ctMemoryBitmap;
end;

function TDIBCanvas.GetDisplayListOwner: TGlCanvas;
begin
  Result:=FOwner;
end;

procedure TDIBCanvas.MakeCurrent;
begin
  if FLockCount=1 then begin
    FOldDC:=SelectObject(FDC,FDIB);
    if FOldDC=0 then
      RaiseLastOSError;
  end;
  inherited;
end;

procedure TDIBCanvas.ShareLists(Format: TGlPixelFormat);
var
  a:Integer;
begin
  for a:=0 to GNullDIBCanvasList.Count-1 do
    if wglShareLists((GNullDIBCanvasList[a] as TNullDIBCanvas).FGLRC2,FGLRC) then begin
      FOwner:=GNullDIBCanvasList[a] as TNullDIBCanvas;
      Exit;
    end;
  FOwner:=TNullDIBCanvas.Create(Format);
  GNullDIBCanvasList.Add(FOwner);
  if not wglShareLists(FOwner.FGLRC2,FGLRC) then
    RaiseLastOSError;
end;

procedure TDIBCanvas.UnMakeCurrent;
begin
  inherited;
  if FLockCount=1 then begin
    if SelectObject(FDC,FOldDC)=0 then
      RaiseLastOSError;
  end;
end;

{ TNullDIBCanvas }

constructor TNullDIBCanvas.Create(Format: TGlPixelFormat);
begin
  inherited Create;
  CreateContext(1,1,Format);
  FGLRC2:=wglCreateContext(FDC);
  if FGLRC2=0 then
    RaiseLastOSError;
  if not wglShareLists(FGLRC2,FGLRC) then
    RaiseLastOSError;
end;

destructor TNullDIBCanvas.Destroy;
begin
  if not wglDeleteContext(FGLRC2) then 
    RaiseLastOSError;
  DestroyContext;
  inherited;
end;

procedure TNullDIBCanvas.ShareLists(Format: TGlPixelFormat);
begin

end;

initialization
  Initialize;
finalization
  Finalize;
end.
