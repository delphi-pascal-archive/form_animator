unit GlTexture;

interface

uses
  Windows,SysUtils,Classes,OpenGl,GlCanvas,Math;

type
  TCardinalArray=array[0..$FFFF] of Cardinal;
  PCardinalArray=^TCardinalArray;
  TIntegerArray=array[0..$FFFF] of Integer;
  PIntegerArray=^TIntegerArray;

  TTextureUnits=record
    TexCount:Integer;
    TexSize,MeshSize:array[0..2] of Integer;
    MeshCoord:array[0..2] of PIntegerArray;
    UnitGlSize:array[0..2] of PIntegerArray;
    TexID:PCardinalArray;
  end;

  TTextureFormat=(tfRGB,tfRGBA,tfBGR,tfBGRA,tfRed,tfGreen,tfBlue,tfAlpha,tfLuminance,tfLuminanceAlpha,tfIntensity);
  TSizeAdjustMode=(samOverNoScale,samOverScale,tsmMultiGrid,samUnderScale);
  //TTextureRepeatMode=

  TTransfertType=(ttFull,ttSub);

  TGlTexture=class
  private
    FSize:array[0..2] of Integer;
    FAdjustMode:array[0..2] of TSizeAdjustMode;
    FContentAllocated,FUnitAllocated:Boolean;
    FFormat: TTextureFormat;
    FUnits: TTextureUnits;
    FOwner: TGlCanvas;

    procedure SetDepth(const Value: Integer);
    procedure SetHeight(const Value: Integer);
    procedure SetWidth(const Value: Integer);
    procedure SetFormat(const Value: TTextureFormat);
  protected
    class function GetTargetProxy:Integer;virtual;abstract;
    class function GetTarget:Integer;virtual;abstract;

    procedure GetUnitCoord(ID:Integer;var x,y,z:Integer);

    procedure SetProxyData(Width,Height,Depth:Integer);virtual;abstract;
    procedure SetPtrData(TransfertType:TTransfertType;Width,Height,Depth,DX,DY,DZ:Integer;Pixels:Pointer;Format,_type:Integer);virtual;abstract;
    procedure CopyData(TransfertType:TTransfertType;X,Y,Width,Height,Depth,DX,DY,DZ:Integer);virtual;abstract;

    function GetGlFormat:Integer;overload;
    function GetGlFormat(f:TTextureFormat):Integer;overload;

    function GetUMax: Single;
    function GetVMax: Single;
    function GetWMax: Single;

    procedure AllocateUnits;
    procedure AllocateContent;
    procedure Unallocate;

    property Width:Integer read FSize[0] write SetWidth;
    property Height:Integer read FSize[1] write SetHeight;
    property Depth:Integer read FSize[2] write SetDepth;

    property UMax:Single read GetUMax;
    property VMax:Single read GetVMax;
    property WMax:Single read GetWMax;
  public
    constructor Create(AOwner:TGlCanvas);

    procedure LoadFromCanvas(Canvas:TGlCanvas;SrcRect:TRect);
    procedure LoadFromBitmap(DC:HDC;Bitmap:HBITMAP;SrcRect:TRect);

//    procedure LoadFromRawPtr(Format:TTextureFormat;SX,SY,SZ,DX,DY,DZ,Width,Height,Depth:Integer;Data:Pointer;DataWidth,DataHeight:Integer);overload;
    procedure LoadFromRawPtr(Format:TTextureFormat;SX,SY,SZ,Width,Height,Depth:Integer;Data:Pointer;DataWidth,DataHeight:Integer);overload;

    property Format:TTextureFormat read FFormat write SetFormat;

    procedure Bind;

    property Owner:TGlCanvas read FOwner;

    destructor Destroy;override;
  end;

  TGl2DTexture=class(TGlTexture)
//  protected
    class function GetTargetProxy:Integer;override;
    class function GetTarget:Integer;override;

    procedure SetProxyData(Width,Height,Depth:Integer);override;
    procedure SetPtrData(TransfertType:TTransfertType;Width,Height,Depth,DX,DY,DZ:Integer;Pixels:Pointer;Format,_type:Integer);override;
    procedure CopyData(TransfertType:TTransfertType;X,Y,Width,Height,Depth,DX,DY,DZ:Integer);override;

    procedure PaintTo(Canvas:TGlCanvas;X,Y,W,H:Single);
  public
    constructor Create(AOwner:TGlCanvas);

    property Width;
    property Height;

    property UMax;
    property VMax;
  end;

procedure glBindTexture(target:GLenum;texture:GLuint);stdcall;external Opengl32;
procedure glDeleteTextures(n:GLsizei;const textures:PGLuint);stdcall;external Opengl32;
procedure glGenTextures(n:GLsizei;textures:PGLuint);stdcall;external Opengl32;

procedure glCopyTexImage1D(target:GLenum;level:GLint;internalFormat:GLenum;x,y:GLint;width:GLsizei;border:GLint);stdcall;external Opengl32;
procedure glCopyTexSubImage1D(target:GLenum;level,xoffset,x,y:GLint;width:GLsizei);stdcall;external Opengl32;
procedure glTexSubImage1D(target:GLenum;level,xoffset:GLint;width:GLsizei;format,_type:GLenum;const pixels:Pointer);stdcall;external Opengl32;

procedure glCopyTexImage2D(target:GLenum;level:GLint;internalFormat:GLenum;x,y:GLint;width,height:GLsizei;border:GLint);stdcall;external Opengl32;
procedure glCopyTexSubImage2D(target:GLenum;level,xoffset,yoffset,x,y:GLint;width,height:GLsizei);stdcall;external Opengl32;
procedure glTexSubImage2D(target:GLenum;level,xoffset,yoffset:GLint;width,height:GLsizei;format,_type:GLenum;const pixels:Pointer);stdcall;external Opengl32;

procedure glCopyTexSubImage3D(target:GLenum;level,xoffset,yoffset,zoffset,x,y:GlInt;width,height:GLsizei);stdcall;external Opengl32;
procedure glTexImage3D(target:GLenum;level,internalformat:GLint;width,height,depth:GLsizei;border:GLint;format,_type:GLenum;const pixels:Pointer);stdcall;external Opengl32;
procedure glTexSubImage3D(target:GLenum;level,xoffset,yoffset,zoffset:GLint;width,height,depth:GLsizei;format,_type:GLenum;const pixels:Pointer);stdcall;external Opengl32;

implementation

{ TGlTexture }

procedure TGlTexture.AllocateContent;
var
  a,b,c,d:Integer;
//  p:Pointer;
begin
  if not FUnitAllocated then
    AllocateUnits;
  FOwner.Lock;
  glPushAttrib(GL_ALL_ATTRIB_BITS);
  try
    with FUnits do begin
      glPixelStore(GL_UNPACK_SKIP_PIXELS,0);
      glPixelStore(GL_UNPACK_SKIP_ROWS,0);
      glPixelStore(GL_UNPACK_ROW_LENGTH,UnitGlSize[0,0]);
//      WinGetMem(p,Align32(UnitGlSize[0,0]*32)*UnitGlSize[1,0]*UnitGlSize[2,0]);
      for d:=0 to TexCount-1 do begin
        glBindTexture(GetTarget,TexID[d]);
        GetUnitCoord(d,a,b,c);
        SetPtrData(ttFull,UnitGlSize[0,a],UnitGlSize[1,b],UnitGlSize[2,c],0,0,0,nil,GL_BGR,GL_UNSIGNED_BYTE);
      end;
//      WinFreeMem(p);
    end;
    FContentAllocated:=True;
  finally
    glPopAttrib;
    FOwner.Unlock;
  end;
end;

procedure TGlTexture.AllocateUnits;
var
  UnitSize:array[0..2] of Integer;
  a,b:Integer;

  procedure CalcMaxSizes;
  var
    a,b,c,d:Integer;
  const
    N=6400;
  begin
    for a:=0 to 2 do
      UnitSize[a]:=NextPowerOfTwo(FSize[a]);
    repeat
      b:=-1;
      d:=1;
      for a:=0 to 2 do
        if UnitSize[a]>d then begin
          b:=a;
          d:=UnitSize[a];
        end;
      SetProxyData(UnitSize[0],UnitSize[1],UnitSize[2]);
      glGetTexLevelParameteriv(GetTargetProxy,0,GL_TEXTURE_WIDTH,@c);
      if (b>-1) and ((c=0) or (UnitSize[b]>=N)) then
        UnitSize[b]:=UnitSize[b] div 2;
    until (b=-1) or ((c<>0) and (UnitSize[b]<N));
    if b=-1 then
      raise Exception.Create('Hardware could not accomodate required texture size');
  end;

begin
  FOwner.Lock;
  glPushAttrib(GL_ALL_ATTRIB_BITS);
  try
    FContentAllocated:=False;
    CalcMaxSizes;
    with FUnits do begin
      TexCount:=1;
      for a:=0 to 2 do begin
        case FAdjustMode[a] of
          samOverScale:begin
                         if (UnitSize[a]>FSize[a]) and FOwner.GL_ARB_texture_non_power_of_two_Present then
                           UnitSize[a]:=FSize[a];
                         TexSize[a]:=UnitSize[a];
                       end;
          samUnderScale:begin
                          if UnitSize[a]>FSize[a] then begin
                            if FOwner.GL_ARB_texture_non_power_of_two_Present then
                              UnitSize[a]:=FSize[a]
                            else
                              UnitSize[a]:=UnitSize[a] div 2;
                          end;
                          TexSize[a]:=UnitSize[a];
                        end;
          samOverNoScale:begin
                           if UnitSize[a]>FSize[a] then
                             TexSize[a]:=FSize[a]
                           else
                             TexSize[a]:=UnitSize[a];
                         end;
          tsmMultiGrid:TexSize[a]:=FSize[a];
        end;
        MeshSize[a]:=Ceil(TexSize[a]/UnitSize[a]);
        Assert(MeshSize[a]>=1);
        TexCount:=TexCount*MeshSize[a];
        GetMem(MeshCoord[a],(MeshSize[a]+1)*SizeOf(Integer));
        GetMem(UnitGlSize[a],MeshSize[a]*SizeOf(Integer));
        for b:=0 to MeshSize[a]-1 do begin
          MeshCoord[a,b]:=b*UnitSize[a];
          UnitGlSize[a,b]:=UnitSize[a];
        end;
        MeshCoord[a,MeshSize[a]]:=TexSize[a];
        if FOwner.GL_ARB_texture_non_power_of_two_Present then
          UnitGlSize[a,MeshSize[a]-1]:=TexSize[a]-MeshCoord[a,MeshSize[a]-1]
        else
          UnitGlSize[a,MeshSize[a]-1]:=NextPowerOfTwo(TexSize[a]-MeshCoord[a,MeshSize[a]-1]);
      end;
      GetMem(TexID,TexCount*SizeOf(Cardinal));
      glGenTextures(TexCount,@TexID[0]);
    end;
    FUnitAllocated:=True;
  finally
    glPopAttrib;
    FOwner.Unlock;
  end;
end;

procedure TGlTexture.Bind;
begin
  if not FContentAllocated then
    AllocateContent;
  with FUnits do begin
    if TexCount<>1 then
      raise Exception.Create('Cannot bind multi-surface texture');
    glBindTexture(GetTarget,TexID[0]);
  end;
end;

constructor TGlTexture.Create(AOwner: TGlCanvas);
begin
  inherited Create;
  if AOwner.GetCanvasType=ctMemoryBitmap then
    FOwner:=AOwner
  else
    FOwner:=AOwner.GetDisplayListOwner;
  Assert(Assigned(FOwner));
end;

destructor TGlTexture.Destroy;
begin
  Unallocate;
  inherited;
end;

function TGlTexture.GetGlFormat: Integer;
begin
  Result:=GetGlFormat(FFormat);
end;

function TGlTexture.GetGlFormat(f: TTextureFormat): Integer;
begin
  Result:=0;
  case f of
    tfRGB:Result:=GL_RGB;
    tfRGBA:Result:=GL_RGBA;
    tfBGR:Result:=GL_BGR;
    tfBGRA:Result:=GL_BGRA;
    tfRed:Result:=GL_RED;
    tfGreen:Result:=GL_GREEN;
    tfBlue:Result:=GL_BLUE;
    tfAlpha:Result:=GL_ALPHA;
    tfLuminance:Result:=GL_LUMINANCE;
    tfLuminanceAlpha:Result:=GL_LUMINANCE_ALPHA;
    tfIntensity:Result:=GL_INTENSITY;
  end;
end;

function TGlTexture.GetUMax: Single;
begin
  with FUnits do
    Result:=TexSize[0]/UnitGLSize[0,0];
end;

procedure TGlTexture.GetUnitCoord(ID: Integer; var x, y, z: Integer);
begin
  with FUnits do begin
    x:=ID mod MeshSize[0];
    y:=(ID div MeshSize[0]) mod MeshSize[1];
    z:=(ID div MeshSize[0]) div MeshSize[1];
  end;
end;

function TGlTexture.GetVMax: Single;
begin
  with FUnits do
    Result:=TexSize[1]/UnitGLSize[1,0];
end;

function TGlTexture.GetWMax: Single;
begin
  with FUnits do
    Result:=Depth/UnitGlSize[2,0];
end;

procedure TGlTexture.LoadFromBitmap(DC: HDC; Bitmap: HBITMAP; SrcRect: TRect);
var
  BMI:TBitmapInfo;
  p:Pointer;
  a,w,h:Integer;
begin
  w:=SrcRect.Right-SrcRect.Left;
  h:=SrcRect.Bottom-SrcRect.Top;
  Width:=w;
  Height:=h;
  if not FContentAllocated then
    AllocateContent;
  ZeroMemory(@BMI,SizeOf(BMI));
  with BMI.bmiHeader do begin
    biSize:=SizeOf(TBitmapInfoHeader);
    biWidth:=w;
    biHeight:=h;
    biPlanes:=1;
    biBitCount:=24;
    biCompression:=BI_RGB;
  end;
  a:=Align32(w*32)*h;
  WinGetMem(p,a);
  GetDIBits(DC,Bitmap,SrcRect.Top,h,p,BMI,DIB_RGB_COLORS);
  try
    LoadFromRawPtr(tfBGR,0,0,0,w,h,1,p,w,h);
  finally
    WinFreeMem(p);
  end;
end;

procedure TGlTexture.LoadFromCanvas(Canvas: TGlCanvas; SrcRect: TRect);
var
  a,b,c,d:Integer;
  p:Pointer;
begin
  Canvas.Lock;
  glPushAttrib(GL_ALL_ATTRIB_BITS);
  try
    Width:=SrcRect.Right-SrcRect.Left;
    Height:=SrcRect.Bottom-SrcRect.Top;
    if not FUnitAllocated then
      AllocateUnits;
    with FUnits do
      if (Canvas.GetDisplayListOwner<>FOwner) or (TexSize[0]<>Width) or (TexSize[1]<>Height) then begin
        a:=Align32(Width*24)*Height;
        GetMem(p,a);
        glReadPixels(SrcRect.Left,SrcRect.Top,Width,Height,GetGlFormat,GL_UNSIGNED_BYTE,p);
        LoadFromRawPtr(FFormat,0,0,0,TexSize[0],TexSize[1],1,p,Width,Height);
        FreeMem(p);
      end else begin
        for d:=0 to TexCount-1 do begin
          glBindTexture(GetTarget,TexID[d]);
          GetUnitCoord(d,a,b,c);
          if FContentAllocated then
            CopyData(ttSub,SrcRect.Left+MeshCoord[0,a],SrcRect.Top+MeshCoord[1,b],MeshCoord[0,a+1]-MeshCoord[0,a],MeshCoord[1,b+1]-MeshCoord[1,b],MeshCoord[2,c+1]-MeshCoord[2,c],0,0,0)
          else
            CopyData(ttFull,SrcRect.Left+MeshCoord[0,a],SrcRect.Top+MeshCoord[1,b],UnitGlSize[0,a],UnitGlSize[1,b],UnitGlSize[2,c],0,0,0);
        end;
        FContentAllocated:=True;
      end;
  finally
    glPopAttrib;
    Canvas.Unlock;
  end;
end;

procedure TGlTexture.LoadFromRawPtr(Format: TTextureFormat; SX, SY, SZ,
  Width, Height, Depth: Integer; Data: Pointer; DataWidth, DataHeight: Integer);
var
  a,b,c,d:Integer;
  p:Pointer;
begin
  FOwner.Lock;
  glPushAttrib(GL_ALL_ATTRIB_BITS);
  try
    Self.Width:=Width;
    Self.Height:=Height;
    Self.Depth:=Depth;
    if not FContentAllocated then
      AllocateContent;

    glPixelStore(GL_UNPACK_ALIGNMENT,4);

    glPixelStore(GL_UNPACK_ROW_LENGTH,DataWidth);
//    glPixelStore(GL_UNPACK_IMAGE_HEIGHT,DataHeight);

    glPixelStore(GL_UNPACK_SKIP_PIXELS,SX);
    glPixelStore(GL_UNPACK_SKIP_ROWS,SY);
//    glPixelStore(GL_UNPACK_SKIP_IMAGES,SZ);

    with FUnits do begin
      if (Width<>TexSize[0]) or (Height<>TexSize[1]) then begin
        glPixelStore(GL_PACK_ALIGNMENT,4);

        glPixelStore(GL_PACK_ROW_LENGTH,TexSize[0]);
  //    glPixelStore(GL_PACK_IMAGE_HEIGHT,TexSize[1]);

        glPixelStore(GL_PACK_SKIP_PIXELS,0);
        glPixelStore(GL_PACK_SKIP_ROWS,0);
  //    glPixelStore(GL_PACK_SKIP_IMAGES,0);

        a:=Align32(32*TexSize[0])*TexSize[1]*TexSize[2];
        WinGetMem(p,a);

        gluScaleImage(GL_RGB,Width,Height,GL_UNSIGNED_BYTE,Data,TexSize[0],TexSize[1],GL_UNSIGNED_BYTE,p);

        SX:=0;
        SY:=0;

        glPixelStore(GL_UNPACK_ALIGNMENT,4);

        glPixelStore(GL_UNPACK_ROW_LENGTH,TexSize[0]);
        //glPixelStore(GL_UNPACK_IMAGE_HEIGHT,TexSize[1]);
      end else
        p:=Data;
      for d:=0 to TexCount-1 do begin
        glBindTexture(GetTarget,TexID[d]);
        GetUnitCoord(d,a,b,c);
        glPixelStore(GL_UNPACK_SKIP_PIXELS,SX+MeshCoord[0,a]);
        glPixelStore(GL_UNPACK_SKIP_ROWS,SY+MeshCoord[1,b]);
        //glPixelStore(GL_UNPACK_SKIP_IMAGES,SY+MeshCoord[2,c]);
        SetPtrData(ttSub,MeshCoord[0,a+1]-MeshCoord[0,a],MeshCoord[1,b+1]-MeshCoord[1,b],MeshCoord[2,c+1]-MeshCoord[2,c],0,0,0,p,GetGlFormat(Format),GL_UNSIGNED_BYTE);
      end;
      if p<>Data then
        WinFreeMem(p);
    end;
  finally
    glPopAttrib;
    FOwner.Unlock;
  end;
end;

procedure TGlTexture.SetDepth(const Value: Integer);
begin
  if Value<>FSize[2] then begin
    FSize[2] := Value;
    Unallocate;
  end;
end;

procedure TGlTexture.SetFormat(const Value: TTextureFormat);
begin
  if Value<>FFormat then begin
    FFormat := Value;
    Unallocate;
  end;
end;

procedure TGlTexture.SetHeight(const Value: Integer);
begin
  if Value<>FSize[1] then begin
    FSize[1] := Value;
    Unallocate;
  end;
end;

procedure TGlTexture.SetWidth(const Value: Integer);
begin
  if Value<>FSize[0] then begin
    FSize[0] := Value;
    Unallocate;
  end;
end;

procedure TGlTexture.Unallocate;
begin
  with FUnits do begin
    if TexCount>0 then begin
      FOwner.Lock;
      glPushAttrib(GL_ALL_ATTRIB_BITS);
      try
        glDeleteTextures(TexCount,@TexId[0]);
      finally
        glPopAttrib;
        FOwner.Unlock;
      end;
    end;
    TexCount:=0;
  end;
  FUnitAllocated:=False;
  FContentAllocated:=False;
end;

{ TGl2DTexture }

procedure TGl2DTexture.CopyData(TransfertType: TTransfertType; X, Y, Width,
  Height, Depth, DX, DY, DZ: Integer);
begin
  case TransfertType of
    ttFull:glCopyTexImage2D(GL_TEXTURE_2D,0,GetGlFormat,X,Y,Width,Height,0);
    ttSub:glCopyTexSubImage2D(GL_TEXTURE_2D,0,DX,DY,X,Y,Width,Height);
  end;
end;

constructor TGl2DTexture.Create(AOwner: TGlCanvas);
begin
  inherited;
  FSize[2]:=1;
end;

class function TGl2DTexture.GetTarget: Integer;
begin
  Result:=GL_TEXTURE_2D;
end;

class function TGl2DTexture.GetTargetProxy: Integer;
begin
  Result:=GL_PROXY_TEXTURE_2D;
end;

procedure TGl2DTexture.PaintTo(Canvas: TGlCanvas; X, Y, W, H: Single);
var
  a,b,c,d:Integer;
  u,v:Single;
begin
  if Canvas.GetDisplayListOwner<>FOwner then
    raise Exception.Create('couille');
  Canvas.Lock;
  try
    glEnable(GetTarget);
    with FUnits do begin
      for d:=0 to TexCount-1 do begin
        GetUnitCoord(d,a,b,c);
        glBindTexture(GetTarget,TexID[d]);
        glTexParameter(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
        glTexParameter(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
        u:=(MeshCoord[0,a+1]-MeshCoord[0,a])/UnitGlSize[0,a];
        v:=(MeshCoord[1,b+1]-MeshCoord[1,b])/UnitGlSize[1,b];
        glBegin(GL_QUADS);
        glTexCoord2f(0,0);
        glVertex2f(X+MeshCoord[0,a]*W/TexSize[0],Y+H-MeshCoord[1,b]*H/TexSize[1]);
        glTexCoord2f(u,0);
        glVertex2f(X+MeshCoord[0,a+1]*W/TexSize[0],Y+H-MeshCoord[1,b]*H/TexSize[1]);
        glTexCoord2f(u,v);
        glVertex2f(X+MeshCoord[0,a+1]*W/TexSize[0],Y+H-MeshCoord[1,b+1]*H/TexSize[1]);
        glTexCoord2f(0,v);
        glVertex2f(X+MeshCoord[0,a]*W/TexSize[0],Y+H-MeshCoord[1,b+1]*H/TexSize[1]);
        glEnd;
      end;
    end;
  finally
    Canvas.Unlock;
  end;
end;

procedure TGl2DTexture.SetProxyData(Width, Height, Depth: Integer);
begin
  glTexImage2D(GL_PROXY_TEXTURE_2D,0,GetGlFormat,Width,Height,0,GL_LUMINANCE,GL_UNSIGNED_BYTE,nil);
end;

procedure TGl2DTexture.SetPtrData(TransfertType: TTransfertType; Width, Height,
  Depth, DX, DY, DZ: Integer; Pixels: Pointer; Format,
  _type: Integer);
begin
  case TransfertType of
    ttFull:glTexImage2D(GL_TEXTURE_2D,0,GetGlFormat,Width,Height,0,Format,_type,Pixels);
    ttSub:glTexSubImage2D(GL_TEXTURE_2D,0,DX,DY,Width,Height,Format,_type,Pixels);
  end;
end;

end.

