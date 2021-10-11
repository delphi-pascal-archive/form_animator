unit GlFont;

interface

uses
  SysUtils,Classes,Windows,OpenGl,Graphics,SyncObjs;

type
  TGlyphMetricsFloats=array[#0..#255] of TGlyphMetricsFloat;

  TGlFontData=record
    ListBase:Cardinal;
    Font:HFont;
    Name:PChar;
    Style:TFontStyles;
    ListOwner:Pointer;
    GlyphMetrics:TGlyphMetricsFloats;
  end;

  TGlFont=class
  private
    FIndex:Integer;
    FSize:Single;
    FStyle:TFontStyles;
    FName:string;
    FListOwner: Pointer;

    function GetIndex:Integer;
    function GetData:TGlFontData;
  protected
    property Index:Integer read GetIndex;
    property Data:TGlFontData read GetData;

    procedure Bind;
    procedure UnBind;
  public
    constructor Create(AListOwner:Pointer);

    function GetName:PChar;
    procedure SetName(Value:PChar);
    property Name:PChar read GetName write SetName;              //Like the usual TFont

    function GetSize:Single;
    procedure SetSize(Value:Single);
    property Size:Single read GetSize write SetSize;             //Like the usual TFont

    function GetStyle:TFontStyles;
    procedure SetStyle(Value:TFontStyles);
    property Style:TFontStyles read GetStyle write SetStyle;     //Like the usual TFont

    function TextSize(Text:PChar):TSize;                         //Size of text (given the size of the font)
    procedure TextOut(X,Y:Single;Text:PChar);                    //Draw text on current canvas

    destructor Destroy;override;
  end;

  TGlFontManager=class
  private
    FFontDatas:array of TGlFontData;
    FSection:TCriticalSection;
  public
    constructor Create;

    function GeTGlFontIndex(AFont:TGlFont):Integer;
    function GeTGlFontData(Index:Integer):TGlFontData;

    destructor Destroy;override;
  end;

var
  GFontManager:TGlFontManager=nil;

procedure Initialize;
procedure Finalize;

implementation

uses
  GlCanvas;

procedure Initialize;
begin
  GFontManager:=TGlFontManager.Create;
end;

procedure Finalize;
begin
  GFontManager.Destroy;
end;

{ TGlFont }

procedure TGlFont.Bind;
begin
  //Assert(GCanvasManager.CurrentCanvas<>nil,'No canvas was current while trying to bind font');
  glPushAttrib(GL_LIST_BIT);
  glListBase(Data.ListBase);
end;

constructor TGlFont.Create(AListOwner: Pointer);
begin
  inherited Create;
  FListOwner:=AListOwner;
  FIndex:=-1;
  FSize:=16;
end;

destructor TGlFont.Destroy;
begin
  inherited;
end;

function TGlFont.GetData: TGlFontData;
begin
  Result:=GFontManager.GeTGlFontData(Index);
end;

function TGlFont.GetIndex: Integer;
begin
  if FIndex=-1 then
    FIndex:=GFontManager.GetGlFontIndex(Self);
  Result:=FIndex;
end;

function TGlFont.GetName: PChar;
begin
  Result:=Data.Name;
end;

function TGlFont.GetSize: Single;
begin
  Result:=FSize;
end;

function TGlFont.GetStyle: TFontStyles;
begin
  Result:=FStyle;
end;

procedure TGlFont.SetName(Value: PChar);
begin
  FName:=Value;
  FIndex:=-1;
end;

procedure TGlFont.SetSize(Value: Single);
begin
  FSize:=Value;
end;

procedure TGlFont.SetStyle(Value: TFontStyles);
begin
  FStyle:=Value;
  FIndex:=-1;
end;

procedure TGlFont.TextOut(X, Y: Single; Text: PChar);
begin
  Bind;
  glMatrixMode(GL_MODELVIEW);
  glPushMatrix;
//  GTLSCanvasManager.CurrentCanvas.ModelViewMatrix.Push;
  try
    glTranslate(X+0.3,Size*0.85+Y+0.3,0);
    glScale(Size,-Size,Size);
    glCallLists(Length(Text),GL_UNSIGNED_BYTE,Text);
  finally
//    GTLSCanvasManager.CurrentCanvas.ModelViewMatrix.Pop;
    glPopMatrix;
    UnBind;
  end;
end;

function TGlFont.TextSize(Text: PChar): TSize;
var
  a:Integer;
  w,h:Single;
begin
  w:=0;
  if Length(Text)>0 then
    h:=1.2//Data.GlyphMetrics[#13].gmfCellIncY
  else
    h:=0;
  for a:=0 to Length(Text)-1 do
    w:=w+Data.GlyphMetrics[Text[a]].gmfCellIncX;
  Result.cx:=Round(FSize*w);
  Result.cy:=Round(FSize*h);
end;

procedure TGlFont.UnBind;
begin
  glPopAttrib;
end;

{ TGlFontManager }

constructor TGlFontManager.Create;
begin
  inherited;
  FSection:=TCriticalSection.Create;
end;

destructor TGlFontManager.Destroy;
var
  a:Integer;
begin
  FSection.Destroy;
  for a:=0 to High(FFontDatas) do
    Assert(DeleteObject(FFontDatas[a].Font),SysErrorMessage(GetLastError));
  SetLength(FFontDatas,0);
  inherited;
end;

function TGlFontManager.GeTGlFontData(Index: Integer): TGlFontData;
begin
  FSection.Enter;
  try
    Assert((Index>=0) and (Index<=High(FFontDatas)));
    Result:=FFontDatas[Index];
  finally
    FSection.Leave;
  end;
end;

function TGlFontManager.GeTGlFontIndex(AFont: TGlFont): Integer;

  procedure Launch;
  var
    a:Integer;
    f:TGlFontData;
    LF:TLogFont;
    t:string;
  const
    Quality=0;
  begin
    if High(FFontDatas)<0 then begin
      f.Font:=GetStockObject(DEFAULT_GUI_FONT);
      TGlCanvas(AFont.FListOwner).GetDisplayListOwner.Lock;
      try
        f.ListBase:=glGenLists(256);
        Assert(SelectObject(wglGetCurrentDC,f.Font)<>0,SysErrorMessage(GetLastError));
        Assert(wglUseFontOutlines(wglGetCurrentDC,0,256,f.ListBase,Quality,0,WGL_FONT_POLYGONS,@f.GlyphMetrics),SysErrorMessage(GetLastError));
        a:=GetTextFace(wglGetCurrentDC,0,nil);
        Assert(a<>0,SysErrorMessage(GetLastError));
        GetMem(f.Name,a);
        a:=GetTextFace(wglGetCurrentDC,a,f.Name);
        Assert(a<>0,SysErrorMessage(GetLastError));
      finally
        TGlCanvas(AFont.FListOwner).GetDisplayListOwner.UnLock;
      end;
      f.Style:=[];
      f.ListOwner:=AFont.FListOwner;
      SetLength(FFontDatas,1);
      FFontDatas[0]:=f;
    end;
    for a:=0 to High(FFontDatas) do begin
      with FFontDatas[a] do begin
        if ((AFont.FName='') or (Name=AFont.FName) and (Style=AFont.Style)) and (ListOwner=AFont.FListOwner) then begin
          Result:=a;
          Exit;
        end;
      end;
    end;
    ZeroMemory(@LF,SizeOf(LF));
    if fsBold in AFont.Style then
      LF.lfWeight:=FW_BOLD
    else
      LF.lfWeight:=FW_NORMAL;
    LF.lfHeight:=50;
    if fsItalic in AFont.Style then
      LF.lfItalic:=255;
    LF.lfCharSet:=DEFAULT_CHARSET;
    LF.lfOutPrecision:=OUT_DEFAULT_PRECIS;
    LF.lfQuality:=DEFAULT_QUALITY;
    LF.lfPitchAndFamily:=DEFAULT_PITCH;
    t:=Copy(AFont.FName,1,31);
    if Length(t)>0 then
      CopyMemory(@LF.lfFaceName[0],@t[1],Length(t));
    f.Font:=CreateFontIndirect(LF);
    Assert(f.Font<>0,SysErrorMessage(GetLastError));
    TGlCanvas(AFont.FListOwner).GetDisplayListOwner.Lock;
    try
      f.ListBase:=glGenLists(256);
      Assert(SelectObject(wglGetCurrentDC,f.Font)<>0,SysErrorMessage(GetLastError));
      if not wglUseFontOutlines(wglGetCurrentDC,0,256,f.ListBase,Quality,0,WGL_FONT_POLYGONS,@f.GlyphMetrics) then begin
        glDeleteLists(f.ListBase,256);
        DeleteObject(f.Font);
        Result:=0;
        Exit;
      end;
      a:=GetTextFace(wglGetCurrentDC,0,nil);
      Assert(a<>0,SysErrorMessage(GetLastError));
      GetMem(f.Name,a);
      a:=GetTextFace(wglGetCurrentDC,a,f.Name);
      Assert(a<>0,SysErrorMessage(GetLastError));
    finally
      TGlCanvas(AFont.FListOwner).GetDisplayListOwner.UnLock;
    end;
    SetLength(FFontDatas,High(FFontDatas)+2);
    Result:=High(FFontDatas);
    f.Style:=AFont.FStyle;
    f.ListOwner:=AFont.FListOwner;
    FFontDatas[Result]:=f;
  end;

begin
  FSection.Enter;
  try
    Launch;
  finally
    FSection.Leave;
  end;
end;

initialization
  Initialize;
finalization
  Finalize;
end.
