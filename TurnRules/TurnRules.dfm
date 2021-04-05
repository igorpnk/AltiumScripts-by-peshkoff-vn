object frmTurnRulesSet: TfrmTurnRulesSet
  Left = 209
  Top = 206
  Caption = 'Setting'
  ClientHeight = 387
  ClientWidth = 355
  Color = clBtnFace
  Constraints.MinHeight = 414
  Constraints.MinWidth = 363
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnResize = frmTurnRulesSetResize
  OnShow = frmTurnRulesSetShow
  PixelsPerInch = 96
  TextHeight = 13
  object clbRulesGroup3: TCheckListBox
    Left = 80
    Top = 0
    Width = 272
    Height = 303
    ItemHeight = 13
    TabOrder = 5
  end
  object clbRulesGroup2: TCheckListBox
    Left = 80
    Top = 0
    Width = 272
    Height = 303
    ItemHeight = 13
    TabOrder = 4
  end
  object clbRulesGroup1: TCheckListBox
    Left = 80
    Top = 0
    Width = 272
    Height = 303
    ItemHeight = 13
    TabOrder = 0
  end
  object butOK: TButton
    Left = 99
    Top = 352
    Width = 75
    Height = 25
    Caption = 'OK'
    Default = True
    TabOrder = 1
    OnClick = butOKClick
  end
  object butCancel: TButton
    Left = 188
    Top = 352
    Width = 75
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    TabOrder = 2
    OnClick = butCancelClick
  end
  object ToolBar1: TToolBar
    Left = 0
    Top = 0
    Width = 74
    Height = 387
    Align = alLeft
    AutoSize = True
    ButtonHeight = 19
    ButtonWidth = 74
    Caption = 'ToolBar1'
    Ctl3D = False
    DrawingStyle = dsGradient
    Flat = False
    List = True
    ShowCaptions = True
    TabOrder = 3
    object ToolButton1: TToolButton
      Left = 0
      Top = 0
      Caption = 'Rule Group 1'
      Down = True
      Grouped = True
      Wrap = True
      Style = tbsCheck
      OnClick = ToolButton1Click
    end
    object ToolButton3: TToolButton
      Left = 0
      Top = 19
      Caption = 'Rule Group 2'
      Grouped = True
      Wrap = True
      Style = tbsCheck
      OnClick = ToolButton3Click
    end
    object ToolButton2: TToolButton
      Left = 0
      Top = 38
      Caption = 'Rule Group 3'
      Grouped = True
      Style = tbsCheck
      OnClick = ToolButton2Click
    end
  end
end
