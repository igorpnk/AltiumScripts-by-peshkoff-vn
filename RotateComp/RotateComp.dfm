object frmRotateCompSetting: TfrmRotateCompSetting
  Left = 238
  Top = 322
  BorderStyle = bsSingle
  Caption = 'Edit Text Setting'
  ClientHeight = 330
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
  object Label1: TLabel
    Left = 8
    Top = 8
    Width = 80
    Height = 13
    Alignment = taCenter
    AutoSize = False
    Caption = 'Height'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object Label2: TLabel
    Left = 88
    Top = 8
    Width = 80
    Height = 13
    Alignment = taCenter
    AutoSize = False
    Caption = 'Width'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object ButtonOK: TButton
    Left = 8
    Top = 296
    Width = 75
    Height = 25
    Caption = 'OK'
    Default = True
    TabOrder = 0
  end
  object ButtonCancel: TButton
    Left = 96
    Top = 296
    Width = 75
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    TabOrder = 1
  end
  object cbClearSelectText: TCheckBox
    Left = 8
    Top = 272
    Width = 160
    Height = 17
    Caption = 'Clear selection after change'
    TabOrder = 2
  end
  object sgText: TStringGrid
    Left = 8
    Top = 24
    Width = 163
    Height = 240
    BevelInner = bvNone
    BevelKind = bkFlat
    BorderStyle = bsNone
    ColCount = 2
    Ctl3D = True
    DefaultColWidth = 80
    DefaultRowHeight = 18
    DrawingStyle = gdsClassic
    FixedCols = 0
    RowCount = 12
    FixedRows = 0
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goEditing]
    ParentCtl3D = False
    ScrollBars = ssNone
    TabOrder = 3
  end
end
