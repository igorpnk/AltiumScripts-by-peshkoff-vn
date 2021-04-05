{ -------------------------------- }
{ ------- Primitive placer -------- }
{ ----------- v 1.0 -------------- }
Uses Registry;

var
    PCBBoard        : IPCB_Board;
    PCBLibrary      : IPCB_Library;
    SelectedPrims   : TStringList;

    arrstrLetter        : array [1..4, 1..4] of string;   //icol, jrow
    arrstrDescrp        : array [1..4, 1..4] of string;   //icol, jrow


    slBndRect       : TStringList;
    slTracks        : TStringList;
    slArcs          : TStringList;
    slVias          : TstringList;
    slRegions       : TStringList;

    modeSave        : Boolean;

    SaveRectCoord,
    SaveTrackCoord,
    SaveArcCoord,
    SaveRegionCoord,
    SaveViaCoord    : String;

// Отрисовываем содержимое реестра на форме
procedure DrawObjects(imgCol : integer, imgRow : integer);
var
    i       : integer;
    xmin, xmax  : TCoord;
    ymin, ymax  : TCoord;  // координаты BoundingRectangle, размерность - TCoord

    wRect, hRect    : TCoord; // ширина и высота BoundingRectangle

    x_img,
    y_img       : integer;  // координаты для отрисовки линии

    x1, y1,
    x2, y2,
    x3, y3,
    x4, y4      : integer; // координаты для отрисовки дуги


//    rct1, rct2  : TRect;
    factor      : double;
begin
    //координаты boundingRectangle
    xmin    := StrToInt(slBndRect[0]); //left
    ymin    := StrToInt(slBndRect[1]); //bottom
    xmax    := StrToInt(slBndRect[2]); //right
    ymax    := StrToInt(slBndRect[3]); //top
    wRect   := xmax - xmin;
    hRect   := ymax - ymin;

    //считаем соотношение, где больше разброс, тот и коэффициент
    //img 64 x 64, область для рисования 48 x 48
    if (wRect / 48) > (hRect / 48) then
        factor := 48 / wRect
        else
        factor := 48 / hRect;

    imgPanel.Canvas.Pen.Color := clNavy;
    imgPanel.Canvas.Pen.Width := 3;

    for i:= 0 to slTracks.Count - 5 do
    begin
        // Обрабатываем только позиции 0, 5, 10 и т.д.
        if (i mod 5) <> 0 then Continue;

        // к каждой координате +8 отступ
        x_img := round(8  + factor * (StrToInt(slTracks[i + 1]) - xmin) + (48 - factor * wRect) / 2);
        y_img := round(56 - factor * (StrToInt(slTracks[i + 2]) - ymin) - (48 - factor * hRect) / 2);
        // корректировка в зависимости от квадрата
        x_img := x_img + 8 + (72 * (imgCol - 1));
        y_img := y_img + 8 + (72 * (imgRow - 1));
        imgPanel.Canvas.MoveTo(x_img, y_img);

        x_img := round(8  + factor * (StrToInt(slTracks[i + 3]) - xmin) + (48 - factor * wRect) / 2);
        y_img := round(56 - factor * (StrToInt(slTracks[i + 4]) - ymin) - (48 - factor * hRect) / 2);
        // корректировка в зависимости от квадрата
        x_img := x_img + 8 + (72 * (imgCol - 1));
        y_img := y_img + 8 + (72 * (imgRow - 1));
        imgPanel.Canvas.LineTo(x_img, y_img);
        // добавляем точку, т.к. линия рисуется до последней точки, исключая последнюю
        imgPanel.Canvas.Pixels[x_img, y_img] := imgPanel.Canvas.Pen.Color;
    end;

    // Дуга:
    for i:= 0 to slArcs.Count - 10 do
    begin
        if (i mod 10) <> 0 then Continue;     //обрабатываем 0, 10, 20 и т.д.

        // x1,y1, x2,y2 - координаты прямоугольника (квадрата), описываемого вокруг полной окружности
        // от центральной точки отступ на расстояние радиуса.
        // квадрат описывает воображаемую дугу с начальным углом 0 и конечным 360 градусов
        // x1,y1 - левый верхний
        // x2,y2 - правый нижний
        //
        x1 := round(8  + factor * (StrToInt(slArcs[i + 1]) - StrToInt(slArcs[i + 3]) - xmin) + (48 - factor * wRect) / 2);
        y1 := round(56 - factor * (StrToInt(slArcs[i + 2]) + StrToInt(slArcs[i + 3]) - ymin) - (48 - factor * hRect) / 2);
        x2 := round(8  + factor * (StrToInt(slArcs[i + 1]) + StrToInt(slArcs[i + 3]) - xmin) + (48 - factor * wRect) / 2);
        y2 := round(56 - factor * (StrToInt(slArcs[i + 2]) - StrToInt(slArcs[i + 3]) - ymin) - (48 - factor * hRect) / 2);

        // x3,y3, x4,y4 - координаты начала и конца
        x3 := round(8  + factor * (StrToInt(slArcs[i + 6]) - xmin) + (48 - factor * wRect) / 2);
        y3 := round(56 - factor * (StrToInt(slArcs[i + 7]) - ymin) - (48 - factor * hRect) / 2);
        x4 := round(8  + factor * (StrToInt(slArcs[i + 8]) - xmin) + (48 - factor * wRect) / 2);
        y4 := round(56 - factor * (StrToInt(slArcs[i + 9]) - ymin) - (48 - factor * hRect) / 2);

        // корректировка в зависимости от квадрата
        x1 := x1 + 8 + (72 * (imgCol - 1));
        y1 := y1 + 8 + (72 * (imgRow - 1));
        x2 := x2 + 8 + (72 * (imgCol - 1));
        y2 := y2 + 8 + (72 * (imgRow - 1));
        x3 := x3 + 8 + (72 * (imgCol - 1));
        y3 := y3 + 8 + (72 * (imgRow - 1));
        x4 := x4 + 8 + (72 * (imgCol - 1));
        y4 := y4 + 8 + (72 * (imgRow - 1));

        imgPanel.Canvas.Arc(x1, y1, x2, y2, x3, y3, x4, y4);

        // дорисовываем крайние точки
        imgPanel.Canvas.Pixels[x3, y3] := imgPanel.Canvas.Pen.Color;
        imgPanel.Canvas.Pixels[x4, y4] := imgPanel.Canvas.Pen.Color;
    end;
    //imgPanel.Canvas.p

    // отрисовываем X0Y0
    imgPanel.Canvas.Pen.Color := clRed;
    imgPanel.Canvas.Pen.Width := 1;
    x_img := round(8 +  factor * (0 - xmin) + (48 - factor * (xmax - xmin)) / 2);
    y_img := round(56 - factor * (0 - ymin) - (48 - factor * (ymax - ymin)) / 2);

   // корректировка в зависимости от квадрата
    x_img := x_img + 8 + (72 * (imgCol - 1));
    y_img := y_img + 8 + (72 * (imgRow - 1));
    imgPanel.Canvas.MoveTo(x_img - 6, y_img);
    imgPanel.Canvas.LineTo(x_img + 7, y_img);
    imgPanel.Canvas.MoveTo(x_img, y_img - 6);
    imgPanel.Canvas.LineTo(x_img, y_img + 7);

end;

// чтение данных одного из наборов и вставка
procedure RegistryReadAndInsert (imgCol : integer, imgRow : integer);
var
    Registry        : TRegistry;
    strRegKey       : String;

    TheLayerStack   : IPCB_LayerStack;
    LayerObjCur     : IPCB_LayerObject;
    NetName1        : String;
    NetName2        : String;
    i, j            : Integer;
    Track_01        : IPCB_Track;
    Arc_01          : IPCB_Arc;
    x0, y0          : TCoord;

    //TrackX          : TStringList; //Набор координат
    //TrackY          : TStringList;

begin
    slTracks    := TStringList.Create;
    slArcs      := TStringList.Create;
    slVias      := TStringList.Create;
    slRegions   := TStringList.Create;

    // создаём объект TRegistry
    Registry := TRegistry.Create;
    Try
        // устанавливаем корневой ключ; напрмер hkey_local_machine или hkey_current_user
        // Registry.RootKey := HKEY_CURRENT_USER; Устанавливается автоматически
        // открываем и создаём ключ

        strRegKey := 'Software\AltiumScripts\PrimitiveTemplatePlacer\Set' + IntToStr (imgRow) + IntToStr (imgCol);
        //Set12 - 1 ряд, 2 колонка
        //Set21 - 2 ряд, 1 колонка

        Registry.OpenKey(strRegKey, true);
        //Читаем строку и сразу раскладываем в StringList в виде объектов
        if Registry.ValueExists('Tracks')   then    slTracks.CommaText  := Registry.ReadString('Tracks');
        if Registry.ValueExists('Arcs')     then    slArcs.CommaText    := Registry.ReadString('Arcs');
        if Registry.ValueExists('Vias')     then    slVias.CommaText    := Registry.ReadString('Vias');
        if Registry.ValueExists('Regions')  then    slRegions.CommaText := Registry.ReadString('Regions');
        Registry.CloseKey;

        //Создаем рисунок с объектами в StringLists
        if (slTracks.Count = 0) and
            (slArcs.Count = 0) and
            (slVias.Count = 0) and
            (slRegions.Count = 0) then exit;


        // закрываем и освобождаем ключ
    Finally
        Registry.Free;

    End;

    //frmPP.Visible := false;
    //frmPP.SendToBack;
    frmPP.Left := 10000;

    PCBBoard := PCBServer.GetCurrentPCBBoard;
    if PCBBoard = Nil Then Exit;

    // Now we need to get the signal layers and populate comboBox
    TheLayerStack := PCBBoard.LayerStack;
    if TheLayerStack = Nil Then Exit;

    LayerObjCur := PCBBoard.CurrentLayer;

    PCBBoard.ChooseLocation(x0, y0, 'choose loc');


    PCBServer.PreProcess;


    for i := 0 to slTracks.Count - 5 do
    begin
        // Обрабатываем только позиции 1, 6, 11 и т.д.
        // Только позиции с X1, остальные - мимо
        if (i mod 5) <> 0 then Continue;

        Track_01 := PCBServer.PCBObjectFactory(eTrackObject, eNoDimension, eCreate_Default);
        Track_01.Width := StrToInt(slTracks[i]);
        Track_01.X1 := x0 + StrToInt(slTracks[i + 1]);
        Track_01.Y1 := y0 + StrToInt(slTracks[i + 2]);
        Track_01.X2 := x0 + StrToInt(slTracks[i + 3]);
        Track_01.Y2 := y0 + StrToInt(slTracks[i + 4]);
        Track_01.Layer := LayerObjCur;


        PCBServer.SendMessageToRobots(
                Track_01.I_ObjectAddress,
                c_Broadcast,
                PCBM_BeginModify ,
                c_NoEventData);

        PCBBoard.AddPCBObject(Track_01);
        Track_01.Selected := true;

        PCBServer.SendMessageToRobots(
                Track_01.I_ObjectAddress,
                c_Broadcast,
                PCBM_EndModify ,
                c_NoEventData);

        Track_01.GraphicallyInvalidate;


    end; //for i по трекам

    for i := 0 to slArcs.Count - 10 do
    begin
        // Обрабатываем только позиции 1, 6, 11 и т.д.
        // Только позиции с X1, остальные - мимо
        if (i mod 10) <> 0 then Continue;

        Arc_01 := PCBServer.PCBObjectFactory(eArcObject, eNoDimension, eCreate_Default);
        Arc_01.LineWidth    := StrToInt(slArcs[i]);
        Arc_01.XCenter      := x0 + StrToInt(slArcs[i + 1]);
        Arc_01.YCenter      := y0 + StrToInt(slArcs[i + 2]);
        Arc_01.Radius       := StrToInt(slArcs[i + 3]);
        Arc_01.StartAngle   := StrToInt(slArcs[i + 4]);
        Arc_01.EndAngle     := StrToInt(slArcs[i + 5]);
        Arc_01.Layer := LayerObjCur;


        PCBServer.SendMessageToRobots(
                Arc_01.I_ObjectAddress,
                c_Broadcast,
                PCBM_BeginModify ,
                c_NoEventData);

        PCBBoard.AddPCBObject(Arc_01);
        Arc_01.Selected := true;

        PCBServer.SendMessageToRobots(
                Arc_01.I_ObjectAddress,
                c_Broadcast,
                PCBM_EndModify ,
                c_NoEventData);

        Arc_01.GraphicallyInvalidate;


    end; //for i по аркам


    PCBServer.PostProcess;

    slTracks.Free;
    slArcs.Free;
    slVias.Free;
    slRegions.Free;



    ResetParameters;

    AddStringParameter('Action','RubberStamp');
    RunProcess('PCB:Paste');
    //frmPP.BringToFront;
    ResetParameters;
    RunProcess('PCB:Clear');
    PCBBoard.ViewManager_FullUpdate;

    frmPP.Close;
end;

// чтение всех ключей и отрисовка на панели
procedure RegistryRead;
var
    Registry        : TRegistry;
    strRegKey       : String;
    icol, jrow      : integer;

Begin
    slBndRect   := TStringList.Create;
    slTracks    := TStringList.Create;
    slArcs      := TStringList.Create;
    slVias      := TStringList.Create;
    slRegions   := TStringList.Create;

    // создаём объект TRegistry
    Registry := TRegistry.Create;
    Try
        for jrow := 1 to 4 do
        begin
            for icol := 1 to 4 do
            begin
                // устанавливаем корневой ключ; напрмер hkey_local_machine или hkey_current_user
                // Registry.RootKey := HKEY_CURRENT_USER; Устанавливается автоматически
                // открываем и создаём ключ

                strRegKey := 'Software\AltiumScripts\PrimitiveTemplatePlacer\Set' + IntToStr (jrow) + IntToStr (icol);
                //Set12 - 1 ряд, 2 колонка
                //Set21 - 2 ряд, 1 колонка

                Registry.OpenKey(strRegKey, true);
                //Читаем строку и сразу раскладываем в StringList в виде объектов

                if Registry.ValueExists('Description')          then    arrstrDescrp[icol, jrow] := Registry.ReadString('Description');
                if Registry.ValueExists('BoundingRectangle')    then    slBndRect.CommaText := Registry.ReadString('BoundingRectangle');
                if Registry.ValueExists('Tracks')               then    slTracks.CommaText  := Registry.ReadString('Tracks');
                if Registry.ValueExists('Arcs')                 then    slArcs.CommaText    := Registry.ReadString('Arcs');
                if Registry.ValueExists('Vias')                 then    slVias.CommaText    := Registry.ReadString('Vias');
                if Registry.ValueExists('Regions')              then    slRegions.CommaText := Registry.ReadString('Regions');
                Registry.CloseKey;

                //Создаем рисунок с объектами в StringLists
                if (slTracks.Count = 0) and
                    (slArcs.Count = 0) and
                    (slVias.Count = 0) and
                    (slRegions.Count = 0) then Continue;

                //Если что-то нашли, отрисовываем в ячейке
                DrawObjects(icol, jrow);

                slBndRect.Clear;
                slTracks.Clear;
                slArcs.Clear;
                slVias.Clear;
                slRegions.Clear;


            end; //icol
        end;// jrow

        // закрываем и освобождаем ключ
    Finally
        Registry.Free;

        slBndRect.Free;
        slTracks.Free;
        slArcs.Free;
        slVias.Free;
        slRegions.Free;

    End;

End;

procedure RegistryWrite (imgCol : integer, imgRow : integer);
var
    Registry: TRegistry;
    strRegKey       : String;

    strDescriptionRegistry      : String;

Begin
    strDescriptionRegistry := InputBox(frmPP.Caption, 'Description of set:', 'My Object Set');
    { создаём объект TRegistry }
    Registry := TRegistry.Create;
    Try
        strRegKey := 'Software\AltiumScripts\PrimitiveTemplatePlacer\Set' + IntToStr (imgRow) + IntToStr (imgCol);
        //Set12 - 1 ряд, 2 колонка
        //Set21 - 2 ряд, 1 колонка

        { устанавливаем корневой ключ; напрмер hkey_local_machine или hkey_current_user }
        //Registry.RootKey := HKEY_CURRENT_USER; {Устанавливается автоматически}
        { открываем и создаём ключ }
        Registry.OpenKey(strRegKey, true);
        { записываем значения }
        Registry.WriteString('Description', strDescriptionRegistry);
        if Length(SaveRectCoord) <> 0   then Registry.WriteString('BoundingRectangle',      SaveRectCoord);
        if Length(SaveTrackCoord) <> 0  then Registry.WriteString('Tracks',      SaveTrackCoord);
        if Length(SaveArcCoord) <> 0    then Registry.WriteString('Arcs',        SaveArcCoord);

        { закрываем и освобождаем ключ }
        Registry.CloseKey;
    Finally
        Registry.Free;
    End;

    frmPP.close;
End;

//Отрисовка imgPanel и 16 квадратов 64 х 64 на ней
procedure DrawOnForm;
var
    i, j         : integer;
    x1r, y1r, x2r, y2r      : integer;
begin
    label1.Transparent := true;
    imgPanel.Canvas.Pen.Color := clBlack;
    imgPanel.Canvas.Pen.Width := 1;
    imgPanel.Canvas.Brush.Color := clBtnFace;
    imgPanel.Canvas.Rectangle(0, 0, imgPanel.Width, imgPanel.Height);

    for j := 1 to 4 do
    for i := 1 to 4 do
    begin
        x1r := 8 + (72 * (i - 1));
        y1r := 8 + (72 * (j - 1));
        x2r := x1r + 64;
        y2r := y1r + 64;
        imgPanel.Canvas.Pen.Color := clBlack;
        imgPanel.Canvas.Rectangle(x1r, y1r, x2r, y2r);

        //добавим тени
        imgPanel.Canvas.Pen.Color := clGray;
        imgPanel.Canvas.MoveTo(x1r + 1, y2r); //левый нижний
        imgPanel.Canvas.LineTo(x2r, y2r); //правый нижний
        imgPanel.Canvas.LineTo(x2r, y1r); //правый верхний
    end;
end;

procedure StartPaste;
begin
    modeSave := false;
    DrawOnForm;
    RegistryRead;
    //frmPP.Position.Left := 550;
    //frmPP.Top := 300;
    frmPP.Show;
end;

procedure StartSave;
var
    i               : integer;

    x0, y0          : TCoord;  // Origin point of selected objects
    bRect           : TCoordRect;      // BoundingRectangle выделенных объектов
    wl_bRect        : TCoord; // толщина линии выделенного объекта

    SaveTrack       : IPCB_Track;
    SaveArc         : IPCB_Arc;
    SaveRegion      : IPCB_Region;
    SaveVia         : IPCB_Via;

    tmpArcStartAngle, tmpArcEndAngle      : TAngle; //

begin
    PCBBoard := PCBServer.GetCurrentPCBBoard;
    if PCBBoard = Nil Then Exit;
    if PCBBoard.SelectecObjectCount = 0 then Exit;

    SaveTrack   := nil;
    SaveArc     := nil;
    SaveRegion  := nil;
    SaveVia     := nil;

    SaveRectCoord       := '';
    SaveTrackCoord      := '';
    SaveArcCoord        := '';
    SaveRegionCoord     := '';
    SaveViaCoord        := '';

    if not(PCBBoard.ChooseLocation(x0, y0, 'Select origin point for Selected objects')) then exit;

    //Описываем BoundingRectangle вокруг первого объекта
    bRect := PCBBoard.SelectecObject[0].BoundingRectangle;

    if x0 < bRect.Left      then bRect.Left     := x0;
    if x0 > bRect.Right     then bRect.Right    := x0;
    if y0 < bRect.Bottom    then bRect.Bottom   := y0;
    if y0 > bRect.Top       then bRect.Top      := y0;



    //Забиваем в строку координаты объектов
    for i := 0 to PCBBoard.SelectecObjectCount - 1 do
    begin
        if ((PCBBoard.SelectecObject[i].ObjectId <> eTrackObject) and
           (PCBBoard.SelectecObject[i].ObjectId <> eArcObject)   and
           (PCBBoard.SelectecObject[i].ObjectId <> eRegionObject)   and
           (PCBBoard.SelectecObject[i].ObjectId <> eViaObject)) then
        begin
          ShowInfo('Please select only track, arc, region and via');
          exit;
        end;

        // Определяем BoundingRectangle выделенных объектов, увеличивая зону с каждым объектом
        if PCBBoard.SelectecObject[i].BoundingRectangle.Left   < bRect.Left
            then bRect.Left   := PCBBoard.SelectecObject[i].BoundingRectangle.Left;
        if PCBBoard.SelectecObject[i].BoundingRectangle.Right  > bRect.Right
            then bRect.Right  := PCBBoard.SelectecObject[i].BoundingRectangle.Right;
        if PCBBoard.SelectecObject[i].BoundingRectangle.Bottom < bRect.Bottom
            then bRect.Bottom := PCBBoard.SelectecObject[i].BoundingRectangle.Bottom;
        if PCBBoard.SelectecObject[i].BoundingRectangle.Top    > bRect.Top
            then bRect.Top    := PCBBoard.SelectecObject[i].BoundingRectangle.Top;

        if PCBBoard.SelectecObject[i].ObjectId = eTrackObject then
        begin
            SaveTrack := PCBBoard.SelectecObject[i];
            SaveTrackCoord := SaveTrackCoord + IntToStr(SaveTrack.Width) + ',' +     //[0]
                                               IntToStr(SaveTrack.x1 - x0) + ',' +   //[1]
                                               IntToStr(SaveTrack.y1 - y0) + ',' +   //[2]
                                               IntToStr(SaveTrack.x2 - x0) + ',' +   //[3]
                                               IntToStr(SaveTrack.y2 - y0) + ',';    //[4]
            wl_bRect := SaveTrack.Width;
            //bRect := SaveTrack
        end;

        if PCBBoard.SelectecObject[i].ObjectId = eArcObject then
        begin
            SaveArc := PCBBoard.SelectecObject[i];
            //tmpArcStartAngle := SaveArc.StartAngle;
            //tmpArcEndAngle := SaveArc.EndAngle;
            SaveArcCoord := SaveArcCoord + IntToStr(SaveArc.LineWidth) + ',' +      //[0]
                                           IntToStr(SaveArc.XCenter - x0) + ',' +   //[1]
                                           IntToStr(SaveArc.YCenter - y0) + ',' +   //[2]
                                           IntToStr(SaveArc.Radius) + ',' +         //[3]
                                           IntToStr(SaveArc.StartAngle) + ',' +     //[4]
                                           IntToStr(SaveArc.EndAngle) + ',' +       //[5]
                                           IntToStr(SaveArc.StartX - x0) + ',' +    //[6]
                                           IntToStr(SaveArc.StartY - y0) + ',' +    //[7]
                                           IntToStr(SaveArc.EndX - x0) + ',' +      //[8]
                                           IntToStr(SaveArc.EndY - y0) + ',';       //[9]
            wl_bRect := SaveArc.LineWidth;
        end;


    end; // of for i := 0 to PCBBoard.SelectecObjectCount - 1 do

    //Описываемый прямоугольник за минусом половины ширины линии с каждой стороны
    bRect.Left :=   bRect.Left      + (wl_bRect / 2) - x0;
    bRect.Right :=  bRect.Right     - (wl_bRect / 2) - x0;
    bRect.Bottom := bRect.Bottom    + (wl_bRect / 2) - y0;
    bRect.Top :=    bRect.Top       - (wl_bRect / 2) - y0;

    SaveRectCoord := (Inttostr(bRect.Left) + ',' +
                      Inttostr(bRect.Bottom) + ',' +
                      Inttostr(bRect.Right) + ',' +
                      Inttostr(bRect.Top));

    //S[Length(s)]
    //Если есть запись
    if Length(SaveTrackCoord) <> 0 then
        //Последнюю ',' удалить
        if SaveTrackCoord[Length(SaveTrackCoord)] = ',' then
            Delete(SaveTrackCoord, Length(SaveTrackCoord), 1);

    if Length(SaveArcCoord) <> 0 then
        if SaveArcCoord[Length(SaveArcCoord)] = ',' then
            Delete(SaveArcCoord, Length(SaveArcCoord), 1);


    lblSave.Visible := true;

   // ShowMessage(SaveTrackCoord);
   // ShowMessage(Length(SaveTrackCoord));

    SaveTrack   := nil;
    SaveArc     := nil;
    SaveRegion  := nil;
    SaveVia     := nil;





    modeSave := true;
    DrawOnForm;          // Рисуем квадраты на форме
    RegistryRead;       // Читаем реестр и отрисовываем объекты на форме
    frmPP.Show;
end;

procedure TfrmPP.imgPanelMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
    lblImgDescription.Caption := ': Some quadrante';
    if (x mod 72) < 8 then begin lblImgDescription.Caption := ''; exit; end;
    if (y mod 72) < 8 then begin lblImgDescription.Caption := ''; exit; end;

    if ((x div 72) > 3) or ((y div 72) > 3) then exit;

    lblImgLetter.Caption := arrstrLetter[(x div 72) + 1, (y div 72) + 1);
    lblImgDescription.Caption := arrstrDescrp [(x div 72) + 1, (y div 72) + 1);

    label1.Caption := 'omg coord: ' + IntTostr(x) + ', ' + inttostr(y);
  {  if (x > 8) and (x < 72) and (y > 8) and (y < 72) then
    begin
        imgPanel.Canvas.Pen.Width : = 1;
        imgPanel.Canvas.Pen.Color := clRed;
        imgPanel.Canvas.MoveTo(8, 8);
        imgPanel.Canvas.LineTo(72 , 8);
        imgPanel.Canvas.LineTo(72 , 72);
        imgPanel.Canvas.LineTo(8 , 72);
        imgPanel.Canvas.LineTo(8 , 8);
    end
    else
    begin
        imgPanel.Canvas.Pen.Width : = 1;
        imgPanel.Canvas.Pen.Color := clBlack;
        imgPanel.Canvas.MoveTo(8, 8);
        imgPanel.Canvas.LineTo(72 , 8);
        imgPanel.Canvas.LineTo(72 , 72);
        imgPanel.Canvas.LineTo(8 , 72);
        imgPanel.Canvas.LineTo(8 , 8);
    end;
    }
end;

procedure TfrmPP.imgPanelMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
   // showmessage('OnMouseDown: ' + inttostr(X)+ ', ' + inttostr(Y));
end;

procedure TfrmPP.imgPanelMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
    if (x mod 72) < 8 then exit; //begin showmessage('x mimo'); exit; end;
    if (y mod 72) < 8 then exit; //begin showmessage('y mimo'); exit; end;

    if modeSave then
    begin
        RegistryWrite((x div 72) + 1, (y div 72) + 1);
    end
    else
    begin
        RegistryReadAndInsert((x div 72) + 1, (y div 72) + 1);
    end;
end;

procedure TfrmPP.frmPPKeyPress(Sender: TObject; var Key: Char);
var
    icol, jrow      : integer;
begin
    //ShowMessage(key);
    if Key = 49 then begin jrow := 1; icol := 1 end;    //1
    if Key = 50 then begin jrow := 1; icol := 2 end;    //2
    if Key = 51 then begin jrow := 1; icol := 3 end;    //3
    if Key = 52 then begin jrow := 1; icol := 4 end;    //4

    if Key = 113 then begin jrow := 2; icol := 1 end;   //Q
    if Key = 119 then begin jrow := 2; icol := 2 end;   //W
    if Key = 101 then begin jrow := 2; icol := 3 end;   //E
    if Key = 114 then begin jrow := 2; icol := 4 end;   //R

    if Key =  97 then begin jrow := 3; icol := 1 end;   //A
    if Key = 115 then begin jrow := 3; icol := 2 end;   //S
    if Key = 100 then begin jrow := 3; icol := 3 end;   //D
    if Key = 102 then begin jrow := 3; icol := 4 end;   //F

    if Key = 122 then begin jrow := 4; icol := 1 end;   //Z
    if Key = 120 then begin jrow := 4; icol := 2 end;   //X
    if Key =  99 then begin jrow := 4; icol := 3 end;   //C
    if Key = 118 then begin jrow := 4; icol := 4 end;   //V

    if modeSave then
    begin
        RegistryWrite(icol, jrow);
    end
    else
    begin
        RegistryReadAndInsert(icol, jrow);
    end;
end;

procedure TfrmPP.butCancelClick(Sender: TObject);
begin
    frmPP.close;
end;


procedure TfrmPP.frmPPCreate(Sender: TObject);
begin
    arrstrLetter[1, 1] := '1';        //icol, jrow
    arrstrLetter[2, 1] := '2';
    arrstrLetter[3, 1] := '3';
    arrstrLetter[4, 1] := '4';
    arrstrLetter[1, 2] := 'Q';        //icol, jrow
    arrstrLetter[2, 2] := 'W';
    arrstrLetter[3, 2] := 'E';
    arrstrLetter[4, 2] := 'R';
    arrstrLetter[1, 3] := 'A';        //icol, jrow
    arrstrLetter[2, 3] := 'S';
    arrstrLetter[3, 3] := 'D';
    arrstrLetter[4, 3] := 'F';
    arrstrLetter[1, 4] := 'Z';        //icol, jrow
    arrstrLetter[2, 4] := 'X';
    arrstrLetter[3, 4] := 'C';
    arrstrLetter[4, 4] := 'V';
end;

