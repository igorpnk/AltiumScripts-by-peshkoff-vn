object frmEditPCBObjectSetting: TfrmEditPCBObjectSetting
  Left = 238
  Top = 322
  Caption = 'Edit PCB Object v 1.0 Setting'
  ClientHeight = 193
  ClientWidth = 337
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
    Left = 72
    Top = 152
    Width = 75
    Height = 25
    Caption = 'OK'
    TabOrder = 0
    OnClick = ButtonOKClick
  end
  object ButtonCancel: TButton
    Left = 160
    Top = 152
    Width = 75
    Height = 25
    Caption = 'Cancel'
    TabOrder = 1
    OnClick = ButtonCancelClick
  end
  object cbClearSelectMoveToLayer: TCheckBox
    Left = 24
    Top = 24
    Width = 176
    Height = 17
    Caption = 'cbClearSelectMoveToLayer'
    TabOrder = 2
  end
  object cbClearSelectWidth: TCheckBox
    Left = 24
    Top = 72
    Width = 176
    Height = 17
    Caption = 'cbClearSelectWidth'
    TabOrder = 4
  end
  object cbClearSelectSetNetName: TCheckBox
    Left = 24
    Top = 48
    Width = 176
    Height = 17
    Caption = 'cbClearSelectSetNetName'
    TabOrder = 3
  end
end
