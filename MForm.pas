unit MForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, IniFiles,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Misc, FileCtrl, StrClasses, DateTimeTools,
   Scripting, LuaTypes, LuaTools, LuaEngine;

type
  TKeyRef = record
    vkc: Integer;
    tag: array [0..4] of CHAR;
    hit: Integer;
  end;

  TMainForm = class(TForm)
    edtSavesFolder: TEdit;
    btnBrowseFolder: TButton;
    dlgOpenFolder: TOpenDialog;
    updTimer: TTimer;
    edtBackupFolder: TEdit;
    btnBrowseBackupFolder: TButton;
    Label1: TLabel;
    Label2: TLabel;
    cbAutobackup: TCheckBox;
    procedure btnBrowseFolderClick(Sender: TObject);
    procedure updTimerTimer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnBrowseBackupFolderClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure cbAutobackupClick(Sender: TObject);
  private
    { Private declarations }
    n_loop: Integer;
     krefs: array of TKeyRef;
      fmap: TStrMap;
      fini: TIniFile;
        le: TLuaEngine;

    procedure CheckUpdatedSaves;
    procedure TestFileUpdated(fn: String);
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation
uses Lua5;

{$R *.dfm}

var
   fsave: THandle = 0;
   gbuff: array [0..4095] of Byte;


function fread_int(L: lua_State; sz: Cardinal): Integer;
var
   ofs: Integer;
    dd: Integer;
begin
  result := 1;
  ofs := lua_tointeger(L, 1);
  if 0 = fsave then
   begin
    lua_pushinteger(L, 0);
    exit;
   end;

  dd := 0;
  FileSeek (fsave, ofs, 0);
  FileRead (fsave, dd, sz);
  lua_pushinteger (L, dd);
end;

function fread_byte (L: lua_State): Integer; cdecl;
begin
 result := fread_int(L, 1);
end;

function fread_int16 (L: lua_State): Integer; cdecl;
begin
  result := fread_int(L, 2);
end;


function fread_int32 (L: lua_State): Integer; cdecl;
begin
  result := fread_int(L, 4);
end;

function fread_sz(L: lua_State; ansi: Boolean): Integer;
var
   ofs: Integer;
   psa: PAnsiChar;
   psw: PWideChar;
   len: Integer;
    dd: Integer;

begin
  result := 1;
  ofs := lua_tointeger(L, 1);
  FillChar (gbuff, SizeOf(gbuff), 0);
  if 0 = fsave then
   begin
    lua_pushwstr(L, '');
    exit;
   end;

  psa := @gbuff[0];
  psw := @gbuff[0];
  len := High(gbuff); // 4k - 1 bytes
  // strict string length
  if lua_gettop(L) > 1 then
     len := lua_tointeger(L, 2) * IfV(ansi, 1, 2);

  FileSeek(fsave, ofs, 0);
  FileRead(fsave, gbuff, len and High(gbuff));
  if ansi then
     lua_pushstring(L, psa)
  else
     lua_pushwstr(L, psw);
end; // fread_fz


function fread_ansi_sz (L: lua_State): Integer; cdecl;
begin
  result := fread_sz(L, True);
end;

function fread_wide_sz (L: lua_State): Integer; cdecl;
begin
  result := fread_sz(L, False);
end;



procedure TMainForm.btnBrowseBackupFolderClick(Sender: TObject);
var
    dir: String;
begin
  if FileCtrl.SelectDirectory('Choose backup folder', 'C:\Backup', dir, [sdNewUI, sdNewFolder], MainForm) then
    edtBackupFolder.Text := dir;
end;

procedure TMainForm.btnBrowseFolderClick(Sender: TObject);
var
    dir: String;
begin
  if FileCtrl.SelectDirectory('Choose savegames folder', 'C:\Users', dir, [sdNewUI], MainForm) then
    edtSavesFolder.Text := dir;
end;

procedure TMainForm.cbAutobackupClick(Sender: TObject);
begin
 fini.WriteString('config', 'SavesPath', edtSavesFolder.Text);
 fini.WriteString('config', 'BackupPath', edtBackupFolder.Text);
end;

procedure TMainForm.TestFileUpdated(fn: String);
var
  fdt: TDateTimeInfoRec;
  src: String;
   sf: String;
   bf: String;
   fx: String;
   sv: TScriptVar;
   dt: Double;
    s: String;
    i: Integer;


begin
 sf := AddSlash(edtSavesFolder.Text);
 bf := AddSlash(edtBackupFolder.Text);

 src := sf + fn;
 if ('.' = fn) or ('..' = fn) or not FileExists(src) then exit;

 if not FileGetDateTimeInfo (src, fdt) then exit;

 bf := bf + FormatDateTime('yymmdd',  fdt.TimeStamp);
 s := FormatDateTime('yymmdd-hhnnss', fdt.TimeStamp);
 if fmap.Values[fn] = s then exit;


 CheckMakeDir (bf);
 bf := AddSlash(bf);

 dt := (Now - fdt.TimeStamp) / DT_ONE_SECOND; // delta time

 wprintf('[~T]. #DBG: file [%s] was updated at [%s] %.1f seconds ago, creating backup...', [src, s, dt]);
 Sleep(100); // TODO: flush-wait pause, but need exclusive file blocking

 if FileExists(bf + fn) then
    DeleteFile(bf + fn);

 // creating copy of file
 if CopyFile ( PChar(src), PChar(bf + fn), TRUE ) then
   begin
    fsave := FileOpen(bf + fn, fmShareDenyWrite);
    if fsave > 0 then
     try
      // trying parse save game for details
      lua_pushwstr(le.State, fn);
      le.SetGlobal('save_file');

      lua_pushwstr(le.State, '');
      le.SetGlobal('suffix');

      lua_pushboolean(le.State, 0);
      le.SetGlobal('discard');

      le.CallFuncEx('parse_save', '', 'suffix');
      FileClose(fsave);
     except
       on E: Exception do OnExceptLog ('TestFileUpdated#lua.parse_save', E, True);
     end;

    fmap.Values[fn] := s; // update

    sv.vName := 'discard';
    sv.SetBool(False);
    le.ReadVar(@sv);

    if sv.bval then
      begin
       wprintf('#WARN: File [~C0A%s~C07] will be discarded, due script filtration', [fn]);
       DeleteFile (bf + fn);
       exit;
      end;

    sv.Empty;
    sv.vName := 'suffix';
    sv.SetStr('');
    le.ReadVar(@sv);

    src := bf + fn;

    s := src + '.' + FormatDateTime('hhnnss', fdt.TimeStamp);
    if sv.wstr <> '' then
     begin
      wprintf('  for file [%s] will be added suffix %s', [fn, sv.wstr]);
      s := s + '.' + sv.wstr;
     end;
    // testing keys is pressed
    if dt < 20 then
     for i := 0 to Length(krefs) - 1 do
      with krefs[i] do
       if hit > 0 then
         s := s + '.k' + tag;

    s := s + '.bak';
    if FileExists(s) then  DeleteFile(s);

    RenameFile (src, s);
   end
 else
   PrintError('Failed CopyFile function');
end;


procedure TMainForm.CheckUpdatedSaves;
var
   sr: TSearchRec;
begin
 //
 if 0 = FindFirst (edtSavesFolder.Text + '\*.*', faNormal, sr) then
  Repeat
   TestFileUpdated (sr.Name);
  Until 0 <> FindNext(sr);
end;

procedure TMainForm.FormCreate(Sender: TObject);
var
   s: String;
begin
 SetLength(krefs, 2);

 krefs [0].vkc := VK_F5;
 StrPCopy (krefs [0].tag, 'F5');

 krefs [1].vkc := VK_F6;
 StrPCopy (krefs [1].tag, 'F6');
 fmap := TStrMap.Create(self);

 s := FindConfigFile('svbackup.conf');
 fini := TIniFile.Create(s);
 edtSavesFolder.Text := fini.ReadString('config', 'SavesPath', edtSavesFolder.Text);
 edtBackupFolder.Text := fini.ReadString('config', 'BackupPath', edtBackupFolder.Text);
 le := TLuaEngine.Create();
 s := fini.ReadString('config', 'ParseScript', '');
 if s <> '' then
    le.LoadScript(s);

 lua_register (le.State, 'fread_byte',  fread_byte);
 lua_register (le.State, 'fread_short',  fread_int16);
 lua_register (le.State, 'fread_long',   fread_int32);
 lua_register (le.State, 'fread_str',   fread_ansi_sz);
 lua_register (le.State, 'fread_wstr',  fread_ansi_sz);
 le.Execute();
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
 SetLength(krefs, 0);
 FreeAndNil(fmap);
 FreeAndNil (fini);
end;

procedure TMainForm.updTimerTimer(Sender: TObject);
var
   st, i: Integer;
begin
 Inc(n_loop);
 cbAutobackup.Enabled := System.SysUtils.DirectoryExists(edtSavesFolder.Text) and
                         System.SysUtils.DirectoryExists(edtBackupFolder.Text);

 for i := 0 to Length(krefs) - 1 do
 with krefs[i] do
   begin
    if hit > 0 then Dec(hit);
    st := GetAsyncKeyState(vkc);
    if st and 1 = 0 then continue;
    wprintf('key %s was pressed, state = $%x', [String(tag), st]);
    hit := 200;
   end;

 if (n_loop mod 10 = 0) and cbAutobackup.Checked then
    CheckUpdatedSaves;
end;

end.
