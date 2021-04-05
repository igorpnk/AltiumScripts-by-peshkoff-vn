object frmEditViaSetting: TfrmEditViaSetting
  Left = 265
  Top = 390
  BorderStyle = bsSingle
  Caption = 'Edit Via Setting'
  ClientHeight = 73
  ClientWidth = 179
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
    Left = 8
    Top = 40
    Width = 75
    Height = 25
    Caption = 'OK'
    Default = True
    TabOrder = 0
    OnClick = ButtonOKClick
  end
  object ButtonCancel: TButton
    Left = 96
    Top = 40
    Width = 75
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    TabOrder = 1
    OnClick = ButtonCancelClick
  end
  object cbClearSelectText: TCheckBox
    Left = 8
    Top = 16
    Width = 160
    Height = 17
    Caption = 'Clear selection after change'
    TabOrder = 2
  end
end
