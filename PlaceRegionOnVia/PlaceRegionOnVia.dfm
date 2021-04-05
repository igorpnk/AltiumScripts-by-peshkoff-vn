object frmPlaceRegionOnViaSetting: TfrmPlaceRegionOnViaSetting
  Left = 265
  Top = 320
  BorderStyle = bsSingle
  Caption = 'Edit Via Setting'
  ClientHeight = 96
  ClientWidth = 176
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
    Top = 64
    Width = 75
    Height = 25
    Caption = 'OK'
    Default = True
    TabOrder = 0
    OnClick = ButtonOKClick
  end
  object ButtonCancel: TButton
    Left = 96
    Top = 64
    Width = 75
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    TabOrder = 1
    OnClick = ButtonCancelClick
  end
  object cbClearAll: TCheckBox
    Left = 8
    Top = 40
    Width = 160
    Height = 17
    Caption = 'Clear selection after change'
    TabOrder = 2
  end
  object cbUseRoundTo: TCheckBox
    Left = 8
    Top = 10
    Width = 97
    Height = 17
    Caption = 'Use Round to:'
    Checked = True
    State = cbChecked
    TabOrder = 3
  end
  object eRoundTo: TEdit
    Left = 104
    Top = 8
    Width = 64
    Height = 21
    TabOrder = 4
    Text = '0.1'
  end
end
