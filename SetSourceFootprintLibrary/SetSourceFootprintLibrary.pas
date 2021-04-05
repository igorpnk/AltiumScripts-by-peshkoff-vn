var
   PCBBoard     : IPCB_Board;
   Iterator     : IPCB_BoardIterator;
   Comp         : IPCB_Component;

procedure start;
begin
    PCBBoard := PCBServer.GetCurrentPCBBoard;
    if PCBBoard = Nil Then Exit;

    Iterator := PCBBoard.BoardIterator_Create;
    if Iterator = Nil Then Exit;
    Iterator.AddFilter_ObjectSet(MkSet(eComponentObject));
    Iterator.AddFilter_LayerSet(MkSet(eTopLayer,eBottomLayer));

    Try
        Comp := Iterator.FirstPCBObject;
        While Comp <> Nil Do
        Begin
            //ShowMessage(Comp.Name.Text);
            Comp.SourceFootprintLibrary := '';
            Comp := Iterator.NextPCBObject;
        End;
    Finally
        PCBBoard.BoardIterator_Destroy(Iterator);
    End;

    PCBBoard.ViewManager_FullUpdate;
end;
