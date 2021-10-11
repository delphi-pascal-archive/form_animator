{
  FormAnimator.pas
  Gestionnaire d'animations de fenêtres évoluées pour Delphi

  Copyright           : Vincent Forman
       Date           : le 22 aout 2006
  Contact de l'auteur : vincent.forman@gmail.com

  Utilisation/license : - libre de droit pour usage privé et pour les
                          applications gratuites.
                          Merci de faire figurer mon nom dans les crédits  ;-)
                        - utilisation et reproduction même partielle
                          INTERDITE sans la permission écrite de l'auteur
                          dans le cadre de logiciels commerciaux.
}

unit FormAnimator;

interface

uses
  SysUtils,Classes,Windows,Messages,Graphics,Forms,Controls,Math,OpenGl,
  GlBitmap,GlCanvas,GlTexture;

type
  TCustomFormHack=class(TCustomForm);

  TFormAnimatorClass=class of TFormAnimator;

  TFormAnimator=class
  private
    FForm:TCustomForm;
  public
    constructor Create;virtual;

    procedure AnimateForm(AForm:TCustomForm);virtual;

    class function GetCaption:string;virtual;

    property Form:TCustomForm read FForm;
  end;

  TWinAnimator=class(TFormAnimator)
  public
    class function GetCaption:string;override;

    procedure AnimateForm(AForm:TCustomForm);override;
  end;

  TCustomFormAnimator=class(TFormAnimator)
  private
    FMethodID:Integer;
    FRect1,FRect2:TRect;
    FWindowDC,FOldWindowDC,FMemScreenDC,FOldMemScreenDC,FScreenDC:HDC;
    FWindowBitmap,FMemScreenBitmap:HBITMAP;
  protected
    function MapRect(t:Single):TRect;virtual;
    function FirstRect:TRect;virtual;

    procedure Launch;virtual;abstract;
  public
    constructor Create;override;

    procedure AnimateForm(AForm:TCustomForm);override;

    property MethodID:Integer read FMethodID;
  end;

  TGDIFormAnimator=class(TCustomFormAnimator)
  protected
    procedure Animate(MemDC,WorkDC,WindowDC:HDC;t:Single;var ClipRect:TRect);virtual;abstract;

    procedure Launch;override;
  end;

  TClassicAnimator=class(TGDIFormAnimator)
  protected
    procedure Animate(MemDC,WorkDC,WindowDC:HDC;t:Single;var ClipRect:TRect);override;
  public
    class function GetCaption:string;override;
  end;

  TVistaEmulationAnimator=class(TGDIFormAnimator)
  private
    FBitmap1,FBitmap2:TBitmap;
    FMethod1,FMethod2:Boolean;
  protected
    procedure Animate(MemDC,WorkDC,WindowDC:HDC;t:Single;var ClipRect:TRect);override;

    procedure Launch;override;
  public
    class function GetCaption:string;override;
  end;

  TGLFormAnimator=class(TCustomFormAnimator)
  private
    FBitmap:TGlBitmap;
    FTexture:TGl2DTexture;
    FMethod1,FMethod2:Boolean;
  protected
    procedure Launch;override;
    procedure LaunchGl(ScreenBits:Pointer);
    procedure DrawGl(t:Single;var ClipRect:TRect);
  public
    constructor Create;override;

    class function GetCaption:string;override;

    destructor Destroy;override;
  end;

var
  TimeMax:Cardinal=700;

implementation

function FixedCheckWin32Version(AMajor: Integer; AMinor: Integer = 0): Boolean;
begin
  Result:=(AMajor<Win32MajorVersion) or
          ((AMajor=Win32MajorVersion) and
           (AMinor<=Win32MinorVersion));
end;

{ TFormAnimator }

procedure TFormAnimator.AnimateForm(AForm: TCustomForm);
begin
  FForm:=AForm;
end;

constructor TFormAnimator.Create;
begin
  inherited;
end;

class function TFormAnimator.GetCaption: string;
begin
  Result:=ClassName;
end;

{ TWinAnimator }

procedure TWinAnimator.AnimateForm(AForm: TCustomForm);
const
  T:array[0..7] of Integer=(AW_HOR_POSITIVE,AW_HOR_NEGATIVE,AW_VER_POSITIVE,AW_VER_NEGATIVE,
                            AW_HOR_POSITIVE or AW_VER_POSITIVE,AW_HOR_NEGATIVE or AW_VER_POSITIVE,
                            AW_HOR_POSITIVE or AW_VER_NEGATIVE,AW_HOR_NEGATIVE or AW_VER_NEGATIVE);
begin
  case Random(4) of
    0:AnimateWindow(AForm.Handle,TimeMax,AW_BLEND);
    1:AnimateWindow(AForm.Handle,TimeMax,AW_CENTER);
    2:AnimateWindow(AForm.Handle,TimeMax,T[Random(High(T)+1)]);
    3:AnimateWindow(AForm.Handle,TimeMax,AW_SLIDE or T[Random(High(T)+1)]);
  end;
end;

class function TWinAnimator.GetCaption: string;
begin
  Result:='Animations système';
end;

{ TCustomFormAnimator }

const
  GAnimatorMeshSize=15;

procedure TCustomFormAnimator.AnimateForm(AForm: TCustomForm);
var
  F,G:HRGN;
  h:TForm;
  p:TPoint;
begin
  inherited;
  FMethodID:=Random(7);
  FRect1:=FirstRect;
  FRect2:=Form.BoundsRect;
  p:=Point(0,0);
  if Form.Parent<>nil then
    p:=Form.Parent.ClientToScreen(p)
  else begin
    if Form.ParentWindow<>0 then
      ClientToScreen(Form.ParentWindow,p);
    if TForm(Form).FormStyle=fsMDIChild then
      ClientToScreen(Application.MainForm.ClientHandle,p);
  end;
  with p do
    OffsetRect(FRect2,X,Y);
  FScreenDC:=GetWindowDC(GetDesktopWindow);
  with FForm do begin
    h:=Screen.ActiveForm;
    if Assigned(h) then begin
      SetForegroundWindow(FForm.Handle);
      h.Repaint;
    end;
    
    FMemScreenDC:=CreateCompatibleDC(FScreenDC);
    FWindowDC:=CreateCompatibleDC(FScreenDC);

    FMemScreenBitmap:=CreateCompatibleBitmap(FScreenDC,Screen.Width,Screen.Height);
    FWindowBitmap:=CreateCompatibleBitmap(FScreenDC,Width,Height);

    FOldMemScreenDC:=SelectObject(FMemScreenDC,FMemScreenBitmap);
    FOldWindowDC:=SelectObject(FWindowDC,FWindowBitmap);

    FillRect(FWindowDC,Rect(0,0,Width,Height),FForm.Brush.Handle);

    if FixedCheckWin32Version(5) then
      Perform(WM_PRINT,FWindowDC,PRF_CHILDREN or PRF_CLIENT or PRF_ERASEBKGND or PRF_NONCLIENT or PRF_OWNED)
    else
      with ClientOrigin,FRect2 do
        PaintTo(FWindowDC,X-Left,Y-Top);
    BitBlt(FMemScreenDC,0,0,Screen.Width,Screen.Height,FScreenDC,0,0,SRCCOPY);

    F:=CreateRectRgn(0,0,Width,Height);
    GetWindowRgn(Handle,F);
    G:=CreateRectRgn(0,0,Width,Height);
    CombineRgn(G,G,F,RGN_DIFF);
    SelectClipRGN(FWindowDC,G);
    SetViewportOrgEx(FWindowDC,0,0,nil);
    with FRect2 do
      BitBlt(FWindowDC,0,0,Width,Height,FScreenDC,Left,Top,SRCCOPY);
    DeleteObject(F);
    DeleteObject(G);
    try
      Launch;
    finally
      SelectObject(FOldWindowDC,FWindowBitmap);
      DeleteDC(FWindowDC);
      DeleteObject(FWindowBitmap);
      SelectObject(FOldMemScreenDC,FMemScreenBitmap);
      DeleteDC(FMemScreenDC);
      DeleteObject(FMemScreenBitmap);
      ReleaseDC(GetDesktopWindow,FScreenDC);
    end;
  end;
end;

constructor TCustomFormAnimator.Create;
begin

end;

function TCustomFormAnimator.FirstRect: TRect;
begin
  ZeroMemory(@Result,SizeOf(Result));
  with FForm do
    case FMethodID of
      1:with Screen do Result:=Rect(Screen.Width,0,Screen.Width,0);
      2:with Screen do Result:=Rect(0,Screen.Height,0,Screen.Height);
      3:with Screen do Result:=Rect(Screen.Width,Screen.Height,Screen.Width,Screen.Height);
      4:if Application.MainForm<>nil then Result:=Application.MainForm.BoundsRect else Result:=FForm.BoundsRect;
      5:with ClientOrigin do Result:=Bounds(x+Width div 2,y+Height div 2,0,0);
      6:with Screen do Result:=Rect(-Width,-Height,2*Width,2*Height);
    end;
end;

function TCustomFormAnimator.MapRect(t: Single): TRect;
var
  u:Single;
const
  r1=0*200;
  r2=0*200;
begin
  t:=t;
  u:=1-t;
  Result.Left:=Round(FRect1.Left*u+FRect2.Left*t);
  Result.Top:=Round(FRect1.Top*u+FRect2.Top*t);
  Result.Right:=Round(FRect1.Right*u+FRect2.Right*t);
  Result.Bottom:=Round(FRect1.Bottom*u+FRect2.Bottom*t);
  if IsRectEmpty(Result) then
    with Result do begin
      Right:=Left+1;
      Bottom:=Top+1;
    end;
end;

{ TGDIFormAnimator }

procedure TGDIFormAnimator.Launch;
var
  WorkDC,OldWorkDC:HDC;
  WorkBitmap:HBitmap;
  r,s,t:TRect;

  procedure MakeAnimate;
  var
    FirstTick,LastTick:Cardinal;
  begin
    FirstTick:=GetTickCount;
    ZeroMemory(@s,SizeOf(s));
    BitBlt(WorkDC,0,0,Screen.Width,Screen.Height,FMemScreenDC,0,0,SRCCOPY);
    repeat
      LastTick:=Min(GetTickCount,FirstTick+TimeMax);
      with s do
        BitBlt(WorkDC,Left,Top,Right-Left,Bottom-Top,FMemScreenDC,Left,Top,SRCCOPY);
      with Screen do
        r:=Rect(0,0,Width,Height);
      Animate(FMemScreenDC,WorkDC,FWindowDC,(LastTick-FirstTick)/TimeMax,r);
      UnionRect(t,s,r);
      if LastTick-FirstTick>=TimeMax then begin
        with Screen do
          t:=Rect(0,0,Width,Height);
      end;
      with t do
        BitBlt(FScreenDC,Left,Top,Right-Left,Bottom-Top,WorkDC,Left,Top,SRCCOPY);
      s:=r;
    until LastTick-FirstTick>=TimeMax;
  end;

begin
  inherited;
  with FForm do begin
    WorkBitmap:=CreateCompatibleBitmap(FScreenDC,Screen.Width,Screen.Height);
    WorkDC:=CreateCompatibleDC(FScreenDC);
    OldWorkDC:=SelectObject(WorkDC,WorkBitmap);
    try
      MakeAnimate;
    finally
      SelectObject(OldWorkDC,WorkBitmap);
      DeleteDC(WorkDC);
      DeleteObject(WorkBitmap);
    end;
  end;
end;

{ TClassicAnimator }

procedure TClassicAnimator.Animate(MemDC, WorkDC, WindowDC: HDC; t: Single;
  var ClipRect: TRect);
var
  BF:TBlendFunction;
const
  O1=0.5;
  O2=0.7;
begin
  with BF do begin
    BlendOp:=0;
    BlendFlags:=0;
    SourceConstantAlpha:=Round(255*Power(t,O1));
    AlphaFormat:=0;
  end;
  t:=Power(t,O2);
  ClipRect:=MapRect(t);
  with ClipRect do
    AlphaBlend(WorkDC,Left,Top,Right-Left,Bottom-Top,WindowDC,0,0,FRect2.Right-FRect2.Left,FRect2.Bottom-FRect2.Top,BF);
end;

class function TClassicAnimator.GetCaption: string;
begin
  Result:='Animations émulées simples';
end;

{ TVistaEmulationAnimator }

procedure TVistaEmulationAnimator.Animate(MemDC, WorkDC, WindowDC: HDC;
  t: Single; var ClipRect: TRect);
var
  BF:TBlendFunction;
  R1,R2,R3:TRect;
  a,b:Integer;
  P:array[0..2] of TPoint;
const
  O1=1.5;
  O2=0.4;
  U=0.5;

  function GetPoint(x,y:Single):TPoint;
  var
    u,v,x1,x2,x3,y1,y2,y3,a,b,c,d:Single;
  begin
    u:=1-x;
    v:=1-y;
    x1:=x*R1.Right+u*R1.Left;
    x2:=x*R2.Right+u*R2.Left;
    x3:=x*R3.Right+u*R3.Left;
    y1:=y*R1.Bottom+v*R1.Top;
    y2:=y*R2.Bottom+v*R2.Top;
    y3:=y*R3.Bottom+v*R3.Top;
    if FMethod1 then
      a:=1-x
    else
      a:=x;
    if FMethod2 then
      c:=1-y
    else
      c:=y;
    b:=1-a;
    d:=1-c;
    Result.X:=Round((x*x1+u*x2)*c+(x*x2+u*x3)*d);
    if Result.X>ClipRect.Right then
      ClipRect.Right:=Result.X;
    if Result.X<ClipRect.Left then
      ClipRect.Left:=Result.X;
    Result.Y:=Round((y*y1+v*y2)*a+(y*y2+v*y3)*b);
    if Result.Y>ClipRect.Bottom then
      ClipRect.Bottom:=Result.Y;
    if Result.Y<ClipRect.Top then
      ClipRect.Top:=Result.Y;
  end;

  function TruncFloat(x:Single):Single;
  begin
    Result:=x;
    if x<0 then
      Result:=0;
    if x>1 then
      Result:=1;
  end;

begin
  Assert(SetStretchBltMode(WorkDC,HALFTONE)<>0);
  Assert(SetStretchBltMode(WindowDC,HALFTONE)<>0);

  with BF do begin
    BlendOp:=0;
    BlendFlags:=0;
    SourceConstantAlpha:=255-Round(255*Power(t,O1));
    AlphaFormat:=0;
  end;

  t:=Power(t,O2);

  R1:=MapRect(TruncFloat((2*U+1)*t-2*U));
  R2:=MapRect(TruncFloat((2*U+1)*t-U));
  R3:=MapRect(TruncFloat((2*U+1)*t));
  UnionRect(ClipRect,R1,R2);
  UnionRect(ClipRect,ClipRect,R3);

  for a:=0 to GAnimatorMeshSize-1 do
    for b:=0 to GAnimatorMeshSize-1 do begin
      P[0]:=GetPoint(a/GAnimatorMeshSize,b/GAnimatorMeshSize);
      P[1]:=GetPoint((a+1)/GAnimatorMeshSize,b/GAnimatorMeshSize);
      P[2]:=GetPoint(a/GAnimatorMeshSize,(b+1)/GAnimatorMeshSize);
      PlgBlt(WorkDC,
             P,
             WindowDC,
             Round(a*FForm.Width/GAnimatorMeshSize),
             Round(b*FForm.Height/GAnimatorMeshSize),
             Round((a+1)*FForm.Width/GAnimatorMeshSize)-Round(a*FForm.Width/GAnimatorMeshSize),
             Round((b+1)*FForm.Height/GAnimatorMeshSize)-Round(b*FForm.Height/GAnimatorMeshSize),
             FBitmap2.Handle,
             0,
             0);
      P[0]:=GetPoint((a+1)/GAnimatorMeshSize,(b+1)/GAnimatorMeshSize);
      P[1]:=GetPoint((a+1)/GAnimatorMeshSize,b/GAnimatorMeshSize);
      P[2]:=GetPoint(a/GAnimatorMeshSize,(b+1)/GAnimatorMeshSize);
      p[0].X:=P[1].X+p[2].X-P[0].X;
      p[0].Y:=P[1].Y+p[2].Y-P[0].Y;
      PlgBlt(WorkDC,
             P,
             WindowDC,
             Round(a*FForm.Width/GAnimatorMeshSize),
             Round(b*FForm.Height/GAnimatorMeshSize),
             Round((a+1)*FForm.Width/GAnimatorMeshSize)-Round(a*FForm.Width/GAnimatorMeshSize),
             Round((b+1)*FForm.Height/GAnimatorMeshSize)-Round(b*FForm.Height/GAnimatorMeshSize),
             FBitmap1.Handle,
             0,
             0);
    end;
  with Screen do
    IntersectRect(ClipRect,Rect(0,0,Width,Height),ClipRect);

  with ClipRect do
    AlphaBlend(WorkDC,Left,Top,Right-Left,Bottom-Top,MemDC,Left,Top,Right-Left,Bottom-Top,BF);
end;

class function TVistaEmulationAnimator.GetCaption: string;
begin
  Result:='Animations style Vista, accélération logicielle';
end;

procedure TVistaEmulationAnimator.Launch;
begin
  FMethod1:=Random>0.5;
  FMethod2:=Random>0.5;
  FBitmap1:=TBitmap.Create;
  with FBitmap1 do begin
    Width:=1+FForm.Width div GAnimatorMeshSize;
    Height:=1+FForm.Height div GAnimatorMeshSize;
    Monochrome:=True;
    Canvas.Brush.Color:=0;
    Canvas.Pen.Color:=0;
    Canvas.Polygon([Point(0,0),Point(Width-1,0),Point(0,Height-1)]);
  end;
  FBitmap2:=TBitmap.Create;
  with FBitmap2 do begin
    Width:=1+FForm.Width div GAnimatorMeshSize;
    Height:=1+FForm.Height div GAnimatorMeshSize;
    Monochrome:=True;
    Canvas.Brush.Color:=0;
    Canvas.Pen.Color:=0;
    Canvas.Polygon([Point(Width,Height),Point(Width+2,0),Point(0,Height+2)]);
  end;
  try
    inherited
  finally
    FBitmap1.Destroy;
    FBitmap2.Destroy;
  end;
end;

{ TGLFormAnimator }

constructor TGLFormAnimator.Create;
begin
  inherited;
  FBitmap:=TGlBitmap.Create;
  with Screen do begin
    FBitmap.Width:=Width;
    FBitmap.Height:=Height;
  end;
  FTexture:=TGl2DTexture.Create(FBitmap.Canvas);
end;

destructor TGLFormAnimator.Destroy;
begin
  FBitmap.Free;
  FTexture.Free;
  inherited;
end;

procedure TGLFormAnimator.DrawGl(t: Single; var ClipRect: TRect);
var
  R1,R2,R3:TRect;
  a,b:Integer;
const
  O1=0.5;
  O2=0.5;
  U=1;

  function GetPoint(x,y:Single):TPointFloat;
  var
    u,v,x1,x2,x3,y1,y2,y3,a,b,c,d:Single;
  begin
    u:=1-x;
    v:=1-y;
    x1:=x*R1.Right+u*R1.Left;
    x2:=x*R2.Right+u*R2.Left;
    x3:=x*R3.Right+u*R3.Left;
    y1:=y*R1.Bottom+v*R1.Top;
    y2:=y*R2.Bottom+v*R2.Top;
    y3:=y*R3.Bottom+v*R3.Top;
    if FMethod1 then
      a:=1-x
    else
      a:=x;
    if FMethod2 then
      c:=1-y
    else
      c:=y;
    b:=1-a;
    d:=1-c;
    Result.X:=Round((x*x1+u*x2)*c+(x*x2+u*x3)*d);
    if Result.X>ClipRect.Right then
      ClipRect.Right:=Round(Result.X);
    if Result.X<ClipRect.Left then
      ClipRect.Left:=Round(Result.X);
    Result.Y:=Round((y*y1+v*y2)*a+(y*y2+v*y3)*b);
    if Result.Y>ClipRect.Bottom then
      ClipRect.Bottom:=Round(Result.Y);
    if Result.Y<ClipRect.Top then
      ClipRect.Top:=Round(Result.Y);
  end;

  function TruncFloat(x:Single):Single;
  begin
    Result:=x;
    if x<0 then
      Result:=0;
    if x>1 then
      Result:=1;
  end;

begin
  glColor4f(1,1,1,Power(t,O1));
  t:=Power(t,O2);

  R1:=MapRect(TruncFloat((3*U)*t-2*U));
  R2:=MapRect(TruncFloat((3*U)*t-U));
  R3:=MapRect(TruncFloat((3*U)*t));
  UnionRect(ClipRect,R1,R2);
  UnionRect(ClipRect,ClipRect,R3);
  glEnable(GL_TEXTURE_2D);
  for a:=0 to GAnimatorMeshSize-1 do begin
    glBegin(GL_QUAD_STRIP);
    for b:=0 to GAnimatorMeshSize do begin
      with FTexture do
        glTexCoord2f(a*UMax/GAnimatorMeshSize,(1-b/GAnimatorMeshSize)*VMax);
      with GetPoint(a/GAnimatorMeshSize,b/GAnimatorMeshSize) do
        glVertex2f(X,Y);
      with FTexture do
        glTexCoord2f((a+1)*UMax/GAnimatorMeshSize,(1-b/GAnimatorMeshSize)*VMax);
      with GetPoint((a+1)/GAnimatorMeshSize,b/GAnimatorMeshSize) do
        glVertex2f(X,Y);
    end;
    glEnd;
  end;
  glDisable(GL_TEXTURE_2D);
end;

class function TGLFormAnimator.GetCaption: string;
begin
  Result:='Animations style Vista, accélération matérielle';
end;

procedure TGLFormAnimator.Launch;
var
  a:Integer;
  ScreenBits:Pointer;
  BMI:TBitmapInfo;
begin
  with Screen do begin
    a:=Align32(Width*24)*Height;
    WinGetMem(ScreenBits,a);
    ZeroMemory(@BMI,SizeOf(BMI));
    with BMI.bmiHeader do begin
      biSize:=SizeOf(TBitmapInfoHeader);
      biWidth:=Width;
      biHeight:=Height;
      biPlanes:=1;
      biBitCount:=24;
      biCompression:=BI_RGB;
    end;
    SelectObject(FOldMemScreenDC,FMemScreenBitmap);
    GetDIBits(FScreenDC,FMemScreenBitmap,0,Height,ScreenBits,BMI,DIB_RGB_COLORS);
    GdiFlush;
    FBitmap.Canvas.Lock;
    try
      with FForm do
        FTexture.LoadFromBitmap(FWindowDC,FWindowBitmap,Rect(0,0,Width,Height));
      FTexture.bind;
      LaunchGl(ScreenBits);
    finally
      FBitmap.Canvas.Unlock;
      SelectObject(FMemScreenDC,FMemScreenBitmap);
      SelectObject(FWindowDC,FWindowBitmap);
      BitBlt(FScreenDC,0,0,Width,Height,FMemScreenDC,0,0,SRCCOPY);
      WinFreeMem(ScreenBits);
    end;
  end;
end;

procedure TGLFormAnimator.LaunchGl(ScreenBits: Pointer);
var
  r,s,t:TRect;
  FirstTick,LastTick:Cardinal;
begin
  FMethod1:=Random>0.5;
  FMethod2:=Random>0.5;
  with Screen do begin
    FBitmap.Canvas.MakeViewPort(Width,Height);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
    glTexEnv(GL_TEXTURE_2D,GL_TEXTURE_ENV_MODE,GL_MODULATE);
    glTexParameter(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
    glTexParameter(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
    s:=Rect(0,0,Width,Height);
    glEnable(GL_SCISSOR_TEST);
    FirstTick:=GetTickCount;
//    Texture.bind;
    repeat
      LastTick:=Min(GetTickCount,FirstTick+TimeMax);
      if IsRectEmpty(s) then begin
        s.Right:=s.Left+1;
        s.Bottom:=s.Top+1;
      end;
      with s do begin
        glScissor(Left,Height-Bottom,Right-Left,Bottom-Top);
        glRasterPos(0,Height);
        glPixelStore(GL_UNPACK_SKIP_PIXELS,0);
        glPixelStore(GL_UNPACK_SKIP_ROWS,0);
        glPixelStore(GL_UNPACK_ROW_LENGTH,Width);
        glDrawPixels(Width,Height,GL_BGR,GL_UNSIGNED_BYTE,ScreenBits);
      end;
      DrawGl((LastTick-FirstTick)/TimeMax,r);
      glDisable(GL_TEXTURE_2D);
      IntersectRect(r,r,Rect(0,0,Width,Height));
      UnionRect(t,s,r);
      s:=r;
      glFlush;
      glFinish;
      FBitmap.SubDraw(t,FScreenDC,t.Left,t.Top);
      repeat until glGetError=0;
    until LastTick-FirstTick>=TimeMax;
  end;
end;

end.
