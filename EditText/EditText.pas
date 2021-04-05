{ -------------------------------- }
{ --------- Edit Text ------------ }
{ ----------- v 1.0 -------------- }
Uses Registry;

var
    PCBBoard        : IPCB_Board;
    SelectedPrims   : TStringList;
    Prim1           : IPCB_Primitive;
    Prim2           : IPCB_Primitive;
    ArrOfSize       : Array[0..1, 0..20] of Single;

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
        Registry.OpenKey('Software\AltiumScripts\EditText',true);

        if Registry.ValueExists('ClearSelectText')   then cbClearSelectText.Checked :=    Registry.ReadBool('ClearSelectText');

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
        Registry.OpenKey('Software\AltiumScripts\EditText',true);
        { записываем значения }

        Registry.WriteBool('ClearSelectText',           cbClearSelectText.Checked);

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

procedure DefaultArray;
begin
    ArrOfSize[0,0] := '0.25';    ArrOfSize[1,0] := '0.05';
    ArrOfSize[0,1] := '0.3';     ArrOfSize[1,1] := '0.05';
    ArrOfSize[0,2] := '0.4';     ArrOfSize[1,2] := '0.075';
    ArrOfSize[0,3] := '0.5';     ArrOfSize[1,3] := '0.1';
    ArrOfSize[0,4] := '0.6';     ArrOfSize[1,4] := '0.125';
    ArrOfSize[0,5] := '0.75';    ArrOfSize[1,5] := '0.15';
    ArrOfSize[0,6] := '1.0';     ArrOfSize[1,6] := '0.2';
    ArrOfSize[0,7] := '1.5';     ArrOfSize[1,7] := '0.3';
end;

procedure TextIncrease;      //the method is doubovy
var
    i,            : Integer;
    textHeight        : Single;
    textWidth         : Single;
begin
    PCBBoard := PCBServer.GetCurrentPCBBoard;
    if PCBBoard = Nil Then Exit;

    //Start of StringList.Create
    //SelectecPrims - StringList с выделенными объекстами
    SelectedPrims := TStringList.Create;

    for i := 0 to PCBBoard.SelectecObjectCount - 1 do
    begin
       if (PCBBoard.SelectecObject[i].ObjectId = eTextObject) then
       SelectedPrims.AddObject(IntToStr(i), PCBBoard.SelectecObject[i]);    //Вносим в перечень  объект
    end;
    //End of TStringList.Create

    if SelectedPrims.Count = 0 then
    begin
        ShowInfo('Please select at least one text object');
        exit;
    end;

    for i := 0 to SelectedPrims.Count - 1 do
    begin
        Prim1 := SelectedPrims.GetObject(i);

        textHeight := CoordToMMs(Prim1.Size);
        textWidth := CoordToMMs(Prim1.Width);

        case textHeight of
            0..0.2999   : begin textHeight := 0.3;  textWidth := 0.05; end;
            0.3..0.399  : begin textHeight := 0.4;  textWidth := 0.075; end;
            0.4..0.499  : begin textHeight := 0.5;  textWidth := 0.1; end;
            0.5..0.599  : begin textHeight := 0.6;  textWidth := 0.125; end;
            0.6..0.749  : begin textHeight := 0.75; textWidth := 0.15; end;
            0.75..0.999 : begin textHeight := 1.0;  textWidth := 0.2; end;
            1.0..1.499  : begin textHeight := 1.5;  textWidth := 0.3; end;
        else
            begin textHeight := textHeight + 0.5; textWidth := textHeight / 5 end;
        end;

        Prim1.BeginModify;

        Prim1.Size := MMsToCoord(textHeight);
        Prim1.width := MMsToCoord(textWidth);

        if Prim1.isComment then
        begin
            Prim1.Component.ChangeCommentAutoposition(Prim1.Component.CommentAutoPosition);
        end;

        if Prim1.IsDesignator then
        begin
            Prim1.Component.ChangeNameAutoposition(Prim1.Component.NameAutoPosition);
        end;

        Prim1.EndModify;

        Prim1.Selected := true;
        Prim1.GraphicallyInvalidate;

    end;  //for i := 0 to SelectedPrims.Count - 1

    RegistryRead;
    if cbClearSelectText.Checked then DeSelectAll;
    PCBBoard.ViewManager_FullUpdate;
    close;
end;

procedure TextDecrease;
var
    i,            : Integer;
    textHeight        : Single;
    textWidth         : Single;
begin
    PCBBoard := PCBServer.GetCurrentPCBBoard;
    if PCBBoard = Nil Then Exit;

    //Start of StringList.Create
    //SelectecPrims - StringList с выделенными объекстами
    SelectedPrims := TStringList.Create;

    for i := 0 to PCBBoard.SelectecObjectCount - 1 do
    begin
       if (PCBBoard.SelectecObject[i].ObjectId = eTextObject) then
       SelectedPrims.AddObject(IntToStr(i), PCBBoard.SelectecObject[i]);    //Вносим в перечень  объект
    end;
    //End of TStringList.Create

    if SelectedPrims.Count = 0 then
    begin
        ShowInfo('Please select at least one text object');
        exit;
    end;

    for i := 0 to SelectedPrims.Count - 1 do
    begin
        Prim1 := SelectedPrims.GetObject(i);

        textHeight := CoordToMMs(Prim1.Size);
        textWidth := CoordToMMs(Prim1.Width);

        case textHeight of
            0..0.3      : begin textHeight := 0.25; textWidth := 0.05; end;
            0.301..0.4  : begin textHeight := 0.3;  textWidth := 0.05; end;
            0.401..0.5  : begin textHeight := 0.4;  textWidth := 0.075; end;
            0.501..0.6  : begin textHeight := 0.5;  textWidth := 0.1;   end;
            0.601..0.75 : begin textHeight := 0.6;  textWidth := 0.125; end;
            0.751..1.0  : begin textHeight := 0.75; textWidth := 0.15;  end;
            1.01..1.5   : begin textHeight := 1.0;  textWidth := 0.2;   end;
            1.5..1.99   : begin textHeight := 1.5;  textWidth := 0.3;   end;
        else
            begin textHeight := textHeight - 0.5; textWidth := textHeight / 5 end;
        end;

        Prim1.BeginModify;

        Prim1.Size := MMsToCoord(textHeight);
        Prim1.Width := MMsToCoord(textWidth);

        if Prim1.isComment then
        begin
            Prim1.Component.ChangeCommentAutoposition(Prim1.Component.CommentAutoPosition);
        end;

        if Prim1.IsDesignator then
        begin
            Prim1.Component.ChangeNameAutoposition(Prim1.Component.NameAutoPosition);
        end;

        Prim1.EndModify;

        Prim1.Selected := true;
        Prim1.GraphicallyInvalidate;

    end;  //for i := 0 to SelectedPrims.Count - 1

    RegistryRead;
    if cbClearSelectText.Checked then DeSelectAll;
    PCBBoard.ViewManager_FullUpdate;
    close;
end;

procedure SetTextRotate0;
var
    i,            : Integer;
begin

    PCBBoard := PCBServer.GetCurrentPCBBoard;
    if PCBBoard = Nil Then Exit;

    //Start of StringList.Create
    //SelectecPrims - StringList с выделенными объекстами
    SelectedPrims := TStringList.Create;

    for i := 0 to PCBBoard.SelectecObjectCount - 1 do
    begin
       if (PCBBoard.SelectecObject[i].ObjectId = eTextObject) then
       SelectedPrims.AddObject(IntToStr(i), PCBBoard.SelectecObject[i]);    //Вносим в перечень  объект
    end;
    //End of TStringList.Create

    if SelectedPrims.Count = 0 then
    begin
        ShowInfo('Please select at least one text object');
        exit;
    end;

    for i := 0 to SelectedPrims.Count - 1 do
    begin
        Prim1 := SelectedPrims.GetObject(i);

        Prim1.BeginModify;
        Prim1.Rotation := 0;

        if Prim1.isComment then
        begin
            Prim1.Component.ChangeCommentAutoposition(Prim1.Component.CommentAutoPosition);
        end;

        if Prim1.IsDesignator then
        begin
            Prim1.Component.ChangeNameAutoposition(Prim1.Component.NameAutoPosition);
        end;

        Prim1.EndModify;

        Prim1.Selected := true;
        Prim1.GraphicallyInvalidate;

    end;  //for i := 0 to SelectedPrims.Count - 1

    RegistryRead;
    if cbClearSelectText.Checked then DeSelectAll;
    PCBBoard.ViewManager_FullUpdate;
    close;
end;

procedure SetTextRotate90;
var
    i,            : Integer;
begin

    PCBBoard := PCBServer.GetCurrentPCBBoard;
    if PCBBoard = Nil Then Exit;

    //Start of StringList.Create
    //SelectecPrims - StringList с выделенными объекстами
    SelectedPrims := TStringList.Create;

    for i := 0 to PCBBoard.SelectecObjectCount - 1 do
    begin
       if (PCBBoard.SelectecObject[i].ObjectId = eTextObject) then
       SelectedPrims.AddObject(IntToStr(i), PCBBoard.SelectecObject[i]);    //Вносим в перечень  объект
    end;
    //End of TStringList.Create

    if SelectedPrims.Count = 0 then
    begin
        ShowInfo('Please select at least one text object');
        exit;
    end;

    for i := 0 to SelectedPrims.Count - 1 do
    begin
        Prim1 := SelectedPrims.GetObject(i);

        Prim1.BeginModify;

        if Prim1.InComponent then
        begin
            if Prim1.Component.Layer = eBottomLayer then
                Prim1.Rotation := 270
            else
                Prim1.Rotation := 90;
        end;

        if Prim1.isComment then
        begin
            Prim1.Component.ChangeCommentAutoposition(Prim1.Component.CommentAutoPosition);
        end;

        if Prim1.IsDesignator then
        begin
            Prim1.Component.ChangeNameAutoposition(Prim1.Component.NameAutoPosition);
        end;

        Prim1.EndModify;

        Prim1.Selected := true;
        Prim1.GraphicallyInvalidate;

    end;  //for i := 0 to SelectedPrims.Count - 1

    RegistryRead;
    if cbClearSelectText.Checked then DeSelectAll;
    PCBBoard.ViewManager_FullUpdate;
    close;
end;

procedure TfrmEditTextSetting.ButtonOKClick(Sender: TObject);
begin
    RegistryWrite;
    close;
end;

procedure TfrmEditTextSetting.ButtonCancelClick(Sender: TObject);
begin
    close;
end;

procedure EditTextSetting;
var i, j : integer;
begin
    DefaultArray;
    RegistryRead;
    //for i := 0 to ArrOfSize
    sgText.Cells[0,0] := '0.25';    sgText.Cells[1,0] := '0.075';
    sgText.Cells[0,1] := '0.3';     sgText.Cells[1,1] := '0.075';
    sgText.Cells[0,2] := '0.4';     sgText.Cells[1,2] := '0.075';
    sgText.Cells[0,3] := '0.5';     sgText.Cells[1,3] := '0.1';
    sgText.Cells[0,4] := '0.6';     sgText.Cells[1,4] := '0.125';
    sgText.Cells[0,5] := '0.75';    sgText.Cells[1,5] := '0.15';
    sgText.Cells[0,6] := '1.0';     sgText.Cells[1,6] := '0.2';
    sgText.Cells[0,7] := '1.5';     sgText.Cells[1,7] := '0.3';

    frmEditTextSetting.Show;
end;


//centertext isnt work...
procedure TfrmEditTextSetting.sgTextDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
var cr:TRect;
begin
with sgText.Canvas do begin
cr:=sgText.CellRect(acol,arow) ;
FillRect(cr);
TextOut(cr.left+((cr.Right-cr.Left) div 2)-(TextWidth(sgText.Cells[acol,arow]) div 2),
cr.Top,sgText.Cells[acol,arow]);
end;
end;
