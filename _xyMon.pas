unit _xyMon;

interface

uses
  RTypes, RCore, RUtils, RCurve, RCrvCtl, RUndo, RIntf,
  TypInfo,
  Graphics, Controls, StdCtrls, ExtCtrls, ComCtrls, Buttons;

type
  {YEdit <> nil, YEDit <> nil}

  TXYMonitor = class(TRPropertyMonitor)
  private
    FXEdit: TEdit;
    FYEdit: TEdit;
    FLockChange: Boolean;
    procedure ChangeHandler(Sender: TObject);
    procedure EnableEdit(Edit: TEdit; Enable: Boolean; Value: Double);
    procedure DoChange(Coord: Char; Value: Double);
  public
    constructor Create(XEdit, YEdit: TEdit);
    procedure Process(Sheet: TRSheet); override;
  end;

implementation

uses
  Windows, Forms, RFigHlp, RGroup, RGrpCtl, SysUtils;

{----------------------------- TXYMonitor ---------------------------------}

type THackControl = class(TControl);

constructor TXYMonitor.Create(XEdit, YEdit: TEdit);
begin
  inherited Create;
  FXEdit := XEdit;
  FXEdit.Enabled := False;
  FXEdit.OnChange := ChangeHandler;

  FYEdit := YEdit;
  FYEdit.Enabled := False;
  FYEdit.OnChange := ChangeHandler;
end;

procedure TXYMonitor.Process(Sheet: TRSheet);
var sel: TRFigure;
    pt: TPointF;
begin
  sel := FindSelectionObject(Sheet, [TRSelCurvePoint]);
  if sel <> nil then
  begin
    pt := TRSelCurvePoint(sel).CurvePoint;
    EnableEdit(FXEdit, True, pt.X);
    EnableEdit(FYEdit, True, pt.Y);
  end
  else
  begin
    EnableEdit(FXEdit, False, 0);
    EnableEdit(FYEdit, False, 0);
  end;
end;

procedure TXYMonitor.ChangeHandler(Sender: TObject);
var v: Double;
begin
  if FLockChange then Exit;

  try
    v := StrToFloat((Sender as TEdit).Text);
  except
    Exit;
  end;
  
  if Sender = FXEdit then DoChange('X', v)
  else if Sender = FYEdit then DoChange('Y', v);
end;

procedure TXYMonitor.EnableEdit(Edit: TEdit; Enable: Boolean; Value: Double);
begin
  FLockChange := True; {???????????}
  try
    Edit.Enabled := Enable;
    if Enable
      then Edit.Text := Format('%.2f', [Value])
      else Edit.Text := '';
  finally
    FLockChange := False;
  end;
end;

procedure TXYMonitor.DoChange(Coord: Char; Value: Double);
var pt: TPointF;
    sel: TRFigure;
begin
  sel := FindSelectionObject(InputSheet, [TRSelCurvePoint]);
  if sel = nil then Exit;

  pt := TRSelCurvePoint(sel).CurvePoint;

  case Coord of
    'X', 'x': pt.X := Value;
    'Y', 'y': pt.Y := Value;
  end;
  
  TRSelCurvePoint(sel).CurvePoint := pt;
  InputSheet.Dest.Refresh; 
end;

end.
