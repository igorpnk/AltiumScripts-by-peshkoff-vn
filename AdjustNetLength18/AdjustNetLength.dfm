object frmMain: TfrmMain
  Left = 400
  Top = 364
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'Adjust Net Length v4.0'
  ClientHeight = 235
  ClientWidth = 266
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object ButtonOK: TButton
    Left = 56
    Top = 200
    Width = 75
    Height = 25
    Caption = 'OK'
    Default = True
    TabOrder = 3
    OnClick = ButtonOKClick
  end
  object ButtonCancel: TButton
    Left = 144
    Top = 200
    Width = 75
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    TabOrder = 4
    OnClick = ButtonCancelClick
  end
  object GroupBox1: TGroupBox
    Left = 8
    Top = 8
    Width = 248
    Height = 72
    Caption = ' Manual Adjustment mode '
    TabOrder = 0
    object Label1: TLabel
      Left = 176
      Top = 24
      Width = 16
      Height = 13
      Caption = 'mm'
    end
    object Label2: TLabel
      Left = 176
      Top = 46
      Width = 16
      Height = 13
      Caption = 'mm'
    end
    object Label3: TLabel
      Left = 16
      Top = 46
      Width = 61
      Height = 13
      Caption = 'Delta Length'
    end
    object Label4: TLabel
      Left = 16
      Top = 24
      Width = 70
      Height = 13
      Caption = 'Manual Length'
    end
    object editManual: TEdit
      Left = 104
      Top = 20
      Width = 64
      Height = 21
      TabOrder = 0
      Text = '20'
    end
    object editDelta: TEdit
      Left = 104
      Top = 42
      Width = 64
      Height = 21
      TabOrder = 1
      Text = '0.2'
    end
  end
  object CheckBoxRules: TCheckBox
    Left = 24
    Top = 176
    Width = 152
    Height = 17
    Caption = 'Design Rules Check'
    TabOrder = 2
  end
  object rgTarget: TRadioGroup
    Left = 8
    Top = 88
    Width = 248
    Height = 80
    Caption = ' Target Length '
    ItemIndex = 0
    Items.Strings = (
      'Routed Length'
      'Signal Length'
      'xSignal Length')
    TabOrder = 1
  end
end
