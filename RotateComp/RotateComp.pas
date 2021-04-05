{ -------------------------------- }
{ --------- Edit Text ------------ }
{ ----------- v 1.0 -------------- }
Uses Registry;

var
    PCBBoard        : IPCB_Board;
    SelectedPrims   : TStringList;
    Comp1           : IPCB_Component;
    //Prim2           : IPCB_Primitive;
    //ArrOfSize       : Array[0..1, 0..20] of Single;

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
        Registry.OpenKey('Software\AltiumScripts\RotateComp',true);

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
        Registry.OpenKey('Software\AltiumScripts\RotateComp',true);
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

procedure CompRotate180;
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
       if (PCBBoard.SelectecObject[i].ObjectId = eComponentObject) then
       SelectedPrims.AddObject(IntToStr(i), PCBBoard.SelectecObject[i]);    //Вносим в перечень  объект
    end;
    //End of TStringList.Create

    if SelectedPrims.Count = 0 then
    begin
        ShowInfo('Please select at least one component');
        exit;
    end;

    for i := 0 to SelectedPrims.Count - 1 do
    begin
        Comp1 := SelectedPrims.GetObject(i);

        Comp1.BeginModify;

        Comp1.RotateBy(180);

        Comp1.EndModify;

        Comp1.Selected := true;
        Comp1.GraphicallyInvalidate;

    end;  //for i := 0 to SelectedPrims.Count - 1

    //RegistryRead;
    //if cbClearSelectText.Checked then DeSelectAll;
    PCBBoard.ViewManager_FullUpdate;
    close;
end;
