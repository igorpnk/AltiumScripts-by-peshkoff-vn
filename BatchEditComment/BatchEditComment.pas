Uses Registry;

var
   Board       : IPCB_Board;
   //MechPairs   : TStringList;
   MechTopList : TStringList;
   MechBotList : TStringList;
   {CTextA : array[1..4] of CText;{ =   (
      (Name : '0.25x0.01'; Height : 0.25; Width : 0.01 ; Width1Sym : 0.22),
      (Name : '0.3x0.01' ; Height : 0.3 ; Width : 0.01 ; Width1Sym : 0.26),
      (Name : '0.4x0.05' ; Height : 0.4 ; Width : 0.05 ; Width1Sym : 0.37),
      (Name : '0.5x0.075'; Height : 0.5 ; Width : 0.075; Width1Sym : 0.45),
    ) ;                           }

procedure RegistryRead;
var
    Registry: TRegistry;
Begin
    { создаём объект TRegistry }
    Registry := TRegistry.Create;
    Try
        { устанавливаем корневой ключ; напрмер hkey_local_machine или hkey_current_user }
        //Registry.RootKey := HKEY_CURRENT_USER; {Устанавливается автоматически}
        { открываем и создаём ключ }
        Registry.OpenKey('Software\AltiumScripts\BatchEditComment',true);
        {Читаем значения}
        {Данные}
        if Registry.ValueExists('rgTarget') then    rgTarget.ItemIndex := Registry.ReadInteger('rgTarget');

        if Registry.ValueExists('chkShowAll') then    CheckBoxShowAll.Checked := Registry.ReadBool('chkShowAll');
        if Registry.ValueExists('chkSelected') then    CheckBoxSelect.Checked := Registry.ReadBool('chkSelected');
        if Registry.ValueExists('chkChip') then    CheckBoxChip.Checked := Registry.ReadBool('chkChip');
        if Registry.ValueExists('MinHeight') then    txtMinHeight.Text := Registry.ReadString('MinHeight');
        if Registry.ValueExists('MaxHeight') then    txtMaxHeight.Text := Registry.ReadString('MaxHeight');
        if Registry.ValueExists('chkSmart') then    CheckBoxSmart.Checked := Registry.ReadBool('chkSmart');

        if Registry.ValueExists('chkDesSelect') then    cbSelectDes.Checked := Registry.ReadBool('chkDesSelect');
        if Registry.ValueExists('chkMinText') then    cbMinTextDes.Checked := Registry.ReadBool('chkMinText');
        if Registry.ValueExists('chkTextCenter') then    cbTexttoCenterDes.Checked := Registry.ReadBool('chkTextCenter');

        {Настройки текста}
        if Registry.ValueExists('txtW0') then    txtW0.Text := Registry.ReadString('txtW0');
        if Registry.ValueExists('txtH1') then    txtH1.Text := Registry.ReadString('txtH1');
        if Registry.ValueExists('txtW1') then    txtW1.Text := Registry.ReadString('txtW1');
        if Registry.ValueExists('txtH2') then    txtH2.Text := Registry.ReadString('txtH2');
        if Registry.ValueExists('txtW2') then    txtW2.Text := Registry.ReadString('txtW2');
        if Registry.ValueExists('txtH3') then    txtH3.Text := Registry.ReadString('txtH3');
        if Registry.ValueExists('txtW3') then    txtW3.Text := Registry.ReadString('txtW3');
        if Registry.ValueExists('txtH4') then    txtH4.Text := Registry.ReadString('txtH4');
        if Registry.ValueExists('txtW4') then    txtW4.Text := Registry.ReadString('txtW4');
        if Registry.ValueExists('txtH5') then    txtH5.Text := Registry.ReadString('txtH5');
        if Registry.ValueExists('txtW5') then    txtW5.Text := Registry.ReadString('txtW5');

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
        Registry.OpenKey('Software\AltiumScripts\BatchEditComment',true);
        { записываем значения }
        {Данные}
        Registry.WriteInteger('rgTarget',   rgTarget.ItemIndex);

        Registry.WriteBool('chkShowAll',    CheckBoxShowAll.Checked);
        Registry.WriteBool('chkSelected',   CheckBoxSelect.Checked);
        Registry.WriteBool('chkChip',       CheckBoxChip.Checked);
        Registry.WriteString('MinHeight',   txtMinHeight.Text);
        Registry.WriteString('MaxHeight',   txtMaxHeight.Text);
        Registry.WriteBool('chkSmart',      CheckBoxSmart.Checked);

        Registry.WriteBool('chkDesSelect',  cbSelectDes.Checked);
        Registry.WriteBool('chkMinText',    cbMinTextDes.Checked);
        Registry.WriteBool('chkTextCenter', cbTexttoCenterDes.Checked);

        {Настройки текста}
        Registry.WriteString('txtW0',txtW0.Text);
        Registry.WriteString('txtH1',txtH1.Text);
        Registry.WriteString('txtW1',txtW1.Text);
        Registry.WriteString('txtH2',txtH2.Text);
        Registry.WriteString('txtW2',txtW2.Text);
        Registry.WriteString('txtH3',txtH3.Text);
        Registry.WriteString('txtW3',txtW3.Text);
        Registry.WriteString('txtH4',txtH4.Text);
        Registry.WriteString('txtW4',txtW4.Text);
        Registry.WriteString('txtH5',txtH5.Text);
        Registry.WriteString('txtW5',txtW5.Text);

        { закрываем и освобождаем ключ }
        Registry.CloseKey;
    Finally
        Registry.Free;
    End;

End;

//Вычисляем максимально допустимую ширину для текста на футпринте
function GetMaxTextWidth (InputStr:String):Real;
begin
    Case Copy(InputStr, 2, 5) of
        'C1005' : Result:=1.0;
        'C1608' : Result:=1.6;
        'C2012' : Result:=2.0;
        'C3216' : Result:=3.2;
        'CP321' : Result:=2.2;     //Tantalum
        'CP352' : Result:=2.4;
        'CP603' : Result:=5;
        'CP734' : Result:=6.2;
    Else
        Result:=3;
    End;
end;

//Вычисляем высоту текста исходя из содержимого текста и максимально допустимого поля для него
function GetTextHeight (InputStr:String; TargetTextWidth:Real):Real;
var
    Width1Sym   : Real;
    TargetWidth1Sym  : Real;
    TargetHeight    : Real;
begin
    //Рассчитываем ширину 1 символа, нуобходимую для вписывания текста в заданные габариты
    TargetWidth1Sym:=TargetTextWidth/Length(InputStr);
    //Расчитываем необходимую высоту текста исходя из ширины
    //В шрифте Default ширина символа в тексте ~0.9 от высоты текста
    TargetHeight:=TargetWidth1Sym/0.9;

    //Если количество символов 1-2, то высоту нужно уменьшить немного
    if Length(InputStr) < 3 then TargetHeight:=TargetWidth1Sym/1.5;
    if Length(InputStr) < 2 then TargetHeight:=TargetWidth1Sym/2.5;

    if TargetHeight > FloatToStr(txtH5.Text) then Result := FloatToStr(txtH5.Text);
    if TargetHeight > FloatToStr(txtH4.Text) then Result := FloatToStr(txtH4.Text);
    if TargetHeight > FloatToStr(txtH3.Text) then Result := FloatToStr(txtH3.Text);
    if TargetHeight > FloatToStr(txtH2.Text) then Result := FloatToStr(txtH2.Text);
    if TargetHeight > FloatToStr(txtH1.Text) then Result := FloatToStr(txtH1.Text);

    //if TargetHeight > 0.25 then Result := 0.25;
    //if TargetHeight > 0.3  then Result := 0.3;
    //if TargetHeight > 0.4  then Result := 0.4;
    //if TargetHeight > 0.5  then Result := 0.5;
    //if TargetHeight > 0.75 then Result := 0.75;
    //if TargetHeight > 1.0  then Result := 1.0;


    //В случае перебора
    if TargetHeight < FloatToStr(txtMinHeight.Text) then Result := FloatToStr(txtMinHeight.Text);
    if TargetHeight > FloatToStr(txtMaxHeight.Text) then Result := FloatToStr(txtMaxHeight.Text);

end;

//Устанавливаем толщину текста в зависимости от высоты
function GetTextThickness (TextHeight:Real):Real;
begin
    Result := FloatToStr(txtW0.Text);
    if TextHeight = FloatToStr(txtH1.Text) then Result := FloatToStr(txtW1.Text);
    if TextHeight = FloatToStr(txtH2.Text) then Result := FloatToStr(txtW2.Text);
    if TextHeight = FloatToStr(txtH3.Text) then Result := FloatToStr(txtW3.Text);
    if TextHeight = FloatToStr(txtH4.Text) then Result := FloatToStr(txtW4.Text);
    if TextHeight = FloatToStr(txtH5.Text) then Result := FloatToStr(txtW5.Text);

//    if TextHeight < 0.76 then Result := 0.15;
 //   if TextHeight < 0.61 then Result := 0.1;
 //   if TextHeight < 0.51 then Result := 0.075;
  //  if TextHeight < 0.41 then Result := 0.05;
  //  if TextHeight < 0.31 then Result := 0.01;
end;

procedure TFormMain.ButOKClick(Sender: TObject);
type
    TText = record
      Height      : Real;
      Width       : Real;
      Width1Sym   : Real;
    end;

Var
    IteratorT : IPCB_BoardIterator;
    IteratorB : IPCB_BoardIterator;
    CompListT : TInterfaceList;
    CompListB : TInterfaceList;
    Comp      : IPCB_Component;

    CommShow  : Boolean;
    CommThickness : Real;
    CommHeight : Real;
    FootPattern : String;
    MaxWidth: real;
    RealWidth :real;

    CText     : TText;

    //x,y,      : TCoord;
    //x1, y1    : TCoord;
    //Rotation  : TAngle;
    i, j         : Integer;
    n : integer;
Begin

        RegistryWrite;
        FormMain.Close;
        IteratorT := Board.BoardIterator_Create;
        If IteratorT = Nil Then Exit;
        IteratorT.AddFilter_ObjectSet(MkSet(eComponentObject));
        IteratorT.AddFilter_LayerSet(MkSet(eTopLayer));

        IteratorB := Board.BoardIterator_Create;
        If IteratorB = Nil Then Exit;
        IteratorB.AddFilter_ObjectSet(MkSet(eComponentObject));
        IteratorB.AddFilter_LayerSet(MkSet(eBottomLayer));


// Make CompList
    CompListT := TInterfaceList.Create;
    CompListB := TInterfaceList.Create;

    Try
        Comp := IteratorT.FirstPCBObject;
        While Comp <> Nil Do
        Begin
            if Comp.Pattern <> 'TESTPIN' then CompListT.Add(Comp);
            Comp := IteratorT.NextPCBObject;
        End;
    Finally
        Board.BoardIterator_Destroy(IteratorT);
    End;

    Try
        Comp := IteratorB.FirstPCBObject;
        While Comp <> Nil Do
        Begin
            if Comp.Pattern <> 'TESTPIN' then CompListB.Add(Comp);
            Comp := IteratorB.NextPCBObject;
        End;
    Finally
        Board.BoardIterator_Destroy(IteratorB);
    End;

//Read Comp from list


 {  Try
        Comp := CompList.items[5];
        //ShowMessage(Comp.Name.Text);
        //re:=CoordToMMs(Comp.Comment.Width);
        //re:=CoordToMMs(Comp.Comment.Size);

        Comp.Comment.Size:=MMsToCoord(3.0);
        Comp.Comment.Rotation:=0;
        Comp.Comment.EndModify;
        Comp.ChangeCommentAutoposition:=eAutoPos_CenterCenter;

    Finally
        CompList.Free;
    End;}


if rgTarget.ItemIndex = 1 then //Comment
begin
        CommShow:=CheckBoxShowAll.Checked;

    Try
        PCBServer.PreProcess;

        For i := 0 to CompListT.Count - 1 Do
        Begin

            Comp := CompListT.items[i];

            //Переход к следующему компоненту если сделали "Select Only" компоненты, а компонент не выбран
            If (Not(Comp.Selected)) and (CheckBoxSelect.Checked) then Continue;
            PCBServer.SendMessageToRobots(Comp.Comment.I_ObjectAddress, c_Broadcast, PCBM_BeginModify , c_NoEventData);

            FootPattern:=Comp.Pattern;

            MaxWidth:=GetMaxTextWidth(FootPattern);
            CommHeight := GetTextHeight(Comp.Comment.Text,MaxWidth);

    //Begin of Персональные корректировки
            if ((CommHeight < 0.3) and (Copy(Comp.Comment.Text, 1, 5) = 'BLM15')) then CommHeight := 0.3;
            if (Copy(FootPattern, 1, 3) = 'QFN') or
               (Copy(FootPattern, 1, 5) = 'SOT23') then
                begin
                CommHeight := 0.5;
                end;
    //End of Персональные корректировки

            //Текст '0.1' делаем 0.3 для 0402
            if (Comp.Comment.Text='0.1')
                and (CommHeight > 0.3)
                and (Copy(FootPattern, 2, 5)='C1005') then
                CommHeight := 0.3;
            CommThickness := GetTextThickness(CommHeight);

            //ShowMessage(FootPattern+ ', Comment: '+ Comp.Comment.Text + ' -- ' + FloatToStr(CommHeight)) ;

            Comp.Comment.Rotation := 0;

            if CommShow then Comp.CommentOn := CommShow;
            Comp.Comment.Size := MMsToCoord(CommHeight);
            Comp.Comment.Width := MMsToCoord(CommThickness);

            // Выбираем слой из списка MechList, там записано полное наименование слоя, прописанное в системе
            // Список MechList совпадает со списком ComboBox
            Comp.Comment.Layer:=String2Layer(MechTopList[ComboBoxLayerTop.ItemIndex]);

            //Если компоненты ортогональны, поворачиваем Comment
            If (Comp.Rotation = 90) or (Comp.Rotation = 270) then
                 Comp.Comment.Rotation := 90
            else
                 Comp.Comment.Rotation := 0;

            Comp.ChangeCommentAutoposition:=eAutoPos_CenterCenter;

            //Если компоненты не ортогонально расположены, то Autoposition д.б. manual!

            //Если в первой и 4-й четверти
            If ((Comp.Rotation > 270) and (Comp.Rotation < 360)) or ((Comp.Rotation > 0) and (Comp.Rotation < 90)) then
                begin
                Comp.ChangeCommentAutoposition:=eAutoPos_Manual;
                Comp.Comment.RotateAroundXY(Comp.X,Comp.Y, Comp.Rotation);
                end;
            If ((Comp.Rotation > 90) and (Comp.Rotation < 180)) or ((Comp.Rotation > 180) and (Comp.Rotation < 270)) then
                begin
                Comp.ChangeCommentAutoposition:=eAutoPos_Manual;
                Comp.Comment.RotateAroundXY(Comp.X,Comp.Y, Comp.Rotation - 180);
                end;

    //Begin of Персональные корректировки
            if (Copy(FootPattern, 1, 3) = 'QFN') or
               (Copy(FootPattern, 1, 5) = 'SOT23') then
                begin
                Comp.Comment.Rotation := 0;
                end;
    //End of Персональные корректировки

            PCBServer.SendMessageToRobots(Comp.Comment.I_ObjectAddress, c_Broadcast, PCBM_EndModify , c_NoEventData);
        End;

 // Bottom Layer
        For i := 0 to CompListB.Count - 1 Do
        Begin

            Comp := CompListB.items[i];

            If (Not(Comp.Selected)) and (CheckBoxSelect.Checked) then Continue;

            PCBServer.SendMessageToRobots(Comp.Comment.I_ObjectAddress, c_Broadcast, PCBM_BeginModify , c_NoEventData);

            FootPattern:=Comp.Pattern;

            MaxWidth:=GetMaxTextWidth(FootPattern);
            CommHeight := GetTextHeight(Comp.Comment.Text,MaxWidth);

            //Текст '0.1' делаем 0.3 для 0402
            if (Comp.Comment.Text='0.1')
                and (CommHeight > 0.3)
                and (Copy(FootPattern, 2, 5)='C1005') then
                CommHeight := 0.3;

            CommThickness := GetTextThickness(CommHeight);

            Comp.Comment.Rotation := 0;

            if CommShow then Comp.CommentOn := CommShow;
            Comp.Comment.Size := MMsToCoord(CommHeight);
            Comp.Comment.Width := MMsToCoord(CommThickness);

            // Выбираем слой из списка MechList, там записано полное наименование слоя, прописанное в системе
            // Список MechList совпадает со списком ComboBox
            Comp.Comment.Layer:=String2Layer(MechBotList[ComboBoxLayerBot.ItemIndex]);

            //Если компоненты ортогональны, поворачиваем Comment
            If (Comp.Rotation = 90) or (Comp.Rotation = 270) then
                 Comp.Comment.Rotation := 270
            else
                 Comp.Comment.Rotation := 0;

            Comp.ChangeCommentAutoposition:=eAutoPos_CenterCenter;

            //Если компоненты не ортогонально расположены, то Autoposition д.б. manual!

            //Если в первой и 4-й четверти
            If ((Comp.Rotation > 270) and (Comp.Rotation < 360)) or ((Comp.Rotation > 0) and (Comp.Rotation < 90)) then
                begin
                Comp.ChangeCommentAutoposition:=eAutoPos_Manual;
                Comp.Comment.RotateAroundXY(Comp.X,Comp.Y, Comp.Rotation);
                end;
            If ((Comp.Rotation > 90) and (Comp.Rotation < 180)) or ((Comp.Rotation > 180) and (Comp.Rotation < 270)) then
                begin
                Comp.ChangeCommentAutoposition:=eAutoPos_Manual;
                Comp.Comment.RotateAroundXY(Comp.X,Comp.Y, Comp.Rotation - 180);
                end;

    //Begin of Персональные корректировки
            if (Copy(FootPattern, 1, 3) = 'QFN') or
               (Copy(FootPattern, 1, 5) = 'SOT23') then
                begin
                Comp.Comment.Rotation := 0;
                end;
    //End of Персональные корректировки


            PCBServer.SendMessageToRobots(Comp.Comment.I_ObjectAddress, c_Broadcast, PCBM_EndModify , c_NoEventData);
        End;

        //PCBServer.SendMessageToRobots(Board.I_ObjectAddress, c_Broadcast, PCBM_EndModify , c_NoEventData);
        PCBServer.PostProcess;
    Finally

        CompListT.Free;
        CompListB.Free;
    End;
end

else //Обрабатываем designators
begin
    Try
        PCBServer.PreProcess;

        For i := 0 to CompListT.Count - 1 Do
        Begin

            Comp := CompListT.items[i];

            //Переход к следующему компоненту если сделали "Select Only" компоненты, а компонент не выбран
            If (Not(Comp.Selected)) and (cbSelectDes.Checked) then Continue;
            PCBServer.SendMessageToRobots(Comp.Name.I_ObjectAddress, c_Broadcast, PCBM_BeginModify , c_NoEventData);

            If (Comp.Rotation = 90) or (Comp.Rotation = 270) then
            Begin
                 Comp.Name.Rotation := 90;
            End
            Else
            Begin
                 Comp.Name.Rotation := 0;
            End;

            if cbMinTextDes.Checked then
            begin
                Comp.Name.Size  := MMsToCoord(0.4);
                Comp.Name.Width := MMsToCoord(0.075);
            end;

            if cbTexttoCenterDes.Checked then Comp.ChangeNameAutoposition := eAutoPos_CenterCenter;

            //Если компоненты не ортогонально расположены, то Autoposition д.б. manual!

            //Если в первой и 4-й четверти
            If ((Comp.Rotation > 270) and (Comp.Rotation < 360)) or ((Comp.Rotation > 0) and (Comp.Rotation < 90)) then
                begin
                Comp.ChangeNameAutoposition := eAutoPos_Manual;
                Comp.Name.RotateAroundXY(Comp.X,Comp.Y, Comp.Rotation);
                end;
            If ((Comp.Rotation > 90) and (Comp.Rotation < 180)) or ((Comp.Rotation > 180) and (Comp.Rotation < 270)) then
                begin
                Comp.ChangeNameAutoposition := eAutoPos_Manual;
                Comp.Name.RotateAroundXY(Comp.X,Comp.Y, Comp.Rotation - 180);
                end;
            //Comp.Rebuild;

            PCBServer.SendMessageToRobots(Comp.Name.I_ObjectAddress, c_Broadcast, PCBM_EndModify , c_NoEventData);
        End;

 // Bottom Layer
        For i := 0 to CompListB.Count - 1 Do
        Begin

            Comp := CompListB.items[i];

            If (Not(Comp.Selected)) and (cbSelectDes.Checked) then Continue;
            PCBServer.SendMessageToRobots(Comp.Name.I_ObjectAddress, c_Broadcast, PCBM_BeginModify , c_NoEventData);

            If (Comp.Rotation = 90) or (Comp.Rotation = 270) then
            Begin
                 Comp.Name.Rotation := 270;
            End
            Else
            Begin
                 Comp.Name.Rotation := 0;
            End;

            if cbMinTextDes.Checked then
            begin
                Comp.Name.Size  := MMsToCoord(0.4);
                Comp.Name.Width := MMsToCoord(0.075);
            end;

            if cbTexttoCenterDes.Checked then Comp.ChangeNameAutoposition := eAutoPos_CenterCenter;

            //Если компоненты не ортогонально расположены, то Autoposition д.б. manual!

            //Если в первой и 4-й четверти
            If ((Comp.Rotation > 270) and (Comp.Rotation < 360)) or ((Comp.Rotation > 0) and (Comp.Rotation < 90)) then
                begin
                Comp.ChangeNameAutoposition := eAutoPos_Manual;
                Comp.Name.RotateAroundXY(Comp.X,Comp.Y, Comp.Rotation);
                end;
            If ((Comp.Rotation > 90) and (Comp.Rotation < 180)) or ((Comp.Rotation > 180) and (Comp.Rotation < 270)) then
                begin
                Comp.ChangeNameAutoposition := eAutoPos_Manual;
                Comp.Name.RotateAroundXY(Comp.X,Comp.Y, Comp.Rotation - 180);
                end;
            //Comp.Rebuild;

            PCBServer.SendMessageToRobots(Comp.Name.I_ObjectAddress, c_Broadcast, PCBM_EndModify , c_NoEventData);
        End;

        //PCBServer.SendMessageToRobots(Board.I_ObjectAddress, c_Broadcast, PCBM_EndModify , c_NoEventData);
        PCBServer.PostProcess;
    Finally

        CompListT.Free;
        CompListB.Free;
    End;
end;

{        Repeat
            Board.ChooseLocation(x,y, 'Choose Component1');
            Comp1 := Board.GetObjectAtXYAskUserIfAmbiguous(x,y,MkSet(eComponentObject),AllLayers, eEditAction_Select);
            If Not Assigned(Comp1) Then Exit;

            // Check if Component Name property exists before extracting the text
            If Comp1.Name = Nil Then Exit;

            Comment1:=Comp1.Comment.Text;
            ShowMessage(Comment1);
        // click on the board to exit or RMB
        Until (Comp1 = Nil) Or (Comp2 = Nil);}

    Board.ViewManager_FullUpdate;
    //Client.SendMessage('PCB:Zoom', 'Action=Redraw' , 255, Client.CurrentView);

End;

procedure TFormMain.FormMainShow(Sender: TObject);
var
   LayerPair : TMechanicalLayerPair;
   i, j      : Integer;
begin
   ComboBoxLayerTop.Clear;
   ComboBoxLayerBot.Clear;
   MechTopList.Clear;
   MechBotList.Clear;

   //LabelInfo1.Caption:= 'MechanicalPairs.Count = ' + IntToStr(Board.MechanicalPairs.Count);
   if Board.MechanicalPairs.Count = 0 then // Если нет пар
   begin
      for i := 1 to 32 do   //Добавляем активные механические слои в Combo
         if Board.LayerStack.LayerObject_V7[ILayer.MechanicalLayer(i)].MechanicalLayerEnabled then
         begin
            ComboBoxLayerTop.Items.Add(Board.LayerName(ILayer.MechanicalLayer(i)));
            ComboBoxLayerBot.Items.Add(Board.LayerName(ILayer.MechanicalLayer(i)));
            if ComboBoxLayerTop.Items.Count = 1 then
               ComboBoxLayerTop.Text := ComboBoxLayerTop.Items[0];
            if ComboBoxLayerBot.Items.Count = 1 then
               ComboBoxLayerBot.Text := ComboBoxLayerBot.Items[0];
         end;
   end
   else  //Если пары есть
   begin  //Ищем пары для каждого слоя
      for i := 1 to 32 do
      begin
         for j := i + 1 to 32 do
            if Board.MechanicalPairs.PairDefined(ILayer.MechanicalLayer(i), ILayer.MechanicalLayer(j)) then
            begin
               // Добавляем в Combo имена слоев явные, а в MechList номера этих слоев
               ComboBoxLayerTop.Items.Add(Board.LayerName(ILayer.MechanicalLayer(i)));
               MechTopList.Add(Layer2String(ILayer.MechanicalLayer(i)));
               ComboBoxLayerBot.Items.Add(Board.LayerName(ILayer.MechanicalLayer(j)));
               MechBotList.Add(Layer2String(ILayer.MechanicalLayer(j)));

               //Необходимо указать, что сейчас ComboBox находятся в позиции 0, иначе получим -1
               ComboBoxLayerTop.ItemIndex:=0;
               ComboBoxLayerBot.ItemIndex:=0;

               if ComboBoxLayerTop.Items.Count = 1 then
                  ComboBoxLayerTop.Text := ComboBoxLayerTop.Items[0];
               if ComboBoxLayerBot.Items.Count = 1 then
                  ComboBoxLayerBot.Text := ComboBoxLayerBot.Items[0];
            end;

      end;
   end;
end;

Procedure Start;
begin
   Board := PCBServer.GetCurrentPCBBoard;
   if Board = nil then exit;

   //MechPairs   := TStringList.Create;
   MechTopList := TStringList.Create;
   MechBotList := TStringList.Create;
        //CText.Name:='CCCCCCC';
        //CText.Name:='HHHHHH';

   RegistryRead;
   FormMain.Width:=360;
   FormMain.ShowModal;
end;


procedure TFormMain.ButCancelClick(Sender: TObject);
begin
Close;
end;

procedure TFormMain.ComboBoxLayerTopChange(Sender: TObject);
begin
     ComboBoxLayerBot.Text := ComboBoxLayerBot.Items[ComboBoxLayerTop.ItemIndex];
end;


procedure TFormMain.ButSettingClick(Sender: TObject);
begin
If FormMain.Width < 518 then
    begin
        FormMain.Width := 518;
        ButSetting.Caption := 'Настройки<<';
    end
    else
    begin
        FormMain.Width := 360;
        ButSetting.Caption := 'Настройки>>';
    end;

end;

procedure TFormMain.rgTargetClick(Sender: TObject);
begin
    if rgTarget.ItemIndex = 0 then
        gbCommentSetting.SendToBack
    else
        gbDesSetting.SendToBack;
end;



