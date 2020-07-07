unit DynamicDLLWithVersion;

interface

uses
  SysUtils, Classes, DynamicDLL;

type
  TDynamicDLLWithVersion = class(TDynamicDLL)
  public
    DLL_Base_Name: String;
    DLL_Version: Integer;
    DLL_VersionMin: Integer;
    DLL_VersionMax: Integer;
    DLL_VersionMax_LowDependencies: Integer;
    DLL_Version_MajorMod: Integer;
    IsEssential: Boolean;
    constructor Create(AOwner: TComponent); override;
    function LoadDll: Boolean; override;
    function GetDLL_Version_Major(v: Integer): Integer; virtual;
    function GetDLL_Version_Minor(v: Integer): Integer; virtual;
  protected
    procedure BeforeLoad; override;
    function ResolvePaths: Boolean; virtual;
    function GetDllName: String; override;
    function GetDllNameByVersion(v: Integer): String; virtual;
  end;

implementation

{ TDynamicDLLWithVersion }

constructor TDynamicDLLWithVersion.Create(AOwner: TComponent);
begin
  inherited;
  DLL_Base_Name := '';
  DLL_Version := 0;
  DLL_VersionMin := 0;
  DLL_VersionMax := 0;
  DLL_VersionMax_LowDependencies := 0;
  DLL_Version_MajorMod := 100;
  IsEssential := True;
end;

function TDynamicDLLWithVersion.GetDllName: String;
begin
  Result := inherited;
  if (Result='') and (DLL_Version <> 0) then
    Result := GetDllNameByVersion(DLL_Version);
end;

function TDynamicDLLWithVersion.GetDllNameByVersion(v: Integer): String;
begin
  Result := DLL_Base_Name + IntToStr(v) + '.dll';
end;

function TDynamicDLLWithVersion.GetDLL_Version_Major(v: Integer): Integer;
begin
  Result := v div DLL_Version_MajorMod;
end;

function TDynamicDLLWithVersion.GetDLL_Version_Minor(v: Integer): Integer;
begin
  Result := v mod DLL_Version_MajorMod;
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
  if DllName <> '' then begin
    Result := Inherited;
  end else begin
//    ResolvePaths;
//    DllName := ''; // workaround a wierd bug
    Result := False;
    while DLL_VersionMax >= DLL_VersionMin do begin
      ThisIsEssential := IsEssential and (DLL_Version = DLL_VersionMin);
      FatalAbort := ThisIsEssential;
      FatalMsgDlg := ThisIsEssential;
      Result := inherited;
      if Result or (DLL_Version=0) then
        break
      else begin
        DLL_VersionMax := DLL_Version-1;
        DLL_Version := 0;
        DllName := '';
      end;
    end;
  end;
end;

function TDynamicDLLWithVersion.ResolvePaths: Boolean;
var
  v: Integer;
  DLLName1: String;
begin
  Result := DLL_Version<>0;
  if Result then exit;

  if (FDllPath = '') then exit;
  if not DirectoryExists(FDllPath) then exit;
  DllPath := IncludeTrailingPathDelimiter(DllPath);
  for v := DLL_VersionMax downto DLL_VersionMin do begin
    DLLName1 := GetDllNameByVersion(v);
    Result := FileExists(DllPath + DLLName1);
    if Result then begin
      DLL_Version := v;
      exit;
    end;
  end;
end;

end.
