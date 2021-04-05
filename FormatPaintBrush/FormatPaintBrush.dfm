object frmFormatPaintBrush: TfrmFormatPaintBrush
  Left = 438
  Top = 389
  Caption = 'Format Paint Brush Setting'
  ClientHeight = 183
  ClientWidth = 324
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object btnOK: TButton
    Left = 72
    Top = 152
    Width = 75
    Height = 25
    Caption = 'OK'
    TabOrder = 0
    OnClick = btnOKClick
  end
  object btnCancel: TButton
    Left = 176
    Top = 152
    Width = 75
    Height = 25
    Caption = 'Cancel'
    TabOrder = 1
    OnClick = btnCancelClick
  end
  object gbSetting: TGroupBox
    Left = 8
    Top = 8
    Width = 312
    Height = 136
    Caption = ' Setting '
    TabOrder = 2
    object cbCopyLayerInfo: TCheckBox
      Left = 16
      Top = 24
      Width = 97
      Height = 17
      Caption = 'Copy Layer Info'
      TabOrder = 0
    end
  end
end
