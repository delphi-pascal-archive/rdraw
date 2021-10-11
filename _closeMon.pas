unit _closeMon;

interface

uses
  RCore, RUtils, RCurve, RCrvCtl, RUndo, RIntf,
  TypInfo,
  Graphics, Controls, ExtCtrls, ComCtrls, Buttons;

type
  TClosedMonitor = class(TRPropertyMonitor)
  private
    FCloseBtn: TControl;
    FFillBtn: TControl;
    procedure ClickHandler(Sender: TObject);
    procedure EnableButton(Btn: TControl; Enable, Down: Boolean);
    procedure DoClose(Closed: Boolean);
    procedure DoFill(Filled: Boolean);
  public
    constructor Create(CloseBtn, FillBtn: TControl);
    procedure Process(Sheet: TRSheet); override;
  end;

implementation

uses
  Windows, Forms, RFigHlp, RGroup, RGrpCtl;

{----------------------------- TClosedMonitor ---------------------------------}

type THackControl = class(TControl);

constructor TClosedMonitor.Create(CloseBtn, FillBtn: TControl);
begin
  inherited Create;
  FCloseBtn := CloseBtn;
  FCloseBtn.Enabled := False;
  THackControl(FCloseBtn).OnClick := ClickHandler;

  FFillBtn := FillBtn;
  FFillBtn.Enabled := False;
  THackControl(FFillBtn).OnClick := ClickHandler;
end;

procedure TClosedMonitor.Process(Sheet: TRSheet);
var sel: TRFigure;
begin
  sel := FindSelectionObject(Sheet, [TRCurveAttorney]);
  if sel <> nil then
  begin
    EnableButton(FCloseBtn, True, TRCurveAttorney(sel).Curve.Closed);
    EnableButton(FFillBtn, True, TRCurveAttorney(sel).Curve.Filled)
  end
  else
  begin
    EnableButton(FCloseBtn, False, False);
    EnableButton(FFillBtn, False, False);
  end;  
end;


procedure TClosedMonitor.ClickHandler(Sender: TObject);
var down: Boolean;
begin
  down := GetPropValue(Sender, 'Down', False);
  if Sender = FCloseBtn then DoClose(down)
  else if Sender = FFillBtn then DoFill(down);
end;

procedure TClosedMonitor.EnableButton(Btn: TControl; Enable, Down: Boolean);
begin
  if Btn = nil then Exit;
  Btn.Enabled := Enable;
  SetPropValue(Btn, 'Down', Down);
end;

procedure TClosedMonitor.DoClose(Closed: Boolean);
var sel: TRFigure;
begin
  sel := FindSelectionObject(InputSheet, [TRCurveAttorney]);
  if sel = nil then Exit;
  InputSheet.BeginDeal;
  UndoStack(InputSheet).Push(
    GetUndoPoint(TRCurveAttorney(sel).Curve, nil, nil, [daGeometry])
  );
  TRCurveAttorney(sel).Curve.Closed := Closed;
  InputSheet.Redraw := True;
  InputSheet.EndDeal;
end;

procedure TClosedMonitor.DoFill(Filled: Boolean);
var sel: TRFigure;
begin
  sel := FindSelectionObject(InputSheet, [TRCurveAttorney]);
  if sel = nil then Exit;
  InputSheet.BeginDeal;
  UndoStack(InputSheet).Push(
    GetUndoPoint(TRCurveAttorney(sel).Curve, nil, nil, [daGeometry])
  );
  TRCurveAttorney(sel).Curve.Filled := Filled;
  InputSheet.Redraw := True;
  InputSheet.EndDeal;
end;

end.
