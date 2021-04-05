//Adjust Net Length v 3.0
Uses Registry;

// �������� ��� ��������
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
    { ������ ������ TRegistry }
    Registry := TRegistry.Create;
    Try
        { ������������� �������� ����; ������� hkey_local_machine ��� hkey_current_user }
        //Registry.RootKey := HKEY_CURRENT_USER; {��������������� �������������}
        { ��������� � ������ ���� }
        Registry.OpenKey('Software\AltiumScripts\AdjustNetLength',true);

        if Registry.ValueExists('ManualLength')  then editManual.Text := Registry.ReadString('ManualLength');
        if Registry.ValueExists('DeltaLength')   then editDelta.Text := Registry.ReadString('DeltaLength');
        if Registry.ValueExists('DRCheck')       then CheckBoxRules.Checked := Registry.ReadBool('DRCheck');
        if Registry.ValueExists('FixTrace')      then CheckBoxRules.Checked := Registry.ReadBool('FixTrace');
        if Registry.ValueExists('FixTrace')      then CheckBoxFix.Checked := Registry.ReadBool('FixTrace');

        { ��������� � ����������� ���� }
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
    { ������ ������ TRegistry }
    Registry := TRegistry.Create;
    Try
        { ������������� �������� ����; ������� hkey_local_machine ��� hkey_current_user }
        //Registry.RootKey := HKEY_CURRENT_USER; {��������������� �������������}
        { ��������� � ������ ���� }
        Registry.OpenKey('Software\AltiumScripts\AdjustNetLength',true);
        { ���������� �������� }

        Registry.WriteString('ManualLength',   floattostr(editManual.Text));
        Registry.WriteString('DeltaLength',   floattostr(editDelta.Text));
        Registry.WriteBool('DRCheck',   CheckBoxRules.Checked);
        Registry.WriteBool('FixTrace',  CheckBoxFix.Checked);

        { ��������� � ����������� ���� }
        Registry.CloseKey;
    Finally
        Registry.Free;
    End;

End;

function Compare2Coord(const x1, y1, x2, y2 : TCoord) : Boolean;
// ��������� ��������� : x1 y1 x2 y2
begin
    Result := false;
    if ((abs(x2 - x1) < eCoord) and (abs(y2 - y1) < eCoord))
    then
    Result := true;
end;

function Compare4Coord(const x1, y1, x2, y2, x3, y3, x4, y4 : TCoord) : Boolean;
// ������������ ��������� ��������� ������� 1: x1 y1 x2 y2
// � �������� 2: x3 y3 x4 y4
// ������������� ������� ��� ���������� ����� �� ���
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
// ����������� �� ����� ��������������
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
    // ���� � ������������ ����
    while (i < Board.SelectecObjectCount - 1) do
    begin
        while j < Board.SelectecObjectCount do
        begin
            // ���� ���������� ������ ��� � �����
            if j = i then inc(j);
            // ���� ��� ������� - ����
            if (Board.SelectecObject[i].ObjectID = 1) and (Board.SelectecObject[j].ObjectID = 1) then
            begin
                Arc1 := Board.SelectecObject[i];
                Arc2 := Board.SelectecObject[j];
                // ���� ��������� ����� � ���� �� ������
                if Compare2Coord(Arc1.XCenter, Arc1.YCenter,
                                 Arc2.XCenter, Arc2.YCenter) and
                   Compare4Coord(Arc1.StartX, Arc1.StartY,
                                 Arc1.EndX, Arc1.EndY,
                                 Arc2.StartX, Arc2.StartY,
                                 Arc2.EndX, Arc2.EndY)
                then
                begin // ���������, ����� �� ������ ������
                    if Compare2Coord(Arc1.StartX, Arc1.StartY,
                                     Arc2.EndX, Arc2.EndY)
                    then        // ���� Start[i] ��������� � End[j]
                        Arc1.StartAngle := Arc2.StartAngle
                    else        // ���� End[i] ��������� �� Start[j]
                        Arc1.EndAngle := Arc2.EndAngle;

                    Board.RemovePCBObject(Arc2);
                    i: = -1;
                    break;
                end
                else // �� ����� ���������� ���������
                begin
                    inc(j);
                end;

            end
            else  // ���-�� �� ����, not ((Board.SelectecObject[i].ObjectID = 1) and (Board.SelectecObject[j].ObjectID = 1))
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


    SelectedPrimsEdit   : TStringList; // ���������� ��������� ��� �������������� �� �������� SelectedPrims
    SelectedPrims   : TStringList;    //���������� ���������
    ExtTrimPrims    : TStringList;   //��������� ��� ��������� ��� ������������
    ExtTrimPrimsA   : TStringList;   //���� ���������� ��� ��������� ��� ������������
    DblDetect       : Boolean;      //���������� ��������� ��������� � TStringList
    PrimExtA        : Real;

    Net1                : IPCB_Net;
    Net2                : IPCB_Net;
    NetTmp              : IPCB_Net;
    NetTarget           : IPCB_Net;
    NetCurrent          : IPCB_Net;     //������� ���� � ����� ��� ��������
    boolMultyNet        : boolean;      //������� ��������� �����
    boolDiffPairNet     : boolean;      //��� (!) ��������� ���� �������� ������ ����� ��������
    boolMoveAndResizePrimSel : boolean; //Selection Primitive �� ������ ����������, �� ��� � �������� ���������

    NetClass            : IPCB_ObjectClass;
    NetClassTmp         : IPCB_ObjectClass; //��������� ����� ����� ��� ���������
    NetClassesList      : TStringList; //�������� �������, ���� ������ ���� ����
    // OurNetClassNet      : TstringList; //�������� ����� � ����� ������
    // OurNetClassNetTmp   : TstringList; //�������� ����� ���������
    NetCountMin         : Long;
    NetCountTmp         : Long;
    strNetClass         : string;

    LenNet1       : real;
    LenNetTmp     : real;
    LenNetTarget  : real;
    DeltaNet      : real;
    DeltaPrimExt  : TCoord;
    LenPrimExt    : TCoord; //����� �����
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

    //���� ������ �� �������
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

    //��������� SelectedPrims : TStringList ���� � ������� ��������� ����������
    SelectedPrims := TStringList.Create;
    //��������� ���� � ���������, ��������������� � ���������, �� ����� ����� ��������� ��� ���������
    ExtTrimPrims := TStringList.Create;
    j := 0; //Iterator for ExtTrimPrims

    //��� ������ ���� ����� � ������� ����������� �������
    Net1:=Board.SelectecObject[0].Net;
    NetName1 := Net1.Name;

    //���� ���� ������ � ��������
    if Net1.InDifferentialPair then
    begin
        //��������� �������� ��� ����������� �������� ��� �������
        Iterator:= Board.BoardIterator_Create;
        Iterator.AddFilter_ObjectSet(MkSet(eDifferentialPairObject));
        Iterator.AddFilter_LayerSet(AllLayers);
        Iterator.AddFilter_Method(eProcessAll);
        DiffPair := Iterator.FirstPCBObject;

        While DiffPair <> Nil do
            begin
            if (Net1 = DiffPair.PositiveNet) or (Net1 = DiffPair.NegativeNet) then
                begin
                //���������� ���� � ��������
                boolDiffPairNet := True;
                break;
                end;
            DiffPair := Iterator.NextPCBObject;
            end;
        Board.BoardIterator_Destroy(Iterator);
    end;

    // *** �����������/������� ���������� �������
    if CheckBoxFix.Checked then FixTrace;
    // *** ��������� �������������/�������

    //�������� �� ��� ����������

    for i := 0 to Board.SelectecObjectCount - 1 do
    begin

        //��������� ������ ���� ������� ��� ������, ���� ���, �� �����
        if ((Board.SelectecObject[i].ObjectId <> eTrackObject) and (Board.SelectecObject[i].ObjectId <> eArcObject)) then
        begin
            ShowMessage('Please select only tracks or/and arcs');
            exit;
        end;

        //���� ��� ���� ��� ����� ��� ������ ���� ��� � �����
        if (not Board.SelectecObject[i].InNet) then
        begin
            ShowMessage('All selected objects must be in a net');
            exit;
        end;
        //���� ��� ������� ��������� ������� ����������� � ���� SelectedPrims
        SelectedPrims.AddObject(IntToStr(i), Board.SelectecObject[i]);

        //////////**    ���� ������������ ����� ������ ���������� ����������
        //��������� ���������� ������ � PrimSel
        PrimSel := SelectedPrims.GetObject(i);

        //��������� ������ ����� (��������� ������� ������)
        if PrimSel.ObjectID = 4 then //��������� ������ - �����
            PrimSelWidth := PrimSel.Width;
        if PrimSel.ObjectID = 1 then //��������� ������ - ����
            PrimSelWidth := PrimSel.LineWidth;

        //���������� �������������, ����������� ��� ��������
        Rectangle := PrimSel.BoundingRectangle;

        // ��������� ������� ��������������, ������� ������ PrimSel
        // �������� � �������� ����������� eCoord = 10 = 0.001 mil
        Rectangle.Left :=   Rectangle.Left   + PrimSelWidth / 2 - eCoord;
        Rectangle.Bottom := Rectangle.Bottom + PrimSelWidth / 2 - eCoord;
        Rectangle.Right :=  Rectangle.Right  - PrimSelWidth / 2 + eCoord;
        Rectangle.Top :=    Rectangle.Top    - PrimSelWidth / 2 + eCoord;

        //������� �������
        BoardIterator := Board.SpatialIterator_Create;
        //����� ��������� ������ �����
        BoardIterator.AddFilter_ObjectSet(MkSet(eTrackObject));
        BoardIterator.AddFilter_LayerSet(MkSet(PrimSel.Layer));
        //������ ������� ������
        BoardIterator.AddFilter_Area(Rectangle.Left,
                                    Rectangle.Bottom,
                                    Rectangle.Right,
                                    Rectangle.Top);
        //������� ������ �������� � ���� �������
        PrimExt := BoardIterator.FirstPCBObject;

        //PrimExtAll := 0;
        //PrimExtFilter := 0;
        //���� �� ���������� �������
        //��������� � ExtTrimPrims     //����� ��������� ���������� PRIMEXT, ������� �������� � BOUNDING RECTANGLE!!!!
        while PrimExt <> Nil do
        begin
        //Inc(PrimExtAll);
            if (Not(PrimExt.Selected)) and // �������� ������ ���� �� ����������
               (PrimExt.ObjectID=eTrackObject) and // �������� ������ ���� ������
               (PrimExt.Layer=PrimSel.Layer) and //������ ���������� � ����� ���� � ����������� ��������� (������� ��� ��������, �� �� �����)
               (PrimExt.Net.Name=PrimSel.Net.Name) //������������ ����� ����
               then

            // ���� ��� ������, �������� �������� �� � Rectangle X � Y �� ������� �������� ������
            if PointInRect(PrimExt.X1, PrimExt.Y1, Rectangle)
                or
               PointInRect(PrimExt.X2, PrimExt.Y2, Rectangle)
               then
            begin

                //��������� ���������� ������������� �������� � ����������
                if PrimSel.ObjectID = 1 then //��������� ������ - ����
                begin   //���� X ��� Y ��������� � ����� �� ����� ���������� ����
                    if not (Compare4Coord(PrimExt.X1, PrimExt.Y1, PrimExt.X2, PrimExt.Y2,
                                    PrimSel.StartX, PrimSel.StartY, PrimSel.EndX, PrimSel.EndY))
                        then
                        begin
                            PrimExt := BoardIterator.NextPCBObject;
                            Continue;
                        end;
                end;

                if PrimSel.ObjectID = 4 then //��������� ������ - �����
                begin
                    if not (Compare4Coord(PrimExt.X1, PrimExt.Y1, PrimExt.X2, PrimExt.Y2,
                                    PrimSel.X1, PrimSel.Y1, PrimSel.X2, PrimSel.Y2))
                        then
                        begin
                            PrimExt := BoardIterator.NextPCBObject;
                            Continue;
                        end;
                end;

                    //��������� ��������� ����������.

                    //����� ���������� ����;
                    PrimExtA:=arctan2((PrimExt.Y2 - PrimExt.Y1),(PrimExt.X2 - PrimExt.X1))/Pi*180;

                    //���� ������� 90 ������� ��������������
                    if (PrimExt.Y2 = PrimExt.Y1) and (PrimExt.X2 > PrimExt.X1) then PrimExtA := 0;
                    if (PrimExt.Y2 = PrimExt.Y1) and (PrimExt.X2 < PrimExt.X1) then PrimExtA := 180; //����������
                    if (PrimExt.Y2 > PrimExt.Y1) and (PrimExt.X2 = PrimExt.X1) then PrimExtA := 90;
                    if (PrimExt.Y2 < PrimExt.Y1) and (PrimExt.X2 = PrimExt.X1) then PrimExtA := 270; //����������?..

                    //������ �������� ������ 123456789 = 12345.6789 mil
                    //RoundTo - ���������� �� 10 -> 12345.678 mil (���������)
                    if PrimSel.ObjectID = 1 then //��������� ������ - ����
                    begin   //���� X2 ��� Y2 ��������� � ����� �� ����� ���������� ���� (�������� +2, 0.010 mil), �� ���������� 180
                        if Compare4Coord(PrimExt.X2, PrimExt.Y2, PrimExt.X2, PrimExt.Y2,
                                        PrimSel.StartX, PrimSel.StartY, PrimSel.EndX, PrimSel.EndY)
                            then PrimExtA := PrimExtA + 180;
                    end;

                    if PrimSel.ObjectID = 4 then //��������� ������ - �����
                    begin
                        if Compare4Coord(PrimExt.X2, PrimExt.Y2, PrimExt.X2, PrimExt.Y2,
                                        PrimSel.X1, PrimSel.Y1, PrimSel.X2, PrimSel.Y2)
                            then PrimExtA := PrimExtA + 180;
                    end;


                    //���� ��� �� ���� �� ������
                    if ExtTrimPrims.Count < 1 then
                    begin
                        ExtTrimPrims.AddObject(IntToStr(PrimExtA), PrimExt);   //������ ������ ������ � ExtTrimPrims
                    end
                    else   //���� ��� ���� �������, ����������� ������ �����
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

                //���������� ��������� ������� ����� ������� � ����, ��� ��� ���� � ������ ExtTrimPrims
                //��������� � ����� �����, ���� ����� �����������
                //else    // if j > 0
                //begin

                //end;

            end; //if Not(PrimExt.Selected)...
            PrimExt := BoardIterator.NextPCBObject;
        end; //while PrimExt <> Nil

        Board.SpatialIterator_Destroy(BoardIterator);
        //PrimExt.GraphicallyInvalidate;

        //ShowMessage('����� PrimExtAll - ' + InttoStr(PrimExtAll) + #13#10 +
        //            '������ ����� ������ - ' + InttoStr(PrimExtFilter));


        /////////////////**   ����� ������ ������������ ����� ������ ���������� ����������



        NetCurrent:=Board.SelectecObject[i].Net;
        //NetName2 := Net2.Name;

        //�������� ���� � ������� �������
        if NetCurrent <> Net1
        then
        begin
            boolMultyNet := True;   //������� ���������, ������������� ���������� �����
        end;

        //���� ������� ����, �� ������ �� � ����� � ��������
        if Not(NetCurrent.InDifferentialPair) then
        begin
            boolDiffPairNet := False;
        end;

        //���� ���� ������ � ��������, �� ��� �������� �� ��������� � ������ �������� ������� �������
        if  NetCurrent.InDifferentialPair and               //���� ������� ���� Board.SelectecObject[i].Net ������ � ��������
            boolDiffPairNet and                             //���� ������ ���� Board.SelectecObject[0].Net ������ � ��������
            (NetCurrent <> DiffPair.PositiveNet) and        //������� ���� �� ������ � ������ ��������
            (NetCurrent <> DiffPair.NegativeNet) then       //
        begin
            boolDiffPairNet := False;  //��������� boolDiffPairNet, �.�. �� ������ � ���� ��������
        end;

    end;//for i := 0 to Board.SelectecObjectCount - 1 do


    //��� �������� ������������� ����:
    //1. �������� ���� ���� � ��� �������� ������ ��������: ��������� �� ������ ����� ��������
    //2. �������� ���� ���� � ��� �� �������� ������ ��������: ������������� �� ������ (����� ������ ���� ��������)
    //3. �������� 2 ����, ���������� ������ ����� ��������
    //4. �������� ����� ����� ����, �� ���������� ������ ����� ��������

   //������� 1 - �������� ���� ���� � ��� �������� ������ ���� ����
   if Not(boolMultyNet) and (Board.SelectecObject[0].Net.InDifferentialPair) then
        TuningVariant := 1;

   //������� 2 - �������� ���� ����, �� ���������� ������ ��������
   if Not(boolMultyNet) and (Not(Board.SelectecObject[0].Net.InDifferentialPair)) then
        TuningVariant := 2;

   //������� 3 - �������� 2 ����, ���������� ������ ����� ��������
   if boolMultyNet and boolDiffPairNet then
        TuningVariant := 3;

   //������� 4 - �������� ����� ����� ����, �� ���������� ������ ����� ��������
   if boolMultyNet and not(boolDiffPairNet) then
        TuningVariant := 4;

if (not (boolModeManual or boolModeDeltaPlus or boolModeDeltaMinus)) and (TuningVariant <> 1) then    //����� ��
    begin
        // ��� ������ ������� AUTO ����� ����������, ������ �� ���� � �����-������ �� �������
        // ���� ���� �� ������ �� � ���� �� �������, � �� �������� ������ �������� (TuningVariant - 1)
        // ��������� RoutedLength ������������� �� ���������
        // �������� ������ �������

        //���������� ������ ������ ����������� ����
        //������� ������ �������
        Iterator := Board.BoardIterator_Create;
        Iterator.SetState_FilterAll;
        Iterator.AddFilter_ObjectSet(MkSet(eClassObject));
        NetClass := Iterator.FirstPCBObject;

        // ������� ����� TStringList
        NetClassesList := TStringList.Create; //������ (�� ����� ���� ���������), ���� ������ ���� ����

        While NetClass <> Nil Do
        begin
            //���� ������� ����� � �������� � ���� ����
            if (NetClass.IsMember(Net1)) and (NetClass.MemberKind = eClassMemberKind_Net) and (NetClass.Name <> 'All Nets') then
                NetClassesList.AddObject(NetClass.Name, NetClass);

            NetClass := Iterator.NextPCBObject;
        end; //NetClass <> Nil
        Board.BoardIterator_Destroy(Iterator);

        if NetClassesList.Count = 0 then // ���� �� ������ �� � ���� �� �������
        begin
            GetManualLengthDialog(Net1.RoutedLength);
        end;
    end;

//��������� Net2 ������ ��� �������� Auto
if not (boolModeManual or boolModeDeltaPlus or boolModeDeltaMinus) then    //����� ��
begin


    //********************* NET CLASS ********************

    //���� ���� ���� � �� �������� ������ ��������, �� ���� � NetClass
   if TuningVariant <> 1 then  //����� ��������, ����� ������� ���� ���� � ������� ��������
   begin

        if NetClassesList.Count > 0 then
        begin

            NetCountMin := 0;
            //NetClass.;
            //�������� ������ �����
            NetClass := NetClassesList.GetObject(0);

            //���������� ���������� �����, �������� � ���� �����
            Iterator := Board.BoardIterator_Create;
            Iterator.AddFilter_ObjectSet(MkSet(eNetObject));
            Iterator.AddFilter_LayerSet(AllLayers);
            Iterator.AddFilter_Method(eProcessAll);
            Net2 := Iterator.FirstPCBObject;

            While Net2 <> Nil do //������� ��� ����
                begin
                If (NetClass.IsMember(Net2)) then  //���� ���� ����������� ������������ ������
                    begin
                    Inc(NetCountMin);
                    end;
                Net2 := Iterator.NextPCBObject;
                end;
            Board.BoardIterator_Destroy(Iterator);    //Destroy Net Iterator

            //���� �������, ���� �������� ���� ���� ������ ������,
            //�� ��� ������������ �������� �����, ���� ������ ������� ���������� �����
            //������������ ���������� �����, �������� � ��������� ������

            for i := 1 to NetClassesList.Count - 1 do //���� �� �������
            begin
                NetCountTmp := 0; //������� ��� �����
                NetClassTmp := NetClassesList.GetObject(i);
                //� ������ ������ ���� �������� �� �����
                Iterator:= Board.BoardIterator_Create;
                Iterator.AddFilter_ObjectSet(MkSet(eNetObject));
                Iterator.AddFilter_LayerSet(AllLayers);
                Iterator.AddFilter_Method(eProcessAll);
                Net2 := Iterator.FirstPCBObject;

                While Net2 <> Nil do
                    begin
                    If (NetClassTmp.IsMember(Net2)) then  //���� ���� ����������� ������������ ������
                        begin
                            Inc(NetCountTmp);
                        end;
                    Net2 := Iterator.NextPCBObject;
                    end;
                Board.BoardIterator_Destroy(Iterator);
                //�������� ���������, ���������� ���������� �����, ���������

                if NetCountTmp < NetCountMin then //���� � ����������� ������ ������� ���������� �����, ��� � ����������
                    begin
                        NetCountMin := NetCountTmp;
                        NetClass := NetClassesList.GetObject(i);
                    end;

            end; //for i := 1 to NetClassesList.Count - 1
        end;

        //frmMain.ShowModal;
        NetCountTmp:=1;
        //��������� ����� ������ ���� � ������
        Iterator := Board.BoardIterator_Create;
        Iterator.AddFilter_ObjectSet(MkSet(eNetObject));
        Iterator.AddFilter_LayerSet(AllLayers);
        Iterator.AddFilter_Method(eProcessAll);
        Net2 := Iterator.FirstPCBObject;

        While Net2 <> Nil do //������� ��� ����
            begin

            //���� ���� ����������� ������������ ������
            //Net1 �� ���������, �������� ��� �������� ����� �������, ����� ����� ������� �� 2-�� �� ����� ����
            if (NetClass.IsMember(Net2)) and (Net2.Name <> Net1.Name) then

            //���� ������� ��������, �� ���� � �������� ������ ��������������
            if (Copy(Net1.Name, 1, Length(Net1.Name) - 2)) <> (Copy(Net2.Name, 1, Length(Net2.Name) - 2))
                then
                begin
                    if NetCountTmp = 1 then        //������������ ����� ��� ������ ���� � ������
                    begin
                        //LeftStr(Net1.Name, Length(Net1.Name) - 2);
                        //NetName2 := Net2.Name;
                        //LenNet2 := CoordToMMs(Net2.RoutedLength);
                        NetTmp := Net2;
                    end;

                    //������������ ����� ��� ������ � ����������� ����� � ������
                    //���� ��������� ���� �������, �����������, ��� ���������� �����������, �� ��� ����� �������
                    //����������� - NetTmp
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
    //Net1 � Net2 ����������

    end;  // TuningVariant <> 1


    //���� �������� ���� ���� � ��� �������� ������ ���� ����
    //�������� ���������� ����
    //DiffPair <> Nil
    If TuningVariant = 1 then
    begin
        if DiffPair <> Nil then
            begin
            if (Net1 = DiffPair.PositiveNet) or (Net1 = DiffPair.NegativeNet) then
                begin
                //���������� ���� � ��������
                if Net1 = DiffPair.PositiveNet
                    then Net2 := DiffPair.NegativeNet
                    else Net2 := DiffPair.PositiveNet;
                end;
            end
            else
            ShowMessage ('Something wrong...');

    end;

    //������� 2  �������� ���� ����, �� ���������� ������ ��������
    If TuningVariant = 2 then
    begin
        // ��������� �� ������� ������� ����� ���� ����
        // ���� �� � ����, �� ������� (��� ���������� ������...)
        // �� ������ ����� �� ����� �����!
        if NetClassesList.Count < 1 then
            begin
            showmessage('���� �� ������� �� � ����� �� �������!');
            exit;
            end;
    end;

    //������� 3  �������� 2 ����, ���������� ������ ����� ��������
    If TuningVariant = 3 then
    begin
        if NetClassesList.Count < 1 then
        begin
            showmessage('���� �� ������� �� � ����� �� �������!');
            exit;
        end;

        if DiffPair <> Nil then
            begin
            if (Net1 = DiffPair.PositiveNet) or (Net1 = DiffPair.NegativeNet) then
                begin
                //���������� ��� ������ � ��������, �� � �������
                if DiffPair.NegativeNet.RoutedLength > DiffPair.PositiveNet.RoutedLength
                    then Net1 := DiffPair.NegativeNet
                    else Net1 := DiffPair.PositiveNet;
                end;
            end
            else
            ShowMessage ('Something wrong...');
    end;

     //������� 4  �������� ����� ����� ����, �� ���������� ������ ����� ��������
    if TuningVariant = 4 then
    begin
        showmessage('���������� ������� ���� ���� ����, ���� 2 ����, ������������� ����� ��������!');
        exit;
    end;

    LenNetTarget := Net2.RoutedLength; //Target

end; //��������� ��������� Net2

    LenNet1 := Net1.RoutedLength; //Selected

    //���� ������ ������ �����
    if boolModeManual then
        LenNetTarget := MMsToCoord(strtofloat(editManual.Text));

    //��������� ������� ����� ����
    DeltaNet := LenNetTarget - LenNet1;

    if boolModeDeltaPlus then
        DeltaNet := MMsToCoord(strtofloat(editDelta.Text));

    if boolModeDeltaMinus then
        DeltaNet := - MMsToCoord(strtofloat(editDelta.Text));

    //���� ������� ������ ���� ������ ��� ��� �������, ���������� ���������� _P � _N ��������
    if (SelectedPrims.Count = 1) or ((SelectedPrims.Count = 2) and (TuningVariant = 3)) then
        boolMoveAndResizePrimSel := true;

    //��� ������� ���� ������ ��� �������� ��� �
    //������� 3 - �������� 2 ����, ���������� ������ ����� ��������
    if boolMoveAndResizePrimSel then
    begin //��� �������, ��� ���� ����� PrimExt = 90
        if PrimSel.ObjectID = 1 then //��������� ������ - ����
        DeltaPrimExt := RoundTo(2 * DeltaNet / (4 - Pi), 0);
        if PrimSel.ObjectID = 4 then //��������� ������ - �����
        DeltaPrimExt := RoundTo((DeltaNet * sin (45 / 180 * Pi)) / (2 * sin (45 / 180 * Pi) -1), 0);
    end
    else //������� ���� ��������, �.�. ���� ����� PrimExt = 0, classic mode
    begin
        DeltaPrimExt:=DeltaNet / 2;
    end;



    Violation_Count := 0;
    PrimViolation_Count  := 0;
    DlgOk   := false;

    //���������� ������������� ������ ������� ���������
    Rectangle := SelectedPrims.GetObject(0).BoundingRectangle;


    //DeltaPrimExt �� ������ ���� ������ ���� ���������� PrimExt
    for j:=0 to ExtTrimPrims.Count - 1 do
    begin
        PrimExt := ExtTrimPrims.GetObject(j);
        LenPrimExt := RoundTo(sqrt (sqr(PrimExt.X2 - PrimExt.X1) + sqr(PrimExt.Y2 - PrimExt.Y1)), 0);
        if (abs(DeltaPrimExt) > LenPrimExt) and (DeltaPrimExt > 0) and (DeltaNet < 0) then
            DeltaPrimExt := LenPrimExt;
        if (abs(DeltaPrimExt) > LenPrimExt) and (DeltaPrimExt < 0) and (DeltaNet < 0) then
            DeltaPrimExt := - LenPrimExt;
    end;



    //������������� ByX, ByY ���� �������� ������ ����� �������
   { for j:=0 to ExtTrimPrims.Count - 1 do
    begin
        PrimExt := ExtTrimPrims.GetObject(j);
        PrimExtA := strtofloat(ExtTrimPrims[j]);

        //���������� delta X, delta Y � ����������� �� 0

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

            // ����� ������� PrimExt
            PCBServer.SendMessageToRobots(PrimExt.I_ObjectAddress, c_Broadcast, PCBM_BeginModify, c_NoEventData);
            //���� ������������ �� ����� �������
            if (abs(PrimExt.X2 - PrimExt.X1) - abs(ByX) < 1) and
               (abs(PrimExt.Y2 - PrimExt.Y1) - abs(ByY) < 1) and
                DeltaNet < 0
                then // �������� 0.0001 mil
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
            // ��������� ������ PrimExt

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

            // ����� ������� PrimExt
            PCBServer.SendMessageToRobots(PrimExt.I_ObjectAddress, c_Broadcast, PCBM_BeginModify, c_NoEventData);
            if (abs(PrimExt.X2 - PrimExt.X1) - abs(ByX) < 1) and
               (abs(PrimExt.Y2 - PrimExt.Y1) - abs(ByY) < 1) and
                DeltaNet < 0
                then // �������� 0.0001 mil
            begin
                Board.RemovePCBObject(PrimExt);
            end
            else
            begin
                PrimExt.X2 := PrimExt.X2 + ByX;
                PrimExt.Y2 := PrimExt.Y2 + ByY;
            end;
            PCBServer.SendMessageToRobots(PrimExt.I_ObjectAddress, c_Broadcast, PCBM_EndModify, c_NoEventData);
            // ��������� ������ PrimExt

        end; //end of else PrimExtA > 90) and (PrimExtA <= 270)

        PCBServer.SendMessageToRobots(
                    PrimExt.I_ObjectAddress,
                    c_Broadcast,
                    PCBM_EndModify ,
                    c_NoEventData);


        PrimExt.GraphicallyInvalidate;
        if boolMoveAndResizePrimSel then PrimSel.GraphicallyInvalidate;

        //��������� � ������ ��������������
        if PrimExt.BoundingRectangle.Left   < Rectangle.Left    then Rectangle.Left   := PrimExt.BoundingRectangle.Left;
        if PrimExt.BoundingRectangle.Bottom < Rectangle.Bottom  then Rectangle.Bottom := PrimExt.BoundingRectangle.Bottom;
        if PrimExt.BoundingRectangle.Right  > Rectangle.Right   then Rectangle.Right  := PrimExt.BoundingRectangle.Right;
        if PrimExt.BoundingRectangle.Top    > Rectangle.Top     then Rectangle.Top    := PrimExt.BoundingRectangle.Top;

    end; //for j:=0 to ExtTrimPrims.Count-1 do

   //��� ������� ���� ������ ��� �������� ��� �
   //������� 3 - �������� 2 ����, ���������� ������ ����� ��������
    if boolMoveAndResizePrimSel then
    begin //��� �������, ��� ���� ����� PrimExt = 90
        for i := 0 to SelectedPrims.Count - 1 do
        begin
            PrimSel := SelectedPrims.GetObject(i);
            if PrimSel.ObjectID = 1 then   // ������ ��� ���
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


   //������������ �������: ������� SelectedPrims 1 ���.
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
    //������� �������
    BoardIterator := Board.SpatialIterator_Create;
    //����� ��������� �� ���� �������� �� ������� ����
    BoardIterator.AddFilter_LayerSet(MkSet(PrimSel.Layer,eMultiLayer));
    BoardIterator.AddFilter_ObjectSet(AllObjects);

    //����������� ������� ������ �� 0.5�� ������ ��������������
    BoardIterator.AddFilter_Area(Rectangle.Left -   MMsToCoord(0.5),
                                 Rectangle.Bottom - MMsToCoord(0.5),
                                 Rectangle.Right +  MMsToCoord(0.5),
                                 Rectangle.Top +    MMsToCoord(0.5));

    //������� ������ � ������ �������� � ���� �������
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
