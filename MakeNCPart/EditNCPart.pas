{..............................................................................}
{ Summary   This scripts can be used to copy some formatting properties from   }
{           one (source) primitive to many other (destination) primitives of   }
{           the same type.                                                     }
{                                                                              }
{           Currently script works with all schematic objects (in SCH document }
{           and library) and only some objects (dimension and coordinate) in   }
{           PCB Document                                                       }
{                                                                              }
{ Created by:    Petar Perisin                                                 }
{..............................................................................}

{..............................................................................}
var
   // SCH variables and objects
   SchDoc          : ISCH_Document;
   Location        : TLocation;
   SchPart          : ISch_Component;
   Parameter  : ISch_Parameter;
   SchSourcePrim   : TObject;
   SchDestinPrim   : TObject;
   SchTempPrim     : TObject;
   SpatialIterator : ISch_Iterator;
   PIterator  : ISch_Iterator;

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

function StartEditParam;
var
   i : integer;
Begin
   DocKind := GetWorkspace.DM_FocusedDocument.DM_DocumentKind;

   boolEditDes:=false;


      // Get the document
      if SchServer = nil then exit;
      SchDoc := SchServer.GetCurrentSchDocument;
      if SchDoc = nil then exit;

      ResetParameters;
      AddStringParameter('Action', 'AllOpenDocuments');
      RunProcess('Sch:DeSelect');
      //RunProcess('Sch:ToggleVisibleGrid');

      Location := TLocation;
      SchSourcePrim := nil;
      SchDestinPrim := nil;
      SchPart := nil;
         while SchSourcePrim = nil do
         begin
            // Get Source Object
            boolLoc := SchDoc.ChooseLocationInteractively(Location, 'Choose Source Object');
            If Not boolLoc Then Exit;

            SpatialIterator := SchDoc.SchIterator_Create;

            If SpatialIterator = Nil Then Exit;

            Try
               SpatialIterator.AddFilter_Area(Location.X - 1, Location.Y - 1, Location.X + 1, Location.Y + 1);
               SpatialIterator.AddFilter_ObjectSet(MkSet(eSchComponent));
               SchTempPrim := SpatialIterator.FirstSchObject;
               // If it got hidden parameter move it away
               // выкидываем скрытые параметры
               while ((SchTempPrim <> nil) and (((SchTempPrim.ObjectId = eDesignator) or (SchTempPrim.ObjectId = eParameter)) and SchTempPrim.IsHidden))  do
               begin
                  //  ShowMessage(SchTempPrim.ObjectId);
                  SchTempPrim   := SpatialIterator.NextSchObject;
               end;

              {  while (SchTempPrim <> nil) do
                    begin
                    showmessage(SchTempPrim.UnitName);
                    SchTempPrim   := SpatialIterator.NextSchObject;
                    end; }

               SchPart := SchTempPrim;   //получили компонент
               if SchPart <> nil then
               begin
                     //Showmessage(SchPart.Comment.Text);
                     PIterator := SchPart.SchIterator_Create;
                     PIterator.AddFilter_ObjectSet(MkSet(eParameter));
                     Parameter := PIterator.FirstSchObject;

                      While Parameter <> Nil Do
                      Begin
                       // ShowMessage(Parameter.Name + ' ' + Parameter.Text);

                          //If SameString (Parameter.Name, ParamName, False) Then
                          Begin
                           {  SchServer.RobotManager.SendMessage(
                                      SchPart.I_ObjectAddress,
                                      c_BroadCast, SCHM_BeginModify, c_NoEventData); }
                             if SchPart.Comment.Text <> '=Value' then SchPart.Comment.Text := 'NC (' + SchPart.Comment.Text +')';
                             if Parameter.Name = 'Value' then Parameter.Text := 'NC (' + Parameter.Text +')';
                             //Parameter.Text := Value;
                            { SchServer.RobotManager.SendMessage(
                                      SchPart.I_ObjectAddress,
                                      c_BroadCast, SCHM_EndModify, c_NoEventData);  }
                             //Exists := True;
                             //Break;
                          End;
                          Parameter := PIterator.NextSchObject;
                      End;



                        //Обновление экрана
                        SchDoc.GraphicallyInvalidate;

               end; // if SchSourcePrim <> nil
               SchSourcePrim := nil;

            Finally
               SchDoc.SchIterator_Destroy(PIterator);
               SchDoc.SchIterator_Destroy(SpatialIterator);
            End;
         end;  //while SchSourcePrim = nil do



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

