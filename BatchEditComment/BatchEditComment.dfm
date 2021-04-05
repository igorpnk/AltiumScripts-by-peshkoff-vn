object FormMain: TFormMain
  Left = 366
  Top = 284
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = 'Batch Edit Comment v2.0'
  ClientHeight = 304
  ClientWidth = 511
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  OnShow = FormMainShow
  PixelsPerInch = 96
  TextHeight = 13
  object gbDesSetting: TGroupBox
    Left = 8
    Top = 80
    Width = 336
    Height = 184
    Caption = ' Dsignators Setting'
    TabOrder = 6
    object cbSelectDes: TCheckBox
      Left = 8
      Top = 16
      Width = 104
      Height = 17
      Caption = 'Selected Items'
      TabOrder = 0
    end
    object cbMinTextDes: TCheckBox
      Left = 8
      Top = 40
      Width = 104
      Height = 17
      Caption = 'Min Text (0.4)'
      TabOrder = 1
    end
    object cbTexttoCenterDes: TCheckBox
      Left = 8
      Top = 64
      Width = 104
      Height = 17
      Caption = 'Text to Center'
      TabOrder = 2
    end
  end
  object gbCommentSetting: TGroupBox
    Left = 8
    Top = 80
    Width = 336
    Height = 184
    Caption = ' Comment Settings '
    TabOrder = 0
    object Label1: TLabel
      Left = 184
      Top = 40
      Width = 50
      Height = 13
      Caption = 'Min Height'
    end
    object Label2: TLabel
      Left = 184
      Top = 64
      Width = 54
      Height = 13
      Caption = 'Max Height'
    end
    object Label3: TLabel
      Left = 8
      Top = 96
      Width = 160
      Height = 13
      AutoSize = False
      Caption = 'Layer for Top Component'
    end
    object Label4: TLabel
      Left = 8
      Top = 120
      Width = 160
      Height = 13
      AutoSize = False
      Caption = 'Layer for Bottom Component'
    end
    object CheckBoxChip: TCheckBox
      Left = 8
      Top = 64
      Width = 104
      Height = 17
      Caption = 'Only Chip'
      Enabled = False
      TabOrder = 2
    end
    object CheckBoxSelect: TCheckBox
      Left = 8
      Top = 40
      Width = 104
      Height = 17
      Caption = 'Selected Items'
      TabOrder = 1
    end
    object CheckBoxSmart: TCheckBox
      Left = 8
      Top = 152
      Width = 232
      Height = 17
      Caption = 'Smart Comment Small Comp'
      Enabled = False
      TabOrder = 7
    end
    object txtMinHeight: TEdit
      Left = 272
      Top = 36
      Width = 48
      Height = 21
      Alignment = taCenter
      AutoSize = False
      TabOrder = 3
      Text = '0.25'
    end
    object txtMaxHeight: TEdit
      Left = 272
      Top = 60
      Width = 48
      Height = 21
      Alignment = taCenter
      AutoSize = False
      TabOrder = 4
      Text = '1.0'
    end
    object ComboBoxLayerTop: TComboBox
      Left = 176
      Top = 92
      Width = 145
      Height = 21
      TabOrder = 5
      Text = 'ComboBoxLayerTop'
      OnChange = ComboBoxLayerTopChange
    end
    object ComboBoxLayerBot: TComboBox
      Left = 176
      Top = 116
      Width = 145
      Height = 21
      Color = clBtnFace
      Ctl3D = True
      ParentCtl3D = False
      TabOrder = 6
      Text = 'ComboBoxLayerBot'
    end
    object CheckBoxShowAll: TCheckBox
      Left = 8
      Top = 16
      Width = 97
      Height = 17
      Caption = 'Show All'
      Checked = True
      State = cbChecked
      TabOrder = 0
    end
  end
  object ButOK: TButton
    Left = 96
    Top = 272
    Width = 75
    Height = 25
    Caption = 'OK'
    Default = True
    TabOrder = 2
    OnClick = ButOKClick
  end
  object ButCancel: TButton
    Left = 184
    Top = 272
    Width = 75
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    TabOrder = 3
    OnClick = ButCancelClick
  end
  object ButSetting: TButton
    Left = 264
    Top = 272
    Width = 83
    Height = 25
    Caption = #1053#1072#1089#1090#1088#1086#1081#1082#1080'>>'
    TabOrder = 4
    OnClick = ButSettingClick
  end
  object GroupBox2: TGroupBox
    Left = 360
    Top = 80
    Width = 144
    Height = 184
    Caption = ' Text Height '
    TabOrder = 1
    object Label5: TLabel
      Left = 24
      Top = 18
      Width = 36
      Height = 13
      Caption = 'Max>>'
    end
    object txtH2: TEdit
      Left = 8
      Top = 64
      Width = 64
      Height = 21
      Alignment = taCenter
      TabOrder = 3
      Text = '0.5'
    end
    object txtH3: TEdit
      Left = 8
      Top = 88
      Width = 64
      Height = 21
      Alignment = taCenter
      TabOrder = 5
      Text = '0.4'
    end
    object txtH4: TEdit
      Left = 8
      Top = 112
      Width = 64
      Height = 21
      Alignment = taCenter
      TabOrder = 7
      Text = '0.3'
    end
    object txtH5: TEdit
      Left = 8
      Top = 136
      Width = 64
      Height = 21
      Alignment = taCenter
      TabOrder = 9
      Text = '0.25'
    end
    object txtH1: TEdit
      Left = 8
      Top = 40
      Width = 64
      Height = 21
      Alignment = taCenter
      TabOrder = 1
      Text = '0.75'
    end
    object txtW5: TEdit
      Left = 72
      Top = 136
      Width = 64
      Height = 21
      Alignment = taCenter
      TabOrder = 10
      Text = '0.075'
    end
    object txtW4: TEdit
      Left = 72
      Top = 112
      Width = 64
      Height = 21
      Alignment = taCenter
      TabOrder = 8
      Text = '0.075'
    end
    object txtW3: TEdit
      Left = 72
      Top = 88
      Width = 64
      Height = 21
      Alignment = taCenter
      TabOrder = 6
      Text = '0.075'
    end
    object txtW2: TEdit
      Left = 72
      Top = 64
      Width = 64
      Height = 21
      Alignment = taCenter
      TabOrder = 4
      Text = '0.1'
    end
    object txtW1: TEdit
      Left = 72
      Top = 40
      Width = 64
      Height = 21
      Alignment = taCenter
      TabOrder = 2
      Text = '0.15'
    end
    object txtW0: TEdit
      Left = 72
      Top = 16
      Width = 64
      Height = 21
      Alignment = taCenter
      TabOrder = 0
      Text = '0.2'
    end
  end
  object rgTarget: TRadioGroup
    Left = 8
    Top = 8
    Width = 336
    Height = 64
    Caption = 'Target Objects'
    ItemIndex = 1
    Items.Strings = (
      'Designators (place to center 0.4/0.075)'
      'Comment')
    TabOrder = 5
    OnClick = rgTargetClick
  end
end
