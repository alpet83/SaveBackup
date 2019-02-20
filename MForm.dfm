object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'Save autobackup v0.1'
  ClientHeight = 175
  ClientWidth = 536
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  DesignSize = (
    536
    175)
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 8
    Width = 90
    Height = 13
    Caption = 'Savegames folder:'
  end
  object Label2: TLabel
    Left = 8
    Top = 72
    Width = 69
    Height = 13
    Caption = 'Backup folder:'
  end
  object edtSavesFolder: TEdit
    Left = 8
    Top = 32
    Width = 413
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 0
    Text = '?:\Games\Miner\Saves'
  end
  object btnBrowseFolder: TButton
    Left = 427
    Top = 28
    Width = 101
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Browse folder'
    TabOrder = 1
    OnClick = btnBrowseFolderClick
  end
  object edtBackupFolder: TEdit
    Left = 8
    Top = 93
    Width = 413
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 2
    Text = '?:\Backup'
  end
  object btnBrowseBackupFolder: TButton
    Left = 427
    Top = 91
    Width = 101
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Browse folder'
    TabOrder = 3
    OnClick = btnBrowseBackupFolderClick
  end
  object cbAutobackup: TCheckBox
    Left = 16
    Top = 136
    Width = 145
    Height = 17
    Caption = 'Enable autobackup'
    TabOrder = 4
    OnClick = cbAutobackupClick
  end
  object dlgOpenFolder: TOpenDialog
    InitialDir = 'C:\Users'
    Options = [ofHideReadOnly, ofPathMustExist, ofEnableSizing]
    Left = 168
    Top = 104
  end
  object updTimer: TTimer
    Interval = 500
    OnTimer = updTimerTimer
    Left = 392
    Top = 128
  end
end
