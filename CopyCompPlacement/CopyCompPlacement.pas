{ -------------------------------- }
{ ------- Edit PCB Object -------- }
{ ----------- v 1.0 -------------- }
Uses Registry;

var
    PCBBoard        : IPCB_Board;
    PCBLibrary      : IPCB_Library;
    SelectedPrims   : TStringList;
    SelectedComps   : TStringList;
    Comp1           : IPCB_Component;
    MoveDes         : Boolean;
    MoveComp        : Boolean;
//    Prim1           : IPCB_Primitive;
//    Prim2           : IPCB_Primitive;

procedure RegistryRead;
var
    Registry  : TRegistry;
Begin
    { создаём объект TRegistry }
    Registry := TRegistry.Create;
    Try
        { устанавливаем корневой ключ; напрмер hkey_local_machine или hkey_current_user }
        //Registry.RootKey := HKEY_CURRENT_USER; {Устанавливается автоматически}
        { открываем и создаём ключ }
        Registry.OpenKey('Software\AltiumScripts\CopyCompPlacement',true);

        if Registry.ValueExists('ClearSelected')   then cbClearSelected.Checked :=    Registry.ReadBool('ClearSelected');
        if Registry.ValueExists('OnlyDes')    then cbOnlyDes.Checked :=     Registry.ReadBool('OnlyDes');

        { закрываем и освобождаем ключ }
        Registry.CloseKey;
    Finally
        Registry.Free;
    End;
End;

procedure RegistryWrite;
var
    Registry: TRegistry;
Begin
    { создаём объект TRegistry }
    Registry := TRegistry.Create;
    Try
        { устанавливаем корневой ключ; напрмер hkey_local_machine или hkey_current_user }
        //Registry.RootKey := HKEY_CURRENT_USER; {Устанавливается автоматически}
        { открываем и создаём ключ }
        Registry.OpenKey('Software\AltiumScripts\CopyCompPlacement',true);
        { записываем значения }

        Registry.WriteBool('ClearSelected',          cbClearSelected.Checked);
        Registry.WriteBool('OnlyDes',     cbOnlyDes.Checked);

        { закрываем и освобождаем ключ }
        Registry.CloseKey;
    Finally
        Registry.Free;
    End;

End;

procedure DetectViolations;
var
    BoardIterator : IPCB_SpatialIterator;
    Iterator      : IPCB_BoardIterator;
    Rule          : IPCB_Rule;
    Violation     : IPCB_Violation;
    Rectangle     : TCoordRect;
    MaxWidth      : Integer;

begin
    // now we have info about selected primitives. We need to cycle through it because

    //Determinate MaxWidth
    Iterator        := PCBBoard.BoardIterator_Create;
    Iterator.AddFilter_ObjectSet(MkSet(eRuleObject));
    Iterator.AddFilter_LayerSet(AllLayers);
    Iterator.AddFilter_Method(eProcessAll);

    MaxWidth := 0;

    Rule := Iterator.FirstPCBObject;

    While (Rule <> Nil) Do
    Begin
        if (Rule.RuleKind = eRule_Clearance) and Rule.Enabled then
           if MaxWidth < Rule.Gap then
              MaxWidth := Rule.Gap;

        Rule := Iterator.NextPCBObject;
    End;  //While (Rule <> Nil)
    //End of Determinate MaxWidth

       Rectangle := Prim1.BoundingRectangle;
       BoardIterator := PCBBoard.SpatialIterator_Create;
       BoardIterator.AddFilter_IPCB_LayerSet(Prim1.Layer);
       BoardIterator.AddFilter_ObjectSet(AllObjects);
       BoardIterator.AddFilter_Area(Rectangle.Left - MaxWidth,
                                    Rectangle.Bottom - MaxWidth,
                                    Rectangle.Right + MaxWidth,
                                    Rectangle.Top + MaxWidth);

       Prim2 := BoardIterator.FirstPCBObject;

       while Prim2 <> Nil do
       begin
          Rule := PCBBoard.FindDominantRuleForObjectPair(Prim1, Prim2, eRule_Clearance);

          if Rule <> nil then
          begin
             PCBBoard.AddPCBObject(Rule.ActualCheck(Prim1, Prim2));
             Prim2.GraphicallyInvalidate;
          end;

          Prim2 := BoardIterator.NextPCBObject;
       end;

    PCBBoard.SpatialIterator_Destroy(BoardIterator);
    PCBBoard.BoardIterator_Destroy(Iterator);

end;

procedure DeSelectAll;
begin
    ResetParameters;
    AddStringParameter('Scope','All');
    RunProcess('PCB:DeSelect');
end;

function GetToken(InputText : String, TokenNum: Integer, SepChar: String): string;
var
  Token: string;
  StringLen: Integer;
  Num: Integer;
  EndofToken: Integer;
  i: Integer;
begin
  {Delete multiple spaces}
  StringLen := Length(InputText);

  Num := 1;
  EndofToken := StringLen;

  while ((Num <= TokenNum) and (EndofToken <> 0)) do
  begin
    EndofToken := Pos(SepChar, InputText);
    if EndofToken <> 0 then
    begin
      Token := Copy(InputText, 1, EndofToken - 1);
      Delete(InputText, 1, EndofToken);
      Inc(Num);
    end
    else
      Token := InputText;
  end;

  if Num >= TokenNum then
    Result := Token
  else
    Result := '';

end;

function NameZeroAdd (InputStr: String; NumLength : Integer) : String;
var
    i               : integer;
    ParseChar       : integer; // текущая позиция в строке
    ParseCharFound  : integer; // Найденая позиция числа
    RealNum         : integer; // 0..9
    InputStr0       : String;
begin
    ParseChar := 0;   // текущий символ
    ParseCharFound := Length(InputStr) + 1; //зададим найденную позицию дальше конца строки
    RealNum := 0;       // сперва ищем '0'
    InputStr0 := InputStr;

    //Ищем позицию первой цифры
    for RealNum := 0 to 9 do
    begin
        ParseChar := pos(IntToStr(RealNum), InputStr);
        if (ParseChar > 0) and (ParseChar < ParseCharFound) then
        ParseCharFound := ParseChar;
    end;

    if Length(InputStr) - ParseCharFound + 1 <= NumLength - 1 then
    begin
        for i := Length(InputStr) - ParseCharFound + 1 to NumLength - 1 do   //чтобы цифр получилось 5
        begin
            Insert('0', InputStr0, ParseCharFound);
        end; // end FOR
    end; //end IF

    Result := InputStr0;
end;


//*********** COPY ***********
procedure CopyCompPos;
var
    CompName0    : String;
    CompName     : String;
    i, j   : Integer;

    StringForSL         : String;
    //StringForSL_Des     : String;

    SL_ClpBrd       :   TStringList;
    //SL_Des_ClpBrd   :   TStringList;
begin
    PCBBoard := PCBServer.GetCurrentPCBBoard;
    If PCBBoard = Nil Then Exit;
    if PCBBoard.SelectecObjectCount = 0 then exit;

    //Start of StringList.Create
    //SelectecPrims - StringList с выделенными объекстами
    SelectedComps := TStringList.Create;
    SL_ClpBrd := TStringList.Create;
    SL_ClpBrd.Sorted := true;

    StringForSL := '';

    for i := 0 to PCBBoard.SelectecObjectCount - 1 do
    begin
       if (PCBBoard.SelectecObject[i].ObjectId = eComponentObject) then
       SelectedComps.AddObject(IntToStr(i), PCBBoard.SelectecObject[i]);    //Вносим в перечень  объект
    end;
    //End of TStringList.Create

    if SelectedComps.Count = 0 then
    begin
        ShowInfo('Please select at least one component');
        exit;
    end;

    for i := 0 to SelectedComps.Count - 1 do
    begin
        Comp1 := SelectedComps.GetObject(i);

        CompName := Comp1.Name.Text;

        //Добавляем незначащие нули для сортировки
        CompName0 := NameZeroAdd(CompName, 5);

  //      StringForSL: = Comp1.Name + #9 + FloatToStr(CoordToMMs(Comp1.x)) + #9 + FloatToStr(CoordToMMs(Comp1.y));
        StringForSL: = CompName0 + #9 +                                   //1
                       Layer2String(Comp1.Layer) + #9 +                   //2
                       IntToStr(Comp1.x - PCBBoard.XOrigin) + #9 +        //3
                       IntToStr(Comp1.y - PCBBoard.YOrigin) + #9 +        //4
                       FloatToStr(Comp1.Rotation) + #9 +                  //5
                       IntToStr(Comp1.Name.XLocation - Comp1.x) + #9 +    //6
                       IntToStr(Comp1.Name.YLocation - Comp1.y) + #9 +    //7
                       FloatToStr(Comp1.Name.Rotation) + #9 +             //8
                       IntToStr(Comp1.Name.Size) + #9 +                   //9
                       IntToStr(Comp1.Name.Width) + #9 +                  //10
                       IntToStr(Comp1.Name.Layer) + #9 +                  //11
                       IntToStr(Comp1.NameOn) + #9 +                      //12
                       IntToStr(Comp1.NameAutoPosition) + #9 +            //13
                       IntToStr(Comp1.Comment.XLocation - Comp1.x) + #9 + //14
                       IntToStr(Comp1.Comment.YLocation - Comp1.y) + #9 + //15
                       FloatToStr(Comp1.Comment.Rotation) + #9 +          //16
                       IntToStr(Comp1.Comment.Size) + #9 +                //17
                       IntToStr(Comp1.Comment.Width)+ #9 +                //18
                       IntToStr(Comp1.Comment.Layer) + #9 +               //19
                       IntToStr(Comp1.CommentOn) + #9 +                   //20
                       IntToStr(Comp1.CommentAutoPosition);               //21
        //ShowMessage(ss);
        SL_ClpBrd.Add(StringForSL);
        //ShowMessage(IntToStr(SL_ClpBrd.Count));

      {  if SL_ClpBrd.Count = 3 then
        begin
            ShowMessage(SL_ClpBrd[0] + #13 +
                        SL_ClpBrd[1] + #13 +
                        SL_ClpBrd[2]);
      
        end;}

    end;  //for i := 0 to SelectedComps.Count - 1
    Clipboard.AsText := SL_ClpBrd.Text;

    //RegistryRead;
    if cbClearSelected.Checked then DeSelectAll;
    SL_ClpBrd.Free;

    close;

end;

//*********** PASTE ***********
procedure PasteCompPosProc;
var
    CompName0    : String;
    CompName     : String;
    i, j   : Integer;

    NewLayer    : TLayer;
    NewX        : TCoord;
    NewY        : TCoord;
    NewRot      : Real;
    NumStr      : integer;

    StringForSL : String;
    SL_SelectedCmp      : TstringList;  //SL с сейчас выделенными компонентами
    SL_ClpBrdPaste      : TStringList;  //SL скопированный
begin
    SL_ClpBrdPaste := TStringList.Create;
    SL_ClpBrdPaste.Sorted := true;
    SL_ClpBrdPaste.Text := Clipboard.AsText;
    //ShowMessage(SL_ClpBrdPaste);

    SL_SelectedCmp := TStringList.Create;
    SL_SelectedCmp.Sorted := true;

    StringForSL := '';

    PCBBoard := PCBServer.GetCurrentPCBBoard;
    If PCBBoard = Nil Then Exit;
    if PCBBoard.SelectecObjectCount = 0 then exit;

    //Start of StringList.Create
    //SelectecPrims - StringList с выделенными объекстами
    SelectedComps := TStringList.Create;

    for i := 0 to PCBBoard.SelectecObjectCount - 1 do
    begin
       if (PCBBoard.SelectecObject[i].ObjectId = eComponentObject) then
       SelectedComps.AddObject(IntToStr(i), PCBBoard.SelectecObject[i]);    //Вносим в перечень  объект
    end;
    //End of TStringList.Create

    if SelectedComps.Count = 0 then
    begin
        ShowInfo('Please select at least one component');
        exit;
    end;

    if SelectedComps.Count <> SL_ClpBrdPaste.Count then
    begin
        ShowInfo('Num copy and paste comps must be equal!' + #13 +
                 'Num of copy comps is ' + IntTostr(SL_ClpBrdPaste.Count) + #13 +
                 'number of selected elements ' + IntTostr(SelectedComps.Count));
        exit;
    end;

    //Составляем перечень выделенных компонентов и сортируем
    for i := 0 to SelectedComps.Count - 1 do
    begin
        Comp1 := SelectedComps.GetObject(i);
        CompName := Comp1.Name.Text;

        //Добавляем незначащие нули для сортировки
        CompName0 := NameZeroAdd(CompName, 5);

        StringForSL: = CompName0; //Добавляем только наименования

        SL_SelectedCmp.Add(StringForSL);

     {   if SL_SelectedCmp.Count = 3 then
            ShowMessage(SL_SelectedCmp[0] + #13 +
                        SL_SelectedCmp[1] + #13 +
                        SL_SelectedCmp[2]);
     }
    end;

    //Редактируем свойства компонентов
    for i := 0 to SelectedComps.Count - 1 do
    begin
        Comp1 := SelectedComps.GetObject(i);
        CompName := Comp1.Name.Text;

        //Поиск и сопоставление компонентов
        //Добавляем незначащие нули для сортировки
        CompName0 := NameZeroAdd(CompName, 5);

        //Ищем позицию выбранного элемента в списке
        NumStr := SL_SelectedCmp.IndexOf(CompName0);


        //ShowMessage(InttoStr(NumStr) + #13 +
        //            CompName);




        if MoveComp then
        begin
            Comp1.BeginModify;
            Comp1.Layer     := String2Layer (GetToken(SL_ClpBrdPaste[NumStr], 2, #9));
            Comp1.X         := StrToInt     (GetToken(SL_ClpBrdPaste[NumStr], 3, #9)) + PCBBoard.XOrigin;
            Comp1.Y         := StrToInt     (GetToken(SL_ClpBrdPaste[NumStr], 4, #9)) + PCBBoard.YOrigin;
            Comp1.Rotation  := StrToFloat   (GetToken(SL_ClpBrdPaste[NumStr], 5, #9));
            Comp1.EndModify; 
        end;
        if MoveDes then
        begin
            Comp1.Name.BeginModify;
            Comp1.Name.XLocation    := StrToInt (GetToken(SL_ClpBrdPaste[NumStr], 6, #9)) + Comp1.x;
            Comp1.Name.YLocation    := StrToInt (GetToken(SL_ClpBrdPaste[NumStr], 7, #9)) + Comp1.y;
            Comp1.Name.Rotation     := StrToFloat(GetToken(SL_ClpBrdPaste[NumStr], 8, #9));
            Comp1.Name.Size         := StrToInt (GetToken(SL_ClpBrdPaste[NumStr], 9, #9));
            Comp1.Name.Width        := StrToInt (GetToken(SL_ClpBrdPaste[NumStr], 10, #9));
            Comp1.Name.Layer        := StrToInt (GetToken(SL_ClpBrdPaste[NumStr], 11, #9));
            Comp1.NameOn            := StrToInt (GetToken(SL_ClpBrdPaste[NumStr], 12, #9));
            Comp1.Comment.XLocation := StrToInt (GetToken(SL_ClpBrdPaste[NumStr], 14, #9)) + Comp1.x;
            Comp1.Comment.YLocation := StrToInt (GetToken(SL_ClpBrdPaste[NumStr], 15, #9)) + Comp1.y;
            Comp1.Comment.Rotation  := StrToFloat (GetToken(SL_ClpBrdPaste[NumStr], 16, #9));
            Comp1.Comment.Size      := StrToInt (GetToken(SL_ClpBrdPaste[NumStr], 17, #9));
            Comp1.Comment.Width     := StrToInt (GetToken(SL_ClpBrdPaste[NumStr], 18, #9));
            Comp1.Comment.Layer     := StrToInt (GetToken(SL_ClpBrdPaste[NumStr], 19, #9));
            Comp1.CommentOn         := StrToInt (GetToken(SL_ClpBrdPaste[NumStr], 20, #9));

            Comp1.ChangeNameAutoposition(StrToInt (GetToken(SL_ClpBrdPaste[NumStr], 13, #9)));
            Comp1.ChangeCommentAutoposition(StrToInt (GetToken(SL_ClpBrdPaste[NumStr], 21, #9)));

            //Если компонент повернут относительно первоначального варианта, докручиваем Des
            Comp1.Name.RotateAroundXY(Comp1.X,Comp1.Y, Comp1.Rotation -  (StrToFloat   (GetToken(SL_ClpBrdPaste[NumStr], 5, #9))) );
            Comp1.Comment.RotateAroundXY(Comp1.X,Comp1.Y, Comp1.Rotation -  (StrToFloat   (GetToken(SL_ClpBrdPaste[NumStr], 5, #9))) );
            Comp1.Name.EndModify;
        end;

        //ShowMessage('Layer = ' + GetToken(SL_ClpBrdPaste[NumStr], 2, #9));
        //ShowMessage('X = ' + GetToken(SL_ClpBrdPaste[NumStr], 3, #9));
        //ShowMessage('Y = ' + GetToken(SL_ClpBrdPaste[NumStr], 4, #9));
        //ShowMessage('Rot = ' + GetToken(SL_ClpBrdPaste[NumStr], 5, #9));





        //Comp1.Selected := true;
        //Comp1.GraphicallyInvalidate;
    end;


    PCBBoard.ViewManager_FullUpdate;

    SL_SelectedCmp.Free;
    SL_ClpBrdPaste.Free;
    close;

end;

procedure PasteCompPos;
begin
    MoveDes := false;
    MoveComp:= true;
    PasteCompPosProc;
end;

procedure PasteCompPosAndDes;
begin
    MoveDes := true;
    MoveComp := true;
    PasteCompPosProc;
end;

procedure PasteCompDes;
begin
    MoveDes := true;
    MoveComp := false;
    PasteCompPosProc;
end;

procedure TfrmCopyCompPlacementSetting.ButtonOKClick(Sender: TObject);
begin
    RegistryWrite;
    close;
end;

procedure TfrmCopyCompPlacementSetting.ButtonCancelClick(Sender: TObject);
begin
    close;
end;

procedure CopyCompPlacementSetting;
begin
    RegistryRead;
    frmCopyCompPlacementSetting.Show;
end;


