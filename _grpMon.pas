unit _grpMon;

interface

uses
  RCore, RUtils, 
  TypInfo,
  Graphics, Controls, ExtCtrls, ComCtrls, Buttons, Menus;

type
  TGroupMonitor = class(TRPropertyMonitor)
  private
    FGroupBtn: TControl;
    FPopupMenu: TPopupMenu;
    procedure ClickHandler(Sender: TObject);
    procedure EnableButton(Enable, Down: Boolean);
    procedure DoGroup;
    procedure DoUngroup;
  public
    constructor Create(GroupBtn: TControl; PopupMenu: TPopupMenu);
    procedure Process(Sheet: TRSheet); override;
  end;

implementation

uses
  Windows, Forms, RFigHlp, RGroup, RGrpCtl;

{------------------------------ TGroupMonitor ---------------------------------}

type THackControl = class(TControl);

constructor TGroupMonitor.Create(GroupBtn: TControl; PopupMenu: TPopupMenu);
begin
  inherited Create;
  FGroupBtn := GroupBtn;
  FGroupBtn.Enabled := False; 
  FPopupMenu := PopupMenu; 

  THackControl(FGroupBtn).OnClick := ClickHandler;
end;

procedure TGroupMonitor.Process(Sheet: TRSheet);
var sel: TRFigure;
begin
  sel := FindSelectionObject(Sheet, [TRSelectionGroupEx]);
  if sel <> nil then
  begin
    EnableButton(True, False);
    Exit;
  end;

  sel := FindSelectionObject(Sheet, [TRArrangeGroup]);
  if sel <> nil then
  begin
    EnableButton(True, True);
    Exit;
  end;

  EnableButton(False, False);
end;


procedure TGroupMonitor.ClickHandler(Sender: TObject);
var down: Boolean;
begin
  down := GetPropValue(FGroupBtn, 'Down', False);
  if down
    then DoGroup
    else DoUngroup;
end;

procedure TGroupMonitor.EnableButton(Enable, Down: Boolean);
begin
  FGroupBtn.Enabled := Enable;
//  if FGroupBtn is TToolButton then TToolButton(FGroupBtn).Down := Down {?}
//  else if FGroupBtn is TSpeedButton then TSpeedButton(FGroupBtn).Down := Down
//  else
  SetPropValue(FGroupBtn, 'Down', Down);  
end;

procedure TGroupMonitor.DoGroup;
var sel: TRFigure;
    g: TRGroup;
begin
  sel := FindSelectionObject(InputSheet, [TRSelectionGroupEx]);
  if sel = nil then Exit;
  InputSheet.BeginDeal;
  g := TRSelectionGroupEx(sel).OwnerGroupContoller.UndoablyGroupSelectedFigures(InputSheet.ActiveLayer);
  g.PopupMenu := FPopupMenu; 
  InputSheet.EndDeal;
end;

procedure TGroupMonitor.DoUngroup;
var sel: TRFigure;
begin
  sel := FindSelectionObject(InputSheet, [TRArrangeGroup]);
  if sel = nil then Exit;
  InputSheet.BeginDeal;
  TRArrangeGroup(sel).OwnerGroupContoller.UndoablyUngroupSelectedFigures(InputSheet.ActiveLayer);
  InputSheet.EndDeal;
end;

end.
