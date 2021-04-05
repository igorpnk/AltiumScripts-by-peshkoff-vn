Uses Registry;

const
    e = 0.001; //0.001 mil
    e_TCoord = 10; //e � ������� �������� TCoord, = 0.001 mil,

var
    x_click_obj1, y_click_obj1,
    x_click_obj2, y_click_obj2          : Double;
    Arc                                 : IPCB_Arc;     // ����������� ����
    Arc_CenterX, Arc_CenterY            : Double;       // ����� ����������� ����
    Angle1, Angle2                      : Double;       // ��������������� ���� ��� ���������� ���� (�� ���������� ������ � �����)
    Arc_Start_A, Arc_End_A              : Double;       // ������������� ���� ��� ����������
    Arc_R                               : Double;       // ������ ����������� ����

    Extcut                              : boolean;
    EmergencyExit                       : boolean;      // ��������� ����� �� ���������

procedure RegistryRead;
var
    Registry  : TRegistry;
    Arc_R_Str : String;
Begin
    { ������ ������ TRegistry }
    Registry := TRegistry.Create;
    Try
        { ������������� �������� ����; ������� hkey_local_machine ��� hkey_current_user }
        //Registry.RootKey := HKEY_CURRENT_USER; {��������������� �������������}
        { ��������� � ������ ���� }
        Registry.OpenKey('Software\AltiumScripts\FilletObjects',true);

        if Registry.ValueExists('Radius')           then    Arc_R_Str           := Registry.ReadString('Radius');
     //   if Registry.ValueExists('Disable LiveHL')   then    cb_livehl.Checked   := Registry.ReadBool('Disable LiveHL');

        { ��������� � ����������� ���� }
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
    { ������ ������ TRegistry }
    Registry := TRegistry.Create;
    Try
        { ������������� �������� ����; ������� hkey_local_machine ��� hkey_current_user }
        //Registry.RootKey := HKEY_CURRENT_USER; {��������������� �������������}
        { ��������� � ������ ���� }
        Registry.OpenKey('Software\AltiumScripts\FilletObjects',true);
        { ���������� �������� }

        Registry.WriteString('Radius',   floattostr(Arc_R));
        //Registry.WriteBool('Disable LiveHL', cb_livehl.Checked);
        { ��������� � ����������� ���� }
        Registry.CloseKey;
    Finally
        Registry.Free;
    End;

End;

function LengthOfLine(Const x1, y1, x2, y2 : Double) : Double;
begin
    Result := sqrt(sqr(x1 - x2) + sqr(y1 - y2));
end;

// ����� ����������� ���� �����, �������� ������������
// x1, y1, x2, y2 - ������ �����
// x3, y3, x4, y4 - ������ �����
procedure CrossOfLineXY(Const x1, y1, x2, y2, x3, y3, x4, y4: Double; Out x, y : Double);
begin
    x := 0;
    y := 0;
    if (abs(x1 - x2) < e) and (abs(x3 - x4) < e) or
       (abs((y2 - y1)*(x4 - x3) - (y4 - y3)*(x2 - x1)) < e)
    then
        begin
            ShowMessage('������� ����������� (proc CrossOfLineXY trouble)');
            EmergencyExit := True;
            exit;
        end
    else //else lvl1
        begin
            if abs(x1 - x2) < e then x := x1; //������ ����� ������������
            if abs(x3 - x4) < e then x := x3; //������ ����� ������������
            if abs(y1 - y2) < e then y := y1; //������ ����� ��������������
            if abs(y3 - y4) < e then y := y3; //������ ����� ��������������

            //��� �� ������������, ���� X
            if (x<>x1) and (x<>x3) then x:=-((x1*y2-x2*y1)*(x4-x3)-(x3*y4-x4*y3)*(x2-x1))/((y1-y2)*(x4-x3)-(y3-y4)*(x2-x1));
            if (y<>y1) and (y<>y3) and (abs(x3-x4) > e) then y:=((y3-y4)*(-x)-(x3*y4-x4*y3))/(x4-x3);
            if (y<>y1) and (y<>y3) and (abs(x3-x4) < e) then y:=y1-((y2-y1)*(x1-x)/(x2-x1));
        end; //else lvl1
end;

// ��� ����� �� ���� ������� �����, x1 y1 x2 y2 - ���������� �����.
function TwoPointOneSideOfLine(Const x1, y1, x2, y2, point1_x, point1_y, point2_x, point2_y : Double) : boolean;
var
    //L1, L2, LTotal  : double;
    //x_fict_cross, y_fict_cross  : double;
    D1, D2      : Double;
begin
    // �(�1,�1), �(�2,�2), �(�3,�3). ����� ����� � � � ��������� ������
    // D = (�3 - �1) * (�2 - �1) - (�3 - �1) * (�2 - �1)
    // - ���� D = 0 - ������, ����� � ����� �� ������ ��.
    // - ���� D < 0 - ������, ����� � ����� ����� �� ������.
    // - ���� D > 0 - ������, ����� � ����� ������ �� ������.
    D1 := (point1_x - x1) * (y2 - y1) - (point1_y - y1) * (x2 - x1);
    D2 := (point2_x - x1) * (y2 - y1) - (point2_y - y1) * (x2 - x1);

    Result := false;

    if (D1 <= 0) and (D2 <= 0) then Result := true;
    if (D1 >= 0) and (D2 >= 0) then Result := true;

end;

function PointToLineDistance(Const x1, y1, x2, y2, x0, y0 : Double) : Double;
begin
    //����� ��������������
    if abs(y2 - y1) < e then Result := abs(y1 - y0);

    //����� ������������
    if abs(x2 - x1) < e then Result := abs(x1 - x0);

    //����� ��� �����
    if ((x2 - x1) <> 0) and ((y2 - y1) <> 0) then
    begin
        Result := abs((y2 - y1)*x0 - (x2 - x1)*y0 + x2*y1 - y2*x1) / sqrt(sqr(y2 - y1) + sqr(x2 - x1));
    end;
end;

// ����������� ���� ����� ������� � ��������� �� 0 �� 359.99
function DetectAngle360 (Const x1, y1, x2, y2 : Double) : Double;
begin
    // ��������� 10E-13..
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
        // ����������� � �������� �� 0 �� 359.99
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

// ���������� ���� < 0 � > 360 � �������� 0..360
function AngleTo360 (Const ang : Double) : Double;
begin
    Result := ang;
    if ang >= 360 then Result := ang - 360;
    if ang < 0 then Result := ang + 360;
end;

// ���� ����� ���������, � ���������� ������
function AbsoluteDeltaAngle(Const Ang1, Ang2: Double) : Double;
begin
    Result := abs(Ang1 - Ang2);
    if Result > 180 then
    begin
        Result := abs(Result - 360);
    end;
end;

// ���������� �����������
function DetectBisectrix (Const Ang1, Ang2 : Double) : Double;
begin
    if Ang2 < Ang1 then // ����������� ����� 360
        Ang2 := Ang2 + 360;

    Result := (Ang2 + Ang1) / 2;
    AngleTo360(Result);
end;

// ���������� ���� � ��������� �� -90 �� 90 ������������ (�������� ��� ���������)
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

    k, b                : Double; //���� ��������� ������
    cx, cy, cr          : Double; //���� ��������� ����������
    aa, bb, cc, d       : Double; //���� ��. ���������

begin
    x1_Cross := 0;
    y1_Cross := 0;
    x2_Cross := 0;
    y2_Cross := 0;

    //������� ������ ��������� � ����� ����������
    //���������� ������ ���� ������� ��������� ����� ����� ����������
    x1 := x1 - xa;
    y1 := y1 - ya;
    x2 := x2 - xa;
    y2 := y2 - ya;

    if abs(y2 - y1) < e then y2 := y1;
    if abs(x2 - x1) < e then x2 := x1;

    if y2 - y1 = 0 then     //����� ��������������
    begin
        if (abs(abs(y1) - ra) < e) and (abs(abs(y2) - ra) < e) then   //�������� � ����� ����� � 90� b 270�
        begin
            x1_Cross := 0;
            y1_Cross := y1;
            x2_Cross := 0;
            y2_Cross := y2;
        end
        else
        begin
            if (abs(y1) < ra) and (abs(y2) < ra) then   //���������� ���������� � ���� ������
            begin
                x1_Cross := - sqrt(sqr(ra) - sqr(y1));
                y1_Cross := y1;
                x2_Cross := sqrt(sqr(ra) - sqr(y1));
                y2_Cross := y2;
            end;
            if (abs(y1) > ra) and (abs(y2) > ra) then   //�� ����������
            begin
                ShowMessage('����� �� ���������� ����������! [procedure CircleLineCross] (��������������)');
            end;
        end;
    end;

    if x2 - x1 = 0 then     //����� ������������
    begin
        if (abs(abs(x1) - ra) < e) and (abs(abs(x2) - ra) < e) then   //�������� � ����� ����� � 90� b 270�
        begin
            x1_Cross := x1;
            y1_Cross := 0;
            x2_Cross := x2;
            y2_Cross := 0;
        end
        else
        begin
            if (abs(x1) < ra) and (abs(x2) < ra) then   //���������� ���������� � ���� ������
            begin
                x1_Cross := x1;
                y1_Cross := - sqrt(sqr(ra) - sqr(x1));
                x2_Cross := x2;
                y2_Cross := sqrt(sqr(ra) - sqr(x1));
            end;
            if (abs(x1) > ra) and (abs(x2) > ra) then   //�� ����������
            begin
                ShowMessage('����� �� ���������� ����������! [procedure CircleLineCross] (������������)');
            end;
        end;
    end;

    if ((x2 - x1) <> 0) and ((y2 - y1) <> 0) then  //����� ��� �����
        begin
        //������������ ������ ���� ������� ��������� ����� ����� ����������
        k := (y2 - y1) / (x2 - x1);                     //k = 0.2
        b := (x2 * y1 - x1 * y2)/(x2 - x1);             //b = 2.980

        //�����. ���������� ��� ������ ���������� � ����������� 0,0
        cx := xa;                              //cx = 25
        cy := ya;                              //cy = 6
        //������ ����������
        cr := ra;                   //cr = 4


        aa := k * k + 1;                        //aa = 1.04
        bb := 2 * k * b;                        //bb = 1.192
        cc := b * b - cr * cr;                  //cc = -7.118
        d  := bb * bb - 4 * aa * cc;             //d = 31.033

        if (abs(d) < e) then d := 0;

        if d < 0 then
        begin
            ShowMessage('����� �� ���������� ����������! [procedure CircleLineCross] (���������)');
            //halt;
        end;

        if d =0 then //�.�. d = 0, 1 �����
        begin
            x1_Cross := -bb / (2 * aa);
            y1_Cross := k * x1_Cross + b;
            x2_Cross := x1_Cross;
            y2_Cross := y1_Cross;
        end;

        if d > 0 then
        begin
            //����� ����������� ����������� � �����������������
            x1_Cross := (-bb - sqrt(d)) / (2 * aa);      //x1_lc = -3.251
            y1_Cross := k * x1_Cross + b;                   //y1_lc = 2.329

            x2_Cross := (-bb + sqrt(d)) / (2 * aa);      //x2_lc = 2.105
            y2_Cross := k * x2_Cross + b;                   //y2_lc = 3.401
        end;
    end;

    //���������� ������ ��������� �� ������ ���������� � 0,0
    x1_Cross := x1_Cross + xa;
    y1_Cross := y1_Cross + ya;
    x2_Cross := x2_Cross + xa;
    y2_Cross := y2_Cross + ya;

end;

procedure CirclesCross(Const xa1, ya1, ra1, xa2, ya2, ra2 : Double; Out x1_cross, y1_cross, x2_cross, y2_cross : Double);
var
    d                       : Double;   // ���������� ����� ��������
    a, h                    : Double;   //
    CenterToCenterAngle     : Double;   // ���� ����� �������� �� Arc1 �� Arc2
    xp3, yp3                : Double;   // ��������������� ������-����� ����������� ����� ����� ��������
                                        // � ����� ����� ������� �����������
begin
    x1_Cross := 0;
    y1_Cross := 0;
    x2_Cross := 0;
    y2_Cross := 0;

    d := LengthOfLine(xa1, ya1, xa2, ya2);
    if d > (ra1 + ra2) then // ���������� ����� ������������ ������ 2-� ��������
    begin
        ShowMessage('Circles do not cross! [procedure CirclesCross] d > (ra1 + ra2)');
        EmergencyExit := true;
        exit;
    end;

    if d < abs(ra1 - ra2) then  // ���� ���������� ������ ������, �� ������������
    begin
        ShowMessage('Circles do not cross! [procedure CirclesCross] d < abs(ra1 - ra2)');
        EmergencyExit := true;
        exit;
    end;

    // ���� ����� ��������
    CenterToCenterAngle := DetectAngle360(xa1, ya1, xa2, ya2);

    if abs(d - (ra1 + ra2)) < e then // ���� ����� �����������
    begin
        x1_cross := xa1 + ra1 * cos(CenterToCenterAngle / 180 * Pi);
        y1_cross := ya1 + ra1 * sin(CenterToCenterAngle / 180 * Pi);
        x2_cross := x1_cross;
        y2_cross := y1_cross;
    end;

    // ���������� ������������ � ������ ��� � ���� ������
    a := (sqr(ra1) - sqr(ra2) + sqr(d)) / (2 * d);
    h := sqrt(sqr(ra1) - sqr(a));

    xp3 := xa1 + a * cos(CenterToCenterAngle / 180 * Pi);
    yp3 := ya1 + a * sin(CenterToCenterAngle / 180 * Pi);

    x1_cross := xp3 + h/d * (ya2 - ya1);
    y1_cross := yp3 - h/d * (xa2 - xa1);

    x2_cross := xp3 - h/d * (ya2 - ya1);
    y2_cross := yp3 + h/d * (xa2 - xa1);

end;

// ����������� ���� �� ����� �� ����� �� ������� � ��������� �� 0 �� 359.99
function DetectAngleFromPointToLine (Const x, y, x1, y1, x2, y2 : Double) : Double;
var
    distance_to_line        : Double;   // ���������� �� ����� �� �����
    x_normal, y_normal      : Double; // ����� ���������� ������� � ����� �� �������� �����
    x_normal_tmp, y_normal_tmp      : Double; // ��������� ����� ��� ����������� ������������ ��������� CircleLineCross
begin
    // ��������� 10E-13..
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
        // ����������� � �������� �� 0 �� 359.99
        if Result >= 360 then Result := Result - 360;
        if Result < 0 then Result := Result + 360;
    end;
end;

// ������� ����� �����
procedure MidPointOfLine(Const x1, y1, x2, y2 : Double; Out x_mid, y_mid: Double);
begin
    x_mid := (x1 + x2) / 2;
    y_mid := (y1 + y2) / 2;
end;

// ������� ����� ���� ���� �������� ���� ������ � �����
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
    x1, y1, x2, y2                  : Double;  // ���������� ����� 1
    x_line1_mid, y_line1_mid        : Double;  // ����� ����� 1
    ang_line1                       : Double;   // ���� ����� 1
    x3, y3, x4, y4                  : Double;  // ���������� ����� 2
    x_line2_mid, y_line2_mid        : Double;  // ����� ����� 2
    ang_line2                       : Double;   // ���� ����� 2

    x, y                            : Double;  // ����� ����������� �����

    x1p_inside, y1p_inside, x2p_inside, y2p_inside                      : Double;  // ���������� ������ ����� 1 ��� �������� ������
    x3p_inside, y3p_inside, x4p_inside, y4p_inside                      : Double;  // ���������� ������ ����� 2 ��� �������� ������
    x1p_outside, y1p_outside, x2p_outside, y2p_outside                  : Double;  // ���������� ������ ����� 1 ��� �������� �������
    x3p_outside, y3p_outside, x4p_outside, y4p_outside                  : Double;  // ���������� ������ ����� 2 ��� �������� �������

    xp_inside, yp_inside                          : Double;   // ���������� ����������� ���������� ������ �����
    xp_outside, yp_outside                          : Double;   // ���������� ����������� �������� ������ �����

    ang1, ang2      : Double; // ���� ����������, ����������������

    new_x_line1, new_y_line1,
    new_x_line2, new_y_line2            : Double;   // ����� ���������� �����
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

    // ���� ������� ������� ������, � �� ���� � ������ �� ������� ���������,
    // ������������� arc_mid, ����� �� ������� ����� ������� click_obj
  {  if ((x_click_obj1 <> nil) and (y_click_obj1 <> nil) and (x_click_obj2 <> nil) and (y_click_obj2 <> nil))
    then
    begin
        x_line1_mid := x_click_obj1;
        y_line1_mid := y_click_obj1;
        x_line2_mid := x_click_obj2;
        y_line2_mid := y_click_obj2;
    end;
    // � ������� �� ���������...
   }
    // ���������� ���� �����
    // �������� ������������ ����� �����������
    ang_line1 := DetectAngle360(x, y, x_line1_mid, y_line1_mid);
    ang_line2 := DetectAngle360(x, y, x_line2_mid, y_line2_mid);

    // ������ ������ ����� � ���� ������ �� Track1
    // �������� ��������������� ������, ������� sin <-> cos
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

    //  ���� ����� ����������� ������ ����� ���� � ������ inside-inside, outside-outside
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
    begin // ���� �� � ������ �������, �� ����� ������ ����
        PCBServer.SendMessageToRobots(Track1.I_ObjectAddress, c_Broadcast, PCBM_BeginModify, c_NoEventData);

        // ���� ����� ����������� ����� � x1
        if LengthOfLine(x, y, x1, y1) < LengthOfLine(x, y, x2, y2)
        then
        begin   // ������� x1
            Track1.x1 := MilsToCoord(new_x_line1);
            Track1.y1 := MilsToCoord(new_y_line1);
        end
        else    // ������� x2
        begin
            Track1.x2 := MilsToCoord(new_x_line1);
            Track1.y2 := MilsToCoord(new_y_line1);
        end;
        PCBServer.SendMessageToRobots(Track1.I_ObjectAddress, c_Broadcast, PCBM_EndModify , c_NoEventData);
    end;

    // ���� ��� ��� �������, ����� ����2 ������
    // ****** MODIFY TRACK 2 *******
    PCBServer.SendMessageToRobots(Track2.I_ObjectAddress, c_Broadcast, PCBM_BeginModify, c_NoEventData);

    // ����
    // - �����
    // - ���� �����
    // - ����� ����������� �� ��� ������� �����, �.�. ����� �������,
    //  �� ������� ������� �� ������� �����
    if ExtCut and (x_click_obj2 <> nil) and not(TwoPointOneSideOfLine(x1,y1,x2,y2,x3,y3,x4,y4)) then
    begin
        // ���� ����� ����� ��������� �� ������� x1,y1 ������������ ����� ����������� x,y
        if LengthOfLine(x3, y3, x_click_obj2, y_click_obj2) < LengthOfLine(x3, y3, x, y)
        then
        begin   // ������� x1
            Track2.x1 := MilsToCoord(new_x_line2);
            Track2.y1 := MilsToCoord(new_y_line2);
        end
        else    // ������� x2
        begin
            Track2.x2 := MilsToCoord(new_x_line2);
            Track2.y2 := MilsToCoord(new_y_line2);
        end;
    end
    else    // � ������ ����
            // - �� � ������ �������/��������� (x_click_obj2 = nil ��� <> nil, �������)
            // - � ������ �������, �� ������� �� ������, � �� ���������� ������� �������� (x_click_obj2 = nil)
            // - ���������� ���������, TwoPointOneSideOfLine(x1,y1,x2,y2,x3,y3,x4,y4) = TRUE
    begin
        // ���� ����� ����� ����� � x1
        // if LengthOfLine(x, y, x3, y3) < LengthOfLine(x, y, x4, y4)
        if LengthOfLine(x, y, x3, y3) < LengthOfLine(x, y, x4, y4)
        then
        begin   // ������� x1
            Track2.x1 := MilsToCoord(new_x_line2);
            Track2.y1 := MilsToCoord(new_y_line2);
        end
        else    // ������� x2
        begin
            Track2.x2 := MilsToCoord(new_x_line2);
            Track2.y2 := MilsToCoord(new_y_line2);
        end;
    end;

    PCBServer.SendMessageToRobots(Track2.I_ObjectAddress, c_Broadcast, PCBM_EndModify , c_NoEventData);

    Track1 := nil;
    Track2 := nil;

end;

// TrimmingObj - ����� �������, ����������� �������/���������
procedure FilletTrackAndArc(Const Track1 : IPCB_Track, Arc1 : IPCB_Arc, TrimmingObj : Integer);
var
    x1, y1, x2, y2                      : Double;  // ���������� ����� 1
    x_line_mid, y_line_mid              : Double;  // ����� ����� 1

    xa2, ya2, ra2                       : Double;  // ���������� � ������ ����-������� 2
    x_cross, y_cross                    : Double;   // ���������� ����������� ����� Track1 � ���� Arc1, ������ ������� �������� ����������
    x_arc_mid, y_arc_mid                : Double;   // ������� ����� ����

    CenterArcToLineDistance             : Double;  // ���������� �a��������� �� ������ ���� �� ����������� �����
    x1_lc, x2_lc, y1_lc, y2_lc          : Double;  // ����� ����������� ���������� � �����
    //TrackX_Normal, TrackY_Normal        : Double;  // ���������� ����� ����������� ������� � ������
    Track1_A_Norm_360                   : Double;  // ���� ������� � ����� 1 � ����������� 360 �� ����� ������� � ������ ����������� ����
    //Track1_A_360                        : Double;  // ���� ����� 1 � ����������� 360 �� ����� �������

    DirectionOfCenterFilletAboutArc     : integer;  // ��������� ������������ ������ ���������� ������������ ���������� Arc1
                                                    // +1 - ���������� � ������� ������� ���� Arc1
                                                    // -1 - ���������� � ���������� ������� ���� Arc1
    x1p, y1p, x2p, y2p                  : Double;  // ���������� ������ ����� 1

    new_x_line, new_y_line              : Double;   // ����� ���������� �����

begin
    x1 := CoordToMils(Track1.x1);
    y1 := CoordToMils(Track1.y1);
    x2 := CoordToMils(Track1.x2);
    y2 := CoordToMils(Track1.y2);

    xa2 := CoordToMils(Arc1.XCenter);
    ya2 := CoordToMils(Arc1.YCenter);
    ra2 := CoordToMils(Arc1.Radius);

    // ������� ���������� �� ����������� ����� �� ������ ����������� ����
    CenterArcToLineDistance := PointToLineDistance(x1, y1, x2, y2, xa2, ya2);

    // ���� ���������� �� ������ ���� �� ����� ������, ��� ������ ���� + 2� ������� ����������,
    // ���������� �� ���������
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

    // ���� �� �����, ����� � �������� ������������ ��� ����������
    // ������������� ���� �� ���������
    //DirectionOfCenterFilletAboutTrack := 1;     // ����� fillet ����� ���������� ������������ Track1 � ��� �� ��������, ��� � ����� ���������� Arc1
    DirectionOfCenterFilletAboutArc := 1;    // ������������ ���������� ������� ����

    // ������� ����� ����� � ����
    MidPointOfLine(x1, y1, x2, y2, x_line_mid, y_line_mid);
    MidPointOfArcByAngle(xa2, ya2, ra2, Arc1.StartAngle, Arc1.EndAngle, x_arc_mid, y_arc_mid);

    // ���� �� ������� ����� ���� �� ������� � ������
    Track1_A_Norm_360 := DetectAngleFromPointToLine(x_arc_mid, y_arc_mid, x1, y1, x2, y2);

    // ������ ����������� �� ��������� ����� ������� �� Track1
    // ���������� �������� = Arc_R
    // ���� �������� = Track1_A_Norm_360
    // ����������� �������� - � ��������������� ������� �� x_arc_mid, y_arc_mid ������������ Track1 (������� "-")
    x1p := x1 - Arc_R * cos(Track1_A_Norm_360 / 180 * Pi);
    y1p := y1 - Arc_R * sin(Track1_A_Norm_360 / 180 * Pi);
    x2p := x2 - Arc_R * cos(Track1_A_Norm_360 / 180 * Pi);
    y2p := y2 - Arc_R * sin(Track1_A_Norm_360 / 180 * Pi);

    // ���� ����� ����� ��������� ������ ����, �� ���������� ����� ������ ���� (ra2 - Arc_R)
    if LengthOfLine(xa2, ya2, x_line_mid, y_line_mid) < ra2 then
        DirectionOfCenterFilletAboutArc := -1;

    // ���� ����� ����������� ���������������� (r = ra2 + Arc_R) � �����������,
    // ��������� �� ���������� ���������� = Arc_R � ������ ����������
    // ��� -Arc_R, ���� �������� ������
    CircleLineCross(x1p, y1p, x2p, y2p, xa2, ya2, ra2 + (Arc_R * DirectionOfCenterFilletAboutArc), x1_lc, y1_lc, x2_lc, y2_lc);

    // ���� ������� ������� ������, � �� ���� � ������ �� ������� ���������,
    // ������������� arc_mid, ����� �� ������� ����� ������� click_obj
    if ((x_click_obj1 <> nil) and (y_click_obj1 <> nil) and (x_click_obj2 <> nil) and (y_click_obj2 <> nil))
    then
    begin
        //x_line1_mid := x_click_obj1;
        //y_line1_mid := y_click_obj1;
        x_arc_mid := x_click_obj2;
        y_arc_mid := y_click_obj2;
    end;

    // ��������� ����� ����� ����������� ����� � ������ ���� ��� � ������� ����� x_click_obj1
    if (LengthOfLine(x_arc_mid, y_arc_mid, x1_lc, y1_lc)) <
       (LengthOfLine(x_arc_mid, y_arc_mid, x2_lc, y2_lc)) then
    begin
        // ������ ����� x1_lc, y1_lc �����
        Arc_CenterX : = x1_lc;
        Arc_CenterY : = y1_lc;
    end
    else
    begin
        Arc_CenterX : = x2_lc;
        Arc_CenterY : = y2_lc;
    end;

    // New Track's parameters
    // ����� ���������� ����� �� ����� ����� (�������� �� ������ ���������� � ����� ��� ����� Track1_A_Norm_360)
    new_x_line := Arc_CenterX + Arc_R * cos(Track1_A_Norm_360 / 180 * Pi);
    new_y_line := Arc_CenterY + Arc_R * sin(Track1_A_Norm_360 / 180 * Pi);

    // New Arc's parameters
    // �� ������ ����������� ���� �� ������� �� �����.
    Angle1 := Track1_A_Norm_360;
    // ������ ���� �� ������ ����������� ���� �� ������ ����������� ����
    Angle2 := DetectAngle360(Arc_CenterX, Arc_CenterY, xa2, ya2);

    // ���� ���������� ������ ����, �� ����������� ������� ���� ���������������,
    // �� ������ ���� � ������ ����������
    if DirectionOfCenterFilletAboutArc = -1 then Angle2 := DetectAngle360(xa2, ya2, Arc_CenterX, Arc_CenterY);

    // ������������ ���� ����
    DetectArcStartEndAngle(Angle1, Angle2, Arc_Start_A, Arc_End_A);

    PCBServer.SendMessageToRobots(Track1.I_ObjectAddress, c_Broadcast, PCBM_BeginModify , c_NoEventData);
    PCBServer.SendMessageToRobots(Arc1.I_ObjectAddress, c_Broadcast, PCBM_BeginModify , c_NoEventData);

    if not(ExtCut) then
    begin
        /// ���� ����� ����������� ����� � x1y1
        if LengthOfLine(x1, y1, new_x_line, new_y_line) < LengthOfLine(x2, y2, new_x_line, new_y_line) then
        begin   // ������� x1
            Track1.x1 := MilsToCoord(new_x_line);
            Track1.y1 := MilsToCoord(new_y_line);
        end
        else    // ������� x2
        begin
            Track1.x2 := MilsToCoord(new_x_line);
            Track1.y2 := MilsToCoord(new_y_line);
        end;

        // Angle2 - ���� �� ������ ���������� � ������ ����������� ����������
        // ���� �� Angle2 ����������� ���� �������������, �� ����������� ������������� ����� ��
        // �� � ��������� �� 180
        if DirectionOfCenterFilletAboutArc = 1 then     // ���� ���������� ������� ����
        begin
            if Angle2 = Arc_End_A   then Arc1.EndAngle   := AngleTo360(Angle2 + 180);
            if Angle2 = Arc_Start_A then Arc1.StartAngle := AngleTo360(Angle2 + 180);
        end
        else     // ���� ���������� ������ ����
        begin
            if Angle2 = Arc_End_A   then Arc1.StartAngle   := AngleTo360(Angle2);
            if Angle2 = Arc_Start_A then Arc1.EndAngle := AngleTo360(Angle2);
        end;
    end
    else  // ExtCut = True;
    begin
        if TrimmingObj = 2 then // arc - prim1, track - prim2 => ������ ����� Track1
        begin
            // ������� ���������� ������� � ����� �� ������ ������� �� �����
            // �.�. ����� ���� �� x1y1 �� ����� ����������� new_x_line � �� ����� ����������� �� x2y2
            // ����� ����� �����, �� ���������� �������:
            if (x_click_obj2 <> nil) and (abs(LengthOfLine(x1,y1,new_x_line, new_y_line) +
                                              LengthOfLine(new_x_line, new_y_line, x2, y2) -
                                              LengthOfLine(x1,y1,x2,y2)) < e) then
            begin
                // ���� ����� ����� ��������� �� ������� x1,y1 ������������ ����� ����������� new_x_line, new_y_line
                if LengthOfLine(x1, y1, x_click_obj2, y_click_obj2) < LengthOfLine(x1, y1, new_x_line, new_y_line) then
                begin   // ������� x1
                    Track1.x1 := MilsToCoord(new_x_line);
                    Track1.y1 := MilsToCoord(new_y_line);
                end
                else    // ������� x2  (����� ����� ����� new_x_line � ������ �����������)
                begin
                    Track1.x2 := MilsToCoord(new_x_line);
                    Track1.y2 := MilsToCoord(new_y_line);
                end;
            end
            else // ������� ���������� ���������� ������� ���������, x_click_obj1 = nil
                 // ��� ���������� ���������
            begin
                // ���� ����� ����������� ����� � x1y1
                if LengthOfLine(x1, y1, new_x_line, new_y_line) < LengthOfLine(x2, y2, new_x_line, new_y_line) then
                begin   // ������� x1
                    Track1.x1 := MilsToCoord(new_x_line);
                    Track1.y1 := MilsToCoord(new_y_line);
                end
                else    // ������� x2
                begin
                    Track1.x2 := MilsToCoord(new_x_line);
                    Track1.y2 := MilsToCoord(new_y_line);
                end;
            end
        end
        else  // TrimmingObj = 1 track - prim1, arc - prim2 => ������ ����� Arc1
        begin
            // ������� ���������� ������� ��� ����� ���� �� ������ ������� �� �����
            if (x_click_obj2 <> nil) and not(TwoPointOneSideOfLine(x1, y1, x2, y2, CoordToMils(Arc1.StartX),
                                                                                    CoordToMils(Arc1.StartY),
                                                                                    CoordToMils(Arc1.EndX),
                                                                                    CoordToMils(Arc1.EndY))) then
            begin
                if LengthOfLine(CoordToMils(Arc1.StartX), CoordToMils(Arc1.StartY), x_click_obj2, y_click_obj2) <
                   LengthOfLine(CoordToMils(Arc1.StartX), CoordToMils(Arc1.StartY), new_x_line, new_y_line) then
                begin // Start ����� � ����� �����, ��� � ����� �����������, �� ������� Start
                    Arc1.StartAngle := DetectAngle360(xa2, ya2, new_x_line, new_y_line);
                end
                else     // ����� ������� End
                begin
                    Arc1.EndAngle := DetectAngle360(xa2, ya2, new_x_line, new_y_line);
                end;
            end
            else // ������� ���������� ���������� ������� ���������, x_click_obj1 = nil
                 // ��� ��� ��������� TwoPointOneSideOfLine = TRUE
            begin
                if DirectionOfCenterFilletAboutArc = 1 then     // ���� ���������� ������� ����
                begin
                    if Angle2 = Arc_End_A   then Arc1.EndAngle   := AngleTo360(Angle2 + 180);
                    if Angle2 = Arc_Start_A then Arc1.StartAngle := AngleTo360(Angle2 + 180);
                end
                else     // ���� ���������� ������ ����
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
    xa1, ya1, ra1                       : Double;  // ���������� � ������ ���� 1
    xa2, ya2, ra2                       : Double;  // ���������� � ������ ���� 2
    CenterArcToArcDistance              : Double;   // ��������� ����� �������� ���
    x_cross, y_cross                    : Double;   // ����� ����������� ���
    x1_ccc_outside, y1_ccc_outside,
    x2_ccc_outside, y2_ccc_outside,                 // ����� ����������� ������ ����������� �������
    x1_ccc_inside, y1_ccc_inside,
    x2_ccc_inside, y2_ccc_inside        : Double;   // ����� ����������� ������ ����������� �������
    x1_ccc, y1_ccc,
    x2_ccc, y2_ccc                      : Double;   // ����� ����������� ������ ����������� tmp

    dir_arc1, dir_arc2                  : integer;  // ����������� ���������� ������ �����������
                                                    // -1 - ������, +1 - ������

    l_inside1, l_inside2,
    l_outside1, l_outside2,             : Double;   // ��������� ���������� �� ����� ����������� ������ � �������
    l_min, l_tmp                        : Double;   // ����� ��� ������ ��������������

    x_arc_mid1, y_arc_mid1,
    x_arc_mid2, y_arc_mid2              : Double;   // ������� ����� ����

    ang1, ang2                          : Double;   // ���� ���� ����������

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

    if CenterArcToArcDistance < (abs(ra1 - ra2) + Arc_R * 2) then  // ���� ���������� ������ ������, Arc_R �� �������
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

    // ������� ����� ���
    MidPointOfArcByAngle(xa1, ya1, ra1, Arc1.StartAngle, Arc1.EndAngle, x_arc_mid1, y_arc_mid1);
    MidPointOfArcByAngle(xa2, ya2, ra2, Arc2.StartAngle, Arc2.EndAngle, x_arc_mid2, y_arc_mid2);

    dir_arc1 := 1; // ����� ���������� ���������� ������� Arc1
    dir_arc2 := 1; // ����� ���������� ���������� ������� Arc2

    // ���� �� ������������ ��� ������������, �� ������ �� ��������� ��������� ���������� ������
    // ���������� ����� ������� ����� ���
    if CenterArcToArcDistance > (ra1 + ra2 - (2 * Arc_R)) then
    begin
        // ������ ��� ������ ���������� � ��������� ra1 + Arc_r � ra2 + Arc_R
        // ���� ����� ����������� ���� ������ ���.
        CirclesCross(xa1, ya1, ra1 + Arc_R, xa2, ya2, ra2 + Arc_R, x1_ccc_outside, y1_ccc_outside, x2_ccc_outside, y2_ccc_outside);

        // �������� 2 ����� ����������� ����������������
        // ������ ���������� � ������� � �����, �������� ������������ � ������� ������ ���

        // ���� ��������� ����� � ��������� ���
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
            x_cross := x1_ccc_outside; // ���������, x_cross �� ����������, ���������� ��� ������� Arc.Start Arc.End
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

    // ���� ������������ � ����� ��� ����� �����������.
    // �������������, ���������� ������ ����������� ������
    // ��������� ���� �� ����� �� ���������� ������, ��� ������� ����������, 2 * Arc_R
    if CenterArcToArcDistance < (ra1 + ra2 - (2 * Arc_R)) then
    begin
        // ����� ����������� ���
        CirclesCross(xa1, ya1, ra1, xa2, ya2, ra2, x1_ccc, y1_ccc, x2_ccc, y2_ccc);

        // ���� ���������
        // ���� ������ ����� ����������� ����� � ������� (mid ��� click), �� ��� ����� ������� � �����������
        if (LengthOfLine(x1_ccc, y1_ccc, x_arc_mid1, y_arc_mid1) + LengthOfLine(x1_ccc, y1_ccc, x_arc_mid2, y_arc_mid2)) <
           (LengthOfLine(x2_ccc, y2_ccc, x_arc_mid1, y_arc_mid1) + LengthOfLine(x2_ccc, y2_ccc, x_arc_mid2, y_arc_mid2))
        then
        begin
            x_cross := x1_ccc;
            y_cross := y1_ccc;
        end
        else  // ����� - ������
        begin
            x_cross := x2_ccc;
            y_cross := y2_ccc;
        end;

        // ���������� ����������� ������ �����������
        // ���� ���������� �� ������ Arc1 �� mid2 ������ ������� ra1
        if LengthOfLine(xa1, ya1, x_arc_mid2, y_arc_mid2) < ra1
        then // �� ����� ���������� ����� ������ Arc1
            dir_arc1 := -1;

        // ���� ���������� �� ������ Arc2 �� mid1 ������ ������� ra2
        if LengthOfLine(xa2, ya2, x_arc_mid1, y_arc_mid1) < ra2
        then // �� ����� ���������� ����� ������ Arc1
            dir_arc2 := -1;

        // ����������� ������-�����������
        CirclesCross(xa1, ya1, ra1 + dir_arc1 * Arc_R, xa2, ya2, ra2 + dir_arc2 * Arc_R, x1_ccc, y1_ccc, x2_ccc, y2_ccc);
        // ��������� � x_cross ����� ������� ����������
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
        begin // ��� (dir = -1) = ang, (dir = 1) = ang + 180
            Arc1.StartAngle := ang1 + 90 + (90 * dir_arc1);
        end
        else
        begin
            Arc1.EndAngle : = ang1 + 90 + (90 * dir_arc1);
        end;
        PCBServer.SendMessageToRobots(Arc1.I_ObjectAddress, c_Broadcast, PCBM_EndModify , c_NoEventData);
    end;

        PCBServer.SendMessageToRobots(Arc2.I_ObjectAddress, c_Broadcast, PCBM_BeginModify , c_NoEventData);

        if (x_click_obj2 <> nil) and ExtCut then // ���� ���� ����� � ������ �������, ������� ����� �� ������ ����� � x_click
        begin
            if LengthOfLine(CoordToMils(Arc2.StartX), CoordToMils(Arc2.StartY), x_click_obj2, y_click_obj2) <
               LengthOfLine(CoordToMils(Arc2.StartX), CoordToMils(Arc2.StartY), x_cross, y_cross) then
                Arc2.StartAngle := ang2 + 90 + (90 * dir_arc2)
            else
                Arc2.EndAngle := ang2 + 90 + (90 * dir_arc2);
        end
        else    // ���� �� ���� ������ ������� ������������ �����������
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
    str_obj1, str_obj2      : String; // ������ �����������

    Net                 : IPCB_Net;
    Prim1               : IPCB_Primitive;
    Prim2               : IPCB_Primitive;
    ObjSet              : integer;          // ����������, ��� � ������
    BoardIterator       : IPCB_BoardIterator;
    Layer               : TLayer;

    // ����������, ���� ������� �����-���� �������
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

    sms_sel := false; //���-�� ��������
    ArcSel := nil;
    Prim1Sel := nil;
    Prim2Sel := nil;
    get3obj := false; //�������� 3 ������� � ��� 2 ����� � ����


    //���� �������� ��������� ��������
    // ���� �������� ����� 3� ��������
    if PCBBoard.SelectecObjectCount > 3 then exit;

    if PCBBoard.SelectecObjectCount <> 0 then
    begin
        // ��������, ��� ��������. ���� ���� ���������� ������, �� ��� ������ ���� ���� ��� �����
        for i := 0 to 2 do
        if (PCBBoard.SelectecObject[i] <> nil) and
           (PCBBoard.SelectecObject[i].ObjectId <> eTrackObject) and
           (PCBBoard.SelectecObject[i].ObjectId <> eArcObject)
            then exit;

        sms_sel := true;   // ���-�� ��������
        case PCBBoard.SelectecObjectCount of

            //  ������� 1 ������. ������ ���� ����, ������ �� ������
            1:  begin
                    if PCBBoard.SelectecObject[0].ObjectId = eArcObject
                    then
                    begin
                        ArcSel := PCBBoard.SelectecObject[0];
                        Arc_R := CoordToMils(ArcSel.Radius);
                    end
                    else exit;
                end; // 1:

            //  �������� 2 �������. ������ ���� ������ Track ��� Arc
            2:  begin
                    Prim1Sel := PCBBoard.SelectecObject[0];
                    Prim2Sel := PCBBoard.SelectecObject[1];
                end; // 2:

            //  �������� 3 �������. ������ ���� ��� ����� � ����
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
                    if not(get3obj) then exit; // ������� 3 �������, �� ��� �� ��� ����� � �� ����.
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
            //���� ������ ������ ������
            if Prim1Sel <> nil then Prim1 := Prim1Sel //���� ��������� ���������� �����, � ����������� ������ �� ��������
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

            if Prim2Sel <> nil then Prim2 := Prim2Sel //���� ��������� ���������� �����, � ����������� ������ �� ��������
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

        // ���������� ����. �� ��������� ���������� ���� ������� �������
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

        // ���� �� ����� �� ��������� ����� ��������, ����� ������
        if EmergencyExit then exit;


        //***** ADDING FILLET ARC ******
        if not(Extcut) then //���� �� �����/��������
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

            if PCBBoard <> nil then   // ���� �������� � .PcbDoc
            begin
                PCBServer.SendMessageToRobots(PCBBoard.I_ObjectAddress,c_Broadcast,PCBM_BoardRegisteration,Arc.I_ObjectAddress);
                PCBBoard.AddPCBObject(Arc);
            end
            else   // �������� � .PcbLib
            begin
                PCBServer.SendMessageToRobots(PCBLibrary.Board.I_ObjectAddress,c_Broadcast,PCBM_BoardRegisteration,Arc.I_ObjectAddress);
                PCBBoard.AddPCBObject(Arc);
            end;

            //If editing track in Component
            If Prim1.InComponent then Prim1.Component.AddPCBObject(Arc);

            //Arc.EndModify;

            PCBBoard.ViewManager_FullUpdate;
            Arc := nil;
        end;  // if not(Extcut) then //���� �� �����/��������



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
