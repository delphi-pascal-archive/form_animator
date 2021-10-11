unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, AnimatorManager, Menus, IniFiles;

type
  TForm1 = class(TForm)
    MainMenu1: TMainMenu;
    Options1: TMenuItem;
    Animations1: TMenuItem;
    procedure Animations1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.Animations1Click(Sender: TObject);
begin
  GAnimatorManager.Customize;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  f:TIniFile;
begin
  f:=TIniFile.Create(ChangeFileExt(Application.ExeName,'.ini'));
  GAnimatorManager.LoadFromIniFile(f);
  f.Destroy;
end;

procedure TForm1.FormDestroy(Sender: TObject);
var
  f:TIniFile;
begin
  f:=TIniFile.Create(ChangeFileExt(Application.ExeName,'.ini'));
  GAnimatorManager.SaveToIniFile(f);
  f.Destroy;
end;

end.
 