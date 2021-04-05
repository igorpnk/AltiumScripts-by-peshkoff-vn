object frmFilletObjectsSet: TfrmFilletObjectsSet
  Left = 247
  Top = 294
  BorderStyle = bsDialog
  Caption = 'Fillet Objects Setting'
  ClientHeight = 93
  ClientWidth = 256
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poOwnerFormCenter
  PixelsPerInch = 96
  TextHeight = 13
  object ButOK: TButton
    Left = 40
    Top = 64
    Width = 75
    Height = 25
    Caption = 'OK'
    Default = True
    TabOrder = 1
    OnClick = ButOKClick
  end
  object ButCancel: TButton
    Left = 136
    Top = 64
    Width = 75
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    TabOrder = 2
    OnClick = ButCancelClick
  end
  object gbRadius: TGroupBox
    Left = 0
    Top = 0
    Width = 256
    Height = 56
    Caption = 'Radius Setting'
    TabOrder = 0
    object lblRadius: TLabel
      Left = 56
      Top = 20
      Width = 32
      Height = 13
      Caption = 'Radius'
    end
    object lblDim: TLabel
      Left = 168
      Top = 20
      Width = 16
      Height = 13
      Caption = 'mm'
    end
    object editRadius: TEdit
      Left = 96
      Top = 16
      Width = 64
      Height = 21
      TabOrder = 0
      Text = '1'
    end
  end
end
