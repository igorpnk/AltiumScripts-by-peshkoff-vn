{ -------------------------------- }
{ --------- Set Width ------------ }
{ ----------- v 1.0 -------------- }

Uses Registry;

var
    PCBBoard        : IPCB_Board;
    PCBLibrary      : IPCB_Library;
    SelectedPrims   : TStringList;
    Prim1           : IPCB_Primitive;
    Prim2           : IPCB_Primitive;
    strTargetWidth  : String;
    strWidthUnit    : String;
    TargetWidth     : TCoord;
    Width01,
    Width02,
    Width03,
    Width04,
    Width05,
    Width06,
    Width07,
    Width08,
    Width09         : String;


procedure RegistryRead;
var
    Registry  : TRegistry;
Begin
    Registry := TRegistry.Create;
    Try
        //Registry.RootKey := HKEY_CURRENT_USER; //default
        Registry.OpenKey('Software\AltiumScripts\SetWidth',true);

        if Registry.ValueExists('Width01')   then Width01 := Registry.ReadString('Width01') else Width01 := 'Minimum';
        if Registry.ValueExists('Width02')   then Width02 := Registry.ReadString('Width02') else Width02 := '0.15mm';
        if Registry.ValueExists('Width03')   then Width03 := Registry.ReadString('Width03') else Width03 := '0.2mm';
        if Registry.ValueExists('Width04')   then Width04 := Registry.ReadString('Width04') else Width04 := '0.25mm';
        if Registry.ValueExists('Width05')   then Width05 := Registry.ReadString('Width05') else Width05 := '0.3mm';
        if Registry.ValueExists('Width06')   then Width06 := Registry.ReadString('Width06') else Width06 := '0.5mm';
        if Registry.ValueExists('Width07')   then Width07 := Registry.ReadString('Width07') else Width07 := '0.75mm';
        if Registry.ValueExists('Width08')   then Width08 := Registry.ReadString('Width08') else Width08 := '1.0mm';
        if Registry.ValueExists('Width09')   then Width09 := Registry.ReadString('Width09') else Width09 := '3.5mil';

        Registry.CloseKey;
    Finally
        Registry.Free;
    End;
End;

procedure RegistryWrite;
var
    Registry: TRegistry;
Begin

    Registry := TRegistry.Create;
    Try
        Registry.OpenKey('Software\AltiumScripts\SetWidth',true);

        Registry.WriteString('Width01',     Edit1.Text);
        Registry.WriteString('Width02',     Edit2.Text);
        Registry.WriteString('Width03',     Edit3.Text);
        Registry.WriteString('Width04',     Edit4.Text);
        Registry.WriteString('Width05',     Edit5.Text);
        Registry.WriteString('Width06',     Edit6.Text);
        Registry.WriteString('Width07',     Edit7.Text);
        Registry.WriteString('Width08',     Edit8.Text);
        Registry.WriteString('Width09',     Edit9.Text);

        Registry.CloseKey;
    Finally
        Registry.Free;
    End;

End;

procedure DetectViolations;
var
    BoardIterator       : IPCB_SpatialIterator;
    Iterator            : IPCB_BoardIterator;
    Rule                : IPCB_Rule;
    Violation           : IPCB_Violation;
    Rectangle           : TCoordRect;
    MaxGap              : Integer; //Gap for arc/track

begin
    // now we have info about selected primitives. We need to cycle through it because

    //Determinate MaxGap
    Iterator        := PCBBoard.BoardIterator_Create;
    Iterator.AddFilter_ObjectSet(MkSet(eRuleObject));
    Iterator.AddFilter_LayerSet(AllLayers);
    Iterator.AddFilter_Method(eProcessAll);

    MaxGap := 0;

    Rule := Iterator.FirstPCBObject;

    While (Rule <> Nil) Do
    Begin
        if (Rule.RuleKind = eRule_Clearance) and Rule.Enabled then
           if MaxGap < Rule.Gap then
              MaxGap := Rule.Gap;
        Rule := Iterator.NextPCBObject;
    End;  //While (Rule <> Nil)

    //End of Determinate MaxGap

       Rectangle := Prim1.BoundingRectangle;
       BoardIterator := PCBBoard.SpatialIterator_Create;
       BoardIterator.AddFilter_IPCB_LayerSet(Prim1.Layer);
       BoardIterator.AddFilter_ObjectSet(AllObjects);
       BoardIterator.AddFilter_Area(Rectangle.Left - MaxGap,
                                    Rectangle.Bottom - MaxGap,
                                    Rectangle.Right + MaxGap,
                                    Rectangle.Top + MaxGap);

       Prim2 := BoardIterator.FirstPCBObject;

       while Prim2 <> Nil do
       begin
          Rule := PCBBoard.FindDominantRuleForObjectPair(Prim1, Prim2, eRule_Clearance);
                  //FindDominantRuleForObject
          if Rule <> nil then
          begin
             PCBBoard.AddPCBObject(Rule.ActualCheck(Prim1, Prim2));
             Prim2.GraphicallyInvalidate;
          end;

          Prim2 := BoardIterator.NextPCBObject;
       end;

        //detect width violation
        Rule := PCBBoard.FindDominantRuleForObject(Prim1, eRule_MaxMinWidth);
        if Rule <> nil then
        begin
            PCBBoard.AddPCBObject(Rule.ActualCheck(Prim1,Prim1));
            Prim1.GraphicallyInvalidate;
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

procedure SetWidth;
var
    i,            : Integer;
    PCBSystemOptions : IPCB_SystemOptions;
    Rule                : IPCB_Rule;
    RuleWidth      : IPCB_MaxMinWidthConstraint;
    //MinWidth       : Tcoord; //Width from rules;

//    aa : IPCB_Arc;
begin
    //strTargetWidth = '0.1mm'
    //TryStrToFloat(
    TargetWidth := 0;

    if Copy(strTargetWidth, Length(strTargetWidth) - 1, 2) = 'mm' then
    begin
        strWidthUnit := 'mm';
        TargetWidth := MMsToCoord(StrToFloat(Copy(strTargetWidth, 1, Length(strTargetWidth) - 2)));
    end
    else if Copy(strTargetWidth, Length(strTargetWidth) - 2, 3) = 'mil' then
            begin
                strWidthUnit := 'mil';
                TargetWidth := MilsToCoord(StrToFloat(Copy(strTargetWidth, 1, Length(strTargetWidth) - 3)));
            end
            else
            begin
                //"Minimum"
                //ShowInfo('Please write target width in format 0.00mil or 0.00mm');
                TargetWidth := 0;
            //exit;
    end;

    PCBBoard := PCBServer.GetCurrentPCBBoard;
    if PCBBoard = Nil Then Exit;

    PCBSystemOptions := PCBServer.SystemOptions;
    If PCBSystemOptions = Nil Then Exit;

    //Start of StringList.Create
    //SelectecPrims - StringList с выделенными объекстами
    SelectedPrims := TStringList.Create;

    for i := 0 to PCBBoard.SelectecObjectCount - 1 do
    begin
       if (PCBBoard.SelectecObject[i].ObjectId = eTrackObject) or
           (PCBBoard.SelectecObject[i].ObjectId = eArcObject)   then
       SelectedPrims.AddObject(IntToStr(i), PCBBoard.SelectecObject[i]);    //Вносим в перечень  объект
    end;
    //End of TStringList.Create

    if SelectedPrims.Count = 0 then
    begin
        ShowInfo('Please select at least one track or arc');
        exit;
    end;

    for i := 0 to SelectedPrims.Count - 1 do
    begin
        Prim1 := SelectedPrims.GetObject(i);

        if TargetWidth = 0 then //Minimum, looking for minimum
        begin

            RuleWidth := PCBBoard.FindDominantRuleForObject(Prim1, eRule_MaxMinWidth);
            TargetWidth := RuleWidth.MinWidth(Prim1.Layer);


            //GetMinRuleWidth;
            //RuleWidth := nil;
            //RuleWidth := PCBServer.PCBRuleFactory(eRule_MaxMinWidth);
            //eMidLayer1
            //TargetWidth := MinWidth;
        end;
        {showmessage(floattostr(Prim1.Width) + ' Coord' + #13#10 +
                    floattostr(CoordToMils(Prim1.Width))+ ' mils' +#13#10 +
                    floattostr(CoordToMMs(Prim1.Width))+ 'mm');   }
        Prim1.BeginModify;

        //We will remove all violations that are connected to the Prim1, using a simple trick :-)
        PCBBoard.RemovePCBObject(Prim1);

        if Prim1.ObjectId = eTrackObject then Prim1.Width := TargetWidth;
        if Prim1.ObjectId = eArcObject then Prim1.LineWidth := TargetWidth;

        PCBBoard.AddPCBObject(Prim1);
        Prim1.EndModify;
        if PCBSystemOptions.DoOnlineDRC then
            DetectViolations;
        Prim1.Selected := true;
        Prim1.GraphicallyInvalidate;

    end;  //for i := 0 to SelectedPrims.Count - 1

  //  if cbClearSelectWidth.Checked then DeSelectAll;
    PCBBoard.ViewManager_FullUpdate;

    close;
end;

procedure SetWidth01;
begin
    RegistryRead;
    strTargetWidth  := Width01;
    SetWidth;
end;

procedure SetWidth02;
begin
    RegistryRead;
    strTargetWidth  := Width02;
    SetWidth;
end;

procedure SetWidth03;
begin
    RegistryRead;
    strTargetWidth  := Width03;
    SetWidth;
end;

procedure SetWidth04;
begin
    RegistryRead;
    strTargetWidth  := Width04;
    SetWidth;
end;

procedure SetWidth05;
begin
    RegistryRead;
    strTargetWidth  := Width05;
    SetWidth;
end;

procedure SetWidth06;
begin
    RegistryRead;
    strTargetWidth  := Width06;
    SetWidth;
end;

procedure SetWidth07;
begin
    RegistryRead;
    strTargetWidth  := Width07;
    SetWidth;
end;

procedure SetWidth08;
begin
    RegistryRead;
    strTargetWidth  := Width08;
    SetWidth;
end;

procedure SetWidth09;
begin
    RegistryRead;
    strTargetWidth  := Width09;
    SetWidth;
end;

procedure SetWidthSetting;
begin
    RegistryRead;
    frmSetWidth.Show;
end;

procedure TfrmSetWidth.butOKClick(Sender: TObject);
begin
    RegistryWrite;
    Close;
end;

procedure TfrmSetWidth.butCancelClick(Sender: TObject);
begin
    Close
end;

procedure TfrmSetWidth.frmSetWidthShow(Sender: TObject);
begin
    Edit1.Text := Width01;
    Edit2.Text := Width02;
    Edit3.Text := Width03;
    Edit4.Text := Width04;
    Edit5.Text := Width05;
    Edit6.Text := Width06;
    Edit7.Text := Width07;
    Edit8.Text := Width08;
    Edit9.Text := Width09;
end;

