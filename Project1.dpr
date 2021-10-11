program Project1;

uses
  Forms,
  Unit1 in 'Unit1.pas' {Form1},
  AnimatorManager in 'AnimatorManager.pas',
  FormAnimator in 'FormAnimator.pas',
  GlBitmap in 'GlBitmap.pas',
  GlCanvas in 'GlCanvas.pas',
  GlFont in 'GlFont.pas',
  GlTexture in 'GlTexture.pas',
  TLS in 'TLS.pas',
  AnimatorManagerDialogFormUnit in 'AnimatorManagerDialogFormUnit.pas' {AnimatorManagerDialogForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
