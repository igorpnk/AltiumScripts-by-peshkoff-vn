{ -------------------------------- }
{ ---------- Edit Via ------------ }
{ ----------- v 1.0 -------------- }
//Uses Registry;

var
    PCBBoard        : IPCB_Board;
    SelectedPrims   : TStringList;
    PrimVia         : IPCB_Via;
    ArrOfSize       : Array[0..1, 0..20] of Single;

procedure DetectViolations;
var
    BoardIterator : IPCB_SpatialIterator;
    Iterator      : IPCB_BoardIterator;
    Rule          : IPCB_Rule;
    Violation     : IPCB_Violation;
    Rectangle     : TCoordRect;
    MaxRuleWidth      : Integer;
    Prim1           : IPCB_Primitive;
    Prim2           : IPCB_Primitive;

begin
    // now we have info about selected primitives. We need to cycle through it because
        Prim1 := PrimVia;

    //Determinate MaxRuleWidth
    Iterator        := PCBBoard.BoardIterator_Create;
    Iterator.AddFilter_ObjectSet(MkSet(eRuleObject));
    Iterator.AddFilter_LayerSet(AllLayers);
    Iterator.AddFilter_Method(eProcessAll);

    MaxRuleWidth := 0;

    Rule := Iterator.FirstPCBObject;

    While (Rule <> Nil) Do
    Begin
        if (Rule.RuleKind = eRule_Clearance) and Rule.Enabled then
           if MaxRuleWidth < Rule.Gap then
              MaxRuleWidth := Rule.Gap;

        Rule := Iterator.NextPCBObject;
    End;  //While (Rule <> Nil)

    Rectangle := Prim1.BoundingRectangle;

    BoardIterator := PCBBoard.SpatialIterator_Create;
    BoardIterator.AddFilter_IPCB_LayerSet(LayerSet.SignalLayers);
    BoardIterator.AddFilter_ObjectSet(AllObjects);
    BoardIterator.AddFilter_Area(Rectangle.Left - MaxRuleWidth,
                                    Rectangle.Bottom - MaxRuleWidth,
                                    Rectangle.Right + MaxRuleWidth,
                                    Rectangle.Top + MaxRuleWidth);

      Prim2 := BoardIterator.FirstPCBObject;

      while Prim2 <> Nil do
      begin
         if Prim1.IntersectLayer(Prim2.Layer) then
         Begin
            Rule := PCBBoard.FindDominantRuleForObjectPair(Prim1, Prim2, eRule_Clearance);

            if Rule <> nil then
            begin
               PCBBoard.AddPCBObject(Rule.ActualCheck(Prim1, Prim2));
               Prim2.GraphicallyInvalidate;
            end;
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

procedure ViaChangeSize;      //the method is doubovy
var
    i            : Integer;
    Rule            : IPCB_Rule;
begin
    PCBBoard := PCBServer.GetCurrentPCBBoard;
    if PCBBoard = Nil Then Exit;


    //Start of StringList.Create
    //SelectecPrims - StringList с выделенными объекстами
    SelectedPrims := TStringList.Create;

    for i := 0 to PCBBoard.SelectecObjectCount - 1 do
    begin
       if (PCBBoard.SelectecObject[i].ObjectId = eViaObject) then
       SelectedPrims.AddObject(IntToStr(i), PCBBoard.SelectecObject[i]);    //Вносим в перечень  объект
    end;
    //End of TStringList.Create

    if SelectedPrims.Count = 0 then
    begin
        ShowInfo('Please select at least one via object');
        exit;
    end;

    for i := 0 to SelectedPrims.Count - 1 do
    begin
        PrimVia := SelectedPrims.GetObject(i);
        Rule := PCBBoard.FindDominantRuleForObject(PrimVia, eRule_RoutingViaStyle);

        PrimVia.BeginModify;

        if (PrimVia.Size >= Rule.MaxWidth) or (PrimVia.Size < Rule.MinWidth) then
            begin
            PrimVia.Size        := Rule.MinWidth;
            PrimVia.HoleSize    := Rule.MinHoleWidth;
            end
        else
        begin
        if (PrimVia.Size >= Rule.PreferedWidth) and (PrimVia.Size < Rule.MaxWidth) then
            begin
            PrimVia.Size        := Rule.MaxWidth;
            PrimVia.HoleSize    := Rule.MaxHoleWidth;
            end

            else
            begin
            PrimVia.Size        := Rule.PreferedWidth;
            PrimVia.HoleSize    := Rule.PreferedHoleWidth;
            end;
         end;

        PCBBoard.RemovePCBObject(PrimVia);//for remove DRC Violation
        PCBBoard.AddPCBObject(PrimVia);

        PrimVia.EndModify;

        PrimVia.Selected := true;
        PrimVia.GraphicallyInvalidate;

        DetectViolations;

        PrimVia.GraphicallyInvalidate;


    end;  //for i := 0 to SelectedPrims.Count - 1

    //RegistryRead;
    if cbClearSelectText.Checked then DeSelectAll;
    PCBBoard.ViewManager_FullUpdate;
    close;
end;


procedure TfrmEditViaSetting.ButtonOKClick(Sender: TObject);
begin
    //RegistryWrite;
    close;
end;

procedure TfrmEditViaSetting.ButtonCancelClick(Sender: TObject);
begin
    close;
end;

procedure EditViaSetting;
begin
    frmEditViaSetting.Show;
end;
