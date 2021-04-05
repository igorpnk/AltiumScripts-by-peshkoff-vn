//Adjust Net Length v 3.0
Uses Registry;

// точность для расчетов
// 10 eCoord = 0.001 mil
const eCoord = 10;

var
    Board               : IPCB_Board;
    boolModeManual      : boolean;
    boolModeDeltaPlus   : boolean;
    boolModeDeltaMinus  : boolean;

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
        Registry.OpenKey('Software\AltiumScripts\AdjustNetLength',true);

        if Registry.ValueExists('ManualLength')  then editManual.Text := Registry.ReadString('ManualLength');
        if Registry.ValueExists('DeltaLength')   then editDelta.Text := Registry.ReadString('DeltaLength');
        if Registry.ValueExists('DRCheck')       then CheckBoxRules.Checked := Registry.ReadBool('DRCheck');
        if Registry.ValueExists('FixTrace')      then CheckBoxRules.Checked := Registry.ReadBool('FixTrace');
        if Registry.ValueExists('FixTrace')      then CheckBoxFix.Checked := Registry.ReadBool('FixTrace');

        { закрываем и освобождаем ключ }
        Registry.CloseKey;
    Finally
        Registry.Free;
    End;
    //rbManual.Checked := not(rbAuto.Checked);
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
        Registry.OpenKey('Software\AltiumScripts\AdjustNetLength',true);
        { записываем значения }

        Registry.WriteString('ManualLength',   floattostr(editManual.Text));
        Registry.WriteString('DeltaLength',   floattostr(editDelta.Text));
        Registry.WriteBool('DRCheck',   CheckBoxRules.Checked);
        Registry.WriteBool('FixTrace',  CheckBoxFix.Checked);

        { закрываем и освобождаем ключ }
        Registry.CloseKey;
    Finally
        Registry.Free;
    End;

End;

function Compare2Coord(const x1, y1, x2, y2 : TCoord) : Boolean;
// сравнение координат : x1 y1 x2 y2
begin
    Result := false;
    if ((abs(x2 - x1) < eCoord) and (abs(y2 - y1) < eCoord))
    then
    Result := true;
end;

function Compare4Coord(const x1, y1, x2, y2, x3, y3, x4, y4 : TCoord) : Boolean;
// перекрестное сравнение координат объекта 1: x1 y1 x2 y2
// с объектом 2: x3 y3 x4 y4
// положительное решение при совпадении одной из пар
begin
    Result := false;
    if ((abs(x3 - x1) < eCoord) and (abs(y3 - y1) < eCoord)) or
       ((abs(x3 - x2) < eCoord) and (abs(y3 - y2) < eCoord)) or
       ((abs(x4 - x1) < eCoord) and (abs(y4 - y1) < eCoord)) or
       ((abs(x4 - x2) < eCoord) and (abs(y4 - y2) < eCoord))
    then
    Result := true;
end;

function PointInRect(const x, y : TCoord; inRect : TCoordRect) : Boolean;
// принадлежит ли точка прямоугольнику
begin
    Result := false;
    if (x >= inRect.Left) and (x <= inRect.Right) and
        (y >= inRect.Bottom) and (y <= inRect.Top)
    then
    Result := true;
end;

procedure FixTrace;
var
i, j : integer;
//Modify      : boolean;
Arc1, Arc2      : IPCB_Arc;
begin
    //selObj := Board.SelectecObjectCount;
    //Board.ObjectIDString
    //Board.sel
    if Board.SelectecObjectCount < 2 then exit;
    i := 0;
    j := 1;
    //Modify := false;
    // Ищем и обрабатываем дуги
    while (i < Board.SelectecObjectCount - 1) do
    begin
        while j < Board.SelectecObjectCount do
        begin
            // если сравниваем объеки сам с собой
            if j = i then inc(j);
            // Если оба объекта - дуги
            if (Board.SelectecObject[i].ObjectID = 1) and (Board.SelectecObject[j].ObjectID = 1) then
            begin
                Arc1 := Board.SelectecObject[i];
                Arc2 := Board.SelectecObject[j];
                // если совпадает центр и один из концов
                if Compare2Coord(Arc1.XCenter, Arc1.YCenter,
                                 Arc2.XCenter, Arc2.YCenter) and
                   Compare4Coord(Arc1.StartX, Arc1.StartY,
                                 Arc1.EndX, Arc1.EndY,
                                 Arc2.StartX, Arc2.StartY,
                                 Arc2.EndX, Arc2.EndY)
                then
                begin // вычисляем, какой из концов совпал
                    if Compare2Coord(Arc1.StartX, Arc1.StartY,
                                     Arc2.EndX, Arc2.EndY)
                    then        // если Start[i] совпадает с End[j]
                        Arc1.StartAngle := Arc2.StartAngle
                    else        // если End[i] совпадает со Start[j]
                        Arc1.EndAngle := Arc2.EndAngle;

                    Board.RemovePCBObject(Arc2);
                    i: = -1;
                    break;
                end
                else // не нашли совпадения координат
                begin
                    inc(j);
                end;

            end
            else  // что-то не дуга, not ((Board.SelectecObject[i].ObjectID = 1) and (Board.SelectecObject[j].ObjectID = 1))
            begin
                inc(j);
            end;
        end; // end of while j
        inc (i);
        j := 1;
    end; // end of while i

    FreeAndNil(Arc1);
    FreeAndNil(Arc2);
end;

procedure GetManualLengthDialog(const CurrentNetLength : TCoord);
var
    strAutoToManual     : string;
begin
    strAutoToManual := floattostr(formatfloat('#.000',(CoordToMMs(CurrentNetLength))));
    if InputQuery('Manual input', 'Net cannot be found' + #13#10 +
                                            'in any net class.' + #13#10 +
                                            'Please enter manual.'  + #13#10 +
                                            'Current length:', strAutoToManual) then
    begin
        boolModeManual := true;
        editManual.Text := strAutoToManual;
    end
    else
    begin
        boolModeManual := true;
        editManual.Text := strAutoToManual;
    end;
end;

procedure MoveSelectObj;
Var

    Iterator        : IPCB_BoardIterator;
    BoardIterator   : IPCB_SpatialIterator;
    FinalLayer      : String;
    PrimSel         : IPCB_Primitive;
    PrimSelWidth    : TCoord;
    PrimExt         : IPCB_Primitive;
    DiffPair        : IPCB_DifferentialPair;
    //TrackForNet     : IPCB_Track;
    Layer1          : String;
    Layer2          : String;
    NetName1        : String;
    NetName2        : String;
    NetNameTmp      : String;
    TuningVariant   : Integer;
    i, j, j1        : Integer;

    Flag1         : Integer;
    Flag2         : Integer;
    Rectangle     : TCoordRect;
    Rule            : IPCB_Rule;
    //Violation       : IPCB_Violation;
    PrimViolation1  : IPCB_Primitive;
    PrimViolation2  : IPCB_Primitive;
    Rule_Count      : Integer;
    Violation_Count : Integer;
    PrimViolation_Count : Integer;


    SelectedPrimsEdit   : TStringList; // Выделенные примитивы для редактирования до создания SelectedPrims
    SelectedPrims   : TStringList;    //Выделенные примитивы
    ExtTrimPrims    : TStringList;   //Примитивы для удлинения или укорачивания
    ExtTrimPrimsA   : TStringList;   //Углы примитивов для удлинения или укорачивания
    DblDetect       : Boolean;      //Определяет найденные дубликаты в TStringList
    PrimExtA        : Real;

    Net1                : IPCB_Net;
    Net2                : IPCB_Net;
    NetTmp              : IPCB_Net;
    NetTarget           : IPCB_Net;
    NetCurrent          : IPCB_Net;     //Текущая цепь в цикле при переборе
    boolMultyNet        : boolean;      //Выбрано несколько цепей
    boolDiffPairNet     : boolean;      //Все (!) выбранные цепи являются частью одной диффпары
    boolMoveAndResizePrimSel : boolean; //Selection Primitive не только перемещаем, но еще и изменяем геометрию

    NetClass            : IPCB_ObjectClass;
    NetClassTmp         : IPCB_ObjectClass; //Временный класс цепей дял сравнения
    NetClassesList      : TStringList; //Перечень классов, куда входит наша цепь
    // OurNetClassNet      : TstringList; //Перечень цепей в нашем классе
    // OurNetClassNetTmp   : TstringList; //Перечень цепей временный
    NetCountMin         : Long;
    NetCountTmp         : Long;
    strNetClass         : string;

    LenNet1       : real;
    LenNetTmp     : real;
    LenNetTarget  : real;
    DeltaNet      : real;
    DeltaPrimExt  : TCoord;
    LenPrimExt    : TCoord; //Длина трэка
    DeltaPrimSel  : real;
    ByX           : TCoord;
    ByY           : TCoord;

    diffname      : string;
    end1          : string;
    end2          : string;

    DlgOk           : boolean;

    PrimExtAll      : single;
    PrimExtFilter   : single;

Begin

    //Если ничего не выбрано
    if Board.SelectecObjectCount = 0 then
    begin
       ShowMessage('No selected objects');
       exit;
    end;

    TuningVariant := 0;
    boolMultyNet := False;
    boolDiffPairNet := False;
    DiffPair := Nil;
    boolMoveAndResizePrimSel := False;

    if ((Board.SelectecObject[0].ObjectId <> eTrackObject) and (Board.SelectecObject[0].ObjectId <> eArcObject)) then exit;

    if Board.SelectecObject[0].Net = Nil then exit;

    //Создается SelectedPrims : TStringList Лист с именами выбранных примитивов
    SelectedPrims := TStringList.Create;
    //Создается лист с объектами, подсоединенными к выбранным, их нужно будет укоротить или нарастить
    ExtTrimPrims := TStringList.Create;
    j := 0; //Iterator for ExtTrimPrims

    //Имя первой цепи берем с первого выделенного объекта
    Net1:=Board.SelectecObject[0].Net;
    NetName1 := Net1.Name;

    //Если цепь входит в диффпару
    if Net1.InDifferentialPair then
    begin
        //Запускаем итератор для определения диффпары как объекта
        Iterator:= Board.BoardIterator_Create;
        Iterator.AddFilter_ObjectSet(MkSet(eDifferentialPairObject));
        Iterator.AddFilter_LayerSet(AllLayers);
        Iterator.AddFilter_Method(eProcessAll);
        DiffPair := Iterator.FirstPCBObject;

        While DiffPair <> Nil do
            begin
            if (Net1 = DiffPair.PositiveNet) or (Net1 = DiffPair.NegativeNet) then
                begin
                //Определяем цепи в диффпаре
                boolDiffPairNet := True;
                break;
                end;
            DiffPair := Iterator.NextPCBObject;
            end;
        Board.BoardIterator_Destroy(Iterator);
    end;

    // *** Редактируем/удаляем выделенные объекты
    if CheckBoxFix.Checked then FixTrace;
    // *** Закончили редактировать/удалять

    //Проходим по все примитивам

    for i := 0 to Board.SelectecObjectCount - 1 do
    begin

        //Примитивы должны быть линиями или дугами, если нет, то выход
        if ((Board.SelectecObject[i].ObjectId <> eTrackObject) and (Board.SelectecObject[i].ObjectId <> eArcObject)) then
        begin
            ShowMessage('Please select only tracks or/and arcs');
            exit;
        end;

        //Если это дуга или линия она должна быть еще и цепью
        if (not Board.SelectecObject[i].InNet) then
        begin
            ShowMessage('All selected objects must be in a net');
            exit;
        end;
        //Если все условия выполнены элемент добавляется в лист SelectedPrims
        SelectedPrims.AddObject(IntToStr(i), Board.SelectecObject[i]);

        //////////**    Ищем невыделенную линию вокруг выделенных примитивов
        //Назначаем выделенный объект в PrimSel
        PrimSel := SelectedPrims.GetObject(i);

        //Вычисляем ширину линии (ограничим область поиска)
        if PrimSel.ObjectID = 4 then //Выбранный объект - линия
            PrimSelWidth := PrimSel.Width;
        if PrimSel.ObjectID = 1 then //Выбранный объект - дуга
            PrimSelWidth := PrimSel.LineWidth;

        //Очерчиваем прямоугольник, описывающий наш примитив
        Rectangle := PrimSel.BoundingRectangle;

        // Уменьшаем границы прямоугольника, убираем ширину PrimSel
        // Прибавим к границам погрешность eCoord = 10 = 0.001 mil
        Rectangle.Left :=   Rectangle.Left   + PrimSelWidth / 2 - eCoord;
        Rectangle.Bottom := Rectangle.Bottom + PrimSelWidth / 2 - eCoord;
        Rectangle.Right :=  Rectangle.Right  - PrimSelWidth / 2 + eCoord;
        Rectangle.Top :=    Rectangle.Top    - PrimSelWidth / 2 + eCoord;

        //Создаем счетчик
        BoardIterator := Board.SpatialIterator_Create;
        //Будем проверять только линии
        BoardIterator.AddFilter_ObjectSet(MkSet(eTrackObject));
        BoardIterator.AddFilter_LayerSet(MkSet(PrimSel.Layer));
        //Задаем область поиска
        BoardIterator.AddFilter_Area(Rectangle.Left,
                                    Rectangle.Bottom,
                                    Rectangle.Right,
                                    Rectangle.Top);
        //Находим первый примитив в этой области
        PrimExt := BoardIterator.FirstPCBObject;

        //PrimExtAll := 0;
        //PrimExtFilter := 0;
        //Пока не закончатся объекты
        //Добавляем в ExtTrimPrims     //НУЖНО ПОСЧИТАТЬ КОЛИЧЕСТВО PRIMEXT, КОТОРОЕ ПОПАДАЕТ В BOUNDING RECTANGLE!!!!
        while PrimExt <> Nil do
        begin
        //Inc(PrimExtAll);
            if (Not(PrimExt.Selected)) and // Примитив должен быть не выделенным
               (PrimExt.ObjectID=eTrackObject) and // Примитив должен быть линией
               (PrimExt.Layer=PrimSel.Layer) and //должен находиться в одном слое с выделенными объектами (сделали уже фильтром, ну да ладно)
               (PrimExt.Net.Name=PrimSel.Net.Name) //Принадлежать одной цепи
               then

            // если все прошло, проверим попадает ли в Rectangle X и Y за минусом половины ширины
            if PointInRect(PrimExt.X1, PrimExt.Y1, Rectangle)
                or
               PointInRect(PrimExt.X2, PrimExt.Y2, Rectangle)
               then
            begin

                //Проверяем соединение невыделенного объекста с выделенным
                if PrimSel.ObjectID = 1 then //Выбранный объект - дуга
                begin   //Если X или Y совпадает с одной из точек выделенной дуги
                    if not (Compare4Coord(PrimExt.X1, PrimExt.Y1, PrimExt.X2, PrimExt.Y2,
                                    PrimSel.StartX, PrimSel.StartY, PrimSel.EndX, PrimSel.EndY))
                        then
                        begin
                            PrimExt := BoardIterator.NextPCBObject;
                            Continue;
                        end;
                end;

                if PrimSel.ObjectID = 4 then //Выбранный объект - линия
                begin
                    if not (Compare4Coord(PrimExt.X1, PrimExt.Y1, PrimExt.X2, PrimExt.Y2,
                                    PrimSel.X1, PrimSel.Y1, PrimSel.X2, PrimSel.Y2))
                        then
                        begin
                            PrimExt := BoardIterator.NextPCBObject;
                            Continue;
                        end;
                end;

                    //Закончили проверять соединение.

                    //Будем определять угол;
                    PrimExtA:=arctan2((PrimExt.Y2 - PrimExt.Y1),(PrimExt.X2 - PrimExt.X1))/Pi*180;

                    //Углы кратные 90 оформим самостоятельно
                    if (PrimExt.Y2 = PrimExt.Y1) and (PrimExt.X2 > PrimExt.X1) then PrimExtA := 0;
                    if (PrimExt.Y2 = PrimExt.Y1) and (PrimExt.X2 < PrimExt.X1) then PrimExtA := 180; //Невозможно
                    if (PrimExt.Y2 > PrimExt.Y1) and (PrimExt.X2 = PrimExt.X1) then PrimExtA := 90;
                    if (PrimExt.Y2 < PrimExt.Y1) and (PrimExt.X2 = PrimExt.X1) then PrimExtA := 270; //Невозможно?..

                    //Формат основных единиц 123456789 = 12345.6789 mil
                    //RoundTo - округление до 10 -> 12345.678 mil (отсечение)
                    if PrimSel.ObjectID = 1 then //Выбранный объект - дуга
                    begin   //Если X2 или Y2 совпадает с одной из точек выделенной дуги (точность +2, 0.010 mil), то прибавляем 180
                        if Compare4Coord(PrimExt.X2, PrimExt.Y2, PrimExt.X2, PrimExt.Y2,
                                        PrimSel.StartX, PrimSel.StartY, PrimSel.EndX, PrimSel.EndY)
                            then PrimExtA := PrimExtA + 180;
                    end;

                    if PrimSel.ObjectID = 4 then //Выбранный объект - линия
                    begin
                        if Compare4Coord(PrimExt.X2, PrimExt.Y2, PrimExt.X2, PrimExt.Y2,
                                        PrimSel.X1, PrimSel.Y1, PrimSel.X2, PrimSel.Y2)
                            then PrimExtA := PrimExtA + 180;
                    end;


                    //Если еще не было ни одного
                    if ExtTrimPrims.Count < 1 then
                    begin
                        ExtTrimPrims.AddObject(IntToStr(PrimExtA), PrimExt);   //Вносим первый объект в ExtTrimPrims
                    end
                    else   //Если уже были объекты, заталкиваем только новые
                    begin
                        DblDetect := false;

                        for j := 0 to ExtTrimPrims.Count - 1 do
                        begin
                            if PrimExt = ExtTrimPrims.GetObject(j) then  DblDetect := true;
                        end;

                        if not(DblDetect) then
                        begin
                            ExtTrimPrims.AddObject(IntToStr(PrimExtA), PrimExt);
                            //inc(j);
                        end;
                    end;

                   // ExtTrimPrimsA..AddObject(IntToStr(j), PrimExtA);
                   // inc(j);

                //end     // if j = 0

                //Необходимо проверить объекты после первого с теми, что уже есть в наборе ExtTrimPrims
                //Добавлять в набор можно, если такой отсутствует
                //else    // if j > 0
                //begin

                //end;

            end; //if Not(PrimExt.Selected)...
            PrimExt := BoardIterator.NextPCBObject;
        end; //while PrimExt <> Nil

        Board.SpatialIterator_Destroy(BoardIterator);
        //PrimExt.GraphicallyInvalidate;

        //ShowMessage('всего PrimExtAll - ' + InttoStr(PrimExtAll) + #13#10 +
        //            'прошли через фильтр - ' + InttoStr(PrimExtFilter));


        /////////////////**   Конец поиска невыделенной линии вокруг выделенных примитивов



        NetCurrent:=Board.SelectecObject[i].Net;
        //NetName2 := Net2.Name;

        //Попались цепи с разными именами
        if NetCurrent <> Net1
        then
        begin
            boolMultyNet := True;   //Выбраны примитивы, принадлежащие нескольким цепям
        end;

        //Если текущая цепь, не входит ни в какую в диффпару
        if Not(NetCurrent.InDifferentialPair) then
        begin
            boolDiffPairNet := False;
        end;

        //Если цепь входит в диффпару, но имя диффпары не совпадает с именем диффпары первого объекта
        if  NetCurrent.InDifferentialPair and               //Если текущая цепь Board.SelectecObject[i].Net входит в диффпару
            boolDiffPairNet and                             //Если первая цепь Board.SelectecObject[0].Net входит в диффпару
            (NetCurrent <> DiffPair.PositiveNet) and        //Текущая цепь не входит в первую диффпару
            (NetCurrent <> DiffPair.NegativeNet) then       //
        begin
            boolDiffPairNet := False;  //Отключаем boolDiffPairNet, т.к. не входят в одну диффпару
        end;

    end;//for i := 0 to Board.SelectecObjectCount - 1 do


    //Три варианта корректировки длин:
    //1. Выделена одна цепь и она является частью диффпары: равняется по второй части диффпары
    //2. Выделена одна цепь и она не является частью диффпары: Выравнивается по классу (класс должен быть назначен)
    //3. Выделено 2 цепи, являющихся частью одной диффпары
    //4. Выделено более одной цепи, не являющихся частью одной диффпары

   //Вариант 1 - Выделена одна цепь и она является частью дифф пары
   if Not(boolMultyNet) and (Board.SelectecObject[0].Net.InDifferentialPair) then
        TuningVariant := 1;

   //Вариант 2 - Выделена одна цепь, не являющаяся частью диффпары
   if Not(boolMultyNet) and (Not(Board.SelectecObject[0].Net.InDifferentialPair)) then
        TuningVariant := 2;

   //Вариант 3 - Выделено 2 цепи, являющихся частью одной диффпары
   if boolMultyNet and boolDiffPairNet then
        TuningVariant := 3;

   //Вариант 4 - Выделено более одной цепи, не являющихся частью одной диффпары
   if boolMultyNet and not(boolDiffPairNet) then
        TuningVariant := 4;

if (not (boolModeManual or boolModeDeltaPlus or boolModeDeltaMinus)) and (TuningVariant <> 1) then    //Никто из
    begin
        // При выборе варанта AUTO нужно определить, входит ли цепь в какой-нибудь из классов
        // Если цепь не входит ни в один из классов, и не является частью диффпары (TuningVariant - 1)
        // вычислить RoutedLength автоматически не получится
        // Попросим ввести вручную

        //Определяем какому классу принадлежит цепь
        //Создаем список классов
        Iterator := Board.BoardIterator_Create;
        Iterator.SetState_FilterAll;
        Iterator.AddFilter_ObjectSet(MkSet(eClassObject));
        NetClass := Iterator.FirstPCBObject;

        // Создаем новые TStringList
        NetClassesList := TStringList.Create; //Классы (их может быть несколько), куда входит наша цепь

        While NetClass <> Nil Do
        begin
            //Если находим класс и входящую в него цепь
            if (NetClass.IsMember(Net1)) and (NetClass.MemberKind = eClassMemberKind_Net) and (NetClass.Name <> 'All Nets') then
                NetClassesList.AddObject(NetClass.Name, NetClass);

            NetClass := Iterator.NextPCBObject;
        end; //NetClass <> Nil
        Board.BoardIterator_Destroy(Iterator);

        if NetClassesList.Count = 0 then // цепь не попала ни в один из классов
        begin
            GetManualLengthDialog(Net1.RoutedLength);
        end;
    end;

//Вычисляем Net2 только для варианта Auto
if not (boolModeManual or boolModeDeltaPlus or boolModeDeltaMinus) then    //Никто из
begin


    //********************* NET CLASS ********************

    //Если цепь одна и не является частью диффпары, то ищем в NetClass
   if TuningVariant <> 1 then  //Кроме варианта, когда выбрана одна цепь в составе диффпары
   begin

        if NetClassesList.Count > 0 then
        begin

            NetCountMin := 0;
            //NetClass.;
            //Выбираем первый класс
            NetClass := NetClassesList.GetObject(0);

            //Рассчитаем количество цепей, входящих в этот класс
            Iterator := Board.BoardIterator_Create;
            Iterator.AddFilter_ObjectSet(MkSet(eNetObject));
            Iterator.AddFilter_LayerSet(AllLayers);
            Iterator.AddFilter_Method(eProcessAll);
            Net2 := Iterator.FirstPCBObject;

            While Net2 <> Nil do //Листаем все цепи
                begin
                If (NetClass.IsMember(Net2)) then  //Если цепь принадлежит исследуемому классу
                    begin
                    Inc(NetCountMin);
                    end;
                Net2 := Iterator.NextPCBObject;
                end;
            Board.BoardIterator_Destroy(Iterator);    //Destroy Net Iterator

            //Если классов, куда попадает наша цепь больше одного,
            //то для выравнивания выбираем класс, куда входит меньшее количество цепей
            //Рассчитываем количество цепей, входящих в остальные классы

            for i := 1 to NetClassesList.Count - 1 do //Цикл по классам
            begin
                NetCountTmp := 0; //Счетчик для цепей
                NetClassTmp := NetClassesList.GetObject(i);
                //В каждом классе свой итератор по цепям
                Iterator:= Board.BoardIterator_Create;
                Iterator.AddFilter_ObjectSet(MkSet(eNetObject));
                Iterator.AddFilter_LayerSet(AllLayers);
                Iterator.AddFilter_Method(eProcessAll);
                Net2 := Iterator.FirstPCBObject;

                While Net2 <> Nil do
                    begin
                    If (NetClassTmp.IsMember(Net2)) then  //Если цепь принадлежит исследуемому классу
                        begin
                            Inc(NetCountTmp);
                        end;
                    Net2 := Iterator.NextPCBObject;
                    end;
                Board.BoardIterator_Destroy(Iterator);
                //Итератор разрушили, рассчитали количество цепей, исследуем

                if NetCountTmp < NetCountMin then //Если в исследуемом классе меньшее количество цепей, чем в предыдущем
                    begin
                        NetCountMin := NetCountTmp;
                        NetClass := NetClassesList.GetObject(i);
                    end;

            end; //for i := 1 to NetClassesList.Count - 1
        end;

        //frmMain.ShowModal;
        NetCountTmp:=1;
        //Вычисляем самую длиную цепь в классе
        Iterator := Board.BoardIterator_Create;
        Iterator.AddFilter_ObjectSet(MkSet(eNetObject));
        Iterator.AddFilter_LayerSet(AllLayers);
        Iterator.AddFilter_Method(eProcessAll);
        Net2 := Iterator.FirstPCBObject;

        While Net2 <> Nil do //Листаем все цепи
            begin

            //Если цепь принадлежит исследуемому классу
            //Net1 не проверяем, возможно она окажется самой длинной, тогда будем равнять по 2-ой по длине цепи
            if (NetClass.IsMember(Net2)) and (Net2.Name <> Net1.Name) then

            //Если выбрана диффпара, то цепи в диффпаре должны игнорироваться
            if (Copy(Net1.Name, 1, Length(Net1.Name) - 2)) <> (Copy(Net2.Name, 1, Length(Net2.Name) - 2))
                then
                begin
                    if NetCountTmp = 1 then        //Рассчитываем длину для первой цепи в классе
                    begin
                        //LeftStr(Net1.Name, Length(Net1.Name) - 2);
                        //NetName2 := Net2.Name;
                        //LenNet2 := CoordToMMs(Net2.RoutedLength);
                        NetTmp := Net2;
                    end;

                    //Рассчитываем длину для второй и последующих цепей в классе
                    //Если следующая цепь длиннее, номинальной, она становится номинальной, по ней будем равнять
                    //Номинальная - NetTmp
                    If (NetCountTmp > 1) and (Net2.RoutedLength > NetTmp.RoutedLength) then
                        NetTmp := Net2;

                Inc(NetCountTmp);
                end;
            Net2 := Iterator.NextPCBObject;
            end;
        Board.BoardIterator_Destroy(Iterator);    //Destroy Net Iterator

        Net2 := NetTmp;
        NetTmp := nil;
    //*********** END NET CLASS *************************
    //Net1 и Net2 определены

    end;  // TuningVariant <> 1


    //Если выделена одна цепь и она является частью дифф пары
    //Диффпару определили выше
    //DiffPair <> Nil
    If TuningVariant = 1 then
    begin
        if DiffPair <> Nil then
            begin
            if (Net1 = DiffPair.PositiveNet) or (Net1 = DiffPair.NegativeNet) then
                begin
                //Определяем цепи в диффпаре
                if Net1 = DiffPair.PositiveNet
                    then Net2 := DiffPair.NegativeNet
                    else Net2 := DiffPair.PositiveNet;
                end;
            end
            else
            ShowMessage ('Something wrong...');

    end;

    //Вариант 2  Выделена одна цепь, не являющаяся частью диффпары
    If TuningVariant = 2 then
    begin
        // Проверяем во сколько классов вошла наша цепь
        // Если ни в один, то выходим (или предлагаем мануал...)
        // Не должно дойти до этого места!
        if NetClassesList.Count < 1 then
            begin
            showmessage('Цепь не найдена ни в одном из классов!');
            exit;
            end;
    end;

    //Вариант 3  Выделено 2 цепи, являющихся частью одной диффпары
    If TuningVariant = 3 then
    begin
        if NetClassesList.Count < 1 then
        begin
            showmessage('Цепь не найдена ни в одном из классов!');
            exit;
        end;

        if DiffPair <> Nil then
            begin
            if (Net1 = DiffPair.PositiveNet) or (Net1 = DiffPair.NegativeNet) then
                begin
                //Определяем кто длинее в диффпаре, то и главный
                if DiffPair.NegativeNet.RoutedLength > DiffPair.PositiveNet.RoutedLength
                    then Net1 := DiffPair.NegativeNet
                    else Net1 := DiffPair.PositiveNet;
                end;
            end
            else
            ShowMessage ('Something wrong...');
    end;

     //Вариант 4  Выделено более одной цепи, не являющихся частью одной диффпары
    if TuningVariant = 4 then
    begin
        showmessage('Необходимо выбрать либо одну цепь, либо 2 цепи, принадлежащие одной диффпаре!');
        exit;
    end;

    LenNetTarget := Net2.RoutedLength; //Target

end; //Закончили вычислять Net2

    LenNet1 := Net1.RoutedLength; //Selected

    //Если выбран ручной режим
    if boolModeManual then
        LenNetTarget := MMsToCoord(strtofloat(editManual.Text));

    //Вычисляем разницу между ними
    DeltaNet := LenNetTarget - LenNet1;

    if boolModeDeltaPlus then
        DeltaNet := MMsToCoord(strtofloat(editDelta.Text));

    if boolModeDeltaMinus then
        DeltaNet := - MMsToCoord(strtofloat(editDelta.Text));

    //Если выделен только один объект или два объекта, являющихся сегментами _P и _N диффпары
    if (SelectedPrims.Count = 1) or ((SelectedPrims.Count = 2) and (TuningVariant = 3)) then
        boolMoveAndResizePrimSel := true;

    //Или выделен один объект или выделено два и
    //Вариант 3 - Выделено 2 цепи, являющихся частью одной диффпары
    if boolMoveAndResizePrimSel then
    begin //При условии, что угол между PrimExt = 90
        if PrimSel.ObjectID = 1 then //Выбранный объект - дуга
        DeltaPrimExt := RoundTo(2 * DeltaNet / (4 - Pi), 0);
        if PrimSel.ObjectID = 4 then //Выбранный объект - линия
        DeltaPrimExt := RoundTo((DeltaNet * sin (45 / 180 * Pi)) / (2 * sin (45 / 180 * Pi) -1), 0);
    end
    else //Выбрана куча объектов, т.е. угол между PrimExt = 0, classic mode
    begin
        DeltaPrimExt:=DeltaNet / 2;
    end;



    Violation_Count := 0;
    PrimViolation_Count  := 0;
    DlgOk   := false;

    //Очерчиваем прямоугольник вокруг превого примитива
    Rectangle := SelectedPrims.GetObject(0).BoundingRectangle;


    //DeltaPrimExt не должен быть длинее всех примитивов PrimExt
    for j:=0 to ExtTrimPrims.Count - 1 do
    begin
        PrimExt := ExtTrimPrims.GetObject(j);
        LenPrimExt := RoundTo(sqrt (sqr(PrimExt.X2 - PrimExt.X1) + sqr(PrimExt.Y2 - PrimExt.Y1)), 0);
        if (abs(DeltaPrimExt) > LenPrimExt) and (DeltaPrimExt > 0) and (DeltaNet < 0) then
            DeltaPrimExt := LenPrimExt;
        if (abs(DeltaPrimExt) > LenPrimExt) and (DeltaPrimExt < 0) and (DeltaNet < 0) then
            DeltaPrimExt := - LenPrimExt;
    end;



    //корректировка ByX, ByY если смещение больше длины отрезка
   { for j:=0 to ExtTrimPrims.Count - 1 do
    begin
        PrimExt := ExtTrimPrims.GetObject(j);
        PrimExtA := strtofloat(ExtTrimPrims[j]);

        //Определяем delta X, delta Y с округлением до 0

        if DeltaPrimExt < 0 then
        if (abs(PrimExt.X2 - PrimExt.X1) < abs(ByX)) or
           (abs(PrimExt.Y2 - PrimExt.Y1) < abs(ByY))
        then
        begin
            if ByX < 0 then ByX := - abs(PrimExt.X2 - PrimExt.X1);
            if ByX > 0 then ByX := abs(PrimExt.X2 - PrimExt.X1);
            if ByY < 0 then ByY := - abs(PrimExt.Y2 - PrimExt.Y1);
            if ByY > 0 then ByY := abs(PrimExt.Y2 - PrimExt.Y1);
            DlgOk := true; //end if not(DlgOk)
        end;

    end;  }

    PCBServer.PreProcess;

    for j:=0 to ExtTrimPrims.Count - 1 do
    begin
        PrimExt := ExtTrimPrims.GetObject(j);
        PrimExtA := strtofloat(ExtTrimPrims[j]);

        ByX := - (RoundTo(DeltaPrimExt * cos(PrimExtA / 180 * Pi),0));
        ByY := - (RoundTo(DeltaPrimExt * sin(PrimExtA / 180 * Pi),0));

        PCBServer.SendMessageToRobots(
                    PrimExt.I_ObjectAddress,
                    c_Broadcast,
                    PCBM_BeginModify ,
                    c_NoEventData);



        if (PrimExtA > 270) or (PrimExtA <= 90) then
        //boolMoveAndResizePrimSel
        begin

            if boolMoveAndResizePrimSel
            then
                for i := 0 to SelectedPrims.Count - 1 do
                begin
                    PrimSel := SelectedPrims.GetObject(i);

                    if PrimSel.ObjectID = 4 then //Selected object is track
                    begin
                        if ((PrimSel.X1 = PrimExt.X1) and (PrimSel.Y1 = PrimExt.Y1))
                        then
                        begin                                      PCBServer.SendMessageToRobots(PrimSel.I_ObjectAddress, c_Broadcast, PCBM_BeginModify, c_NoEventData);
                            PrimSel.X1 := PrimSel.X1 + ByX;
                            PrimSel.Y1 := PrimSel.Y1 + ByY;        PCBServer.SendMessageToRobots(PrimSel.I_ObjectAddress, c_Broadcast, PCBM_EndModify, c_NoEventData);
                            break;
                        end;

                        if ((PrimSel.X2 = PrimExt.X1) and (PrimSel.Y2 = PrimExt.Y1))
                        then
                        begin                                      PCBServer.SendMessageToRobots(PrimSel.I_ObjectAddress, c_Broadcast, PCBM_BeginModify, c_NoEventData);
                            PrimSel.X2 := PrimSel.X2 + ByX;
                            PrimSel.Y2 := PrimSel.Y2 + ByY;        PCBServer.SendMessageToRobots(PrimSel.I_ObjectAddress, c_Broadcast, PCBM_EndModify, c_NoEventData);
                            break;
                        end;
                    end;

                    if (PrimSel.ObjectID = 1) and (PrimSel.Net = PrimExt.Net) then //Selected object is arc
                    begin
                        {if ((PrimSel.StartX = PrimExt.X1) and (PrimSel.StartY = PrimExt.Y1)) or
                           ((PrimSel.EndX = PrimExt.X1) and (PrimSel.EndY = PrimExt.Y1))
                        then  }
                        begin
                                                                              PCBServer.SendMessageToRobots(PrimSel.I_ObjectAddress, c_Broadcast, PCBM_BeginModify, c_NoEventData);
                            PrimSel.XCenter := PrimSel.XCenter + ByX;
                            PrimSel.YCenter := PrimSel.YCenter + ByY;         PCBServer.SendMessageToRobots(PrimSel.I_ObjectAddress, c_Broadcast, PCBM_EndModify, c_NoEventData);
                            break;
                        end;
                    end;

                end; //if boolMoveAndResizePrimSel

            // Будем править PrimExt
            PCBServer.SendMessageToRobots(PrimExt.I_ObjectAddress, c_Broadcast, PCBM_BeginModify, c_NoEventData);
            //Если перемещаемся на длину отрезка
            if (abs(PrimExt.X2 - PrimExt.X1) - abs(ByX) < 1) and
               (abs(PrimExt.Y2 - PrimExt.Y1) - abs(ByY) < 1) and
                DeltaNet < 0
                then // точность 0.0001 mil
            begin
                //Delete PrimExt
                Board.RemovePCBObject(PrimExt);
               // ShowMessage('Delete1!');
            end
            else   //else modify
            begin
                PrimExt.X1 := PrimExt.X1 + ByX;
                PrimExt.Y1 := PrimExt.Y1 + ByY;
            end;
            PCBServer.SendMessageToRobots(PrimExt.I_ObjectAddress, c_Broadcast, PCBM_EndModify, c_NoEventData);
            // Закончили правку PrimExt

        end
        else  //PrimExtA > 90) and (PrimExtA <= 270)
        begin

            if boolMoveAndResizePrimSel
            then
                for i := 0 to SelectedPrims.Count - 1 do
                begin
                    PrimSel := SelectedPrims.GetObject(i);

                    if PrimSel.ObjectID = 4 then //Selected object is track
                    begin
                        if ((PrimSel.X1 = PrimExt.X2) and (PrimSel.Y1 = PrimExt.Y2))
                        then
                        begin                                      PCBServer.SendMessageToRobots(PrimSel.I_ObjectAddress, c_Broadcast, PCBM_BeginModify, c_NoEventData);
                            PrimSel.X1 := PrimSel.X1 + ByX;
                            PrimSel.Y1 := PrimSel.Y1 + ByY;        PCBServer.SendMessageToRobots(PrimSel.I_ObjectAddress, c_Broadcast, PCBM_EndModify, c_NoEventData);
                            break;
                        end;
                        if ((PrimSel.X2 = PrimExt.X2) and (PrimSel.Y2 = PrimExt.Y2))
                        then
                        begin                                      PCBServer.SendMessageToRobots(PrimSel.I_ObjectAddress, c_Broadcast, PCBM_BeginModify, c_NoEventData);
                            PrimSel.X2 := PrimSel.X2 + ByX;
                            PrimSel.Y2 := PrimSel.Y2 + ByY;        PCBServer.SendMessageToRobots(PrimSel.I_ObjectAddress, c_Broadcast, PCBM_EndModify, c_NoEventData);
                            break;
                        end;
                    end;

                    if (PrimSel.ObjectID = 1) and (PrimSel.Net = PrimExt.Net) then //Selected object is arc
                    begin
                       { if ((PrimSel.StartX = PrimExt.X2) and (PrimSel.StartY = PrimExt.Y2)) or
                           ((PrimSel.EndX = PrimExt.X2) and (PrimSel.EndY = PrimExt.Y2))
                        then  }
                        begin
                                                                              PCBServer.SendMessageToRobots(PrimSel.I_ObjectAddress, c_Broadcast, PCBM_BeginModify, c_NoEventData);
                            PrimSel.XCenter := PrimSel.XCenter + ByX;
                            PrimSel.YCenter := PrimSel.YCenter + ByY;         PCBServer.SendMessageToRobots(PrimSel.I_ObjectAddress, c_Broadcast, PCBM_EndModify, c_NoEventData);
                            break;
                        end;
                    end;


                end;

            // Будем править PrimExt
            PCBServer.SendMessageToRobots(PrimExt.I_ObjectAddress, c_Broadcast, PCBM_BeginModify, c_NoEventData);
            if (abs(PrimExt.X2 - PrimExt.X1) - abs(ByX) < 1) and
               (abs(PrimExt.Y2 - PrimExt.Y1) - abs(ByY) < 1) and
                DeltaNet < 0
                then // точность 0.0001 mil
            begin
                Board.RemovePCBObject(PrimExt);
            end
            else
            begin
                PrimExt.X2 := PrimExt.X2 + ByX;
                PrimExt.Y2 := PrimExt.Y2 + ByY;
            end;
            PCBServer.SendMessageToRobots(PrimExt.I_ObjectAddress, c_Broadcast, PCBM_EndModify, c_NoEventData);
            // Закончили правку PrimExt

        end; //end of else PrimExtA > 90) and (PrimExtA <= 270)

        PCBServer.SendMessageToRobots(
                    PrimExt.I_ObjectAddress,
                    c_Broadcast,
                    PCBM_EndModify ,
                    c_NoEventData);


        PrimExt.GraphicallyInvalidate;
        if boolMoveAndResizePrimSel then PrimSel.GraphicallyInvalidate;

        //Добавляем к нашему прямоугольнику
        if PrimExt.BoundingRectangle.Left   < Rectangle.Left    then Rectangle.Left   := PrimExt.BoundingRectangle.Left;
        if PrimExt.BoundingRectangle.Bottom < Rectangle.Bottom  then Rectangle.Bottom := PrimExt.BoundingRectangle.Bottom;
        if PrimExt.BoundingRectangle.Right  > Rectangle.Right   then Rectangle.Right  := PrimExt.BoundingRectangle.Right;
        if PrimExt.BoundingRectangle.Top    > Rectangle.Top     then Rectangle.Top    := PrimExt.BoundingRectangle.Top;

    end; //for j:=0 to ExtTrimPrims.Count-1 do

   //Или выделен один объект или выделено два и
   //Вариант 3 - Выделено 2 цепи, являющихся частью одной диффпары
    if boolMoveAndResizePrimSel then
    begin //При условии, что угол между PrimExt = 90
        for i := 0 to SelectedPrims.Count - 1 do
        begin
            PrimSel := SelectedPrims.GetObject(i);
            if PrimSel.ObjectID = 1 then   // только для дуг
            begin
                PCBServer.SendMessageToRobots(
                            PrimSel.I_ObjectAddress,
                            c_Broadcast,
                            PCBM_BeginModify ,
                            c_NoEventData);

                PrimSel.Radius := PrimSel.Radius - DeltaPrimExt;

                PCBServer.SendMessageToRobots(
                            PrimSel.I_ObjectAddress,
                            c_Broadcast,
                            PCBM_EndModify ,
                            c_NoEventData);


                PrimSel.GraphicallyInvalidate;

                if PrimSel.BoundingRectangle.Left   < Rectangle.Left    then Rectangle.Left   := PrimSel.BoundingRectangle.Left;
                if PrimSel.BoundingRectangle.Bottom < Rectangle.Bottom  then Rectangle.Bottom := PrimSel.BoundingRectangle.Bottom;
                if PrimSel.BoundingRectangle.Right  > Rectangle.Right   then Rectangle.Right  := PrimSel.BoundingRectangle.Right;
                if PrimSel.BoundingRectangle.Top    > Rectangle.Top     then Rectangle.Top    := PrimSel.BoundingRectangle.Top;
            end;
        end;  //for i := 0 to SelectedPrims.Count - 1 do
    end;   //if boolMoveAndResizePrimSel


   //Классический вариант: двигаем SelectedPrims 1 раз.
    if not(boolMoveAndResizePrimSel) then
    begin
        for i := 0 to SelectedPrims.Count - 1 do
        begin
            PrimSel := SelectedPrims.GetObject(i);

            PCBServer.SendMessageToRobots(
                        PrimSel.I_ObjectAddress,
                        c_Broadcast,
                        PCBM_BeginModify ,
                        c_NoEventData);

            PrimSel.MoveByXY(ByX,ByY);

            PCBServer.SendMessageToRobots(
                        PrimSel.I_ObjectAddress,
                        c_Broadcast,
                        PCBM_EndModify ,
                        c_NoEventData);


            PrimSel.GraphicallyInvalidate;

            if PrimSel.BoundingRectangle.Left   < Rectangle.Left    then Rectangle.Left   := PrimSel.BoundingRectangle.Left;
            if PrimSel.BoundingRectangle.Bottom < Rectangle.Bottom  then Rectangle.Bottom := PrimSel.BoundingRectangle.Bottom;
            if PrimSel.BoundingRectangle.Right  > Rectangle.Right   then Rectangle.Right  := PrimSel.BoundingRectangle.Right;
            if PrimSel.BoundingRectangle.Top    > Rectangle.Top     then Rectangle.Top    := PrimSel.BoundingRectangle.Top;

        end;  //for i := 0 to SelectedPrims.Count - 1 do
    end;

    PCBServer.PostProcess;

    //DRC
    if CheckBoxRules.Checked then
    begin
    //Создаем счетчик
    BoardIterator := Board.SpatialIterator_Create;
    //Будем проверять по всем объектам на текущем слое
    BoardIterator.AddFilter_LayerSet(MkSet(PrimSel.Layer,eMultiLayer));
    BoardIterator.AddFilter_ObjectSet(AllObjects);

    //Увеличиваем область поиска на 0.5мм вокруг прямоугольника
    BoardIterator.AddFilter_Area(Rectangle.Left -   MMsToCoord(0.5),
                                 Rectangle.Bottom - MMsToCoord(0.5),
                                 Rectangle.Right +  MMsToCoord(0.5),
                                 Rectangle.Top +    MMsToCoord(0.5));

    //Находим первый и второй примитив в этой области
    PrimViolation1 := BoardIterator.FirstPCBObject;

    //PrimViolation_Count := 2;
    //Rule_Count := 0;
    //Violation := nil;
    //Violation_Count := 0;

    while PrimViolation1 <> Nil do
    begin
        //inc(PrimViolation_Count);
        for j := 0 to ExtTrimPrims.Count - 1 do
        begin
            PrimViolation2 := ExtTrimPrims.GetObject(j);
            if PrimViolation1 <> PrimViolation2 then
            begin
            Rule := Board.FindDominantRuleForObjectPair(PrimViolation1, PrimViolation2, eRule_Clearance);
            if Rule <> nil then
            begin
                Board.AddPCBObject(Rule.ActualCheck(PrimViolation1, PrimViolation2));
                PrimViolation1.GraphicallyInvalidate;
                PrimViolation2.GraphicallyInvalidate;
            end;
            end;
        end;

        for i := 0 to SelectedPrims.Count - 1 do
        begin
            PrimViolation2 := SelectedPrims.GetObject(i);
            if PrimViolation1 <> PrimViolation2 then
            begin
            Rule := Board.FindDominantRuleForObjectPair(PrimViolation1, PrimViolation2, eRule_Clearance);
            if Rule <> nil then
            begin
                Board.AddPCBObject(Rule.ActualCheck(PrimViolation1, PrimViolation2));
                PrimViolation1.GraphicallyInvalidate;
                PrimViolation2.GraphicallyInvalidate;
            end;
            end;
        end;

        PrimViolation1 := BoardIterator.NextPCBObject;
    end; //PrimViolation1

    Board.SpatialIterator_Destroy(BoardIterator);

    end; //DRC

    ExtTrimPrims := nil;
    SelectedPrims := nil;
    Net1 := nil;
    Net2 := nil;
    DiffPair := nil;
    NetClass := nil;
    NetClassesList := nil;
    Rectangle := nil;
    PrimExt := nil;
    PrimViolation1 := nil;
    PrimViolation2 := nil;

    Board.ViewManager_FullUpdate;
    close;
 End;

Procedure Start;
begin  // Get the board
   Board := PCBServer.GetCurrentPCBBoard;
   If Board = Nil Then Exit;

   // Now we need to get the signal layers and populate comboBox
   TheLayerStack := Board.LayerStack;
   If TheLayerStack = Nil Then Exit;

   if Board.SelectecObjectCount = 0 then exit;

   MoveToLayer.ShowModal;
end;

Procedure StartAuto;
begin  // Get the board
    RegistryRead;
    Board := PCBServer.GetCurrentPCBBoard;
    if Board = Nil Then Exit;
    if Board.SelectecObjectCount = 0 then exit;

    boolModeManual      := false;
    boolModeDeltaPlus   := false;
    boolModeDeltaMinus  := false;
    MoveSelectObj;
end;

Procedure StartManual;
begin  // Get the board
    RegistryRead;
    Board := PCBServer.GetCurrentPCBBoard;
    if Board = Nil Then Exit;
    if Board.SelectecObjectCount = 0 then exit;

    boolModeManual      := true;
    boolModeDeltaPlus   := false;
    boolModeDeltaMinus  := false;
    MoveSelectObj;
end;

Procedure StartDeltaPlus;
begin  // Get the board
    RegistryRead;
    Board := PCBServer.GetCurrentPCBBoard;
    if Board = Nil Then Exit;
    if Board.SelectecObjectCount = 0 then exit;

    boolModeManual      := false;
    boolModeDeltaPlus   := true;
    boolModeDeltaMinus  := false;
    MoveSelectObj;
end;

Procedure StartDeltaMinus;
begin  // Get the board
    RegistryRead;
    Board := PCBServer.GetCurrentPCBBoard;
    if Board = Nil Then Exit;
    if Board.SelectecObjectCount = 0 then exit;

    boolModeManual      := false;
    boolModeDeltaPlus   := false;
    boolModeDeltaMinus  := true;
    MoveSelectObj;
end;

Procedure StartSet;
begin
    RegistryRead;
    frmMain.Show;
end;

procedure TfrmMain.ButtonOKClick(Sender: TObject);
begin
    RegistryWrite;
    frmMain.Close;
end;

procedure TfrmMain.ButtonCancelClick(Sender: TObject);
begin
   frmMain.Close;
end;
