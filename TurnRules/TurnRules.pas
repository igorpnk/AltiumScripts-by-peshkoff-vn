{ -------------------------------- }
{ --------- Turn Rules ----------- }
{ ----------- v 1.0 -------------- }
Uses Registry;

var
    Board           : IPCB_Board;
    Rule            : IPCB_Rule;
    BoardIterator   : IPCB_BoardIterator;
    slRules1        : TStringList;
    slRules2        : TStringList;
    slRules3        : TStringList;
    CurrentSet      : integer;

procedure RegistryRead;
var
    Registry  : TRegistry;
    info : TRegKeyInfo;

Begin
    slRules1 := TStringList.Create;
    slRules2 := TStringList.Create;
    slRules3 := TStringList.Create;

    //if Rule.DRCEnabled then slRules1.Add(Rule.Name);

    { Create TRegistry }
    Registry := TRegistry.Create;

    Try
        { устанавливаем корневой ключ; напрмер hkey_local_machine или hkey_current_user }
        //Registry.RootKey := HKEY_CURRENT_USER; {Устанавливается автоматически}
        { открываем и создаём ключ }
        Registry.OpenKey('Software\AltiumScripts\TurnRules\Set01', true);
        Registry.GetValueNames(slRules1);
        Registry.CloseKey;
        Registry.OpenKey('Software\AltiumScripts\TurnRules\Set02', true);
        Registry.GetValueNames(slRules2);
        Registry.CloseKey;
        Registry.OpenKey('Software\AltiumScripts\TurnRules\Set03', true);
        Registry.GetValueNames(slRules3);
        Registry.CloseKey;
    Finally
        Registry.Free;
    End;

End;

procedure RegistryWrite;
var
    i: integer;
    Registry: TRegistry;
Begin
    { создаём объект TRegistry }
    Registry := TRegistry.Create;
    Try
        { устанавливаем корневой ключ; напрмер hkey_local_machine или hkey_current_user }
        //Registry.RootKey := HKEY_CURRENT_USER; {Устанавливается автоматически}
        { открываем и создаём ключ }
        Registry.DeleteKey('Software\AltiumScripts\TurnRules\Set01');
        Registry.OpenKey('Software\AltiumScripts\TurnRules\Set01', true);
        for i := 0 to slRules1.Count - 1 do
            Registry.WriteBool(slRules1[i], True);
        Registry.CloseKey;

        Registry.DeleteKey('Software\AltiumScripts\TurnRules\Set02');
        Registry.OpenKey('Software\AltiumScripts\TurnRules\Set02', true);
        for i := 0 to slRules2.Count - 1 do
            Registry.WriteBool(slRules2[i], True);
        Registry.CloseKey;

        Registry.DeleteKey('Software\AltiumScripts\TurnRules\Set03');
        Registry.OpenKey('Software\AltiumScripts\TurnRules\Set03', true);
        for i := 0 to slRules3.Count - 1 do
            Registry.WriteBool(slRules3[i], True);
        Registry.CloseKey;

    Finally
        Registry.Free;
    End;

End;

Procedure Turn;
var
    i             : Integer;
    j             : Integer;
    slRulesCur    : TStringList;

Begin
    slRulesCur := TStringList.Create;
    case CurrentSet of
        1:  slRulesCur := slRules1;
        2:  slRulesCur := slRules2;
        3:  slRulesCur := slRules3;
    else    ShowMessage('something wrong..')
    end;

    // Retrieve the current board
    Board := PCBServer.GetCurrentPCBBoard;
    If Board = Nil Then Exit;

    // Retrieve the iterator
    BoardIterator        := Board.BoardIterator_Create;
    BoardIterator.AddFilter_ObjectSet(MkSet(eRuleObject));

    BoardIterator.AddFilter_LayerSet(AllLayers);
    BoardIterator.AddFilter_Method(eProcessAll);

    Rule := BoardIterator.FirstPCBObject;

    While (Rule <> Nil) Do
    Begin
//        Inc(Count);
        for i := 0 to slRulesCur.Count - 1 do
        begin
            if Rule.Name = slRulesCur[i] then
            begin
                if Rule.DRCEnabled = false then
                    Rule.DRCEnabled := true
                else
                Rule.DRCEnabled := false;
                //showmessage('C_Diff-Diff_0.5mm!');
            end;
        end;

        Rule := BoardIterator.NextPCBObject;
    End;
    slRulesCur.Clear;
    Board.BoardIterator_Destroy(BoardIterator);
 End;

procedure TfrmTurnRulesSet.frmTurnRulesSetShow(Sender: TObject);
var
    i : integer;
    strRulePriority : string;
    strRuleKind     : string;
begin
    Board := PCBServer.GetCurrentPCBBoard;
    If Board = Nil Then Exit;

    // Retrieve the iterator
    BoardIterator        := Board.BoardIterator_Create;
    BoardIterator.AddFilter_ObjectSet(MkSet(eRuleObject));

    BoardIterator.AddFilter_LayerSet(AllLayers);
    BoardIterator.AddFilter_Method(eProcessAll);

    Rule := BoardIterator.FirstPCBObject;

    While (Rule <> Nil) Do
    Begin
        //  ShowMessage();
        //Get Rule Kind
        strRuleKind := IntToStr(Rule.RuleKind);
        if length(strRuleKind) = 1 then strRuleKind := '0' + strRuleKind;

        //Get Rule Priority
        strRulePriority := IntToStr(Rule.Priority);
        if length(strRulePriority) = 1 then strRulePriority := '0' + strRulePriority;

        //Add Full name of Rules to TStringList
        clbRulesGroup1.Items.AddObject(strRuleKind + ': (' + strRulePriority + ') ' + Rule.Name, Rule);
        clbRulesGroup2.Items.AddObject(strRuleKind + ': (' + strRulePriority + ') ' + Rule.Name, Rule);
        clbRulesGroup3.Items.AddObject(strRuleKind + ': (' + strRulePriority + ') ' + Rule.Name, Rule);

        //Check Items in GroupBox and delete it (later checked items will be added)
        //this need for keep RulesNames of another projects
        for i := slRules1.Count -1 downto 0 do
            if slRules1[i] = Rule.Name then
            begin
                clbRulesGroup1.Checked[clbRulesGroup1.Count - 1] := true;
                slRules1.Delete(i);
            end;

        for i := slRules2.Count -1 downto 0 do
            if slRules2[i] = Rule.Name then
            begin
                clbRulesGroup2.Checked[clbRulesGroup2.Count - 1] := true;
                slRules2.Delete(i);
            end;


        for i := slRules3.Count -1 downto 0 do
            if slRules3[i] = Rule.Name then
            begin
                clbRulesGroup3.Checked[clbRulesGroup3.Count - 1] := true;
                slRules3.Delete(i);
            end;

        Rule := BoardIterator.NextPCBObject;
    End;

    clbRulesGroup1.Sorted := true;
    clbRulesGroup2.Sorted := true;
    clbRulesGroup3.Sorted := true;
    Board.BoardIterator_Destroy(BoardIterator);
    //OleStrToString
    //ShowMessage(cRuleIdStrings[1]);
    //clbRulesGroup1.Sorted


end;

Procedure TurnRulesSet01;
begin
    CurrentSet := 1;
    RegistryRead;
    Turn;
end;

Procedure TurnRulesSet02;
begin
    CurrentSet := 2;
    RegistryRead;
    Turn;
end;

Procedure TurnRulesSet03;
begin
    CurrentSet := 3;
    RegistryRead;
    Turn;
end;

Procedure TurnRulesSet;
begin
    RegistryRead;
    frmTurnRulesSet.Show;
end;

procedure TfrmTurnRulesSet.butOKClick(Sender: TObject);
var
    i   : Integer;
begin

    for i := 0 to clbRulesGroup1.Items.Count - 1 do
    begin
        if clbRulesGroup1.Checked[i] then
        slRules1.Add(Copy(clbRulesGroup1.Items[i], 10, Length(clbRulesGroup1.Items[i])));      //Закидываем часть названия в реестр (без подразделов)

    end;

    for i := 0 to clbRulesGroup2.Items.Count - 1 do
    begin
        if clbRulesGroup2.Checked[i] then
        slRules2.Add(Copy(clbRulesGroup2.Items[i], 10, Length(clbRulesGroup2.Items[i])));

    end;

    for i := 0 to clbRulesGroup3.Items.Count - 1 do
    begin
        if clbRulesGroup3.Checked[i] then
        slRules3.Add(Copy(clbRulesGroup3.Items[i], 10, Length(clbRulesGroup3.Items[i])));

    end;

    RegistryWrite;
    frmTurnRulesSet.Close;
end;


procedure TfrmTurnRulesSet.butCancelClick(Sender: TObject);
begin
    frmTurnRulesSet.Close;
end;

procedure TfrmTurnRulesSet.ToolButton1Click(Sender: TObject);
begin
    clbRulesGroup1.BringToFront;
end;

procedure TfrmTurnRulesSet.ToolButton3Click(Sender: TObject);
begin
    clbRulesGroup2.BringToFront;
end;

procedure TfrmTurnRulesSet.ToolButton2Click(Sender: TObject);
begin
    clbRulesGroup3.BringToFront;
end;

procedure TfrmTurnRulesSet.frmTurnRulesSetResize(Sender: TObject);
begin
    clbRulesGroup1.Width    :=  frmTurnRulesSet.Width - 90;
    clbRulesGroup1.Height   :=  frmTurnRulesSet.Height - 111;
    clbRulesGroup2.Width    :=  frmTurnRulesSet.Width - 90;
    clbRulesGroup2.Height   :=  frmTurnRulesSet.Height - 111;
    clbRulesGroup3.Width    :=  frmTurnRulesSet.Width - 90;
    clbRulesGroup3.Height   :=  frmTurnRulesSet.Height - 111;

    butOk.Left      :=  (frmTurnRulesSet.Width div 2) - 82;
    butCancel.Left  :=  (frmTurnRulesSet.Width div 2) + 7;
    butOk.Top       :=   frmTurnRulesSet.Height - 62;
    butCancel.Top   :=   frmTurnRulesSet.Height - 62;

end;


