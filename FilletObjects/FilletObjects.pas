Uses Registry;

const
    e = 0.001; //0.001 mil
    e_TCoord = 10; //e в системе единицах TCoord, = 0.001 mil,

var
    x_click_obj1, y_click_obj1,
    x_click_obj2, y_click_obj2          : Double;
    Arc                                 : IPCB_Arc;     // Добавляемая дуга
    Arc_CenterX, Arc_CenterY            : Double;       // Центр добавляемой дуги
    Angle1, Angle2                      : Double;       // предварительные углы для построения дуги (не определено начало и конец)
    Arc_Start_A, Arc_End_A              : Double;       // Окончательные углы для построения
    Arc_R                               : Double;       // Радиус добавляемой дуги

    Extcut                              : boolean;
    EmergencyExit                       : boolean;      // Аварийный выход из программы

procedure RegistryRead;
var
    Registry  : TRegistry;
    Arc_R_Str : String;
Begin
    { создаём объект TRegistry }
    Registry := TRegistry.Create;
    Try
        { устанавливаем корневой ключ; напрмер hkey_local_machine или hkey_current_user }
        //Registry.RootKey := HKEY_CURRENT_USER; {Устанавливается автоматически}
        { открываем и создаём ключ }
        Registry.OpenKey('Software\AltiumScripts\FilletObjects',true);

        if Registry.ValueExists('Radius')           then    Arc_R_Str           := Registry.ReadString('Radius');
     //   if Registry.ValueExists('Disable LiveHL')   then    cb_livehl.Checked   := Registry.ReadBool('Disable LiveHL');

        { закрываем и освобождаем ключ }
        Registry.CloseKey;
    Finally
        Registry.Free;
    End;
    editRadius.Text:=Arc_R_Str;
    Arc_R := strtofloat(Arc_R_Str) / 0.0254;  // MMsToMils ;)
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
        Registry.OpenKey('Software\AltiumScripts\FilletObjects',true);
        { записываем значения }

        Registry.WriteString('Radius',   floattostr(Arc_R));
        //Registry.WriteBool('Disable LiveHL', cb_livehl.Checked);
        { закрываем и освобождаем ключ }
        Registry.CloseKey;
    Finally
        Registry.Free;
    End;

End;

function LengthOfLine(Const x1, y1, x2, y2 : Double) : Double;
begin
    Result := sqrt(sqr(x1 - x2) + sqr(y1 - y2));
end;

// точка пересечения двух линий, заданных координатами
// x1, y1, x2, y2 - первая линия
// x3, y3, x4, y4 - вторая линия
procedure CrossOfLineXY(Const x1, y1, x2, y2, x3, y3, x4, y4: Double; Out x, y : Double);
begin
    x := 0;
    y := 0;
    if (abs(x1 - x2) < e) and (abs(x3 - x4) < e) or
       (abs((y2 - y1)*(x4 - x3) - (y4 - y3)*(x2 - x1)) < e)
    then
        begin
            ShowMessage('Отрезки параллельны (proc CrossOfLineXY trouble)');
            EmergencyExit := True;
            exit;
        end
    else //else lvl1
        begin
            if abs(x1 - x2) < e then x := x1; //Первая линия вертикальная
            if abs(x3 - x4) < e then x := x3; //Вторая линия вертикальная
            if abs(y1 - y2) < e then y := y1; //Первая линия горизонтальная
            if abs(y3 - y4) < e then y := y3; //Вторая линия горизонтальная

            //Обе не вертикальные, ищем X
            if (x<>x1) and (x<>x3) then x:=-((x1*y2-x2*y1)*(x4-x3)-(x3*y4-x4*y3)*(x2-x1))/((y1-y2)*(x4-x3)-(y3-y4)*(x2-x1));
            if (y<>y1) and (y<>y3) and (abs(x3-x4) > e) then y:=((y3-y4)*(-x)-(x3*y4-x4*y3))/(x4-x3);
            if (y<>y1) and (y<>y3) and (abs(x3-x4) < e) then y:=y1-((y2-y1)*(x1-x)/(x2-x1));
        end; //else lvl1
end;

// Две точки по одну сторону линии, x1 y1 x2 y2 - координаты линии.
function TwoPointOneSideOfLine(Const x1, y1, x2, y2, point1_x, point1_y, point2_x, point2_y : Double) : boolean;
var
    //L1, L2, LTotal  : double;
    //x_fict_cross, y_fict_cross  : double;
    D1, D2      : Double;
begin
    // А(х1,у1), Б(х2,у2), С(х3,у3). Через точки А и Б проведена прямая
    // D = (х3 - х1) * (у2 - у1) - (у3 - у1) * (х2 - х1)
    // - Если D = 0 - значит, точка С лежит на прямой АБ.
    // - Если D < 0 - значит, точка С лежит слева от прямой.
    // - Если D > 0 - значит, точка С лежит справа от прямой.
    D1 := (point1_x - x1) * (y2 - y1) - (point1_y - y1) * (x2 - x1);
    D2 := (point2_x - x1) * (y2 - y1) - (point2_y - y1) * (x2 - x1);

    Result := false;

    if (D1 <= 0) and (D2 <= 0) then Result := true;
    if (D1 >= 0) and (D2 >= 0) then Result := true;

end;

function PointToLineDistance(Const x1, y1, x2, y2, x0, y0 : Double) : Double;
begin
    //линия горизонтальная
    if abs(y2 - y1) < e then Result := abs(y1 - y0);

    //линия вертикальная
    if abs(x2 - x1) < e then Result := abs(x1 - x0);

    //Линия под углом
    if ((x2 - x1) <> 0) and ((y2 - y1) <> 0) then
    begin
        Result := abs((y2 - y1)*x0 - (x2 - x1)*y0 + x2*y1 - y2*x1) / sqrt(sqr(y2 - y1) + sqr(x2 - x1));
    end;
end;

// Определение угла между точками в диапазоне от 0 до 359.99
function DetectAngle360 (Const x1, y1, x2, y2 : Double) : Double;
begin
    // устраняем 10E-13..
    if abs(x1 - x2) < e then x1 := x2;
    if abs(y1 - y2) < e then y1 := y2;

    if (x1 = x2) or (y1 = y2) then
    begin
        if (x1 = x2) then if (y2 > y1) then Result := 90 else Result := 270;
        if (y1 = y2) then if (x2 > x1) then Result := 0 else Result := 180;
    end
    else
    begin
        Result := arctan2(y2 - y1, x2 - x1) / Pi * 180;
        // Заталкиваем в диапазон от 0 до 359.99
        if Result >= 360 then Result := Result - 360;
        if Result < 0 then Result := Result + 360;
    end;
end;

procedure DetectArcStartEndAngle (Const Ang1, Ang2: Double; Out AngStart, AngEnd : Double);
begin
    AngStart := Ang2;   //238
    AngEnd   := Ang1;   //101

    if (Ang1 - Ang2 > 180) or ((Ang1 - Ang2 < 0) and (Ang1 - Ang2 > -180)) then
    begin
        AngStart := Ang1;
        AngEnd   := Ang2;
    end;
end;

// Перетащить углы < 0 и > 360 в диапазон 0..360
function AngleTo360 (Const ang : Double) : Double;
begin
    Result := ang;
    if ang >= 360 then Result := ang - 360;
    if ang < 0 then Result := ang + 360;
end;

// угол между отрезками, с известными углами
function AbsoluteDeltaAngle(Const Ang1, Ang2: Double) : Double;
begin
    Result := abs(Ang1 - Ang2);
    if Result > 180 then
    begin
        Result := abs(Result - 360);
    end;
end;

// Вычисление биссектрисы
function DetectBisectrix (Const Ang1, Ang2 : Double) : Double;
begin
    if Ang2 < Ang1 then // перешагнули через 360
        Ang2 := Ang2 + 360;

    Result := (Ang2 + Ang1) / 2;
    AngleTo360(Result);
end;

// Определние угла в диапазоне от -90 до 90 включительно (подумать над удалением)
function DetectAngle (Const x1, y1, x2, y2 : Double) : Double;
var
    Result_A :      real;
begin
    Result_A := arctan2(y2 - y1, x2 - x1) / Pi * 180;
    if (Result_A = 90) and (y2 < y1) then Result_A := -90;
    if x2 < x1 then showmessage('Problem: x2 < x1');
    Result := Result_A;
end;

procedure CircleLineCross(Const x1, y1, x2, y2, xa, ya, ra: Double; Out x1_Cross, y1_Cross, x2_Cross, y2_Cross: Double);
var //x,x0,y,y0,r,a,b,c,a1,b1,c1,d,x1,y1,x2,y2:real;

    k, b                : Double; //коэф уравнения прямой
    cx, cy, cr          : Double; //коэф уравнения окружности
    aa, bb, cc, d       : Double; //коэф кв. уравнения

begin
    x1_Cross := 0;
    y1_Cross := 0;
    x2_Cross := 0;
    y2_Cross := 0;

    //Смещаем начало координат в центр окружности
    //Координаты прямой если центром координат будет центр окружности
    x1 := x1 - xa;
    y1 := y1 - ya;
    x2 := x2 - xa;
    y2 := y2 - ya;

    if abs(y2 - y1) < e then y2 := y1;
    if abs(x2 - x1) < e then x2 := x1;

    if y2 - y1 = 0 then     //линия горизонтальная
    begin
        if (abs(abs(y1) - ra) < e) and (abs(abs(y2) - ra) < e) then   //касается в одной точке в 90° b 270°
        begin
            x1_Cross := 0;
            y1_Cross := y1;
            x2_Cross := 0;
            y2_Cross := y2;
        end
        else
        begin
            if (abs(y1) < ra) and (abs(y2) < ra) then   //пересекает окружность в двух точках
            begin
                x1_Cross := - sqrt(sqr(ra) - sqr(y1));
                y1_Cross := y1;
                x2_Cross := sqrt(sqr(ra) - sqr(y1));
                y2_Cross := y2;
            end;
            if (abs(y1) > ra) and (abs(y2) > ra) then   //не пересекает
            begin
                ShowMessage('Линия не пересекает окружность! [procedure CircleLineCross] (Горизонтальная)');
            end;
        end;
    end;

    if x2 - x1 = 0 then     //линия вертикальная
    begin
        if (abs(abs(x1) - ra) < e) and (abs(abs(x2) - ra) < e) then   //касается в одной точке в 90° b 270°
        begin
            x1_Cross := x1;
            y1_Cross := 0;
            x2_Cross := x2;
            y2_Cross := 0;
        end
        else
        begin
            if (abs(x1) < ra) and (abs(x2) < ra) then   //пересекает окружность в двух точках
            begin
                x1_Cross := x1;
                y1_Cross := - sqrt(sqr(ra) - sqr(x1));
                x2_Cross := x2;
                y2_Cross := sqrt(sqr(ra) - sqr(x1));
            end;
            if (abs(x1) > ra) and (abs(x2) > ra) then   //не пересекает
            begin
                ShowMessage('Линия не пересекает окружность! [procedure CircleLineCross] (Вертикальная)');
            end;
        end;
    end;

    if ((x2 - x1) <> 0) and ((y2 - y1) <> 0) then  //Линия под углом
        begin
        //Коэффициенты прямой если центром координат будет центр окружности
        k := (y2 - y1) / (x2 - x1);                     //k = 0.2
        b := (x2 * y1 - x1 * y2)/(x2 - x1);             //b = 2.980

        //Коэфф. окружности при центре окружности в координатах 0,0
        cx := xa;                              //cx = 25
        cy := ya;                              //cy = 6
        //Радиус окружности
        cr := ra;                   //cr = 4


        aa := k * k + 1;                        //aa = 1.04
        bb := 2 * k * b;                        //bb = 1.192
        cc := b * b - cr * cr;                  //cc = -7.118
        d  := bb * bb - 4 * aa * cc;             //d = 31.033

        if (abs(d) < e) then d := 0;

        if d < 0 then
        begin
            ShowMessage('Линия не пересекает окружность! [procedure CircleLineCross] (Наклонная)');
            //halt;
        end;

        if d =0 then //т.е. d = 0, 1 точка
        begin
            x1_Cross := -bb / (2 * aa);
            y1_Cross := k * x1_Cross + b;
            x2_Cross := x1_Cross;
            y2_Cross := y1_Cross;
        end;

        if d > 0 then
        begin
            //точки пересечения псевдолинии с псевдоокружностью
            x1_Cross := (-bb - sqrt(d)) / (2 * aa);      //x1_lc = -3.251
            y1_Cross := k * x1_Cross + b;                   //y1_lc = 2.329

            x2_Cross := (-bb + sqrt(d)) / (2 * aa);      //x2_lc = 2.105
            y2_Cross := k * x2_Cross + b;                   //y2_lc = 3.401
        end;
    end;

    //возвращаем начало координат из центра окружности в 0,0
    x1_Cross := x1_Cross + xa;
    y1_Cross := y1_Cross + ya;
    x2_Cross := x2_Cross + xa;
    y2_Cross := y2_Cross + ya;

end;

procedure CirclesCross(Const xa1, ya1, ra1, xa2, ya2, ra2 : Double; Out x1_cross, y1_cross, x2_cross, y2_cross : Double);
var
    d                       : Double;   // Расстояние между центрами
    a, h                    : Double;   //
    CenterToCenterAngle     : Double;   // Угол между центрами от Arc1 до Arc2
    xp3, yp3                : Double;   // вспомогательная псевдо-точка пересечения линии между центрами
                                        // и линии между точками пересечения
begin
    x1_Cross := 0;
    y1_Cross := 0;
    x2_Cross := 0;
    y2_Cross := 0;

    d := LengthOfLine(xa1, ya1, xa2, ya2);
    if d > (ra1 + ra2) then // расстояние между окружностями больше 2-х радиусов
    begin
        ShowMessage('Circles do not cross! [procedure CirclesCross] d > (ra1 + ra2)');
        EmergencyExit := true;
        exit;
    end;

    if d < abs(ra1 - ra2) then  // Одна окружность внутри другой, не пересекаются
    begin
        ShowMessage('Circles do not cross! [procedure CirclesCross] d < abs(ra1 - ra2)');
        EmergencyExit := true;
        exit;
    end;

    // угол между центрами
    CenterToCenterAngle := DetectAngle360(xa1, ya1, xa2, ya2);

    if abs(d - (ra1 + ra2)) < e then // Одна точка пересечения
    begin
        x1_cross := xa1 + ra1 * cos(CenterToCenterAngle / 180 * Pi);
        y1_cross := ya1 + ra1 * sin(CenterToCenterAngle / 180 * Pi);
        x2_cross := x1_cross;
        y2_cross := y1_cross;
    end;

    // Окружности пересекаются и делают это в двух точках
    a := (sqr(ra1) - sqr(ra2) + sqr(d)) / (2 * d);
    h := sqrt(sqr(ra1) - sqr(a));

    xp3 := xa1 + a * cos(CenterToCenterAngle / 180 * Pi);
    yp3 := ya1 + a * sin(CenterToCenterAngle / 180 * Pi);

    x1_cross := xp3 + h/d * (ya2 - ya1);
    y1_cross := yp3 - h/d * (xa2 - xa1);

    x2_cross := xp3 - h/d * (ya2 - ya1);
    y2_cross := yp3 + h/d * (xa2 - xa1);

end;

// Определение угла от точки до линии по нормали в диапазоне от 0 до 359.99
function DetectAngleFromPointToLine (Const x, y, x1, y1, x2, y2 : Double) : Double;
var
    distance_to_line        : Double;   // Расстояние от точки до линии
    x_normal, y_normal      : Double; // Точка подведения нормали к линии от исходной точки
    x_normal_tmp, y_normal_tmp      : Double; // Временные точки для корректного срабатывания процедуры CircleLineCross
begin
    // устраняем 10E-13..
    if abs(x1 - x2) < e then x1 := x2;
    if abs(y1 - y2) < e then y1 := y2;

    if (x1 = x2) or (y1 = y2) then
    begin
        if (x1 = x2) then if (x < x1) then Result := 0 else Result := 180;
        if (y1 = y2) then if (y < y1) then Result := 90 else Result := 270;
    end
    else
    begin
        distance_to_line := PointToLineDistance(x1, y1, x2, y2, x, y);
        CircleLineCross(x1, y1, x2, y2, x, y, distance_to_line, x_normal, y_normal, x_normal_tmp, y_normal_tmp);
        Result := arctan2(y_normal - y, x_normal - x) / Pi * 180;
        // Заталкиваем в диапазон от 0 до 359.99
        if Result >= 360 then Result := Result - 360;
        if Result < 0 then Result := Result + 360;
    end;
end;

// Средняя точка линии
procedure MidPointOfLine(Const x1, y1, x2, y2 : Double; Out x_mid, y_mid: Double);
begin
    x_mid := (x1 + x2) / 2;
    y_mid := (y1 + y2) / 2;
end;

// Средняя точка дуги если входящие угол начала и конца
procedure MidPointOfArcByAngle(Const xa, ya, ra, start_a, end_a : Double; Out x_mid, y_mid: Double);
var
    mid_a       : Double;
begin
    mid_a := DetectBisectrix(start_a, end_a);

    x_mid := xa + ra * cos(mid_a / 180 * Pi);
    y_mid := ya + ra * sin(mid_a / 180 * Pi);
end;

procedure FilletTracks(Const Track1 : IPCB_Track, Track2 : IPCB_Track);
var
    x1, y1, x2, y2                  : Double;  // координаты линии 1
    x_line1_mid, y_line1_mid        : Double;  // центр линии 1
    ang_line1                       : Double;   // угол линии 1
    x3, y3, x4, y4                  : Double;  // координаты линии 2
    x_line2_mid, y_line2_mid        : Double;  // центр линии 2
    ang_line2                       : Double;   // угол линии 2

    x, y                            : Double;  // точка пересечения линий

    x1p_inside, y1p_inside, x2p_inside, y2p_inside                      : Double;  // координаты псевдо линии 1 при смещении внутрь
    x3p_inside, y3p_inside, x4p_inside, y4p_inside                      : Double;  // координаты псевдо линии 2 при смещении внутрь
    x1p_outside, y1p_outside, x2p_outside, y2p_outside                  : Double;  // координаты псевдо линии 1 при смещении внаружу
    x3p_outside, y3p_outside, x4p_outside, y4p_outside                  : Double;  // координаты псевдо линии 2 при смещении внаружу

    xp_inside, yp_inside                          : Double;   // координаты пересечения внутренних псевдо линий
    xp_outside, yp_outside                          : Double;   // координаты пересечения наружних псевдо линий

    ang1, ang2      : Double; // углы скругления, неподготовленные

    new_x_line1, new_y_line1,
    new_x_line2, new_y_line2            : Double;   // Новые координаты линий
begin
    x1 := CoordToMils(Track1.x1);
    y1 := CoordToMils(Track1.y1);
    x2 := CoordToMils(Track1.x2);
    y2 := CoordToMils(Track1.y2);

    x3 := CoordToMils(Track2.x1);
    y3 := CoordToMils(Track2.y1);
    x4 := CoordToMils(Track2.x2);
    y4 := CoordToMils(Track2.y2);

    CrossOfLineXY(x1, y1, x2, y2, x3, y3, x4, y4, x, y);
    if EmergencyExit then exit;

    MidPointOfLine(x1, y1, x2, y2, x_line1_mid, y_line1_mid);
    MidPointOfLine(x3, y3, x4, y4, x_line2_mid, y_line2_mid);

    // Если объекты вызваны кликом, а не были в наборе до запуска программы,
    // Переопределим arc_mid, будем за опорную точку считать click_obj
  {  if ((x_click_obj1 <> nil) and (y_click_obj1 <> nil) and (x_click_obj2 <> nil) and (y_click_obj2 <> nil))
    then
    begin
        x_line1_mid := x_click_obj1;
        y_line1_mid := y_click_obj1;
        x_line2_mid := x_click_obj2;
        y_line2_mid := y_click_obj2;
    end;
    // С треками не прокатило...
   }
    // Определяем углы линий
    // Измеряем относительно точки пересечения
    ang_line1 := DetectAngle360(x, y, x_line1_mid, y_line1_mid);
    ang_line2 := DetectAngle360(x, y, x_line2_mid, y_line2_mid);

    // Строим псевдо линии с двух сторон от Track1
    // Смещение перпендикулярно линиям, поэтому sin <-> cos
    x1p_inside := x1 - Arc_R * sin(ang_line1 / 180 * Pi);
    y1p_inside := y1 + Arc_R * cos(ang_line1 / 180 * Pi);
    x2p_inside := x2 - Arc_R * sin(ang_line1 / 180 * Pi);
    y2p_inside := y2 + Arc_R * cos(ang_line1 / 180 * Pi);

    x1p_outside := x1 + Arc_R * sin(ang_line1 / 180 * Pi);
    y1p_outside := y1 - Arc_R * cos(ang_line1 / 180 * Pi);
    x2p_outside := x2 + Arc_R * sin(ang_line1 / 180 * Pi);
    y2p_outside := y2 - Arc_R * cos(ang_line1 / 180 * Pi);

    x3p_inside := x3 + Arc_R * sin(ang_line2 / 180 * Pi);
    y3p_inside := y3 - Arc_R * cos(ang_line2 / 180 * Pi);
    x4p_inside := x4 + Arc_R * sin(ang_line2 / 180 * Pi);
    y4p_inside := y4 - Arc_R * cos(ang_line2 / 180 * Pi);

    x3p_outside := x3 - Arc_R * sin(ang_line2 / 180 * Pi);
    y3p_outside := y3 + Arc_R * cos(ang_line2 / 180 * Pi);
    x4p_outside := x4 - Arc_R * sin(ang_line2 / 180 * Pi);
    y4p_outside := y4 + Arc_R * cos(ang_line2 / 180 * Pi);

    //  Ищем точки пересечения псевдо линий друг с другом inside-inside, outside-outside
    CrossOfLineXY(x1p_inside,  y1p_inside,  x2p_inside,  y2p_inside,  x3p_inside,  y3p_inside,  x4p_inside,  y4p_inside,  xp_inside,  yp_inside);
    CrossOfLineXY(x1p_outside, y1p_outside, x2p_outside, y2p_outside, x3p_outside, y3p_outside, x4p_outside, y4p_outside, xp_outside, yp_outside);
    if EmergencyExit then exit;

    if (LengthOfLine(x_line1_mid, y_line1_mid, xp_inside,  yp_inside) + LengthOfLine(x_line2_mid, y_line2_mid, xp_inside,  yp_inside)) <
       (LengthOfLine(x_line1_mid, y_line1_mid, xp_outside,  yp_outside) + LengthOfLine(x_line2_mid, y_line2_mid, xp_outside,  yp_outside))
    then
    begin
        Arc_CenterX : = xp_inside;
        Arc_CenterY : = yp_inside;
    end
    else
    begin
        Arc_CenterX : = xp_outside;
        Arc_CenterY : = yp_outside;
    end;

    ang1 := DetectAngleFromPointToLine (Arc_CenterX, Arc_CenterY, x1, y1, x2, y2);
    ang2 := DetectAngleFromPointToLine (Arc_CenterX, Arc_CenterY, x3, y3, x4, y4);

    new_x_line1 := Arc_CenterX + Arc_R * cos(ang1 / 180 * Pi);
    new_y_line1 := Arc_CenterY + Arc_R * sin(ang1 / 180 * Pi);
    new_x_line2 := Arc_CenterX + Arc_R * cos(ang2 / 180 * Pi);
    new_y_line2 := Arc_CenterY + Arc_R * sin(ang2 / 180 * Pi);

    DetectArcStartEndAngle(ang1, ang2, Arc_Start_A, Arc_End_A);

    // ****** MODIFY TRACK 1 *******
    if not(Extcut) then
    begin // если не в режиме обрезки, то режем первый трек
        PCBServer.SendMessageToRobots(Track1.I_ObjectAddress, c_Broadcast, PCBM_BeginModify, c_NoEventData);

        // если точка пересечения ближе к x1
        if LengthOfLine(x, y, x1, y1) < LengthOfLine(x, y, x2, y2)
        then
        begin   // двигаем x1
            Track1.x1 := MilsToCoord(new_x_line1);
            Track1.y1 := MilsToCoord(new_y_line1);
        end
        else    // двигаем x2
        begin
            Track1.x2 := MilsToCoord(new_x_line1);
            Track1.y2 := MilsToCoord(new_y_line1);
        end;
        PCBServer.SendMessageToRobots(Track1.I_ObjectAddress, c_Broadcast, PCBM_EndModify , c_NoEventData);
    end;

    // Есть или нет обрезка, режем трек2 всегда
    // ****** MODIFY TRACK 2 *******
    PCBServer.SendMessageToRobots(Track2.I_ObjectAddress, c_Broadcast, PCBM_BeginModify, c_NoEventData);

    // Если
    // - режем
    // - есть клики
    // - Точки расположены по две стороны линии, т.е. будет обрезка,
    //  то обрезка зависит от стороны клика
    if ExtCut and (x_click_obj2 <> nil) and not(TwoPointOneSideOfLine(x1,y1,x2,y2,x3,y3,x4,y4)) then
    begin
        // если точка клика находится со стороны x1,y1 относительно точки пересечения x,y
        if LengthOfLine(x3, y3, x_click_obj2, y_click_obj2) < LengthOfLine(x3, y3, x, y)
        then
        begin   // двигаем x1
            Track2.x1 := MilsToCoord(new_x_line2);
            Track2.y1 := MilsToCoord(new_y_line2);
        end
        else    // двигаем x2
        begin
            Track2.x2 := MilsToCoord(new_x_line2);
            Track2.y2 := MilsToCoord(new_y_line2);
        end;
    end
    else    // В случае если
            // - Не в режиме обрезки/удлинения (x_click_obj2 = nil или <> nil, неважно)
            // - В режиме обрезки, но обрезка не кликом, а на выделенных заранее объектах (x_click_obj2 = nil)
            // - Происходит удлинение, TwoPointOneSideOfLine(x1,y1,x2,y2,x3,y3,x4,y4) = TRUE
    begin
        // если новая точка ближе к x1
        // if LengthOfLine(x, y, x3, y3) < LengthOfLine(x, y, x4, y4)
        if LengthOfLine(x, y, x3, y3) < LengthOfLine(x, y, x4, y4)
        then
        begin   // двигаем x1
            Track2.x1 := MilsToCoord(new_x_line2);
            Track2.y1 := MilsToCoord(new_y_line2);
        end
        else    // двигаем x2
        begin
            Track2.x2 := MilsToCoord(new_x_line2);
            Track2.y2 := MilsToCoord(new_y_line2);
        end;
    end;

    PCBServer.SendMessageToRobots(Track2.I_ObjectAddress, c_Broadcast, PCBM_EndModify , c_NoEventData);

    Track1 := nil;
    Track2 := nil;

end;

// TrimmingObj - номер объекта, подлежащего одрезке/удлинению
procedure FilletTrackAndArc(Const Track1 : IPCB_Track, Arc1 : IPCB_Arc, TrimmingObj : Integer);
var
    x1, y1, x2, y2                      : Double;  // координаты линии 1
    x_line_mid, y_line_mid              : Double;  // центр линии 1

    xa2, ya2, ra2                       : Double;  // координаты и радиус дуги-объекта 2
    x_cross, y_cross                    : Double;   // координата пересечения линии Track1 и дуги Arc1, вокруг которой строится скругление
    x_arc_mid, y_arc_mid                : Double;   // Средняя точка дуги

    CenterArcToLineDistance             : Double;  // Нормальное рaасстояние от центра дуги до сопрягаемой линии
    x1_lc, x2_lc, y1_lc, y2_lc          : Double;  // точки пересечения окружности и линии
    //TrackX_Normal, TrackY_Normal        : Double;  // Координаты точки пересечения нормаль с линией
    Track1_A_Norm_360                   : Double;  // угол нормали к линии 1 в размерности 360 от точки обрезки к центру сопрягающей дуги
    //Track1_A_360                        : Double;  // угол линии 1 в размерности 360 от точки обрезки

    DirectionOfCenterFilletAboutArc     : integer;  // Указатель расположения центра скругления относительно окружности Arc1
                                                    // +1 - расположен с внешней стороны дуги Arc1
                                                    // -1 - расположен с внутренней стороны дуги Arc1
    x1p, y1p, x2p, y2p                  : Double;  // координаты псевдо линии 1

    new_x_line, new_y_line              : Double;   // Новые координаты линий

begin
    x1 := CoordToMils(Track1.x1);
    y1 := CoordToMils(Track1.y1);
    x2 := CoordToMils(Track1.x2);
    y2 := CoordToMils(Track1.y2);

    xa2 := CoordToMils(Arc1.XCenter);
    ya2 := CoordToMils(Arc1.YCenter);
    ra2 := CoordToMils(Arc1.Radius);

    // считаем расстояние от сопрягаемой линии до центра сопрягаемой дуги
    CenterArcToLineDistance := PointToLineDistance(x1, y1, x2, y2, xa2, ya2);

    // если расстояние от центра дуги до линии больше, чем радиус дуги + 2х радиуса скругления,
    // скругление не получится
    if CenterArcToLineDistance > (ra2 + Arc_R * 2 + e) then
    begin
        showmessage('Line is too far! (Or fillet radius is too small)' + #13#10 +
                    'Arc radius :' + floattostrF(ra2 * 0.0254, ffFixed, 8, 3)  + #13#10 +
                    'Fillet radius :' + floattostrF(Arc_R *0.0254, ffFixed, 8, 3)  + #13#10 +
                    'Arc to line normal distance :' + floattostrF((CenterArcToLineDistance - ra2) * 0.0254, ffFixed, 8, 3)
                    );
        EmergencyExit := true;
        exit;
    end;

    // Если не вышли, линия в пределах досягаемости для скругления
    // Устанавливаем коэф по умолчанию
    //DirectionOfCenterFilletAboutTrack := 1;     // центр fillet будет расположен относительно Track1 с той же стороный, что и центр окружности Arc1
    DirectionOfCenterFilletAboutArc := 1;    // Расположение скругления снаружи дуги

    // Средние точки линии и дуги
    MidPointOfLine(x1, y1, x2, y2, x_line_mid, y_line_mid);
    MidPointOfArcByAngle(xa2, ya2, ra2, Arc1.StartAngle, Arc1.EndAngle, x_arc_mid, y_arc_mid);

    // Угол от средней точки дуги по нормали к прямой
    Track1_A_Norm_360 := DetectAngleFromPointToLine(x_arc_mid, y_arc_mid, x1, y1, x2, y2);

    // Строим псевдолинию со смещением вдоль нормали от Track1
    // Расстояние смещения = Arc_R
    // Угол смещения = Track1_A_Norm_360
    // Направление смещения - с противоположной стороны от x_arc_mid, y_arc_mid относительно Track1 (поэтому "-")
    x1p := x1 - Arc_R * cos(Track1_A_Norm_360 / 180 * Pi);
    y1p := y1 - Arc_R * sin(Track1_A_Norm_360 / 180 * Pi);
    x2p := x2 - Arc_R * cos(Track1_A_Norm_360 / 180 * Pi);
    y2p := y2 - Arc_R * sin(Track1_A_Norm_360 / 180 * Pi);

    // Если центр линии находится внутри дуги, то скругление будет внутри дуги (ra2 - Arc_R)
    if LengthOfLine(xa2, ya2, x_line_mid, y_line_mid) < ra2 then
        DirectionOfCenterFilletAboutArc := -1;

    // ищем точки пересечения псевдоокружности (r = ra2 + Arc_R) и псевдолинии,
    // смещенной на нормальное расстояние = Arc_R к центру окружности
    // или -Arc_R, если смещение внутрь
    CircleLineCross(x1p, y1p, x2p, y2p, xa2, ya2, ra2 + (Arc_R * DirectionOfCenterFilletAboutArc), x1_lc, y1_lc, x2_lc, y2_lc);

    // Если объекты вызваны кликом, а не были в наборе до запуска программы,
    // Переопределим arc_mid, будем за опорную точку считать click_obj
    if ((x_click_obj1 <> nil) and (y_click_obj1 <> nil) and (x_click_obj2 <> nil) and (y_click_obj2 <> nil))
    then
    begin
        //x_line1_mid := x_click_obj1;
        //y_line1_mid := y_click_obj1;
        x_arc_mid := x_click_obj2;
        y_arc_mid := y_click_obj2;
    end;

    // Вычисляем какая точка пересечения ближе к центру дуги или к опорной точке x_click_obj1
    if (LengthOfLine(x_arc_mid, y_arc_mid, x1_lc, y1_lc)) <
       (LengthOfLine(x_arc_mid, y_arc_mid, x2_lc, y2_lc)) then
    begin
        // первая точка x1_lc, y1_lc ближе
        Arc_CenterX : = x1_lc;
        Arc_CenterY : = y1_lc;
    end
    else
    begin
        Arc_CenterX : = x2_lc;
        Arc_CenterY : = y2_lc;
    end;

    // New Track's parameters
    // Новые координаты одной из точек линии (движение от центра скругления к линии под углом Track1_A_Norm_360)
    new_x_line := Arc_CenterX + Arc_R * cos(Track1_A_Norm_360 / 180 * Pi);
    new_y_line := Arc_CenterY + Arc_R * sin(Track1_A_Norm_360 / 180 * Pi);

    // New Arc's parameters
    // От центра скругляющей дуги по нормали до линии.
    Angle1 := Track1_A_Norm_360;
    // второй угол от центра скругляющей дуги до центра скругляемой дуги
    Angle2 := DetectAngle360(Arc_CenterX, Arc_CenterY, xa2, ya2);

    // если скругление внутри дуги, то направление второго угла противоположное,
    // от центра дуги к центру скругления
    if DirectionOfCenterFilletAboutArc = -1 then Angle2 := DetectAngle360(xa2, ya2, Arc_CenterX, Arc_CenterY);

    // Корректируем углы дуги
    DetectArcStartEndAngle(Angle1, Angle2, Arc_Start_A, Arc_End_A);

    PCBServer.SendMessageToRobots(Track1.I_ObjectAddress, c_Broadcast, PCBM_BeginModify , c_NoEventData);
    PCBServer.SendMessageToRobots(Arc1.I_ObjectAddress, c_Broadcast, PCBM_BeginModify , c_NoEventData);

    if not(ExtCut) then
    begin
        /// если точка пересечения ближе к x1y1
        if LengthOfLine(x1, y1, new_x_line, new_y_line) < LengthOfLine(x2, y2, new_x_line, new_y_line) then
        begin   // двигаем x1
            Track1.x1 := MilsToCoord(new_x_line);
            Track1.y1 := MilsToCoord(new_y_line);
        end
        else    // двигаем x2
        begin
            Track1.x2 := MilsToCoord(new_x_line);
            Track1.y2 := MilsToCoord(new_y_line);
        end;

        // Angle2 - угол от центра скругления к центру сопрягаемой окружности
        // Если на Angle2 сопрягающая дуга заканчивается, то сопрягаемая заканчивается здесь же
        // но с доворотом на 180
        if DirectionOfCenterFilletAboutArc = 1 then     // если скругление снаружи дуги
        begin
            if Angle2 = Arc_End_A   then Arc1.EndAngle   := AngleTo360(Angle2 + 180);
            if Angle2 = Arc_Start_A then Arc1.StartAngle := AngleTo360(Angle2 + 180);
        end
        else     // если скругление внутри дуги
        begin
            if Angle2 = Arc_End_A   then Arc1.StartAngle   := AngleTo360(Angle2);
            if Angle2 = Arc_Start_A then Arc1.EndAngle := AngleTo360(Angle2);
        end;
    end
    else  // ExtCut = True;
    begin
        if TrimmingObj = 2 then // arc - prim1, track - prim2 => Резать будем Track1
        begin
            // Обрезку определили кликами и точки по разную сторону от линии
            // т.е. сумма длин от x1y1 до точки пересечения new_x_line и от точки пересечения до x2y2
            // равна длине линии, то произойдет обрезка:
            if (x_click_obj2 <> nil) and (abs(LengthOfLine(x1,y1,new_x_line, new_y_line) +
                                              LengthOfLine(new_x_line, new_y_line, x2, y2) -
                                              LengthOfLine(x1,y1,x2,y2)) < e) then
            begin
                // если точка клика находится со стороны x1,y1 относительно точки пересечения new_x_line, new_y_line
                if LengthOfLine(x1, y1, x_click_obj2, y_click_obj2) < LengthOfLine(x1, y1, new_x_line, new_y_line) then
                begin   // двигаем x1
                    Track1.x1 := MilsToCoord(new_x_line);
                    Track1.y1 := MilsToCoord(new_y_line);
                end
                else    // двигаем x2  (точка клика между new_x_line и точкой пересечения)
                begin
                    Track1.x2 := MilsToCoord(new_x_line);
                    Track1.y2 := MilsToCoord(new_y_line);
                end;
            end
            else // Обрезка определена выбранными заранее объектами, x_click_obj1 = nil
                 // Или происходит удлинение
            begin
                // если точка пересечения ближе к x1y1
                if LengthOfLine(x1, y1, new_x_line, new_y_line) < LengthOfLine(x2, y2, new_x_line, new_y_line) then
                begin   // двигаем x1
                    Track1.x1 := MilsToCoord(new_x_line);
                    Track1.y1 := MilsToCoord(new_y_line);
                end
                else    // двигаем x2
                begin
                    Track1.x2 := MilsToCoord(new_x_line);
                    Track1.y2 := MilsToCoord(new_y_line);
                end;
            end
        end
        else  // TrimmingObj = 1 track - prim1, arc - prim2 => Резать будем Arc1
        begin
            // Обрезку определили кликами все точки дуги по разную сторону от линии
            if (x_click_obj2 <> nil) and not(TwoPointOneSideOfLine(x1, y1, x2, y2, CoordToMils(Arc1.StartX),
                                                                                    CoordToMils(Arc1.StartY),
                                                                                    CoordToMils(Arc1.EndX),
                                                                                    CoordToMils(Arc1.EndY))) then
            begin
                if LengthOfLine(CoordToMils(Arc1.StartX), CoordToMils(Arc1.StartY), x_click_obj2, y_click_obj2) <
                   LengthOfLine(CoordToMils(Arc1.StartX), CoordToMils(Arc1.StartY), new_x_line, new_y_line) then
                begin // Start ближе к точке клика, чем к точке пересечения, то двигаем Start
                    Arc1.StartAngle := DetectAngle360(xa2, ya2, new_x_line, new_y_line);
                end
                else     // иначе двигаем End
                begin
                    Arc1.EndAngle := DetectAngle360(xa2, ya2, new_x_line, new_y_line);
                end;
            end
            else // Обрезка определена выбранными заранее объектами, x_click_obj1 = nil
                 // или это удлинение TwoPointOneSideOfLine = TRUE
            begin
                if DirectionOfCenterFilletAboutArc = 1 then     // если скругление снаружи дуги
                begin
                    if Angle2 = Arc_End_A   then Arc1.EndAngle   := AngleTo360(Angle2 + 180);
                    if Angle2 = Arc_Start_A then Arc1.StartAngle := AngleTo360(Angle2 + 180);
                end
                else     // если скругление внутри дуги
                begin
                    if Angle2 = Arc_End_A   then Arc1.StartAngle   := AngleTo360(Angle2);
                    if Angle2 = Arc_Start_A then Arc1.EndAngle := AngleTo360(Angle2);
                end;
            end;
        end;
    end;  // not(ExtCut)

    PCBServer.SendMessageToRobots(Track1.I_ObjectAddress, c_Broadcast, PCBM_EndModify , c_NoEventData);
    PCBServer.SendMessageToRobots(Arc1.I_ObjectAddress, c_Broadcast, PCBM_EndModify , c_NoEventData);

    Track1 := nil;
    Arc1 := nil;
end;

procedure FilletArcs(Const Arc1 : IPCB_Arc, Arc2 : IPCB_Arc);
var
    xa1, ya1, ra1                       : Double;  // координаты и радиус дуги 1
    xa2, ya2, ra2                       : Double;  // координаты и радиус дуги 2
    CenterArcToArcDistance              : Double;   // Дистанция между центрами дуг
    x_cross, y_cross                    : Double;   // Точка пересечения дуг
    x1_ccc_outside, y1_ccc_outside,
    x2_ccc_outside, y2_ccc_outside,                 // точки пересечения псевдо окружностей снаружи
    x1_ccc_inside, y1_ccc_inside,
    x2_ccc_inside, y2_ccc_inside        : Double;   // точки пересечения псевдо окружностей изнутри
    x1_ccc, y1_ccc,
    x2_ccc, y2_ccc                      : Double;   // точки пересечения псевдо окружностей tmp

    dir_arc1, dir_arc2                  : integer;  // Направление построений псевдо окружностей
                                                    // -1 - внутрь, +1 - наружу

    l_inside1, l_inside2,
    l_outside1, l_outside2,             : Double;   // суммарные расстояния от точек пересечения внутри и снаружи
    l_min, l_tmp                        : Double;   // Длины для поиска наикратчайшего

    x_arc_mid1, y_arc_mid1,
    x_arc_mid2, y_arc_mid2              : Double;   // Средняя точка дуги

    ang1, ang2                          : Double;   // Углы дуги скругления

    i, j               : integer;
begin
    xa1 := CoordToMils(Arc1.XCenter);
    ya1 := CoordToMils(Arc1.YCenter);
    ra1 := CoordToMils(Arc1.Radius);
    xa2 := CoordToMils(Arc2.XCenter);
    ya2 := CoordToMils(Arc2.YCenter);
    ra2 := CoordToMils(Arc2.Radius);

    CenterArcToArcDistance := LengthOfLine(xa1, ya1, xa2, ya2);

    if CenterArcToArcDistance > (ra1 + ra2 + Arc_R * 2) then
    begin
        showmessage('Arcs is too far! (Or fillet radius is too small)' + #13#10 +
                    'Arc1 radius :' + floattostrF(ra1 * 0.0254, ffFixed, 8, 3)  + #13#10 +
                    'Arc2 radius :' + floattostrF(ra2 * 0.0254, ffFixed, 8, 3)  + #13#10 +
                    'Fillet radius :' + floattostrF(Arc_R * 0.0254, ffFixed, 8, 3)  + #13#10 +
                    'Arc-to-Arc space distance :' + floattostrF((CenterArcToArcDistance - ra1 - ra2) * 0.0254, ffFixed, 8, 3)
                    );
        EmergencyExit := true;
        exit;
    end;

    if CenterArcToArcDistance < (abs(ra1 - ra2) + Arc_R * 2) then  // Одна окружность внутри другой, Arc_R не достает
    begin
        showmessage('Fillet radius is too small. (Arc1 inside Arc2)' + #13#10 +
                    'Arc1 radius :' + floattostrF(ra1 * 0.0254, ffFixed, 8, 3)  + #13#10 +
                    'Arc2 radius :' + floattostrF(ra2 * 0.0254, ffFixed, 8, 3)  + #13#10 +
                    'Fillet radius :' + floattostrF(Arc_R * 0.0254, ffFixed, 8, 3)  + #13#10 +
                    'Arc-to-Arc center distance :' + floattostrF((CenterArcToArcDistance) * 0.0254, ffFixed, 8, 3)
                    );
        EmergencyExit := true;
        exit;
    end;

    // Средние точки дуг
    MidPointOfArcByAngle(xa1, ya1, ra1, Arc1.StartAngle, Arc1.EndAngle, x_arc_mid1, y_arc_mid1);
    MidPointOfArcByAngle(xa2, ya2, ra2, Arc2.StartAngle, Arc2.EndAngle, x_arc_mid2, y_arc_mid2);

    dir_arc1 := 1; // Центр скругления расположен снаружи Arc1
    dir_arc2 := 1; // Центр скругления расположен снаружи Arc2

    // Дуги не пересекаются или пересекаются, но радиус не позволяет построить скругление внутри
    // Скругление будет снаружи обеих дуг
    if CenterArcToArcDistance > (ra1 + ra2 - (2 * Arc_R)) then
    begin
        // Строим две псевдо окружности с радиусами ra1 + Arc_r и ra2 + Arc_R
        // Ищем точки пересечения этих псевдо дуг.
        CirclesCross(xa1, ya1, ra1 + Arc_R, xa2, ya2, ra2 + Arc_R, x1_ccc_outside, y1_ccc_outside, x2_ccc_outside, y2_ccc_outside);

        // Получаем 2 точки пересечения псевдоскруглений
        // Строим скругление с центром в точке, наиболее приближенной к средним точкам дуг

        // Ищем ближайшую точка к серединам дуг
        l_min := 100000; // mil
        l_outside1 := LengthOfLine(x_arc_mid1, y_arc_mid1, x1_ccc_outside, y1_ccc_outside) +
                        LengthOfLine(x_arc_mid2, y_arc_mid2, x1_ccc_outside, y1_ccc_outside);
        l_outside2 := LengthOfLine(x_arc_mid1, y_arc_mid1, x2_ccc_outside, y2_ccc_outside) +
                        LengthOfLine(x_arc_mid2, y_arc_mid2, x2_ccc_outside, y2_ccc_outside);

        if l_outside1 < l_min then
        begin
            l_min := l_outside1;
            Arc_CenterX := x1_ccc_outside;
            Arc_CenterY := y1_ccc_outside;
            x_cross := x1_ccc_outside; // Фиктивные, x_cross не существует, необходимо для расчета Arc.Start Arc.End
            y_cross := y1_ccc_outside;
        end;

        if l_outside2 < l_min then
        begin
            l_min := l_outside2;
            Arc_CenterX := x2_ccc_outside;
            Arc_CenterY := y2_ccc_outside;
            x_cross := x2_ccc_outside;
            y_cross := y2_ccc_outside;
        end;

        ang1 := DetectAngle360(Arc_CenterX, Arc_CenterY, xa1, ya1);
        ang2 := DetectAngle360(Arc_CenterX, Arc_CenterY, xa2, ya2);

    end;

    // Дуги пересекаются и имеют две точки пересечения.
    // Дополнительно, внутренние кромки окружностей должны
    // отступать друг от друга на расстояние больше, чем диаметр скругления, 2 * Arc_R
    if CenterArcToArcDistance < (ra1 + ra2 - (2 * Arc_R)) then
    begin
        // Точки пересечения дуг
        CirclesCross(xa1, ya1, ra1, xa2, ya2, ra2, x1_ccc, y1_ccc, x2_ccc, y2_ccc);

        // Ищем ближайшую
        // Если первая точка пересечения ближе к оперной (mid или click), то эта точка главная в пересечении
        if (LengthOfLine(x1_ccc, y1_ccc, x_arc_mid1, y_arc_mid1) + LengthOfLine(x1_ccc, y1_ccc, x_arc_mid2, y_arc_mid2)) <
           (LengthOfLine(x2_ccc, y2_ccc, x_arc_mid1, y_arc_mid1) + LengthOfLine(x2_ccc, y2_ccc, x_arc_mid2, y_arc_mid2))
        then
        begin
            x_cross := x1_ccc;
            y_cross := y1_ccc;
        end
        else  // Иначе - вторая
        begin
            x_cross := x2_ccc;
            y_cross := y2_ccc;
        end;

        // Определяем направление псевдо окружностей
        // Если расстояние от центра Arc1 до mid2 меньше радиуса ra1
        if LengthOfLine(xa1, ya1, x_arc_mid2, y_arc_mid2) < ra1
        then // то центр скругления будет внутри Arc1
            dir_arc1 := -1;

        // Если расстояние от центра Arc2 до mid1 меньше радиуса ra2
        if LengthOfLine(xa2, ya2, x_arc_mid1, y_arc_mid1) < ra2
        then // то центр скругления будет внутри Arc1
            dir_arc2 := -1;

        // Пересечение псевдо-окружностей
        CirclesCross(xa1, ya1, ra1 + dir_arc1 * Arc_R, xa2, ya2, ra2 + dir_arc2 * Arc_R, x1_ccc, y1_ccc, x2_ccc, y2_ccc);
        // Ближайшая к x_cross будет центром скругления
        if LengthOfLine(x1_ccc, y1_ccc, x_cross, y_cross) < LengthOfLine(x2_ccc, y2_ccc, x_cross, y_cross)
        then
        begin
            Arc_CenterX := x1_ccc;
            Arc_CenterY := y1_ccc;
        end
        else
        begin
            Arc_CenterX := x2_ccc;
            Arc_CenterY := y2_ccc;
        end;

        if dir_arc1 = 1 then
            ang1 := DetectAngle360(Arc_CenterX, Arc_CenterY, xa1, ya1)
        else
            ang1 := DetectAngle360(xa1, ya1, Arc_CenterX, Arc_CenterY);

        if dir_arc2 = 1 then
            ang2 := DetectAngle360(Arc_CenterX, Arc_CenterY, xa2, ya2)
        else
            ang2 := DetectAngle360(xa2, ya2, Arc_CenterX, Arc_CenterY);
    end;

        //l_min := 100000; // mil

    DetectArcStartEndAngle(ang1, ang2, Arc_Start_A, Arc_End_A);

        // ******* MODIFY ARCS *******


    if not(ExtCut) then
    begin
        PCBServer.SendMessageToRobots(Arc1.I_ObjectAddress, c_Broadcast, PCBM_BeginModify , c_NoEventData);
        if LengthOfLine(x_cross, y_cross, CoordToMils(Arc1.StartX), CoordToMils(Arc1.StartY)) <
            LengthOfLine(x_cross, y_cross, CoordToMils(Arc1.EndX), CoordToMils(Arc1.EndY))
        then
        begin // При (dir = -1) = ang, (dir = 1) = ang + 180
            Arc1.StartAngle := ang1 + 90 + (90 * dir_arc1);
        end
        else
        begin
            Arc1.EndAngle : = ang1 + 90 + (90 * dir_arc1);
        end;
        PCBServer.SendMessageToRobots(Arc1.I_ObjectAddress, c_Broadcast, PCBM_EndModify , c_NoEventData);
    end;

        PCBServer.SendMessageToRobots(Arc2.I_ObjectAddress, c_Broadcast, PCBM_BeginModify , c_NoEventData);

        if (x_click_obj2 <> nil) and ExtCut then // Если были клики и делаем обрезку, смотрим какой из концов ближе к x_click
        begin
            if LengthOfLine(CoordToMils(Arc2.StartX), CoordToMils(Arc2.StartY), x_click_obj2, y_click_obj2) <
               LengthOfLine(CoordToMils(Arc2.StartX), CoordToMils(Arc2.StartY), x_cross, y_cross) then
                Arc2.StartAngle := ang2 + 90 + (90 * dir_arc2)
            else
                Arc2.EndAngle := ang2 + 90 + (90 * dir_arc2);
        end
        else    // Если не было кликов смотрим относительно пересечения
        begin
            if LengthOfLine(x_cross, y_cross, CoordToMils(Arc2.StartX), CoordToMils(Arc2.StartY)) <
                LengthOfLine(x_cross, y_cross, CoordToMils(Arc2.EndX), CoordToMils(Arc2.EndY))
            then
                Arc2.StartAngle := ang2 + 90 + (90 * dir_arc2)
            else
                Arc2.EndAngle : = ang2 + 90 + (90 * dir_arc2);
        end;

        PCBServer.SendMessageToRobots(Arc2.I_ObjectAddress, c_Broadcast, PCBM_EndModify , c_NoEventData);

    Arc1 := nil;
    Arc2 := nil;
end;

function FilletObjects;
var
    DocKind             : String;
    ver                 : String;
    // PCB variables and objects
    PCBBoard            : IPCB_Board;
    PCBLibrary          : IPCB_Library;
//    PCBSystemOptions        : IPCB_SystemOptions;
    str_obj1, str_obj2      : String; // Текста приветствия

    Net                 : IPCB_Net;
    Prim1               : IPCB_Primitive;
    Prim2               : IPCB_Primitive;
    ObjSet              : integer;          // Определяет, что в наборе
    BoardIterator       : IPCB_BoardIterator;
    Layer               : TLayer;

    // Переменные, если выбраны какие-либо объекты
    sms_sel     : boolean;
    get3obj     : boolean;
    ArcSel      : IPCB_Arc;
    Prim1Sel    : IPCB_Track;
    Prim2Sel    : IPCB_Track;
    i           : integer;

    // Common variables
    ASetOfObjects       : TObjectSet;

Begin
    DocKind := GetWorkspace.DM_FocusedDocument.DM_DocumentKind;

    ver := GetCurrentProductBuild;
    //showmessage(ver);

    If PCBServer = Nil Then Exit;

    PCBBoard := PCBServer.GetCurrentPCBBoard;
    PCBLibrary := PCBServer.GetCurrentPCBLibrary;
//    PCBSystemOptions := PCBServer.SystemOptions;

    //PCBBoard.SetState_Navigate_HighlightObjectList(;
    if (PCBBoard = nil) and (PCBLibrary = nil) then exit;

    ASetOfObjects := MkSet(eTrackObject, eArcObject);

    Arc     := nil;
    Prim1   := nil;
    Prim2   := nil;
    Net := nil;
    EmergencyExit := false;

    sms_sel := false; //что-то выделено
    ArcSel := nil;
    Prim1Sel := nil;
    Prim2Sel := nil;
    get3obj := false; //выделено 3 объекта и это 2 линии и дуга


    //Если выделены несколько объектов
    // Если выделено более 3х объектов
    if PCBBoard.SelectecObjectCount > 3 then exit;

    if PCBBoard.SelectecObjectCount <> 0 then
    begin
        // Проверка, что выделили. Если есть выделенный объект, то это должна быть дуга или линия
        for i := 0 to 2 do
        if (PCBBoard.SelectecObject[i] <> nil) and
           (PCBBoard.SelectecObject[i].ObjectId <> eTrackObject) and
           (PCBBoard.SelectecObject[i].ObjectId <> eArcObject)
            then exit;

        sms_sel := true;   // Что-то выделено
        case PCBBoard.SelectecObjectCount of

            //  Выделен 1 объект. Должна быть дуга, читаем ее радиус
            1:  begin
                    if PCBBoard.SelectecObject[0].ObjectId = eArcObject
                    then
                    begin
                        ArcSel := PCBBoard.SelectecObject[0];
                        Arc_R := CoordToMils(ArcSel.Radius);
                    end
                    else exit;
                end; // 1:

            //  Выделено 2 объекта. Должны быть только Track или Arc
            2:  begin
                    Prim1Sel := PCBBoard.SelectecObject[0];
                    Prim2Sel := PCBBoard.SelectecObject[1];
                end; // 2:

            //  Выделено 3 объекта. Должны быть две линии и дуга
            3:  begin
                    if (PCBBoard.SelectecObject[0].ObjectId = eTrackObject) and
                       (PCBBoard.SelectecObject[1].ObjectId = eTrackObject) and
                       (PCBBoard.SelectecObject[2].ObjectId = eArcObject)
                    then
                    begin
                        get3obj := true;
                        Prim1Sel := PCBBoard.SelectecObject[0];
                        Prim2Sel := PCBBoard.SelectecObject[1];
                        ArcSel := PCBBoard.SelectecObject[2];
                        Arc_R := CoordToMils(ArcSel.Radius);
                    end;
                    if (PCBBoard.SelectecObject[0].ObjectId = eTrackObject) and
                       (PCBBoard.SelectecObject[1].ObjectId = eArcObject) and
                       (PCBBoard.SelectecObject[2].ObjectId = eTrackObject)
                    then
                    begin
                        get3obj := true;
                        Prim1Sel := PCBBoard.SelectecObject[0];
                        ArcSel := PCBBoard.SelectecObject[1];
                        Prim2Sel := PCBBoard.SelectecObject[2];
                        Arc_R := CoordToMils(ArcSel.Radius);
                    end;
                    if (PCBBoard.SelectecObject[0].ObjectId = eArcObject) and
                       (PCBBoard.SelectecObject[1].ObjectId = eTrackObject) and
                       (PCBBoard.SelectecObject[2].ObjectId = eTrackObject)
                    then
                    begin
                        get3obj := true;
                        ArcSel := PCBBoard.SelectecObject[0];
                        Prim1Sel := PCBBoard.SelectecObject[1];
                        Prim2Sel := PCBBoard.SelectecObject[2];
                        Arc_R := CoordToMils(ArcSel.Radius);
                    end;
                    if not(get3obj) then exit; // выбраны 3 объекта, но это не две линии и не дуга.
                end // 3:

            else exit;
        end; //case PCBBoard.SelectecObjectCount

    end; //PCBBoard.SelectecObjectCount <> 0

    x_click_obj1 := nil;
    y_click_obj1 := nil;
    x_click_obj2 := nil;
    y_click_obj2 := nil;

    if not(ExtCut) then
    begin
        str_obj1 := 'Choose first track or arc for fillet. R = ' + FormatFloat('0.###', Arc_R * 0.0254);
        str_obj2 := 'Choose second track or arc for fillet. R = ' + FormatFloat('0.###', Arc_R * 0.0254);;
    end
    else
    begin
        str_obj1 := 'Choose cutting/extend edge';
        str_obj2 := 'Choose object and side to trim or extend';
    end;

    While (Prim1 = nil) do   //Simple cycle forever
    begin
        While (Prim2 = nil) or (Prim1 = nil) Do
        begin
            //Если выбран первый объект
            if Prim1Sel <> nil then Prim1 := Prim1Sel //Пока оставляем выделенные треки, с выделенными дугами не работаем
            else
            begin
                if ExtCut then
                begin
                    PCBBoard.ChooseLocation(x_click_obj1, y_click_obj1, str_obj1);
                    Prim1 := PCBBoard.GetObjectAtXYAskUserIfAmbiguous(x_click_obj1, y_click_obj1, ASetOfObjects, AllLayers, eEditAction_Select);
                    x_click_obj1 := CoordToMils(x_click_obj1);
                    y_click_obj1 := CoordToMils(y_click_obj1);
                end
                else
                begin
                    Prim1 := PCBBoard.GetObjectAtCursor(ASetOfObjects, AllLayers, str_obj1);
                end;

            end;

            if Prim1 = nil then exit;

            if Prim2Sel <> nil then Prim2 := Prim2Sel //Пока оставляем выделенные треки, с выделенными дугами не работаем
            else
            begin
                if ExtCut then
                begin
                    PCBBoard.ChooseLocation(x_click_obj2, y_click_obj2, str_obj2);
                    Prim2 := PCBBoard.GetObjectAtXYAskUserIfAmbiguous(x_click_obj2, y_click_obj2, ASetOfObjects, AllLayers, eEditAction_Select);
                    x_click_obj2 := CoordToMils(x_click_obj2);
                    y_click_obj2 := CoordToMils(y_click_obj2);
                end
                else
                begin
                    Prim2 := PCBBoard.GetObjectAtCursor(ASetOfObjects, AllLayers, str_obj1);
                end;
            end;

            if Prim2 = nil then Prim1 := nil;


        end;  //While (Prim2 = nil) or (Prim1 = nil) Do

    ResetParameters;
    PCBServer.PreProcess;
    Try

        // Определяем цепь. По умолчанию используем цепь первого отрезка
        if Prim2.Net <> nil then Net := Prim2.Net;
        if Prim1.Net <> nil then Net := Prim1.Net;

        if ((Prim1.ObjectID = eTrackObject) and (Prim2.ObjectID = eTrackObject)) then
        begin
            FilletTracks(Prim1, Prim2);
        end;

        if ((Prim1.ObjectID = eTrackObject) and (Prim2.ObjectID = eArcObject)) then
        begin
            FilletTrackAndArc(Prim1, Prim2, 1);
        end;

        if ((Prim1.ObjectID = eArcObject) and (Prim2.ObjectID = eTrackObject)) then
        begin
            FilletTrackAndArc(Prim2, Prim1, 2);
        end;

        if ((Prim1.ObjectID = eArcObject) and (Prim2.ObjectID = eArcObject)) then
        begin
            FilletArcs(Prim1, Prim2);
        end;

        // Если из какой то процедуры вышли аварийно, выйти совсем
        if EmergencyExit then exit;


        //***** ADDING FILLET ARC ******
        if not(Extcut) then //если не режем/удлиняем
        begin
            // Always use IPCB_Primitive.BeginModify instead of PCBServer.SendMessageToRobots because is deprecated
            Arc := PCBServer.PCBObjectFactory(eArcObject, eNoDimension, eCreate_Default);
            Arc.Layer       := Prim1.Layer;
            if (Prim1.ObjectID = eTrackObject) then Arc.LineWidth   := Prim1.Width else Arc.LineWidth   := Prim1.LineWidth;
            Arc.XCenter     := MilsToCoord(Arc_CenterX);
            Arc.YCenter     := MilsToCoord(Arc_CenterY);
            Arc.Radius      := MilsToCoord(Arc_R);
            Arc.StartAngle  := Arc_Start_A;
            Arc.EndAngle    := Arc_End_A;

            if Net <> nil then Arc.Net := Net;

            //Arc.BeginModify;

            if PCBBoard <> nil then   // Если работаем с .PcbDoc
            begin
                PCBServer.SendMessageToRobots(PCBBoard.I_ObjectAddress,c_Broadcast,PCBM_BoardRegisteration,Arc.I_ObjectAddress);
                PCBBoard.AddPCBObject(Arc);
            end
            else   // Работаем с .PcbLib
            begin
                PCBServer.SendMessageToRobots(PCBLibrary.Board.I_ObjectAddress,c_Broadcast,PCBM_BoardRegisteration,Arc.I_ObjectAddress);
                PCBBoard.AddPCBObject(Arc);
            end;

            //If editing track in Component
            If Prim1.InComponent then Prim1.Component.AddPCBObject(Arc);

            //Arc.EndModify;

            PCBBoard.ViewManager_FullUpdate;
            Arc := nil;
        end;  // if not(Extcut) then //если не режем/удлиняем



    Finally
        PCBServer.PostProcess;
    End;


        Arc := nil;
        Prim1 := nil;
        Prim2 := nil;
        Net := nil;

        if sms_sel then
        begin
            ArcSel := nil;
            Prim1Sel := nil;
            Prim2Sel := nil;
            exit;
        end;

    end; //While (Track1 = nil) do

end;

procedure FilletObjectsStart;
begin
    RegistryRead;
    Extcut := false;
    FilletObjects;
end;

procedure FilletObjectsStart0;
begin
    Arc_R := 0;
    Extcut := False;
    FilletObjects;
end;

procedure ExtendOrCutObjectsStart;
begin
    Arc_R := 0;
    ExtCut := True;
    FilletObjects;
end;

procedure FilletObjectsSet;
begin
    RegistryRead;
    frmFilletObjectsSet.Show;
end;

procedure TfrmFilletObjectsSet.ButCancelClick(Sender: TObject);
begin
    frmFilletObjectsSet.Close;
end;


procedure TfrmFilletObjectsSet.ButOKClick(Sender: TObject);
begin
    Arc_R:=strtofloat(editRadius.Text);
    RegistryWrite;
    frmFilletObjectsSet.Close;
end;
