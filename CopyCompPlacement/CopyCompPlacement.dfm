object frmCopyCompPlacementSetting: TfrmCopyCompPlacementSetting
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
  object cbClearSelected: TCheckBox
    Left = 24
    Top = 24
    Width = 176
    Height = 17
    Caption = 'Clear selection after proc'
    TabOrder = 2
  end
  object cbOnlyDes: TCheckBox
    Left = 24
    Top = 48
    Width = 176
    Height = 17
    Caption = 'Only Designators'
    TabOrder = 3
  end
end
