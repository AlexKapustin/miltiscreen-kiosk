program monitors;

uses
  Forms,
  frmMain in 'frmMain.pas' {frmConfiguration},
  uScreenPosition in 'uScreenPosition.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.Title := '';
  Application.CreateForm(TfrmConfiguration, frmConfiguration);
  Application.Run;
end.
