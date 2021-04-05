object frmEditDes: TfrmEditDes
  Left = 0
  Top = 0
  Caption = 'Edit Designator By One Click'
  ClientHeight = 245
  ClientWidth = 312
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
    Left = 32
    Top = 32
    Width = 31
    Height = 13
    Caption = 'Label1'
  end
  object Label2: TLabel
    Left = 32
    Top = 60
    Width = 31
    Height = 13
    Caption = 'Label2'
  end
  object Label3: TLabel
    Left = 32
    Top = 88
    Width = 31
    Height = 13
    Caption = 'Label3'
  end
  object Label4: TLabel
    Left = 32
    Top = 112
    Width = 31
    Height = 13
    Caption = 'Label4'
  end
  object Edit1: TEdit
    Left = 96
    Top = 32
    Width = 121
    Height = 21
    TabOrder = 0
    Text = 'Edit1'
  end
  object Edit2: TEdit
    Left = 96
    Top = 56
    Width = 121
    Height = 21
    TabOrder = 1
    Text = 'Edit2'
  end
  object Edit3: TEdit
    Left = 96
    Top = 80
    Width = 121
    Height = 21
    TabOrder = 2
    Text = 'Edit3'
  end
  object Edit4: TEdit
    Left = 96
    Top = 104
    Width = 121
    Height = 21
    TabOrder = 3
    Text = 'Edit4'
  end
  object butOK: TButton
    Left = 56
    Top = 160
    Width = 75
    Height = 25
    Caption = 'butOK'
    TabOrder = 4
    OnClick = butOKClick
  end
  object butCancel: TButton
    Left = 144
    Top = 160
    Width = 75
    Height = 25
    Caption = 'butCancel'
    TabOrder = 5
    OnClick = butCancelClick
  end
end
