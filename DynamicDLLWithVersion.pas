unit DynamicDLLWithVersion;

interface

uses
  SysUtils, Classes, DynamicDLL;

type
  TDynamicDLLWithVersion = class(TDynamicDLL)
  protected
    DLL_VersionMinDefault: Integer;
    DLL_VersionMaxDefault: Integer;
  public
    DLL_Version: Integer;
    DLL_VersionMin: Integer;
    DLL_VersionMax: Integer;
    DLL_VersionMax_LowDependencies: Integer;
    IsEssential: Boolean;
    constructor Create(AOwner: TComponent); override;
    function LoadDll: Boolean; override;
  protected
    procedure BeforeLoad; override;
    function ResolvePaths: Boolean; virtual;
  end;

implementation

{ TDynamicDLLWithVersion }

constructor TDynamicDLLWithVersion.Create(AOwner: TComponent);
begin
  inherited;
  DLL_Version := 0;
  DLL_VersionMin := 0;
  DLL_VersionMax := 0;
  DLL_VersionMax_LowDependencies := 0;
  IsEssential := True;
end;

procedure TDynamicDLLWithVersion.BeforeLoad;
begin
  inherited;
  ResolvePaths;
end;

function TDynamicDLLWithVersion.LoadDll: Boolean;
var
  ThisIsEssential: Boolean;
begin
  {Result := Inherited;
  exit;}
  ResolvePaths;
  DllName := ''; // workaround a wierd bug
  Result := False;
  while DLL_VersionMax >= DLL_VersionMin do begin
    ThisIsEssential := IsEssential and (DLL_Version = DLL_VersionMin);
    FatalAbort := ThisIsEssential;
    FatalMsgDlg := ThisIsEssential;
    Result := inherited;
    if Result then begin
      break;
    end else begin
      DLL_VersionMax := DLL_Version-1;
      DLL_Version := 0;
      DllName := '';
    end;
  end;
end;

function TDynamicDLLWithVersion.ResolvePaths: Boolean;
begin
  Result := True;
end;

end.
