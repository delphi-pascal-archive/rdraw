unit _attrMon;

interface

uses
  RCore, RBezier, RGroup, RUtils, RIntf, _attr,
  Graphics, StdCtrls,
  {$IFDEF FPC}
  ColorBox;
  {$ELSE}
  ExtCtrls;
  {$ENDIF}

type
  //TColorBox = TComboBox; // D5

  TColorMonitor = class(TRPropertyMonitor)
  private
    FFillColorBox: TColorBox;
    FLineColorBox: TColorBox;
    procedure ChangeHandler(Sender: TObject);

    function GetSelectionColor(SelObj: TObject; Aspect: TAttributeAspect; var Color: TColor): Boolean;
    procedure SetSelectionColor(SelObj: TObject; Aspect: TAttributeAspect; AColor: TColor);
  public
    constructor Create(FillColorBox, LineColorBox: TColorBox);
    procedure Process(Sheet: TRSheet); override;

    class function Filter(Figure: TRFigure): Boolean;
  end;

function GetAttributesOf(SelObj: TObject; var attr): Boolean;

implementation

uses
  {$IFDEF UNIX}

  {$ELSE}
  Windows,
  {$ENDIF}

  Forms,

  RFigHlp, RCrvCtl, RUndo, SysUtils;

function GetAttributesOf(SelObj: TObject; var attr): Boolean;
var i, n: Integer;
    _attr: IDrawingAttributes;
begin
  Result := False;

  {---------------------------------}
  if SelObj.GetInterface(IDrawingAttributes, attr) then
    Result := True;
  {---------------------------------}
  if SelObj is TRCurveAttorney then
    if TRCurveAttorney(SelObj).Curve.GetInterface(IDrawingAttributes, attr) then
      Result := True;
  {---------------------------------}
  if SelObj is TRGroup then
  begin
    n := 0;
    for i := 0 to TRGroup(SelObj).Count-1 do
      if TRGroup(SelObj)[i].GetInterface(IDrawingAttributes, _attr) then
      begin
        IUnknown(attr) := _attr;
        Inc(n);
        if n > 1 then Break;
      end;
    Result := (n = 1);
  end;
  {---------------------------------}
end;

constructor TColorMonitor.Create(FillColorBox, LineColorBox: TColorBox);
begin
  inherited Create;
  FFillColorBox := FillColorBox;
  if Assigned(FFillColorBox) then
  begin
    FFillColorBox.Enabled := False;
    FFillColorBox.OnChange := ChangeHandler;
    FFillColorBox.ItemIndex := -1;
  end;

  FLineColorBox := LineColorBox;
  if Assigned(FLineColorBox) then
  begin
    FLineColorBox.Enabled := False;
    FLineColorBox.OnChange := ChangeHandler;
    FLineColorBox.ItemIndex := -1;
  end;
end;

procedure TColorMonitor.Process(Sheet: TRSheet);
var
    sel: TRFigure;
    Color: TColor;
    Ident: string;

    procedure InitColorBox(CBox: TColorBox; Aspect: TAttributeAspect);
    begin
      if CBox = nil then Exit;
      CBox.Enabled := True;
      if GetSelectionColor(sel, Aspect, Color) then
      begin
        ColorToIdent(Color, Ident);
        CBox.ItemIndex := CBox.Items.IndexOf(Ident);
      end
      else
        CBox.ItemIndex := -1;
    end;

    procedure DisableColorBox(CBox: TColorBox);
    begin
      if CBox = nil then Exit;
      CBox.ItemIndex := -1;
      CBox.Enabled := False;
    end;

begin
  //sel := FindSelectionObject(Sheet, [TRCurveAttorney, TRGroup{TRSelectionGroup}]);
  sel := FindSelectionObject(Sheet, Filter);

  if Assigned(sel) then
  begin
    InitColorBox(FFillColorBox, aaBrush);
    InitColorBox(FLineColorBox, aaPen);
  end
  else
  begin
    DisableColorBox(FFillColorBox);
    DisableColorBox(FLineColorBox);
  end;
end;

function GetColorBoxColor(CBox: TColorBox): TColor;
var Col: Integer;
begin
  //Result := CBox.Colors[CBox.ItemIndex];
  Result := clWhite;
  if IdentToColor(CBox.Items[CBox.ItemIndex], Col) then Result := Col;
end;

procedure TColorMonitor.ChangeHandler(Sender: TObject);
var sel: TRFigure;
    aspect: TAttributeAspect;
begin
  aspect := aaBrush;

  //sel := FindSelectionObject(InputSheet, [TRCurveAttorney, TRGroup{TRSelectionGroup}]);
  sel := FindSelectionObject(InputSheet, Filter);

  if Sender = FFillColorBox       then aspect := aaBrush
  else if Sender = FLineColorBox  then aspect := aaPen
  else Assert(False);

  SetSelectionColor(sel, aspect, GetColorBoxColor(Sender as TColorBox));

  InputSheet.Dest.Refresh;
end;

class function TColorMonitor.Filter(Figure: TRFigure): Boolean;
var attr: IDrawingAttributes;
    i: Integer;
begin
  Result := False;

  if Figure = nil then Exit;

  if Figure.GetInterface(IDrawingAttributes, attr) then
    Result := True;

  if Figure is TRCurveAttorney then
    Result := TRCurveAttorney(Figure).Curve.GetInterface(IDrawingAttributes, attr);

  if Figure is TRGroup then
    for i := 0 to TRGroup(Figure).Count-1 do
      if TRGroup(Figure)[i].GetInterface(IDrawingAttributes, attr) then
      begin
        Result := True;
        Break;
      end;
end;

function TColorMonitor.GetSelectionColor(SelObj: TObject; Aspect: TAttributeAspect; var Color: TColor): Boolean;
var attr: IDrawingAttributes;
begin
  Result := False;

  if GetAttributesOf(SelObj, attr) then
  begin
    Result := True;
    Color := GetAttrColor(attr, Aspect);
  end;
end;

procedure TColorMonitor.SetSelectionColor(SelObj: TObject; Aspect: TAttributeAspect; AColor: TColor);
var attr: IDrawingAttributes;
    i: Integer;
begin
  UndoStack(InputSheet).Push(GetUndoPoint(
    SelObj as TRFigure, InputSheet, InputSheet.ActiveLayer, [daAttributes])
  );

  if GetAttributesOf(SelObj, attr) then
    SetAttrColor(attr, Aspect, AColor)
  else
  if SelObj is TRGroup then
  begin
    for i := 0 to TRGroup(SelObj).Count-1 do
      if TRGroup(SelObj)[i].GetInterface(IDrawingAttributes, attr) then
        SetAttrColor(attr, Aspect, AColor);
  end;
end;

initialization

finalization

end.
