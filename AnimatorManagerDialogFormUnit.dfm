object AnimatorManagerDialogForm: TAnimatorManagerDialogForm
  Left = 527
  Top = 331
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = 'Animations'
  ClientHeight = 361
  ClientWidth = 649
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -14
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  Icon.Data = {
    0000010001002020100000000000E80200001600000028000000200000004000
    0000010004000000000080020000000000000000000000000000000000000000
    0000000080000080000000808000800000008000800080800000C0C0C0008080
    80000000FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00CCC0
    000CCCC0000000000CCCC7777CCCCCCC0000CCCC00000000CCCC7777CCCCCCCC
    C0000CCCCCCCCCCCCCC7777CCCCC0CCCCC0000CCCCCCCCCCCC7777CCCCC700CC
    C00CCCC0000000000CCCC77CCC77000C0000CCCC00000000CCCC7777C7770000
    00000CCCC000000CCCC777777777C000C00000CCCC0000CCCC77777C777CCC00
    CC00000CCCCCCCCCC77777CC77CCCCC0CCC000CCCCC00CCCCC777CCC7CCCCCCC
    CCCC0CCCCCCCCCCCCCC7CCCCCCCCCCCC0CCCCCCCCCCCCCCCCCCCCCC7CCC70CCC
    00CCCCCCCC0CC0CCCCCCCC77CC7700CC000CCCCCC000000CCCCCC777CC7700CC
    0000CCCC00000000CCCC7777CC7700CC0000C0CCC000000CCC7C7777CC7700CC
    0000C0CCC000000CCC7C7777CC7700CC0000CCCC00000000CCCC7777CC7700CC
    000CCCCCC000000CCCCCC777CC7700CC00CCCCCCCC0CC0CCCCCCCC77CC770CCC
    0CCCCCCCCCCCCCCCCCCCCCC7CCC7CCCCCCCC0CCCCCCCCCCCCCC7CCCCCCCCCCC0
    CCC000CCCCC00CCCCC777CCC7CCCCC00CC00000CCCCCCCCCC77777CC77CCC000
    C00000CCCC0000CCCC77777C777C000000000CCCC000000CCCC777777777000C
    0000CCCC00000000CCCC7777C77700CCC00CCCC0000000000CCCC77CCC770CCC
    CC0000CCCCCCCCCCCC7777CCCCC7CCCCC0000CCCCCCCCCCCCCC7777CCCCCCCCC
    0000CCCC00000000CCCC7777CCCCCCC0000CCCC0000000000CCCC7777CCC0000
    0000000000000000000000000000000000000000000000000000000000000000
    0000000000000000000000000000000000000000000000000000000000000000
    0000000000000000000000000000000000000000000000000000000000000000
    000000000000000000000000000000000000000000000000000000000000}
  OldCreateOrder = False
  Position = poMainFormCenter
  OnCreate = FormCreate
  PixelsPerInch = 120
  TextHeight = 16
  object GroupBox1: TGroupBox
    Left = 8
    Top = 8
    Width = 289
    Height = 249
    Caption = ' Style of animation '
    TabOrder = 0
    object ListBox1: TListBox
      Left = 2
      Top = 18
      Width = 285
      Height = 229
      Align = alClient
      BevelKind = bkFlat
      BorderStyle = bsNone
      ItemHeight = 16
      TabOrder = 0
      OnClick = ListBox1Click
    end
  end
  object Panel1: TPanel
    Left = 8
    Top = 264
    Width = 289
    Height = 25
    Alignment = taLeftJustify
    BevelOuter = bvLowered
    Caption = ' Duration: 700 ms'
    TabOrder = 1
    object TrackBar1: TTrackBar
      Left = 111
      Top = 1
      Width = 177
      Height = 23
      Align = alRight
      Anchors = [akLeft, akTop, akRight, akBottom]
      Max = 3000
      Min = 10
      Position = 700
      TabOrder = 0
      ThumbLength = 16
      TickMarks = tmBoth
      TickStyle = tsNone
      OnChange = TrackBar1Change
    end
  end
  object Panel2: TPanel
    Left = 8
    Top = 296
    Width = 289
    Height = 25
    Alignment = taLeftJustify
    BevelOuter = bvLowered
    Caption = ' Utilisation: 100%'
    TabOrder = 2
    object TrackBar2: TTrackBar
      Left = 111
      Top = 1
      Width = 177
      Height = 23
      Align = alRight
      Anchors = [akLeft, akTop, akRight, akBottom]
      Max = 100
      Position = 100
      TabOrder = 0
      ThumbLength = 16
      TickMarks = tmBoth
      TickStyle = tsNone
      OnChange = TrackBar2Change
    end
  end
  object BitBtn1: TBitBtn
    Left = 455
    Top = 328
    Width = 90
    Height = 25
    TabOrder = 3
    Kind = bkOK
  end
  object BitBtn2: TBitBtn
    Left = 552
    Top = 328
    Width = 89
    Height = 25
    TabOrder = 4
    Kind = bkCancel
  end
  object BitBtn3: TBitBtn
    Left = 8
    Top = 328
    Width = 97
    Height = 25
    Caption = 'Preview'
    TabOrder = 5
    OnClick = BitBtn3Click
    Glyph.Data = {
      DE010000424DDE01000000000000760000002800000024000000120000000100
      0400000000006801000000000000000000001000000000000000000000000000
      80000080000000808000800000008000800080800000C0C0C000808080000000
      FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00333333444444
      33333333333F8888883F33330000324334222222443333388F3833333388F333
      000032244222222222433338F8833FFFFF338F3300003222222AAAAA22243338
      F333F88888F338F30000322222A33333A2224338F33F8333338F338F00003222
      223333333A224338F33833333338F38F00003222222333333A444338FFFF8F33
      3338888300003AAAAAAA33333333333888888833333333330000333333333333
      333333333333333333FFFFFF000033333333333344444433FFFF333333888888
      00003A444333333A22222438888F333338F3333800003A2243333333A2222438
      F38F333333833338000033A224333334422224338338FFFFF8833338000033A2
      22444442222224338F3388888333FF380000333A2222222222AA243338FF3333
      33FF88F800003333AA222222AA33A3333388FFFFFF8833830000333333AAAAAA
      3333333333338888883333330000333333333333333333333333333333333333
      0000}
    NumGlyphs = 2
  end
  object Panel3: TPanel
    Left = 304
    Top = 16
    Width = 337
    Height = 305
    BorderStyle = bsSingle
    TabOrder = 6
    object PaintBox1: TPaintBox
      Left = 1
      Top = 1
      Width = 331
      Height = 299
      Align = alClient
      Color = clBackground
      ParentColor = False
      OnPaint = PaintBox1Paint
    end
  end
end