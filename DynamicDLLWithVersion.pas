unit DynamicDLLWithVersion;

interface

uses
  SysUtils, Classes, DynamicDLL;

type
  TDynamicDLLWithVersion = class(TDynamicDLL)
  protected
    DLL_VersionsSupported: TList;
    DLL_VersionsSpeculated: TList;
    DLL_VersionsFallback: TList;
    DLL_Base_Name: String;
    DLL_Version_MajorMod: Integer;
  public
    DLL_Version: Integer;
    PrefereFallback: Boolean;
    IsEssential: Boolean;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function LoadDll: Boolean; override;
    function LoadDllByVersion(Versions: TList): Boolean;
    function GetDLL_Version_Major(v: Integer): Integer; virtual;
    function GetDLL_Version_Minor(v: Integer): Integer; virtual;
  protected
    procedure BeforeLoad; override;
    function ResolvePaths: Boolean; virtual;
    function GetDllNameByVersion(v: Integer): String; virtual;
  end;

implementation

{ TDynamicDLLWithVersion }

constructor TDynamicDLLWithVersion.Create(AOwner: TComponent);
begin
  inherited;
  DLL_Base_Name := '';
  DLL_Version := 0;
  DLL_VersionsSupported := TList.Create;
  DLL_VersionsSpeculated := TList.Create;
  DLL_VersionsFallback := TList.Create;
  PrefereFallback := False;
  DLL_Version_MajorMod := 100;
  IsEssential := True;
end;

destructor TDynamicDLLWithVersion.Destroy;
begin
  DLL_VersionsSpeculated.Free;
  DLL_VersionsSupported.Free;
  DLL_VersionsFallback.Free;
  inherited;
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
begin
  if DllName <> '' then begin
    Result := Inherited;
  end else begin
    if PrefereFallback then begin
      Result := LoadDllByVersion(DLL_VersionsFallback);
      if not Result then
        Result := LoadDllByVersion(DLL_VersionsSupported);
    end else begin
      Result := LoadDllByVersion(DLL_VersionsSupported);
      if not Result then
        Result := LoadDllByVersion(DLL_VersionsFallback);
    end;
    if not Result then
      Result := LoadDllByVersion(DLL_VersionsSpeculated);
  end;
end;

function TDynamicDLLWithVersion.LoadDllByVersion(Versions: TList): Boolean;
var
  i, v: Integer;
  ThisIsEssential: Boolean;
begin
  Result := False;
  for i := 0 to Versions.Count-1 do begin
    v := Integer(Versions[i]);
    ThisIsEssential := IsEssential and (i=Versions.Count-1);
    FatalAbort := ThisIsEssential;
    FatalMsgDlg := ThisIsEssential;
    DllName := GetDllNameByVersion(v);
    Result := inherited LoadDll;
    if Result then begin
      DLL_Version := v;
      break;
    end
    else begin
      DllName := '';
    end;
  end;
end;

function TDynamicDLLWithVersion.ResolvePaths: Boolean;
begin
  Result := (DllPath<>'') and FileExists(DllFullFileName);
end;

end.
