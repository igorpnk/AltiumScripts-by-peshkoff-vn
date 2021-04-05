{ -------------------------------- }
{ ------- Edit PCB Object -------- }
{ ----------- v 1.0 -------------- }
Uses Registry;

var
    PCBBoard        : IPCB_Board;
    PCBLibrary      : IPCB_Library;
    SelectedPrims   : TStringList;
    Prim1           : IPCB_Primitive;
    Prim2           : IPCB_Primitive;

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
        Registry.OpenKey('Software\AltiumScripts\EditPCBObject',true);

        if Registry.ValueExists('ClearSelectMoveToLayer')   then cbClearSelectMoveToLayer.Checked :=    Registry.ReadBool('ClearSelectMoveToLayer');
        if Registry.ValueExists('ClearSelectSetNetName')    then cbClearSelectSetNetName.Checked :=     Registry.ReadBool('ClearSelectSetNetName');
        if Registry.ValueExists('ClearSelectWidth')         then cbClearSelectWidth.Checked :=          Registry.ReadBool('ClearSelectWidth');

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
        Registry.OpenKey('Software\AltiumScripts\EditPCBObject',true);
        { записываем значения }

        Registry.WriteBool('ClearSelectWidth',          cbClearSelectWidth.Checked);
        Registry.WriteBool('ClearSelectSetNetName',     cbClearSelectSetNetName.Checked);
        Registry.WriteBool('ClearSelectMoveToLayer',    cbClearSelectMoveToLayer.Checked);

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

procedure trytoread;
var
    getWidth        : String ;
    ServerProcess   : IServerProcess;
    ProcLaunch  : IProcessLauncherInfo;
    ACommandLauncher : ICommandLauncher;
    //caption : String;
    AServerModule : IServerModule;
    OwnerDocument   : IServerDocument;

    ff : String;
    nn :  integer;
    CurrentView     : IServerDocumentView;
    Command, Parameters        : PChar;
    View : IServerDocumentView;

    Enabled, Checked, Visible          : LongBool;
    Caption, ImageFile        : PChar ;

begin
    GetStringParameter('Width', getWidth);
    //Showmessage(getWidth);
    //GetCaption
    //nn := Client.GetServerRecordCount;
    //ShowInfo(inttostr(nn));
    //Client.CommandLauncher;
    //Client.CommandLauncher.GetCommandState(
    //AServerModule := Client.getser.GetServerModule;
   // ACommandLauncher := Client.CommandLauncher;

    //CurrentView   := Client.CurrentView;
    //ShowMessage(CurrentView.Caption);  close;
    //If Client.CommandLauncher <> Nil Then
    {Begin
        Client.CommandLauncher.GetCommandState(Command,
                                     Parameters,
                                     View,
                                     Enabled,
                                     Checked,
                                     Visible,
                                     Caption,
                                     ImageFile);
        // do what you want with the parameters
        // after you have supplied the Command parameter.
    End;
     }
    ProcLaunch := Client.GUIManager.GetProcessLauncherInfoByID('RunScript');
   { ProcLaunch := Client.GUIManager.GetActivePLByCommand();
    ProcLaunch := Client.CommandLauncher.GetCommandState(Command,
                                     Parameters,
                                     View,
                                     Enabled,
                                     Checked,
                                     Visible,
                                     Caption,
                                     ImageFile);         }
if Client.GUIManager.CurrentProcessLauncherAvailable then showinfo('OK');
    //Client.GUIManager.
    getWidth := ProcLaunch.Caption;
    //getWidth := Client.GUIManager.GetShortcutTextForPLID('RunScript');
    Showmessage(getWidth);
    //ProcLaunch := Client.g;
    //ServerProcess := ServerRecord;
    //ProcLaunch  : = AServerModule.ProcessControl.ProcessDepth;
    //olo :=  Client.ProcessControl.ProcessLauncherInfo;
    //ProcLaunch  := ProcessLauncherInfo;
    //ff := ProcLaunch .Description;
    //ShowInfo(ProcLaunch.Caption);
    close;
end;

procedure trytoread2;
var
    AServerModule : IServerModule;
    OwnerDocument   : IServerDocument;
    ServerModule  :  IServerModule;
    ACommandLauncher : ICommandLauncher;

    Command, Parameters        : PWideChar;
    View : IServerDocumentView;

    Enabled, Checked, Visible          : LongBool;
    Caption, Image        : PWideChar ;
    ProcLaunch2  : IProcessLauncherInfo;
    fff : TStringList;
    m : integer;
    vv : string;
    s1 , s2 : WideString;
begin


    ServerModule  :=  Client.ServerModuleByName('PCB');
    ShowMessage('Doc  Count  =  '  +  IntToStr(ServerModule.DocumentCount));

    OwnerDocument := Client.CurrentView.OwnerDocument;
    //s2 := ServerModule.
    s1 := 'ScriptingSystem:RunScript';
    s2 := 'ProjectName=D:\Work\Altium Designer\Scripts\EditPCBObject v1.0\EditPCBObject.PrjScr|ProcName=EditPCBObject.pas>SetWidth|Width=0.1';
    //ServerModule.CommandLauncher.LaunchCommand(
    //OwnerDocument.ServerModule;
    showinfo(Client.CurrentView.ViewName);
    ProcLaunch2 := Client.GUIManager.GetActivePLByCommand(
                'PCB',s1,s2);{,
                WideCharToString(s1),
                WideCharToString(s2));    }

    if  ProcLaunch2 = nil then exit;
    showinfo('Caption = ' + ProcLaunch2.Caption + #13#10 +
                'Description = ' + ProcLaunch2.Description + #13#10 +
                'Parameters = ' + ProcLaunch2.Parameters);
    //exit;

    ACommandLauncher := ServerModule.GetCommandLauncher;


    //exit;
    //Caption := 'NILdd';
    If ACommandLauncher <> Nil Then
    Begin
        ProcLaunch2 := ServerModule.CommandLauncher.GetCommandState(Command,
                                     Parameters,
                                     View,
                                     Enabled,
                                     Checked,
                                     Visible,
                                     Caption,
                                     Image);
        // do what you want with the parameters
        // after you have supplied the Command parameter.
        //ProcLaunch2 := ACommandLauncher.;
        //vv := View.Caption;
        //ServerModule;
        vv:='vivi';
        Showmessage('Command = ' + WideCharToString(Command) + #13#10 +
                    'Parameters = ' + WideCharToString(Parameters) + #13#10 +
                    'View = ' + vv + #13#10 +
                    'Enabled = ' + booltostr(Enabled) + #13#10 +
                    'Checked = ' + booltostr(Checked) + #13#10 +
                    'Visible = ' + booltostr(Visible) + #13#10 +
                    'Caption = ' + WideCharToString(Caption) + #13#10 +
                    'Image = ' + WideCharToString(Image));
    End;
end;

procedure trytoRun;
begin
    ResetParameters;
    AddStringParameter('ProjectName','D:\Work\Altium Designer\Scripts\EditPCBObject v1.0\EditPCBObject.PrjScr');
    AddStringParameter('ProcName','EditPCBObject.pas>trytoread');
    RunProcess('ScriptingSystem:RunScript');
end;

procedure SetNetName;
var
    i, n, iss       : Integer;
    NetName         : String;
    Net, NetOld     : IPCB_Net;
    Iterator        : IPCB_BoardIterator;
    DetectNet       : Boolean;
//    DetectNetByTrack, DetectNetByVia, DetectNetByPad       : Boolean;
    DetectNetBy       : integer; //0 - Pad, 1 - Via, 2 - Track/Arc
    Nets            : TStringList;
    tmpStr          : String;
//    aa            : IPCB_Polygon;
    PCBSystemOptions : IPCB_SystemOptions;

begin
//    RegistryRead;

    PCBBoard := PCBServer.GetCurrentPCBBoard;
    if PCBBoard = Nil Then Exit;

    PCBSystemOptions := PCBServer.SystemOptions;
    If PCBSystemOptions = Nil Then Exit;


    //if PCBBoard.SelectecObjectCount < 2 then exit;
    DetectNet := False;
    Net := nil;

    //Start of StringList.Create
    //SelectecPrims - StringList с выделенными объекстами
    SelectedPrims := TStringList.Create;

    Nets          := TStringList.Create; //Создаем перечень попавших цепей для Rebuild в дальнейшем
    Nets.Duplicates := dupIgnore;
    Nets.Sorted := True;

    n := 0; //Для цикла внутри цикла i
    DetectNetBy := 5; //Пока поставим наихудший приоритет

    for i := 0 to PCBBoard.SelectecObjectCount - 1 do
    begin
       if ((PCBBoard.SelectecObject[i].ObjectId <> eTrackObject) and
           (PCBBoard.SelectecObject[i].ObjectId <> eArcObject)   and
           (PCBBoard.SelectecObject[i].ObjectId <> eFillObject)  and
           (PCBBoard.SelectecObject[i].ObjectId <> ePolyObject)  and
           (PCBBoard.SelectecObject[i].ObjectId <> ePadObject)   and
           (PCBBoard.SelectecObject[i].ObjectId <> eViaObject)   and
           (PCBBoard.SelectecObject[i].ObjectId <> eRegionObject)   and
           (PCBBoard.SelectecObject[i].ObjectId <> eSplitPlaneObject)) then
       begin
          ShowInfo('Please select only primitive, via or pad');
          exit;
       end;

       //if PCBBoard.SelectecObject[i].ObjectId <> ePadObject then
       SelectedPrims.AddObject(IntToStr(i), PCBBoard.SelectecObject[i]);    //Вносим в перечень  объект

       if PCBBoard.SelectecObject[i].Net = nil then Continue;   //Если объект без цепи, преходим к следующему объекту

       //Определяем цепь по Pad
       if PCBBoard.SelectecObject[i].ObjectId = ePadObject then
       begin
          Net := PCBBoard.SelectecObject[i].Net;
          DetectNetBy := 0;
       end;

       //Определяем цепь по Via, если не определено по Pad
       if (PCBBoard.SelectecObject[i].ObjectId = eViaObject) and
          (DetectNetBy > 0) then
       begin
          Net := PCBBoard.SelectecObject[i].Net;
          DetectNetBy := 1;
       end;

       //Определяем цепь по Track/Arc, если не определено по Via или Pad
       if ((PCBBoard.SelectecObject[i].ObjectId = eTrackObject) or
          (PCBBoard.SelectecObject[i].ObjectId = eArcObject)) and
          (DetectNetBy > 1) then
       begin
          Net := PCBBoard.SelectecObject[i].Net;
          DetectNetBy := 2;
       end;

    end;
    //End of TStringList.Create

    if Net = nil then // если не определили цепь
    //ищем 'GND'
    begin
        Iterator := PCBBoard.BoardIterator_Create;
        Iterator.AddFilter_ObjectSet(MkSet(eNetObject));
        Iterator.AddFilter_LayerSet(AllLayers);
        Iterator.AddFilter_Method(eProcessAll);

        Net := Iterator.FirstPCBObject;

        while (Net <> Nil) Do
        begin
            if Net.Name = 'GND' then break;
            Net := Iterator.NextPCBObject;
        end;
        PCBBoard.BoardIterator_Destroy(Iterator);
    end;

    PCBServer.PreProcess;

    for i := 0 to SelectedPrims.Count - 1 do
    begin
        Prim1 := SelectedPrims.GetObject(i);

        if Not(Prim1.InComponent) then     //??
        begin

            if (Prim1.ObjectID <> ePadObject)
               then
               begin
                    PCBServer.SendMessageToRobots(
                                Prim1.I_ObjectAddress,
                                c_Broadcast,
                                PCBM_BeginModify ,
                                c_NoEventData);

                    if Prim1.InNet then   //Если у редактируемого примитива была цепь
                    begin
                         Nets.AddObject(Prim1.Net.Name, Prim1.Net);

                         NetOld := Prim1.Net;
                         PCBServer.SendMessageToRobots(
                                    NetOld.I_ObjectAddress,
                                    c_Broadcast,
                                    PCBM_BeginModify ,
                                    c_NoEventData);
                         Prim1.Net.RemovePCBObject(Prim1); //Удаляем примитив из цепи
                         PCBServer.SendMessageToRobots(
                                    NetOld.I_ObjectAddress,
                                    c_Broadcast,
                                    PCBM_EndModify ,
                                    c_NoEventData);
                         //NetOld.Rebuild;                   //Перестраиваем старую цепь
                    end;

                    Prim1.Net := Net;

                    // We will remove all violations that are connected to the Prim1, using a simple trick :-)
                    PCBBoard.RemovePCBObject(Prim1);
                    PCBBoard.AddPCBObject(Prim1);

                    //Если нашелся полигон и в настройках стоит Repour: Always, перезаливаем
                    if Prim1.ObjectID = ePolyObject then
                       if PCBSystemOptions.PolygonRepour = eAlwaysRepour then Prim1.Rebuild;

                    PCBServer.SendMessageToRobots(
                                Prim1.I_ObjectAddress,
                                c_Broadcast,
                                PCBM_EndModify ,
                                c_NoEventData);
                    Prim1.Selected := True;



               end;
        end;

        if Prim1.ObjectIDString <> 'SplitPlane' then
            DetectViolations;

        Prim1.GraphicallyInvalidate;

    end;  //for i := 0 to SelectedPrims.Count - 1

    //If Net <> nil then Net.Rebuild;

    //Rebuild all selected nets
    for iss := 0 to Nets.Count-1 do
    begin
        Net := Nets.GetObject(iss);
        If Net <> nil then Net.Rebuild;
    end;

    //showmessage(Nets[iss]);

    PCBServer.PostProcess;
    RegistryRead;
    if cbClearSelectSetNetName.Checked then DeSelectAll;
    PCBBoard.ViewManager_FullUpdate;
    close;

end;

Procedure MoveToCurrentLayer;
Var
    TheLayerStack : IPCB_LayerStack;
    LayerObjCur   : IPCB_LayerObject;
    NetName1      : String;
    NetName2      : String;
    i, j          : Integer;
    SelectedPrims : TStringList;

begin
     PCBBoard := PCBServer.GetCurrentPCBBoard;
     If PCBBoard = Nil Then Exit;

     // Now we need to get the signal layers and populate comboBox
     TheLayerStack := PCBBoard.LayerStack;
     If TheLayerStack = Nil Then Exit;

     LayerObjCur := PCBBoard.CurrentLayer;

     if PCBBoard.SelectecObjectCount = 0 then exit;

     //SelectecPrims - StringList с выделенными объекстами
    SelectedPrims := TStringList.Create;
    for i := 0 to PCBBoard.SelectecObjectCount - 1 do
    begin
       if ((PCBBoard.SelectecObject[i].ObjectId <> eTrackObject) and
           (PCBBoard.SelectecObject[i].ObjectId <> eArcObject)   and
           (PCBBoard.SelectecObject[i].ObjectId <> eFillObject)  and
           (PCBBoard.SelectecObject[i].ObjectId <> ePolyObject)  and
           (PCBBoard.SelectecObject[i].ObjectId <> ePadObject)   and
           (PCBBoard.SelectecObject[i].ObjectId <> eViaObject)   and
           (PCBBoard.SelectecObject[i].ObjectId <> eTextObject)   and
           (PCBBoard.SelectecObject[i].ObjectId <> eRegionObject)) then
       begin
          ShowInfo('Please select only primitive');
          exit;
       end;
       SelectedPrims.AddObject(IntToStr(i), PCBBoard.SelectecObject[i]);
    end;
    //Закончили формирование SlectecPrims
    PCBServer.PreProcess;

    for i := 0 to SelectedPrims.Count - 1 do
    begin
       Prim1 := SelectedPrims.GetObject(i);
       //PCBServer.PreProcess;

       if (Prim1.ObjectID <> ePadObject) and (Prim1.ObjectID <> eViaObject) then
       begin
            PCBServer.SendMessageToRobots(
                    Prim1.I_ObjectAddress,
                    c_Broadcast,
                    PCBM_BeginModify ,
                    c_NoEventData);

            Prim1.Layer := LayerObjCur;
            PCBServer.SendMessageToRobots(
                    Prim1.I_ObjectAddress,
                    c_Broadcast,
                    PCBM_EndModify ,
                    c_NoEventData);


            // We will remove all violations that are connected to the Prim1, using a simple trick :-)
            PCBBoard.RemovePCBObject(Prim1);
            PCBBoard.AddPCBObject(Prim1);
            Prim1.Selected := True;

            DetectViolations;
       end;

       //PCBServer.PostProcess;
       Prim1.GraphicallyInvalidate;

    end;

    PCBServer.PostProcess;   
    RegistryRead;
    if cbClearSelectMoveToLayer.Checked then DeSelectAll;
    PCBBoard.ViewManager_FullUpdate;
    close;
end;


{procedure SetWidth010;
begin
    SetWidth(0.10);
end;

procedure SetWidth0125;
begin
    SetWidth(0.125);
end;

procedure SetWidth015;
begin
    SetWidth(0.15);
end;

procedure SetWidth020;
begin
    SetWidth(0.2);
end;

procedure SetWidth030;
begin
    SetWidth(0.3);
end;

procedure SetWidth050;
begin
    SetWidth(0.5);
end;

procedure SetWidth100;
begin
    SetWidth(1.0);
    RunApplication
end;
                  }
procedure tmp;
Var
    TheLayerStack : IPCB_LayerStack;
    i             : Integer;
    Layer      : IPCB_LayerObject;
    Str            : String;
Begin
    PCBBoard := PCBServer.GetCurrentPCBBoard;
    If PCBBoard = Nil Then Exit;

    // Note that the Layer stack only stores
    // existing copper based layers.
    // But you can use the LayerObject property to fetch all layers.
    TheLayerStack := PCBBoard.LayerStack;
    If TheLayerStack = Nil Then Exit;
    //LS       := '';

    LayerObj := TheLayerStack.FirstLayer;
    Repeat
        LS       := LS + Layer2String(LayerObj.LayerID) + #13#10;
        ShowMessage(LayerObj.LayerID);
        LayerObj := TheLayerStack.NextLayer(LayerObj);
    Until LayerObj = Nil;
    ShowInfo('The Layer Stack has :'#13#10 + LS);

End;

procedure TfrmEditPCBObjectSetting.ButtonOKClick(Sender: TObject);
begin
    RegistryWrite;
    close;
end;

procedure TfrmEditPCBObjectSetting.ButtonCancelClick(Sender: TObject);
begin
    close;
end;

procedure EditPCBObjectSetting;
begin
    RegistryRead;
    frmEditPCBObjectSetting.Show;
end;

