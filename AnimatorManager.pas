{
  AnimatorManager.pas
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

unit AnimatorManager;

interface

uses
  SysUtils,Classes,Windows,Messages,FormAnimator,Contnrs,Controls,Forms,Dialogs,
  IniFiles;

type
  TCustomFormHack=class(TCustomForm);

  TAnimatorManager=class
  private
    FAnimatorClassID: Integer;
    FAnimator: TFormAnimator;
    FCurrentForm: TCustomFormHack;
    FRegisteredAnimatorClasses: TClassList;
    FHook: HHOOK;
    FAnimationProbability: Integer;

    procedure SetDelay(const Value: Cardinal);
    procedure SetAnimatorClassID(const Value: Integer);
    function GetRegisteredAnimatorClassCount: Integer;
    function GetAnimatorClass(Index: Integer): TFormAnimatorClass;
    function GetDelay: Cardinal;
    procedure SetAnimationProbability(const Value: Integer);

    procedure WMShowWindow(var Message:TWMShowWindow);message WM_SHOWWINDOW;
  protected
    procedure HackedWNDProc(var Message:TMessage);
    procedure HackFormWNDProc(AForm:TCustomForm);
    procedure HackWindows;
  public
    constructor Create;

    procedure DefaultHandler(var Message);override;

    procedure AnimateForm(AForm:TCustomForm;Force:Boolean=False);

    procedure Customize;

    property Delay:Cardinal read GetDelay write SetDelay;
    property AnimatorClassID:Integer read FAnimatorClassID write SetAnimatorClassID;
    property AnimationProbability:Integer read FAnimationProbability write SetAnimationProbability;

    procedure RegisterAnimatorClass(AClass:TFormAnimatorClass);
    property RegisteredAnimatorClassCount:Integer read GetRegisteredAnimatorClassCount;
    property AnimatorClass[Index:Integer]:TFormAnimatorClass read GetAnimatorClass;

    procedure SaveToIniFile(AIniFile:TIniFile;Section:string='Animator');
    procedure LoadFromIniFile(AIniFile:TIniFile;Section:string='Animator');

    destructor Destroy;override;
  end;

var
  GAnimatorManager:TAnimatorManager=nil;

implementation

uses
  AnimatorManagerDialogFormUnit;

function CBTProc(nCode,wParam:Integer;lParam:PCBTCreateWnd):Integer;stdcall;
begin
  Result:=CallNextHookEx(GAnimatorManager.FHook,nCode,wParam,Integer(lParam));
  if nCode=HCBT_CREATEWND then
    GAnimatorManager.HackWindows;
end;

{ TAnimatorManager }

procedure TAnimatorManager.AnimateForm(AForm: TCustomForm; Force: Boolean);
var
  a:TFormAnimator;
begin
  if Assigned(FAnimator) and
    ((AForm.Parent=nil) and (AForm.ParentWindow=0) and (Random(100)<FAnimationProbability) or Force) then begin
    try
      FAnimator.AnimateForm(AForm);
    except
      on e:Exception do begin
        a:=FAnimator;
        FAnimator:=nil;
        if MessageDlg('Le gestionnaire d''animations a provoqué une erreur avec ce message:'#13#13'"'+e.Message+'"'#13#13'Souhaitez-vous le désactiver, ainsi que le style "'+TFormAnimatorClass(FRegisteredAnimatorClasses[FAnimatorClassID-1]).GetCaption+'", qui a déclenché l''erreur?',mtWarning,[mbYes,mbNo],0)=mrYes then begin
          FRegisteredAnimatorClasses.Delete(FAnimatorClassID-1);
          FAnimator:=a;
          AnimatorClassID:=0;
        end else
          FAnimator:=a;
      end;
    end;
  end;
end;

constructor TAnimatorManager.Create;
begin
  Randomize;
  if Assigned(GAnimatorManager) then
    raise EInvalidOperation.Create('Animator manager already created'); 
  GAnimatorManager:=Self;
  inherited;
  FRegisteredAnimatorClasses:=TClassList.Create;
  RegisterAnimatorClass(TClassicAnimator);
  RegisterAnimatorClass(TWinAnimator);
  RegisterAnimatorClass(TVistaEmulationAnimator);
  RegisterAnimatorClass(TGLFormAnimator);
  FHook:=SetWindowsHookEx(WH_CBT,@CBTProc,0,GetCurrentThreadId);
  FAnimationProbability:=100;
end;

procedure TAnimatorManager.Customize;
var
  LDelay:Cardinal;
  LAnimatorClassID,LAnimationProbability:Integer;
begin
  LDelay:=Delay;
  LAnimatorClassID:=FAnimatorClassID;
  LAnimationProbability:=FAnimationProbability;
  if not Assigned(AnimatorManagerDialogForm) then
    Application.CreateForm(TAnimatorManagerDialogForm,AnimatorManagerDialogForm);
  if not AnimatorManagerDialogForm.Execute then begin
    AnimatorClassID:=LAnimatorClassID;
    Delay:=LDelay;
    AnimationProbability:=LAnimationProbability;
  end;
end;

procedure TAnimatorManager.DefaultHandler(var Message);
begin
  if Assigned(FCurrentForm) then
    FCurrentForm.WndProc(TMessage(Message));
end;

destructor TAnimatorManager.Destroy;
begin
  UnhookWindowsHookEx(FHook);
  FRegisteredAnimatorClasses.Destroy;
  if Assigned(FAnimator) then
    FAnimator.Destroy;
  inherited;
  GAnimatorManager:=nil;
end;

function TAnimatorManager.GetAnimatorClass(
  Index: Integer): TFormAnimatorClass;
begin
  Result:=TFormAnimatorClass(FRegisteredAnimatorClasses[Index]);
end;

function TAnimatorManager.GetDelay: Cardinal;
begin
  Result:=TimeMax;
end;

function TAnimatorManager.GetRegisteredAnimatorClassCount: Integer;
begin
  Result:=FRegisteredAnimatorClasses.Count;
end;

procedure TAnimatorManager.HackedWNDProc(var Message: TMessage);
var
  OldForm:TCustomFormHack;
begin
  if Assigned(GAnimatorManager) then begin
    OldForm:=GAnimatorManager.FCurrentForm;
    GAnimatorManager.FCurrentForm:=TCustomFormHack(Self);
    GAnimatorManager.Dispatch(Message);
    GAnimatorManager.FCurrentForm:=OldForm;
  end else
    TCustomFormHack(Self).WndProc(Message);
end;

procedure TAnimatorManager.HackFormWNDProc(AForm: TCustomForm);
var
  m:TMethod;
begin
  TWndMethod(m):=HackedWNDProc;
  m.Data:=AForm;
  TCustomFormHack(AForm).WindowProc:=TWndMethod(m);
end;

procedure TAnimatorManager.HackWindows;
var
  a:Integer;
begin
  for a:=Screen.FormCount-1 downto 0 do
    HackFormWNDProc(Screen.Forms[a]);
end;

procedure TAnimatorManager.LoadFromIniFile(AIniFile: TIniFile;
  Section: string);
var
  s:string;
  a:Integer;
begin
  Delay:=AIniFile.ReadInteger(Section,'Delay',Delay);
  FAnimationProbability:=AIniFile.ReadInteger(Section,'AnimationProbability',FAnimationProbability);
  s:=AIniFile.ReadString(Section,'AnimatorClass','');
  for a:=0 to FRegisteredAnimatorClasses.Count-1 do
    if FRegisteredAnimatorClasses[a].ClassNameIs(s) then begin
      AnimatorClassID:=a+1;
      Break;
    end;
end;

procedure TAnimatorManager.RegisterAnimatorClass(
  AClass: TFormAnimatorClass);
begin
  FRegisteredAnimatorClasses.Add(AClass);
end;

procedure TAnimatorManager.SaveToIniFile(AIniFile: TIniFile;
  Section: string);
begin
  AIniFile.WriteInteger(Section,'Delay',Delay);
  AIniFile.WriteInteger(Section,'AnimationProbability',FAnimationProbability);
  if Assigned(FAnimator) then
    AIniFile.WriteString(Section,'AnimatorClass',FAnimator.ClassName)
  else
    AIniFile.WriteString(Section,'AnimatorClass','');
end;

procedure TAnimatorManager.SetAnimationProbability(const Value: Integer);
begin
  FAnimationProbability := Value;
end;

procedure TAnimatorManager.SetAnimatorClassID(const Value: Integer);
begin
  if FAnimatorClassID<>Value then begin
    try
      if Assigned(FAnimator) then
        FreeAndNil(FAnimator);
    finally
      FAnimatorClassID := Value;
      if FAnimatorClassID>FRegisteredAnimatorClasses.Count then
        FAnimatorClassID:=FRegisteredAnimatorClasses.Count;
      if FAnimatorClassID<0 then
        FAnimatorClassID:=0;
      if FAnimatorClassID>0 then begin
        try
          FAnimator:=TFormAnimatorClass(FRegisteredAnimatorClasses[FAnimatorClassID-1]).Create;
        except
          on e:Exception do begin
            if MessageDlg('Le gestionnaire d''animations a provoqué une erreur avec ce message:'#13#13'"'+e.Message+'"'#13#13'Souhaitez-vous retirer le style "'+TFormAnimatorClass(FRegisteredAnimatorClasses[FAnimatorClassID-1]).GetCaption+'", qui a déclenché l''erreur?',mtWarning,[mbYes,mbNo],0)=mrYes then 
              FRegisteredAnimatorClasses.Delete(FAnimatorClassID-1);
            AnimatorClassID:=0;
          end;
        end;
      end;
    end;
  end;
end;

procedure TAnimatorManager.SetDelay(const Value: Cardinal);
begin
  TimeMax := Value;
end;

procedure TAnimatorManager.WMShowWindow(var Message: TWMShowWindow);
begin
  inherited;
  if Message.Show and (TCustomForm(FCurrentForm) is TForm) and (Message.Status=0) then
    AnimateForm(FCurrentForm);
end;

initialization
  TAnimatorManager.Create;
finalization
  GAnimatorManager.Destroy;
end.
