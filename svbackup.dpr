program svbackup;

uses
  Vcl.Forms, Misc, StrClasses, Windows,
  MForm in 'MForm.pas' {MainForm};

{$R *.res}

begin
  ShowConsole(SW_SHOW);
  StartLogging('');

  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
