Procedure GridOffOn;
var
    PCBBoard    : IPCB_Board;
    PCBLibrary  : IPCB_Library;
begin
    PCBBoard := PCBServer.GetCurrentPCBBoard;
    PCBLibrary := PCBServer.GetCurrentPCBLibrary;

    if (PCBBoard = nil) and (PCBLibrary = nil) then exit;

    if PCBBoard.LayerIsDisplayed[79] then
    begin
         PCBBoard.LayerIsDisplayed[79] := False;
         PCBBoard.LayerIsDisplayed[80] := False;
    end
    else
    begin
         PCBBoard.LayerIsDisplayed[79] := True;
         PCBBoard.LayerIsDisplayed[80] := False;
    end;
    PCBBoard.ViewManager_FullUpdate;

end;
