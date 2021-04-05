//Adjust Net Length v 3.0
Uses Registry;

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

        { закрываем и освобождаем ключ }
        Registry.CloseKey;
    Finally
        Registry.Free;
    End;

End;

procedure MoveSelectObj;
Var

    Iterator        : IPCB_BoardIterator;
    BoardIterator   : IPCB_SpatialIterator;
    FinalLayer      : String;
    Prim            : IPCB_Primitive;
    Prim1           : IPCB_Primitive;
    Prim2           : IPCB_Primitive;
    PrimSel         : IPCB_Primitive;
    PrimExt         : IPCB_Primitive;
    DiffPair        : IPCB_DifferentialPair;
    TrackForNet     : IPCB_Track;
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
    Violation       : IPCB_Violation;
    PrimViolation1  : IPCB_Primitive;
    PrimViolation2  : IPCB_Primitive;
    Rule_Count      : Integer;
    Violation_Count : Integer;
    PrimViolation_Count : Integer;


    SelectedPrims   : TStringList;    //Выделенные примитивы
    ExtTrimPrims    : TStringList;   //Примитивы для удлинения или укорачивания
    DblDetect       : Boolean;      //Определяет найденные дубликаты в TStringList
    PrimExtA        : Real;

    Net1                : IPCB_Net;
    Net2                : IPCB_Net;
    NetTmp              : IPCB_Net;
    NetTarget           : IPCB_Net;
    NetCurrent          : IPCB_Net;     //Текущая цепь в цикле при переборе
    boolMultyNet        : boolean;      //Выбрано несколько цепей
    boolDiffPairNet     : boolean;      //Все (!) выбранные цепи являются частью одной диффпары

    NetClass            : IPCB_ObjectClass;
    NetClassTmp         : IPCB_ObjectClass; //Временный класс цепей дял сравнения
    NetClassesList      : TStringList; //Перечень классов, куда входит наша цепь
    OurNetClassNet      : TstringList; //Перечень цепей в нашем классе
    OurNetClassNetTmp   : TstringList; //Перечень цепей временный
    NetCountMin         : Long;
    NetCountTmp         : Long;
    strNetClass         : string;

    LenNet1       : real;
    LenNetTmp     : real;
    LenNetTarget  : real;
    DeltaNet      : real;
    DeltaNetHalf  : real;
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

    //Создается SelectedPrims : TStringList Лист с именами выбранных примитивов
    SelectedPrims := TStringList.Create;
    //Создается лист с объектами, подсоединенными к выбранным, их нужно будет укоротить или нарастить
    ExtTrimPrims := TStringList.Create;
    j := 0; //Iterator for ExtTrimPrims

        if ((Board.SelectecObject[0].ObjectId <> eTrackObject) and (Board.SelectecObject[0].ObjectId <> eArcObject)) then exit;

        if Board.SelectecObject[0].Net = Nil then exit;

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

        //begin

        //diffname := copy(NetName1, 1, Length(NetName1) - 2);  //От имени цепи отрезаем 2 символа в конце
        //end;

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

        //Очерчиваем прямоугольник, описывающий наш примитив
        Rectangle := PrimSel.BoundingRectangle;

        //Создаем счетчик
        BoardIterator := Board.SpatialIterator_Create;
        //Будем проверять только линии
        BoardIterator.AddFilter_ObjectSet(MkSet(eTrackObject));
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
               (PrimExt.Layer=PrimSel.Layer) and //Примитив должен находиться в одном слое с выделенными объектами
               (PrimExt.Net.Name=PrimSel.Net.Name) //Принадлежать одной цепи
               then

            // если все прошло, проверим попадает ли в Rectangle X и Y
            if (((PrimExt.X1 > Rectangle.Left) and (PrimExt.X1 < Rectangle.Right)) and ((PrimExt.Y1 > Rectangle.Bottom) and (PrimExt.Y1 < Rectangle.Top))) or
               (((PrimExt.X2 > Rectangle.Left) and (PrimExt.X2 < Rectangle.Right)) and ((PrimExt.Y2 > Rectangle.Bottom) and (PrimExt.Y2 < Rectangle.Top)))
               then
            begin
                //Inc(PrimExtFilter);
                if j = 0 then  //Определяем угол только для первого объекта
                begin
                    ExtTrimPrims.AddObject(IntToStr(j), PrimExt);   //Вносим первый объект в ExtTrimPrims
                    inc(j);

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
                    begin   //Если X2 или Y2 совпадает с одной из точек выделенной линии (точность 0.001 mil), то прибавляем 180
                        if  ((RoundTo(PrimExt.X2,+1) = RoundTo(PrimSel.StartX,+1)) and (RoundTo(PrimExt.Y2,+1) = RoundTo(PrimSel.StartY,+1))) or
                            ((RoundTo(PrimExt.X2,+1) = RoundTo(PrimSel.EndX,  +1)) and (RoundTo(PrimExt.Y2,+1) = RoundTo(PrimSel.EndY,  +1)))
                            then PrimExtA := PrimExtA + 180;
                    end;

                    if PrimSel.ObjectID = 4 then //Выбранный объект - линия
                    begin
                        if  ((RoundTo(PrimExt.X2,+1) = RoundTo(PrimSel.X1,+1)) and (RoundTo(PrimExt.Y2,+1) = RoundTo(PrimSel.Y1,+1))) or
                            ((RoundTo(PrimExt.X2,+1) = RoundTo(PrimSel.X2,+1)) and (RoundTo(PrimExt.Y2,+1) = RoundTo(PrimSel.Y2,+1)))
                            then PrimExtA := PrimExtA + 180;
                    end;
                end     // if j = 0

                //Необходимо проверить объекты после первого с теми, что уже есть в наборе ExtTrimPrims
                //Добавлять в набор можно, если такой отсутствует
                else    // if j > 0
                begin
                    DblDetect := false;

                    for j1 := 0 to j - 1 do
                    begin
                        if PrimExt = ExtTrimPrims.GetObject(j1) then  DblDetect := true;
                    end;

                    if not(DblDetect) then
                    begin
                        ExtTrimPrims.AddObject(IntToStr(j), PrimExt);
                        inc(j);
                    end;

                end;

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

   //Если выделена одна цепи и она является частью дифф пары

   if Not(boolMultyNet) and (Board.SelectecObject[0].Net.InDifferentialPair) then
        TuningVariant := 1;
   //Вариант 2  Выделена одна цепь, не являющаяся частью диффпары
   if Not(boolMultyNet) and (Not(Board.SelectecObject[0].Net.InDifferentialPair)) then
        TuningVariant := 2;
    //Вариант 3  Выделено 2 цепи, являющихся частью одной диффпары
   if boolMultyNet and boolDiffPairNet then
        TuningVariant := 3;

    //Вариант 4  Выделено более одной цепи, не являющихся частью одной диффпары
   if boolMultyNet and not(boolDiffPairNet) then
        TuningVariant := 4;


//Вычисляем Net2 только для варианта Auto
if not (boolModeManual or boolModeDeltaPlus or boolModeDeltaMinus) then    //Никто из
begin


    //********************* NET CLASS ********************

    //Если цепь одна и не является частью диффпары, то ищем в NetClass
   if TuningVariant <> 1 then  //Кроме варианта, когда выбрана одна цепь в составе диффпары
   begin
         //Определяем какому классу принадлежит цепь
         //Создаем список классов
         Iterator := Board.BoardIterator_Create;
         Iterator.SetState_FilterAll;
         Iterator.AddFilter_ObjectSet(MkSet(eClassObject));
         NetClass := Iterator.FirstPCBObject;

        //Создаем новые TStringList
         OurNetClassNet := TStringList.Create; //Цепи в нашем классе
         NetClassesList := TStringList.Create; //Классы (их может быть несколько), куда входит наша цепь

         While NetClass <> Nil Do
         begin
         //Если находим класс и входящую в него цепь
            if (NetClass.IsMember(Net1)) and (NetClass.MemberKind = eClassMemberKind_Net) and (NetClass.Name <> 'All Nets') then
            //Вычисляем самую длинную цепь в классе
            begin
                NetClassesList.AddObject(NetClass.Name,NetClass);
                //ComboBoxNetClass.Items.AddObject(NetClass.Name, NetClass);
            end;
         NetClass := Iterator.NextPCBObject;
         end; //NetClass <> Nil
         Board.BoardIterator_Destroy(Iterator);

        NetCountMin := 0;

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

        if NetClassesList.Count > 1 then
        begin
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
            if Not (boolMultyNet and
                    boolDiffPairNet and
                    Net2.InDifferentialPair)
                then
                begin
                    if NetCountTmp = 1 then        //Рассчитываем длину для первой цепи в классе
                    begin
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
        //Проверяем во сколько классов вошла наша цепь
        //Если ни в один, то выходим (или предлагаем мануал...)
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
    //LenNet1 := Net1.;

    //Если выбран ручной режим
    if boolModeManual then
        LenNetTarget := MMsToCoord(strtofloat(editManual.Text));

    //Вычисляем разницу между ними
    DeltaNet:=LenNetTarget-LenNet1;

    if boolModeDeltaPlus then
        DeltaNet := MMsToCoord(strtofloat(editDelta.Text));

    if boolModeDeltaMinus then
        DeltaNet := - MMsToCoord(strtofloat(editDelta.Text));

    DeltaNetHalf:=DeltaNet/2;

    //Определяем delta X, delta Y с округлением до 0
    ByX := - (RoundTo(DeltaNetHalf * cos(PrimExtA / 180 * Pi),0));
    ByY := - (RoundTo(DeltaNetHalf * sin(PrimExtA / 180 * Pi),0));

    Violation_Count := 0;
    PrimViolation_Count  := 0;
    DlgOk   := false;

    //Очерчиваем прямоугольник вокруг превого примитива
    Rectangle := SelectedPrims.GetObject(0).BoundingRectangle;

    //корректировка ByX, ByY если смещение больше длины отрезка
    for j:=0 to ExtTrimPrims.Count - 1 do
    begin
        PrimExt := ExtTrimPrims.GetObject(j);
        if DeltaNetHalf < 0 then
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

    end;

    PCBServer.PreProcess;

    for j:=0 to ExtTrimPrims.Count - 1 do
    begin
        PrimExt := ExtTrimPrims.GetObject(j);

        PCBServer.SendMessageToRobots(
                    PrimExt.I_ObjectAddress,
                    c_Broadcast,
                    PCBM_BeginModify ,
                    c_NoEventData);

        if (PrimExtA > 270) or (PrimExtA <= 90) then
        begin
            PrimExt.X1 := PrimExt.X1 + ByX;
            PrimExt.Y1 := PrimExt.Y1 + ByY;
        end
        else
        begin
            PrimExt.X2 := PrimExt.X2 + ByX;
            PrimExt.Y2 := PrimExt.Y2 + ByY;
        end;

        PCBServer.SendMessageToRobots(
                    PrimExt.I_ObjectAddress,
                    c_Broadcast,
                    PCBM_EndModify ,
                    c_NoEventData);


        PrimExt.GraphicallyInvalidate;

        //Добавялем к нашему прямоугольнику
        if PrimExt.BoundingRectangle.Left   < Rectangle.Left    then Rectangle.Left   := PrimExt.BoundingRectangle.Left;
        if PrimExt.BoundingRectangle.Bottom < Rectangle.Bottom  then Rectangle.Bottom := PrimExt.BoundingRectangle.Bottom;
        if PrimExt.BoundingRectangle.Right  > Rectangle.Right   then Rectangle.Right  := PrimExt.BoundingRectangle.Right;
        if PrimExt.BoundingRectangle.Top    > Rectangle.Top     then Rectangle.Top    := PrimExt.BoundingRectangle.Top;

    end; //for j:=0 to ExtTrimPrims.Count-1 do

    for i := 0 to SelectedPrims.Count - 1 do
    begin
        Prim1 := SelectedPrims.GetObject(i);


        PCBServer.SendMessageToRobots(
                    Prim1.I_ObjectAddress,
                    c_Broadcast,
                    PCBM_BeginModify ,
                    c_NoEventData);

        Prim1.MoveByXY(ByX,ByY);

        PCBServer.SendMessageToRobots(
                    Prim1.I_ObjectAddress,
                    c_Broadcast,
                    PCBM_EndModify ,
                    c_NoEventData);


        Prim1.GraphicallyInvalidate;

        if Prim1.BoundingRectangle.Left   < Rectangle.Left    then Rectangle.Left   := Prim1.BoundingRectangle.Left;
        if Prim1.BoundingRectangle.Bottom < Rectangle.Bottom  then Rectangle.Bottom := Prim1.BoundingRectangle.Bottom;
        if Prim1.BoundingRectangle.Right  > Rectangle.Right   then Rectangle.Right  := Prim1.BoundingRectangle.Right;
        if Prim1.BoundingRectangle.Top    > Rectangle.Top     then Rectangle.Top    := Prim1.BoundingRectangle.Top;

    end;  //for i := 0 to SelectedPrims.Count - 1 do
    PCBServer.PostProcess;

    //DRC
    if CheckBoxRules.Checked then
    begin
    //Создаем счетчик
    BoardIterator := Board.SpatialIterator_Create;
    //Будем проверять по всем объектам на текущем слое
    BoardIterator.AddFilter_LayerSet(MkSet(Prim1.Layer,eMultiLayer));
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

    ExtTrimPrims.Free;
    SelectedPrims.Free;
    if Net1 <> nil then Net1 := nil;
    if Net2 <> nil then Net2 := nil;
    if DiffPair <> nil then DiffPair := nil;
    if Rectangle <> nil then Rectangle := nil;
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

{Procedure StartDelta;
begin  // Get the board
    RegistryRead;
    Board := PCBServer.GetCurrentPCBBoard;
    if Board = Nil Then Exit;
    if Board.SelectecObjectCount = 0 then exit;

    boolModeManual := false;
    boolModeDelta := true;
    MoveSelectObj;
end;  }

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


{

            Violation := Rule.ActualCheck(PrimViolation1, PrimViolation2);
            If Violation <> Nil Then
                begin
                ShowMessage('Violation Name : ' + Violation.Name + #13#10 +
                            'Description    : ' + Violation.Description + #13#10 +
                            'Rule Name      : ' + Rule.Name);
                ShowMessage('Rectangle : ' + #13#10 +
                            'Left   : ' + floattostr(CoordToMMs(Rectangle.Left)   - 1000) + #13#10 +
                            'Bottom : ' + floattostr(CoordToMMs(Rectangle.Bottom) -  500) + #13#10 +
                            'Right  : ' + floattostr(CoordToMMs(Rectangle.Right)  - 1000) + #13#10 +
                            'Top    : ' + floattostr(CoordToMMs(Rectangle.Top)    -  500) + #13#10 +
                            'Rectangle + Delta : ' + #13#10 +
                            'Left   : ' + floattostr(CoordToMMs(Rectangle.Left   -   (abs(DeltaNetHalf) + MMsToCoord(0.5))) - 1000) + #13#10 +
                            'Bottom : ' + floattostr(CoordToMMs(Rectangle.Bottom -   (abs(DeltaNetHalf) + MMsToCoord(0.5))) -  500) + #13#10 +
                            'Right  : ' + floattostr(CoordToMMs(Rectangle.Right  -   (abs(DeltaNetHalf) + MMsToCoord(0.5))) - 1000) + #13#10 +
                            'Top    : ' + floattostr(CoordToMMs(Rectangle.Top    -   (abs(DeltaNetHalf) + MMsToCoord(0.5))) -  500)
                            );

                inc(Violation_Count);
                end;
            //Violation.
             inc(Rule_Count);

}

        //showmessage(PrimViolation1.ObjectIDString + ' ' + PrimViolation2.ObjectIDString);

      {  ShowMessage('PrimViolation1     : ' + #13#10 +
                    'ObjectIDString     : ' + PrimViolation1.ObjectIDString + #13#10 +
                    'Layer              : ' + Layer2String(PrimViolation1.Layer) + #13#10 +
                    'Index              : ' + IntToStr(PrimViolation1.Index) + #13#10 +
                    'Selected           : ' + booltostr(PrimViolation1.Selected) + #13#10 +
                    'DRC           : ' + booltostr(PrimViolation1.DRCError) + #13#10 +
                    #13#10 +
                    'PrimViolation2     : ' + #13#10 +
                    'ObjectIDString     : ' + PrimViolation2.ObjectIDString + #13#10 +
                    'Layer              : ' + Layer2String(PrimViolation2.Layer) + #13#10 +
                    'Index              : ' + IntToStr(PrimViolation2.Index) + #13#10 +
                    'Selected           : ' + booltostr(PrimViolation2.Selected) + #13#10 +
                    #13#10 +
                    'Violation_Count    : ' + IntToStr(Violation_Count));
                                                         }
{        if Rule <> nil then
        begin
            //ShowMessage('Rule Name : ' + Rule.Name);
            inc(Rule_Count);
            Board.AddPCBObject(Rule.ActualCheck(PrimViolation1, PrimViolation2));

            Violation := Rule.ActualCheck(PrimViolation1, PrimViolation2);
            If Violation <> Nil Then inc(Violation_Count);

            //PrimViolation1.GraphicallyInvalidate;
            PrimViolation2.GraphicallyInvalidate;
        end;
                            }

