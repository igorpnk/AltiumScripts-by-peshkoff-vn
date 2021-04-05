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

        { ��������� � ����������� ���� }
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


    SelectedPrims   : TStringList;    //���������� ���������
    ExtTrimPrims    : TStringList;   //��������� ��� ��������� ��� ������������
    DblDetect       : Boolean;      //���������� ��������� ��������� � TStringList
    PrimExtA        : Real;

    Net1                : IPCB_Net;
    Net2                : IPCB_Net;
    NetTmp              : IPCB_Net;
    NetTarget           : IPCB_Net;
    NetCurrent          : IPCB_Net;     //������� ���� � ����� ��� ��������
    boolMultyNet        : boolean;      //������� ��������� �����
    boolDiffPairNet     : boolean;      //��� (!) ��������� ���� �������� ������ ����� ��������

    NetClass            : IPCB_ObjectClass;
    NetClassTmp         : IPCB_ObjectClass; //��������� ����� ����� ��� ���������
    NetClassesList      : TStringList; //�������� �������, ���� ������ ���� ����
    OurNetClassNet      : TstringList; //�������� ����� � ����� ������
    OurNetClassNetTmp   : TstringList; //�������� ����� ���������
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

    //��������� SelectedPrims : TStringList ���� � ������� ��������� ����������
    SelectedPrims := TStringList.Create;
    //��������� ���� � ���������, ��������������� � ���������, �� ����� ����� ��������� ��� ���������
    ExtTrimPrims := TStringList.Create;
    j := 0; //Iterator for ExtTrimPrims

        if ((Board.SelectecObject[0].ObjectId <> eTrackObject) and (Board.SelectecObject[0].ObjectId <> eArcObject)) then exit;

        if Board.SelectecObject[0].Net = Nil then exit;

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

        //begin

        //diffname := copy(NetName1, 1, Length(NetName1) - 2);  //�� ����� ���� �������� 2 ������� � �����
        //end;

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

        //���������� �������������, ����������� ��� ��������
        Rectangle := PrimSel.BoundingRectangle;

        //������� �������
        BoardIterator := Board.SpatialIterator_Create;
        //����� ��������� ������ �����
        BoardIterator.AddFilter_ObjectSet(MkSet(eTrackObject));
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
               (PrimExt.Layer=PrimSel.Layer) and //�������� ������ ���������� � ����� ���� � ����������� ���������
               (PrimExt.Net.Name=PrimSel.Net.Name) //������������ ����� ����
               then

            // ���� ��� ������, �������� �������� �� � Rectangle X � Y
            if (((PrimExt.X1 > Rectangle.Left) and (PrimExt.X1 < Rectangle.Right)) and ((PrimExt.Y1 > Rectangle.Bottom) and (PrimExt.Y1 < Rectangle.Top))) or
               (((PrimExt.X2 > Rectangle.Left) and (PrimExt.X2 < Rectangle.Right)) and ((PrimExt.Y2 > Rectangle.Bottom) and (PrimExt.Y2 < Rectangle.Top)))
               then
            begin
                //Inc(PrimExtFilter);
                if j = 0 then  //���������� ���� ������ ��� ������� �������
                begin
                    ExtTrimPrims.AddObject(IntToStr(j), PrimExt);   //������ ������ ������ � ExtTrimPrims
                    inc(j);

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
                    begin   //���� X2 ��� Y2 ��������� � ����� �� ����� ���������� ����� (�������� 0.001 mil), �� ���������� 180
                        if  ((RoundTo(PrimExt.X2,+1) = RoundTo(PrimSel.StartX,+1)) and (RoundTo(PrimExt.Y2,+1) = RoundTo(PrimSel.StartY,+1))) or
                            ((RoundTo(PrimExt.X2,+1) = RoundTo(PrimSel.EndX,  +1)) and (RoundTo(PrimExt.Y2,+1) = RoundTo(PrimSel.EndY,  +1)))
                            then PrimExtA := PrimExtA + 180;
                    end;

                    if PrimSel.ObjectID = 4 then //��������� ������ - �����
                    begin
                        if  ((RoundTo(PrimExt.X2,+1) = RoundTo(PrimSel.X1,+1)) and (RoundTo(PrimExt.Y2,+1) = RoundTo(PrimSel.Y1,+1))) or
                            ((RoundTo(PrimExt.X2,+1) = RoundTo(PrimSel.X2,+1)) and (RoundTo(PrimExt.Y2,+1) = RoundTo(PrimSel.Y2,+1)))
                            then PrimExtA := PrimExtA + 180;
                    end;
                end     // if j = 0

                //���������� ��������� ������� ����� ������� � ����, ��� ��� ���� � ������ ExtTrimPrims
                //��������� � ����� �����, ���� ����� �����������
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

   //���� �������� ���� ���� � ��� �������� ������ ���� ����

   if Not(boolMultyNet) and (Board.SelectecObject[0].Net.InDifferentialPair) then
        TuningVariant := 1;
   //������� 2  �������� ���� ����, �� ���������� ������ ��������
   if Not(boolMultyNet) and (Not(Board.SelectecObject[0].Net.InDifferentialPair)) then
        TuningVariant := 2;
    //������� 3  �������� 2 ����, ���������� ������ ����� ��������
   if boolMultyNet and boolDiffPairNet then
        TuningVariant := 3;

    //������� 4  �������� ����� ����� ����, �� ���������� ������ ����� ��������
   if boolMultyNet and not(boolDiffPairNet) then
        TuningVariant := 4;


//��������� Net2 ������ ��� �������� Auto
if not (boolModeManual or boolModeDeltaPlus or boolModeDeltaMinus) then    //����� ��
begin


    //********************* NET CLASS ********************

    //���� ���� ���� � �� �������� ������ ��������, �� ���� � NetClass
   if TuningVariant <> 1 then  //����� ��������, ����� ������� ���� ���� � ������� ��������
   begin
         //���������� ������ ������ ����������� ����
         //������� ������ �������
         Iterator := Board.BoardIterator_Create;
         Iterator.SetState_FilterAll;
         Iterator.AddFilter_ObjectSet(MkSet(eClassObject));
         NetClass := Iterator.FirstPCBObject;

        //������� ����� TStringList
         OurNetClassNet := TStringList.Create; //���� � ����� ������
         NetClassesList := TStringList.Create; //������ (�� ����� ���� ���������), ���� ������ ���� ����

         While NetClass <> Nil Do
         begin
         //���� ������� ����� � �������� � ���� ����
            if (NetClass.IsMember(Net1)) and (NetClass.MemberKind = eClassMemberKind_Net) and (NetClass.Name <> 'All Nets') then
            //��������� ����� ������� ���� � ������
            begin
                NetClassesList.AddObject(NetClass.Name,NetClass);
                //ComboBoxNetClass.Items.AddObject(NetClass.Name, NetClass);
            end;
         NetClass := Iterator.NextPCBObject;
         end; //NetClass <> Nil
         Board.BoardIterator_Destroy(Iterator);

        NetCountMin := 0;

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

        if NetClassesList.Count > 1 then
        begin
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
            if Not (boolMultyNet and
                    boolDiffPairNet and
                    Net2.InDifferentialPair)
                then
                begin
                    if NetCountTmp = 1 then        //������������ ����� ��� ������ ���� � ������
                    begin
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
        //��������� �� ������� ������� ����� ���� ����
        //���� �� � ����, �� ������� (��� ���������� ������...)
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
    //LenNet1 := Net1.;

    //���� ������ ������ �����
    if boolModeManual then
        LenNetTarget := MMsToCoord(strtofloat(editManual.Text));

    //��������� ������� ����� ����
    DeltaNet:=LenNetTarget-LenNet1;

    if boolModeDeltaPlus then
        DeltaNet := MMsToCoord(strtofloat(editDelta.Text));

    if boolModeDeltaMinus then
        DeltaNet := - MMsToCoord(strtofloat(editDelta.Text));

    DeltaNetHalf:=DeltaNet/2;

    //���������� delta X, delta Y � ����������� �� 0
    ByX := - (RoundTo(DeltaNetHalf * cos(PrimExtA / 180 * Pi),0));
    ByY := - (RoundTo(DeltaNetHalf * sin(PrimExtA / 180 * Pi),0));

    Violation_Count := 0;
    PrimViolation_Count  := 0;
    DlgOk   := false;

    //���������� ������������� ������ ������� ���������
    Rectangle := SelectedPrims.GetObject(0).BoundingRectangle;

    //������������� ByX, ByY ���� �������� ������ ����� �������
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

        //��������� � ������ ��������������
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
    //������� �������
    BoardIterator := Board.SpatialIterator_Create;
    //����� ��������� �� ���� �������� �� ������� ����
    BoardIterator.AddFilter_LayerSet(MkSet(Prim1.Layer,eMultiLayer));
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

