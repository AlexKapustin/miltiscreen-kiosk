unit frmMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Menus, uScreenPosition, ShellApi, Grids,
  ValEdit, inifiles;
type TListTrect = array of TRect;
type ScreenInfo = record
  List: TListTrect;
  MaxRect: TRect;
end;

type
  TfrmConfiguration = class(TForm)
    mainConfigurationMenu: TMainMenu;
    File1: TMenuItem;
    est1: TMenuItem;
    screenPreview: TImage;
    pnlUrls: TPanel;
    urlsEditor: TValueListEditor;
    Refresh1: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure urlsEditorSetEditText(Sender: TObject; ACol,
      ARow: Integer; const Value: String);
    procedure est1Click(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure Refresh1Click(Sender: TObject);
  private
    ScreenInfo : TScreenPosition;
    appIni : TIniFile;
    procedure PlaceWindows();
  public
    { Public declarations }
  end;

var
  frmConfiguration: TfrmConfiguration;

implementation

uses Types;
const INI_SECTION_SYSTEM = 'system';
const INI_SECTION_MONITORS = 'monitors';
const INI_KEY_SCREEN_PREFIX = 'screen_';

{$R *.dfm}
{
function GetHWndByPID(const hPID: THandle): THandle;
    type
    PEnumInfo = ^TEnumInfo;
    TEnumInfo = record
    ProcessID: DWORD;
    HWND: THandle;
  end;

    function EnumWindowsProc(Wnd: DWORD; var EI: TEnumInfo): Bool; stdcall;
    var
        PID: DWORD;
    begin
        GetWindowThreadProcessID(Wnd, @PID);
        Result := (PID <> EI.ProcessID) or
                (not IsWindowVisible(WND)) or
                (not IsWindowEnabled(WND));

        if not Result then EI.HWND := WND; //break on return FALSE
    end;

    function FindMainWindow(PID: DWORD): DWORD;
    var
        EI: TEnumInfo;
    begin
        EI.ProcessID := PID;
        EI.HWND := 0;
        EnumWindows(@EnumWindowsProc, Integer(@EI));
        Result := EI.HWND;
    end;
    
begin
    if hPID<>0 then
        Result:=FindMainWindow(hPID)
    else
        Result:=0;
end;
}

function CreateProcessSimple(
  sExecutableFilePath : string )
    : THandle;
var
  pi: TProcessInformation;
  si: TStartupInfo;
//  h : THandle;
begin
  FillMemory(@si, sizeof(si), 0);
  si.cb := sizeof(si);

  CreateProcess(
    Nil,
    // path to the executable file:
    PChar(sExecutableFilePath),

    Nil, Nil, False,
    CREATE_NEW_PROCESS_GROUP + NORMAL_PRIORITY_CLASS, Nil, Nil,
    si, pi
  );

  //WaitForInputIdle(pi.hProcess, 20000);
  //Result := GetHWndByPID(pi.dwProcessId);
  CloseHandle(pi.hProcess);
  CloseHandle(pi.hThread);
end;

procedure TfrmConfiguration.FormCreate(Sender: TObject);
var
 res : TScreenListInfo;
 i : integer;
 str : String;
begin
  ScreenInfo := TScreenPosition.Create();
  appIni := TIniFile.Create(Application.ExeName + '.ini');
  res := ScreenInfo.GetAllRects();
  for i := 0 to res.MonitorCount - 1 do
  begin
    str := IntToStr(i);
    urlsEditor.InsertRow(
      INI_KEY_SCREEN_PREFIX + str,
      appIni.ReadString(INI_SECTION_MONITORS, INI_KEY_SCREEN_PREFIX + str, ''),
      false
    );
  end;
  ScreenInfo.DrawMonitors(screenPreview.Canvas);
  if ParamStr(1) = 'place' then
  begin
    PlaceWindows();
    Halt;
  end;
end;
procedure TfrmConfiguration.urlsEditorSetEditText(Sender: TObject; ACol,
  ARow: Integer; const Value: String);
begin
  caption := IntToStr(AROw) + ': ' + value;
  appIni.WriteString(INI_SECTION_MONITORS, urlsEditor.Keys[Arow], value);
end;

procedure TfrmConfiguration.PlaceWindows();
var
  i : Integer;
  workingDir, cmd, exe, exeArgs, arguments : String;
  h : THandle;
  tmpRect : TRect;
  res: TScreenListInfo;
begin
  res := ScreenInfo.GetAllRects();
  exe := appIni.ReadString(INI_SECTION_SYSTEM, 'exe_path', '');
  exeArgs := appIni.ReadString(INI_SECTION_SYSTEM, 'exe_arguments', '');
  if (exe = '') OR (not FileExists(exe))then
  begin
    MessageBox(Handle, 'configuration error', 'please setup exe_path in [system] section', MB_ICONERROR);
    exit;
  end;
  for i:= 0 to res.MonitorCount - 1 do
  begin
    arguments := appIni.ReadString(
      INI_SECTION_MONITORS,
      INI_KEY_SCREEN_PREFIX + IntToStr(i),
      ''
    );
    if arguments <> '' then
    begin
      tmpRect := res.list[i].Rect;
      cmd := exe;
      cmd := cmd + Format(' --start-fullscreen --window-position=%d,%d ', [tmpRect.Left + 10, tmpRect.Top + 10]);
      workingDir := ExtractFilePath(Application.ExeName) + PathDelim + INI_KEY_SCREEN_PREFIX + IntToStr(i);
      if not DirectoryExists(workingDir) then
      begin
        CreateDirectory(PChar(workingDir), nil);
      end;
      cmd := cmd + Format('--user-data-dir="%s" ', [workingDir]);
      cmd := cmd + exeArgs + ' ' + arguments;
      h := CreateProcessSimple(cmd);
      if h <> 0 then
      begin
      {
        tmpRect := res.list[i].Rect;
        SetWindowPos(h, HWND_TOP, tmpRect.Left + 10, tmpRect.Top + 10, 100, 100, SW_NORMAL);
        PostMessage(h, WM_KEYDOWN, VK_F11, 0);
        sleep(10);
        PostMessage(h, WM_KEYUP, VK_F11, 0);
        }
      end;
    end;
  end;
end;

procedure TfrmConfiguration.est1Click(Sender: TObject);
begin
  PlaceWindows();
end;

procedure TfrmConfiguration.FormResize(Sender: TObject);
begin
  Refresh1Click(screenPreview);
end;

procedure TfrmConfiguration.Refresh1Click(Sender: TObject);
begin
  screenPreview.Picture.Bitmap.Width := screenPreview.Width;
  screenPreview.Picture.Bitmap.Height := screenPreview.Height;
  ScreenInfo.DrawMonitors(screenPreview.Canvas);
end;

end.
