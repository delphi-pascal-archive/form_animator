unit TLS;

interface

uses
  SysUtils,Classes,Windows,SyncObjs;

type
  TTLSObject=class(TObject)
  private
    FIndex:Cardinal;
    function GetValue: Pointer;
    procedure SetValue(const Value: Pointer);
  protected
    property Value:Pointer read GetValue write SetValue;
  public
    constructor Create;
    destructor Destroy;override;
  end;

implementation

{ TTLSObject }

constructor TTLSObject.Create;
begin
  inherited;
  FIndex:=TlsAlloc;
  if FIndex=TLS_OUT_OF_INDEXES then
    RaiseLastOSError;
end;

destructor TTLSObject.Destroy;
begin
  if not TlsFree(FIndex) then
    RaiseLastOSError;
  inherited;
end;

function TTLSObject.GetValue: Pointer;
var
  e:Cardinal;
begin
  Result:=TlsGetValue(FIndex);
  e:=GetLastError;
  if e<>ERROR_SUCCESS then
    raise EOSError.Create(SysErrorMessage(e));
end;

procedure TTLSObject.SetValue(const Value: Pointer);
begin
  if not TlsSetValue(FIndex,Value) then
    RaiseLastOSError;
end;

end.
