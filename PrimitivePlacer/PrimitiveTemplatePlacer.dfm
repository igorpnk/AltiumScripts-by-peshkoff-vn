object frmPP: TfrmPP
  Left = 212
  Top = 260
  Caption = 'Primitive Template Placer'
  ClientHeight = 357
  ClientWidth = 297
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  Position = poMainFormCenter
  OnCreate = frmPPCreate
  OnKeyPress = frmPPKeyPress
  PixelsPerInch = 96
  TextHeight = 13
  object lblSave: TLabel
    Left = 8
    Top = 328
    Width = 125
    Height = 13
    Caption = 'please select slot for save'
    Visible = False
  end
  object imgPanel: TImage
    Left = 0
    Top = 0
    Width = 296
    Height = 320
    OnMouseDown = imgPanelMouseDown
    OnMouseMove = imgPanelMouseMove
    OnMouseUp = imgPanelMouseUp
  end
  object Label1: TLabel
    Left = 6
    Top = 302
    Width = 31
    Height = 13
    Caption = 'Label1'
    Color = clBtnFace
    ParentColor = False
  end
  object lblImgDescription: TLabel
    Left = 20
    Top = 290
    Width = 88
    Height = 13
    Caption = ': lblImgDescription'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object lblImgLetter: TLabel
    Left = 6
    Top = 290
    Width = 8
    Height = 13
    Caption = 'Q'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsUnderline]
    ParentFont = False
  end
  object butCancel: TButton
    Left = 216
    Top = 328
    Width = 75
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    TabOrder = 0
    OnClick = butCancelClick
  end
end
