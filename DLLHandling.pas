{$INCLUDE jedi.inc}
unit DLLHandling;
// we might also use the dll loading logic as in Load7Zip function @ jcl\source\windows\sevenzip.pas
interface

uses
  Windows, SysUtils,
  StrUtils2, PathUtil, TaLoSDirs;

{$IFNDEF DELPHI2009_UP}{$IFNDEF CPP} function SetDllDirectory(lpPathName: LPCSTR): BOOL; stdcall;{$ENDIF}{$ENDIF}

function GetFullDataFilePath (RelativeFileName: String; IsBinary: Boolean): String;
function LoadDLL (RelativeDLLPath: String; var FullDLLPath: String): HMODULE;

{
What to do if the DLL crushes on Win32 and not on Win64?
1.  check in the h file if the calling convertion is cdecl or stdcall,
    declare the function interface accordingly.
    otherwise the program will probably crush when leaving the function which called the misdeclared function.
2.  check with depends (dependecy walker) if the function has stdcall decoration
    i.e. the function name appeares as _@MyFuncX as X is the argument size in bytes
    in that case call GetProcAddress2 with X.
    otherwise the function won't be found.
3.  No monkey bussiness like that exist on Win64.
}
function GetProcAddress2(hModule: HMODULE; lpProcName: LPCWSTR; args: integer=-1): FARPROC;

implementation

uses Msg;

{$IFNDEF DELPHI2009_UP}function SetDllDirectory; external kernel32 name 'SetDllDirectoryA';{$ENDIF}

function GetProcAddress2(hModule: HMODULE; lpProcName: LPCWSTR; args: integer=-1): FARPROC;
begin
  {$IFDEF WIN32}
  // stupid STDCall name decoration!
  // copy paste the function names from dependency walker to notepad and search for the function name there.
  if args>=0 then
    Result := GetProcAddress(hModule, PChar('_'+String(lpProcName)+'@'+IntToStr(args)))
  else
  {$ENDIF}
  Result := GetProcAddress(hModule, lpProcName);
  {$IFDEF DEBUG}
  if Result=nil then
    WarningMsg('function load failed: '+lpProcName);
  {$ENDIF}
end;

function GetFullDataFilePath (RelativeFileName: String; IsBinary: Boolean): String;
begin
  Result := GetFullPath(LocalCache, RelativeFileName);
  if FileExists(Result) then exit;
  if IsBinary then begin
    Result := GetFullPath(BinDirectory, RelativeFileName);
    if FileExists(Result) then exit;
  end;
  Result := GetFullPath(TaLoSDirectory, RelativeFileName);
  if FileExists(Result) then exit;
  Result := GetFullPath(DataFilesPath, RelativeFileName);
  if FileExists(Result) then exit;
end;

function LoadDLL (RelativeDLLPath: String; var FullDLLPath: String): HMODULE;
var
  FullDLLPathFileName, DLLFileName: String;
begin
  FullDLLPathFileName := GetFullDataFilePath(RelativeDLLPath, true);
  if not FileExists(FullDLLPathFileName) then
    raise Exception.Create('DLL not found: '+FullDLLPathFileName);
  FullDLLPath := ExtractFilePath(FullDLLPathFileName);
  DLLFileName := ExtractFileName(FullDLLPathFileName);
  if FullDLLPath<>'' then
    SetDllDirectory(PChar(FullDLLPath));
  Result := SafeLoadLibrary(PChar(DLLFileName));
  if Result=0 then
    raise Exception.Create('Could not load DLL: '+FullDLLPathFileName+' Error Code: '+IntToStr(GetLastError));
end;

end.
