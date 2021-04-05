object FormLengthTuning: TFormLengthTuning
  Left = 189
  Top = 131
  Caption = 'Length Tuning Helper v3.0:'
  ClientHeight = 258
  ClientWidth = 312
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnResize = FormLengthTuningResize
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 16
    Top = 168
    Width = 49
    Height = 13
    Caption = 'Net Class:'
  end
  object LabelFileName: TLabel
    Left = 96
    Top = 70
    Width = 77
    Height = 13
    Caption = 'No File Choosen'
  end
  object LabelComponent: TLabel
    Left = 16
    Top = 24
    Width = 58
    Height = 13
    Caption = 'IC Package:'
  end
  object Label2: TLabel
    Left = 16
    Top = 48
    Width = 207
    Height = 13
    Caption = 'Choose File With Length Info inside this IC:'
  end
  object Label3: TLabel
    Left = 16
    Top = 144
    Width = 219
    Height = 13
    Caption = 'Choose Net Class that needs to be equalized:'
  end
  object Label4: TLabel
    Left = 16
    Top = 108
    Width = 69
    Height = 13
    Caption = 'Delay, ps/mm:'
  end
  object ComboBoxNetClass: TComboBox
    Left = 88
    Top = 166
    Width = 208
    Height = 21
    Style = csDropDownList
    Sorted = True
    TabOrder = 0
  end
  object CheckBoxViaLength: TCheckBox
    Left = 16
    Top = 192
    Width = 128
    Height = 17
    Caption = 'Include Length of Vias'
    TabOrder = 1
  end
  object ButtonOK: TButton
    Left = 78
    Top = 224
    Width = 76
    Height = 25
    Caption = 'OK'
    TabOrder = 2
    OnClick = ButtonOKClick
  end
  object ButtonCancel: TButton
    Left = 166
    Top = 224
    Width = 76
    Height = 25
    Caption = 'Cancel'
    TabOrder = 3
    OnClick = ButtonCancelClick
  end
  object ButtonLoadFile: TButton
    Left = 16
    Top = 64
    Width = 75
    Height = 25
    Caption = 'Open File'
    TabOrder = 4
    OnClick = ButtonLoadFileClick
  end
  object ComboBoxIC: TComboBox
    Left = 88
    Top = 22
    Width = 208
    Height = 21
    Style = csDropDownList
    Sorted = True
    TabOrder = 5
    OnChange = ComboBoxICChange
  end
  object EditDelay: TEdit
    Left = 88
    Top = 104
    Width = 64
    Height = 21
    TabOrder = 6
    Text = '6.5*'
  end
  object OpenFileDialog: TOpenDialog
    DefaultExt = 'csv'
    Filter = 'Pkg File|*.pkg|CSV File | *.csv'
    Left = 256
    Top = 64
  end
end
