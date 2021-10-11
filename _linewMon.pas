unit _linewMon;

interface

uses
  RCore, RUtils, RCurve, RCrvCtl, RUndo, RIntf,
  _attrMon, 
  TypInfo,
  Graphics, Controls, StdCtrls, ComCtrls, Buttons;//, Spin;

type
  TLineWidthMonitor = class(TRPropertyMonitor)
  private
    FWidthEdit: TControl;
    FDenyHandler: Boolean;
    procedure ChangeHandler(Sender: TObject);

    function GetEditValue: Integer;
    procedure SetEditValue(WidthValue: Integer);

    function GetSelectionLineWidth(SelObj: TObject; var WidthValue: Integer): Boolean;
    procedure SetSelectionLineWidth(SelObj: TObject; WidthValue: Integer);
  public
    constructor Create(WidthEdit: TControl);
    procedure Process(Sheet: TRSheet); override;
  end;

implementation

uses
  Windows, Forms, SysUtils, 
  RFigHlp, RGroup, RGrpCtl,
  _attr;

const
  NoneValue = -1;

{--------------------------- TLineWidthMonitor --------------------------------}

constructor TLineWidthMonitor.Create(WidthEdit: TControl);
begin
  inherited Create;
  FWidthEdit := WidthEdit;
  FWidthEdit.Enabled := False;

  if FWidthEdit is TCustomEdit then
    TEdit(FWidthEdit).OnChange := ChangeHandler;
end;

procedure TLineWidthMonitor.Process(Sheet: TRSheet);
var sel: TRFigure;
    w: Integer;
begin
  sel := FindSelectionObject(Sheet, TColorMonitor.Filter);
  if sel <> nil then
  begin
    FWidthEdit.Enabled := True;
    if GetSelectionLineWidth(sel, w)
      then SetEditValue(w)
      else SetEditValue(NoneValue);
  end
  else
  begin
    FWidthEdit.Enabled := False;
  end;
end;

procedure TLineWidthMonitor.ChangeHandler(Sender: TObject);
var sel: TRFigure; 
    newWidth: Integer;
begin
  if FDenyHandler then Exit;
  if InputSheet = nil then Exit; 

  sel := FindSelectionObject(InputSheet, TColorMonitor.Filter);
  if sel = nil then Exit;

  newWidth := GetEditValue;
  SetSelectionLineWidth(sel, newWidth);
end;

function TLineWidthMonitor.GetSelectionLineWidth(SelObj: TObject; var WidthValue: Integer): Boolean;
var attr: IDrawingAttributes;
begin
  Result := False;
  if GetAttributesOf(SelObj, attr) then
  begin
    WidthValue := attr.Attributes.Pen.Width;
    Result := True;
  end else if Assigned(attr) then {???}
  begin
    WidthValue := attr.Attributes.Pen.Width;
    Result := True;
  end;
end;

procedure TLineWidthMonitor.SetSelectionLineWidth(SelObj: TObject; WidthValue: Integer);
var sel: TRFigure;
    attr: IDrawingAttributes;
    i: Integer;
begin
  sel := FindSelectionObject(InputSheet, TColorMonitor.Filter);
  if sel = nil then Exit;

  InputSheet.BeginDeal;

  UndoStack(InputSheet).Push(
    GetUndoPoint(SelObj as TRFigure, nil, nil, [daAttributes])
  );

  if GetAttributesOf(sel, attr) then
    attr.Attributes.Pen.Width := WidthValue
  else
  if sel is TRGroup then
  begin
    for i := 0 to TRGroup(sel).Count-1 do
      if TRGroup(sel)[i].GetInterface(IDrawingAttributes, attr) then
        attr.Attributes.Pen.Width := WidthValue;
  end;

  InputSheet.Redraw := True;
  InputSheet.EndDeal;
end;

function TLineWidthMonitor.GetEditValue: Integer;
var s: string;
    w, er: Integer;
begin
  Result := 1;
  //if FWidthEdit is TSpinEdit then Result := TSpinEdit(FWidthEdit).Value;
  s := GetPropValue(FWidthEdit, 'Text', True);
  Val(s, w, er);
  if er = 0 then Result := w; 
end;

procedure TLineWidthMonitor.SetEditValue(WidthValue: Integer);
begin
  FDenyHandler := True;
  try
    if WidthValue = NoneValue then WidthValue := 1;

    //if FWidthEdit is TSpinEdit then TSpinEdit(FWidthEdit).Value := WidthValue;
    if FWidthEdit is TEdit then TEdit(FWidthEdit).Text := IntToStr(WidthValue);
  finally
    FDenyHandler := False; 
  end;
end;

end.
