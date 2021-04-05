{ -------------------------------- }
{ ---- Place Region On Via ------- }
{ ----------- v 1.0 -------------- }
Uses Registry;

var
    PCBBoard        : IPCB_Board;
    SelectedPrims   : TStringList;
    PrimVia         : IPCB_Via;
    Contour         : IPCB_Contour;
    Region          : IPCB_Region;
    CurrentLayer    : Boolean;
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
        Registry.OpenKey('Software\AltiumScripts\PlaceRegionOnVia',true);

        if Registry.ValueExists('ClearAll')     then cbClearAll.Checked :=      Registry.ReadBool('ClearAll');
        if Registry.ValueExists('UseRoundTo')   then cbUseRoundTo.Checked :=    Registry.ReadBool('UseRoundTo');
        if Registry.ValueExists('RoundTo')      then eRoundTo.Text :=           Registry.ReadString('RoundTo');

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
        Registry.OpenKey('Software\AltiumScripts\PlaceRegionOnVia',true);
        { записываем значения }

        Registry.WriteBool  ('ClearAll',    cbClearAll.Checked);
        Registry.WriteBool  ('UseRoundTo',  cbUseRoundTo.Checked);
        Registry.WriteString('RoundTo',     floattostr(eRoundTo.Text));

        { закрываем и освобождаем ключ }
        Registry.CloseKey;
    Finally
        Registry.Free;
    End;

End;

Function ADVersion : Double;
var
   VersionStr        : String;
Begin
   VersionStr := GetCurrentProductBuild;
   if pos('.', VersionStr) = 0 then
      Result := StrToInt(VersionStr)
   else
      Result := StrToInt(Copy(VersionStr, 1, pos('.', VersionStr) - 1))
end;

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
        Prim1 := Region;

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
         if Prim1.Layer = Prim2.Layer then
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

procedure PlaceRegionOnVia;
var
    i               : Integer;
    Rule            : IPCB_Rule;
    ViaX1, ViaY1, ViaX2, ViaY2      : integer;
    Net             : IPCB_Net;
    cc1x, cc2x, cc3x, cc4x, cc5x, cc6x, cc7x, cc8x      : TCoord;
    cc1y, cc2y, cc3y, cc4y, cc5y, cc6y, cc7y, cc8y      : TCoord;

    TheLayerStack       : IPCB_LayerStack;
    LayerObj            : IPCB_LayerObject;
    Layer               : TLayer;
    Signals             : IPCB_LayerSet;
    LS : String;
    Rnd     : Real;

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

    PrimVia := SelectedPrims.GetObject(0);
    ViaX1 := PrimVia.x;
    ViaY1 := PrimVia.y;
    ViaX2 := PrimVia.x;
    ViaY2 := PrimVia.y;

    Net := PrimVia.Net;

    for i := 1 to SelectedPrims.Count - 1 do
    begin
        PrimVia := SelectedPrims.GetObject(i);

        if PrimVia.Net <> Net then Continue;    //ignore via with other nets

        if PrimVia.x < ViaX1 then ViaX1 := PrimVia.x;
        if PrimVia.y < ViaY1 then ViaY1 := PrimVia.y;
        if PrimVia.x > ViaX2 then ViaX2 := PrimVia.x;
        if PrimVia.y > ViaY2 then ViaY2 := PrimVia.y;

        PrimVia.Selected := true;
        PrimVia.GraphicallyInvalidate;

        PrimVia.GraphicallyInvalidate;


    end;  //for i := 0 to SelectedPrims.Count - 1

    if (abs(ViaX1 - ViaX2) < 10) and (abs(ViaY1 - ViaY2) < 10) then exit;  //if one via same net
//    ShowMessage(FloatToStr(CoordToMMs(ViaX1 - PCBBoard.XOrigin)) + '; ' + FloatToStr(CoordToMMs(ViaY1 - PCBBoard.YOrigin)) + #13 +
//                FloatToStr(CoordToMMs(ViaX2 - PCBBoard.XOrigin)) + '; ' + FloatToStr(CoordToMMs(ViaY2 - PCBBoard.YOrigin)));

    cc1x := ViaX1;                  cc1y := ViaY1 - PrimVia.Size/2;
    cc2x := ViaX2;                  cc2y := ViaY1 - PrimVia.Size/2;
    cc3x := ViaX2 + PrimVia.Size/2; cc3y := ViaY1;
    cc4x := ViaX2 + PrimVia.Size/2; cc4y := ViaY2;
    cc5x := ViaX2;                  cc5y := ViaY2 + PrimVia.Size/2;
    cc6x := ViaX1;                  cc6y := ViaY2 + PrimVia.Size/2;
    cc7x := ViaX1 - PrimVia.Size/2; cc7y := ViaY2;
    cc8x := ViaX1 - PrimVia.Size/2; cc8y := ViaY1;

    //Round to 0.1
    Rnd := strtofloat(eRoundTo.Text);
    if (Rnd <> 0) and cbUseRoundTo.Checked then
    begin
        cc1x := MMsToCoord(Round(CoordToMMs(cc1x - PCBBoard.XOrigin)/Rnd) * Rnd) + PCBBoard.XOrigin;
        cc2x := MMsToCoord(Round(CoordToMMs(cc2x - PCBBoard.XOrigin)/Rnd) * Rnd) + PCBBoard.XOrigin;
        cc3x := MMsToCoord(Round(CoordToMMs(cc3x - PCBBoard.XOrigin)/Rnd) * Rnd) + PCBBoard.XOrigin;
        cc4x := MMsToCoord(Round(CoordToMMs(cc4x - PCBBoard.XOrigin)/Rnd) * Rnd) + PCBBoard.XOrigin;
        cc5x := MMsToCoord(Round(CoordToMMs(cc5x - PCBBoard.XOrigin)/Rnd) * Rnd) + PCBBoard.XOrigin;
        cc6x := MMsToCoord(Round(CoordToMMs(cc6x - PCBBoard.XOrigin)/Rnd) * Rnd) + PCBBoard.XOrigin;
        cc7x := MMsToCoord(Round(CoordToMMs(cc7x - PCBBoard.XOrigin)/Rnd) * Rnd) + PCBBoard.XOrigin;
        cc8x := MMsToCoord(Round(CoordToMMs(cc8x - PCBBoard.XOrigin)/Rnd) * Rnd) + PCBBoard.XOrigin;

        cc1y := MMsToCoord(Round(CoordToMMs(cc1y - PCBBoard.YOrigin)/Rnd) * Rnd) + PCBBoard.YOrigin;
        cc2y := MMsToCoord(Round(CoordToMMs(cc2y - PCBBoard.YOrigin)/Rnd) * Rnd) + PCBBoard.YOrigin;
        cc3y := MMsToCoord(Round(CoordToMMs(cc3y - PCBBoard.YOrigin)/Rnd) * Rnd) + PCBBoard.YOrigin;
        cc4y := MMsToCoord(Round(CoordToMMs(cc4y - PCBBoard.YOrigin)/Rnd) * Rnd) + PCBBoard.YOrigin;
        cc5y := MMsToCoord(Round(CoordToMMs(cc5y - PCBBoard.YOrigin)/Rnd) * Rnd) + PCBBoard.YOrigin;
        cc6y := MMsToCoord(Round(CoordToMMs(cc6y - PCBBoard.YOrigin)/Rnd) * Rnd) + PCBBoard.YOrigin;
        cc7y := MMsToCoord(Round(CoordToMMs(cc7y - PCBBoard.YOrigin)/Rnd) * Rnd) + PCBBoard.YOrigin;
        cc8y := MMsToCoord(Round(CoordToMMs(cc8y - PCBBoard.YOrigin)/Rnd) * Rnd) + PCBBoard.YOrigin;
    end;

//    ShowMessage(FloatToStr(CoordToMMs(cc1x - PCBBoard.XOrigin)) + '; ' + FloatToStr(CoordToMMs(cc1y - PCBBoard.YOrigin)) + #13 +
//                FloatToStr(CoordToMMs(cc2x - PCBBoard.XOrigin)) + '; ' + FloatToStr(CoordToMMs(cc2y - PCBBoard.YOrigin)));

    Contour := PCBServer.PCBContourFactory;
    Contour.AddPoint(cc1x, cc1Y);
    Contour.AddPoint(cc2x, cc2Y);
    Contour.AddPoint(cc3x, cc3Y);
    Contour.AddPoint(cc4x, cc4Y);
    Contour.AddPoint(cc5x, cc5Y);
    Contour.AddPoint(cc6x, cc6Y);
    Contour.AddPoint(cc7x, cc7Y);
    Contour.AddPoint(cc8x, cc8Y);

    Signals := LayerSet.SignalLayers;

    if CurrentLayer then
    begin
        Layer := PCBBoard.CurrentLayer;
        if Signals.Contains(Layer) then
        begin
            Region := PCBServer.PCBObjectFactory(eRegionObject, eNoDimension, eCreate_Default);
            Region.SetOutlineContour(Contour);
            Region.Net := Net;
            Region.Layer := Layer;
            Region.BeginModify;
            PCBBoard.AddPCBObject(Region);
            DetectViolations;
            Region.EndModify;
        end
        else exit;
        LayerObj := Nil;
    end
    else
    begin

        if ADVersion > 10 then // (AD13 = 10 version)
            TheLayerStack := PCBBoard.LayerStack_V7
        else   //For 13 versions and lower
            TheLayerStack := PCBBoard.LayerStack;


            If TheLayerStack = Nil Then Exit;
            LayerObj := TheLayerStack.FirstLayer;

            Repeat
                if Signals.Contains(LayerObj.LayerID) then
                begin
                    Region := PCBServer.PCBObjectFactory(eRegionObject, eNoDimension, eCreate_Default);
                    Region.SetOutlineContour(Contour);
                    Region.Net := Net;
                    Region.Layer := LayerObj.LayerID;
                    Region.BeginModify;
                    PCBBoard.AddPCBObject(Region);
                    DetectViolations;
                    Region.EndModify;
                end;
                LayerObj := TheLayerStack.NextLayer(LayerObj);
            Until LayerObj = Nil;
            TheLayerStack := Nil;


    end;

    Contour.Clear;
    //PrimRegion.
    Net.Rebuild;

    //RegistryRead;
    if cbClearAll.Checked then DeSelectAll;
    PCBBoard.ViewManager_FullUpdate;
    close;
end;

procedure PlaceRegionOnViaOnAllLayer;
begin
    RegistryRead;
    CurrentLayer := False;
    PlaceRegionOnVia;
end;

procedure PlaceRegionOnViaOnCurrentLayer;
begin
    RegistryRead;
    CurrentLayer := True;
    PlaceRegionOnVia;
end;

procedure TfrmPlaceRegionOnViaSetting.ButtonOKClick(Sender: TObject);
begin
    RegistryWrite;
    close;
end;

procedure TfrmPlaceRegionOnViaSetting.ButtonCancelClick(Sender: TObject);
begin
    close;
end;

procedure PlaceRegionOnViaSetting;
begin
    RegistryRead;
    frmPlaceRegionOnViaSetting.Show;
end;
