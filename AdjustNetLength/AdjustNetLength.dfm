object frmMain: TfrmMain
  Left = 345
  Top = 394
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'Adjust Net Length v3.0'
  ClientHeight = 185
  ClientWidth = 266
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  PixelsPerInch = 96
  TextHeight = 13
  object ButtonOK: TButton
    Left = 56
    Top = 152
    Width = 75
    Height = 25
    Caption = 'OK'
    Default = True
    TabOrder = 1
    OnClick = ButtonOKClick
  end
  object ButtonCancel: TButton
    Left = 144
    Top = 152
    Width = 75
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    TabOrder = 2
    OnClick = ButtonCancelClick
  end
  object GroupBox1: TGroupBox
    Left = 8
    Top = 8
    Width = 248
    Height = 96
    Caption = 'Manual Adjustment mode'
    TabOrder = 0
    object Label1: TLabel
      Left = 184
      Top = 32
      Width = 16
      Height = 13
      Caption = 'mm'
    end
    object Label2: TLabel
      Left = 184
      Top = 62
      Width = 16
      Height = 13
      Caption = 'mm'
    end
    object Label3: TLabel
      Left = 24
      Top = 62
      Width = 61
      Height = 13
      Caption = 'Delta Length'
    end
    object Label4: TLabel
      Left = 24
      Top = 32
      Width = 70
      Height = 13
      Caption = 'Manual Length'
    end
    object editManual: TEdit
      Left = 112
      Top = 28
      Width = 64
      Height = 21
      TabOrder = 0
      Text = '20'
    end
    object editDelta: TEdit
      Left = 112
      Top = 58
      Width = 64
      Height = 21
      TabOrder = 1
      Text = '0.2'
    end
  end
  object CheckBoxRules: TCheckBox
    Left = 16
    Top = 112
    Width = 152
    Height = 17
    Caption = 'Design Rules Check'
    TabOrder = 3
  end
  object CheckBoxFix: TCheckBox
    Left = 16
    Top = 128
    Width = 152
    Height = 17
    Caption = 'Try to Fix Trace'
    TabOrder = 4
  end
end
