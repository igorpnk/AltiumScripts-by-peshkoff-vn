object frmSetWidth: TfrmSetWidth
  Left = 214
  Top = 202
  Caption = 'Setting'
  ClientHeight = 314
  ClientWidth = 224
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnShow = frmSetWidthShow
  PixelsPerInch = 96
  TextHeight = 13
  object GroupBox1: TGroupBox
    Left = 8
    Top = 8
    Width = 208
    Height = 240
    Caption = '  Set Width  '
    TabOrder = 0
    object Label1: TLabel
      Left = 16
      Top = 20
      Width = 40
      Height = 13
      Caption = 'Width01'
    end
    object Label2: TLabel
      Left = 16
      Top = 43
      Width = 44
      Height = 13
      Caption = 'Width02:'
    end
    object Label3: TLabel
      Left = 16
      Top = 66
      Width = 44
      Height = 13
      Caption = 'Width03:'
    end
    object Label4: TLabel
      Left = 16
      Top = 90
      Width = 44
      Height = 13
      Caption = 'Width04:'
    end
    object Label5: TLabel
      Left = 16
      Top = 114
      Width = 44
      Height = 13
      Caption = 'Width05:'
    end
    object Label6: TLabel
      Left = 16
      Top = 138
      Width = 44
      Height = 13
      Caption = 'Width06:'
    end
    object Label7: TLabel
      Left = 16
      Top = 162
      Width = 44
      Height = 13
      Caption = 'Width07:'
    end
    object Label8: TLabel
      Left = 16
      Top = 186
      Width = 44
      Height = 13
      Caption = 'Width08:'
    end
    object Label9: TLabel
      Left = 16
      Top = 210
      Width = 44
      Height = 13
      Caption = 'Width09:'
    end
    object Edit1: TEdit
      Left = 72
      Top = 16
      Width = 121
      Height = 21
      TabOrder = 0
      Text = '0.075mm'
    end
    object Edit2: TEdit
      Left = 72
      Top = 39
      Width = 121
      Height = 21
      TabOrder = 1
      Text = '0.1mm'
    end
    object Edit3: TEdit
      Left = 72
      Top = 62
      Width = 121
      Height = 21
      TabOrder = 2
      Text = '0.125mm'
    end
    object Edit4: TEdit
      Left = 72
      Top = 86
      Width = 121
      Height = 21
      TabOrder = 3
      Text = '0.15mm'
    end
    object Edit5: TEdit
      Left = 72
      Top = 110
      Width = 121
      Height = 21
      TabOrder = 4
      Text = '0.2mm'
    end
    object Edit6: TEdit
      Left = 72
      Top = 134
      Width = 121
      Height = 21
      TabOrder = 5
      Text = '0.3mm'
    end
    object Edit7: TEdit
      Left = 72
      Top = 158
      Width = 121
      Height = 21
      TabOrder = 6
      Text = '0.5mm'
    end
    object Edit8: TEdit
      Left = 72
      Top = 182
      Width = 121
      Height = 21
      TabOrder = 7
      Text = '3mil'
    end
    object Edit9: TEdit
      Left = 72
      Top = 206
      Width = 121
      Height = 21
      TabOrder = 8
      Text = '3.5mil'
    end
  end
  object cbClear: TCheckBox
    Left = 16
    Top = 256
    Width = 97
    Height = 17
    Caption = 'Clear after set'
    TabOrder = 1
  end
  object butOK: TButton
    Left = 32
    Top = 280
    Width = 75
    Height = 25
    Caption = 'OK'
    Default = True
    TabOrder = 2
    OnClick = butOKClick
  end
  object butCancel: TButton
    Left = 120
    Top = 280
    Width = 75
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    TabOrder = 3
    OnClick = butCancelClick
  end
end
