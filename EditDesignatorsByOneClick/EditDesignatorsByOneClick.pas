uses SysUtils;

var
   // SCH variables and objects
   SchDoc          : ISCH_Document;
   Location        : TLocation;
   SchSourcePrim   : TObject;
   SchDestinPrim   : TObject;
   SchTempPrim     : TObject;
   SpatialIterator : ISch_Iterator;

   iterator             : ISch_Iterator; // Итератор для поиска выделенных компонентов
   SchComp      : ISCH_Component;
   SLSelectedComps      : TStringList;

   boolEditDes     : boolean;
   DesPref         : string;
   numDesIn        : string;
   numDesOut       : string;
   DesIn           : string;
   DesOut          : string;


   // Common variables
   ASetOfObjects   : TObjectSet;
   boolLoc         : Integer;
   DocKind         : String;
   SnapGrid         : boolean;

function GetDesPref(const InputStr : String) : String;
var
    resultStr       : String;
    m  : integer;
begin
    resultStr := '';
    for m := 1 to Length(InputStr) do
    begin
        if (InputStr[m] >= '0') and (InputStr[m] <= '9') then
        InputStr := InputStr + InputStr[m]
        else
        if (InputStr[m] <> '?') then resultStr := resultStr + InputStr[m]
    end;
    Result := resultStr;
end;

procedure Annotate(const slComponents : TstringList);
var
    selDesIn, selDesOut     : String;
    NewDesNum       : String;
    actualComp      : Integer;
begin
    selDesOut := InputBox('New Des','Please input start number:', '');

    if selDesOut = '' then exit;

    for actualComp := 0 to slComponents.Count - 1 do
    begin
        NewDesNum := StrToInt(selDesOut) + actualComp;
        SchComp := slComponents.GetObject(actualComp);
        SchComp.Designator.Text := GetDesPref(SchComp.Designator.Text) + IntTostr(NewDesNum);
    end;

end;

function StartEditDes;
var
   i, j : integer;
   xLoc, yLoc   : integer;
   sortLocString    : String;
Begin
   DocKind := GetWorkspace.DM_FocusedDocument.DM_DocumentKind;

   boolEditDes:=false;


    // Get the document
    if SchServer = nil then exit;
    SchDoc := SchServer.GetCurrentSchDocument;

    if SchDoc = nil then exit;

    iterator := SchDoc.schIterator_Create;
    iterator.SetState_FilterAll;
    iterator.AddFilter_ObjectSet(mkSet(eSchComponent));
    SLSelectedComps := TStringList.Create;
    SLSelectedComps.Sorted := true;
    SchComp := iterator.FirstSCHObject;
    i := 0;

    While SchComp <> Nil Do
    begin
        if SchComp.Selection then
        begin
            inc(i);
            //SLSelectedComps.InsertObject(
            xLoc := SchComp.Location.X;
            yLoc := SchDoc.SheetSizeY - SchComp.Location.Y;
            // sortLocString := Inttostr(xLoc) + Inttostr(yLoc);
            sortLocString := Format('%.*d', [10, xLoc]) + Format('%.*d', [10, yLoc]);

            SLSelectedComps.AddObject(sortLocString, SchComp);
        end;
        SchComp := iterator.NextSchObject;
    end;

    if i <> 0 then
    begin
        Annotate(SLSelectedComps);
        FreeAndNil(SchComp);
        FreeAndNil(SLSelectedComps);
        SchDoc.UpdateDocumentProperties;
        SchDoc.GraphicallyInvalidate;
        exit;
    end;

    FreeAndNil(SchComp);
    FreeAndNil(SLSelectedComps);
    SchDoc.SchIterator_Destroy(iterator);


      // if SchDoc.se

      ResetParameters;
      AddStringParameter('Action', 'AllOpenDocuments');
      RunProcess('Sch:DeSelect');
      //RunProcess('Sch:ToggleVisibleGrid');

      SnapGrid := SchDoc.SnapGridOn;
      SchDoc.SnapGridOn := false;
      SchDoc.UpdateDocumentProperties;
      Location := TLocation;
      SchSourcePrim := nil;
      SchDestinPrim := nil;
      SchTempPrim := nil;

         while SchSourcePrim = nil do
         begin
            // Get Source Object
            boolLoc := SchDoc.ChooseLocationInteractively(Location, 'Choose Source Object');

            If Not boolLoc Then Break;

            SpatialIterator := SchDoc.SchIterator_Create;

            If SpatialIterator = Nil Then Break;

            Try
               SpatialIterator.AddFilter_Area(Location.X - 1, Location.Y - 1, Location.X + 1, Location.Y + 1);
               SchTempPrim := SpatialIterator.FirstSchObject;
               i := 0;
               j := 0;
               // If it got hidden parameter move it away
               while (SchTempPrim <> nil) do // and (((SchTempPrim.ObjectId = eDesignator) or (SchTempPrim.ObjectId = eParameter)) and SchTempPrim.IsHidden) do
                    begin
                        if SchTempPrim.ObjectId = eDesignator then
                        begin
                            i := i + 1;   //Считаем кол-во Designators
                            SchSourcePrim := SchTempPrim;
                        end
                        else
                        begin
                            j := j + 1;   //Считаем кол-во других объектов
                        end;
                    SchTempPrim := SpatialIterator.NextSchObject;
                    end;

               if (SchSourcePrim <> nil) and (i = 1) then
               begin
                  if (SchSourcePrim.ObjectId = eDesignator) then
                  begin
                     DesPref:='';
                     numDesIn:='';
                     numDesOut:='';
                     DesIn:='';
                     DesOut:='';

                     DesIn := SchSourcePrim.Text;

                     DesPref := GetDesPref(DesIn);

                     numDesOut := InputBox('New Des','New Des:',numDesIn);
                     if numDesOut <> numDesIn then //Введено новое значение
                     begin

                        SchSourcePrim.Text := DesPref + numDesOut;

                        //Обновление экрана
                        SchDoc.GraphicallyInvalidate;
                     end;   //if DesOut<>DesIn

                   end; //  if (SchSourcePrim.ObjectId = eDesignator)
               end; // if SchSourcePrim <> nil
               SchSourcePrim := nil;

            Finally
               SchDoc.SchIterator_Destroy(SpatialIterator);
            End;
         end;  //while SchSourcePrim = nil do

               SchDoc.SnapGridOn := SnapGrid;
                SchDoc.UpdateDocumentProperties;


End;

procedure TfrmEditDes.butOKClick(Sender: TObject);
begin
boolEditDes:=true;
startDes:=Edit1.Text;
frmEditDes.Hide;
end;

procedure TfrmEditDes.butCancelClick(Sender: TObject);
begin
boolEditDes:=false;
end;

