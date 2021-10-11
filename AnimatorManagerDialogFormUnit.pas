{
  AnimatorManagerDialogFormUnit.pas
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

unit AnimatorManagerDialogFormUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, AnimatorManager, StdCtrls, ExtCtrls, ComCtrls, Buttons;

type
  TAnimatorManagerDialogForm = class(TForm)
    GroupBox1: TGroupBox;
    Panel1: TPanel;
    Panel2: TPanel;
    ListBox1: TListBox;
    TrackBar1: TTrackBar;
    TrackBar2: TTrackBar;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    BitBtn3: TBitBtn;
    Panel3: TPanel;
    PaintBox1: TPaintBox;
    procedure TrackBar2Change(Sender: TObject);
    procedure TrackBar1Change(Sender: TObject);
    procedure BitBtn3Click(Sender: TObject);
    procedure ListBox1Click(Sender: TObject);
    procedure PaintBox1Paint(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    FPreview:TForm;
  public
    function Execute:Boolean;
  end;

var
  AnimatorManagerDialogForm: TAnimatorManagerDialogForm=nil;

implementation

{$R *.dfm}

{ TAnimatorManagerDialogForm }

function TAnimatorManagerDialogForm.Execute: Boolean;
var
  a:Integer;
begin
  ListBox1.Clear;
  ListBox1.Items.Add('Pas d''animations (désactivé)');
  for a:=0 to GAnimatorManager.RegisteredAnimatorClassCount-1 do
    ListBox1.Items.Add(GAnimatorManager.AnimatorClass[a].GetCaption);
  ListBox1.ItemIndex:=GAnimatorManager.AnimatorClassID;
  TrackBar1.Position:=GAnimatorManager.Delay;
  TrackBar2.Position:=GAnimatorManager.AnimationProbability;
  TrackBar1Change(nil);
  TrackBar2Change(nil);
  Result:=ShowModal=mrOk;
  Application.MainForm.Repaint;
end;

procedure TAnimatorManagerDialogForm.TrackBar2Change(Sender: TObject);
begin
  Panel2.Caption:=Format(' Utilisation: %d%%',[TrackBar2.Position]);
  GAnimatorManager.AnimationProbability:=TrackBar2.Position;
end;

procedure TAnimatorManagerDialogForm.TrackBar1Change(Sender: TObject);
begin
  Panel1.Caption:=Format(' Duration: %d ms',[TrackBar1.Position]);
  GAnimatorManager.Delay:=TrackBar1.Position;
end;

procedure TAnimatorManagerDialogForm.BitBtn3Click(Sender: TObject);
begin
  FPreview.Hide;
  GAnimatorManager.AnimateForm(FPreview,True);
  FPreview.Show;
end;

procedure TAnimatorManagerDialogForm.ListBox1Click(Sender: TObject);
var
  a:Integer;
begin
  GAnimatorManager.AnimatorClassID:=ListBox1.ItemIndex;
  BitBtn3.Click;
  if ListBox1.Items.Count<>GAnimatorManager.RegisteredAnimatorClassCount+1 then begin
    ListBox1.Items.BeginUpdate;
    try
      ListBox1.Items.Clear;
      ListBox1.Items.Add('Pas d''animations (désactivé)');
      for a:=0 to GAnimatorManager.RegisteredAnimatorClassCount-1 do
        ListBox1.Items.Add(GAnimatorManager.AnimatorClass[a].GetCaption);
    finally
      ListBox1.Items.EndUpdate;
    end;
  end;
  ListBox1.ItemIndex:=GAnimatorManager.AnimatorClassID;
end;

procedure TAnimatorManagerDialogForm.PaintBox1Paint(Sender: TObject);
begin
  PaintBox1.Canvas.FillRect(PaintBox1.ClientRect);
end;

procedure TAnimatorManagerDialogForm.FormCreate(Sender: TObject);
begin
  Application.CreateForm(TForm,FPreview);
  FPreview.BorderIcons:=[];
  FPreview.Parent:=Panel3;
  FPreview.Caption:='Exemple d''animation';
  FPreview.SetBounds(20,20,Panel3.ClientWidth-40,Panel3.ClientHeight-40);
  FPreview.Visible:=True;
end;

end.
