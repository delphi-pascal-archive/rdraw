unit _bzrBtn;

interface

uses
  {$IFDEF UNIX} {$ELSE} Windows, {$ENDIF}
  Classes, Controls, Buttons, ComCtrls,
  RCore, RCurve, RBezier, RIntf, RUndo;

type
  TBezierButton = TToolButton; //TSpeedButton;

  TBezierButtonSet = record
    NodeTypeBtn: array[TNodeType]of TBezierButton;
    SegmentTypeBtn: array[TSegmentType]of TBezierButton;
  end;

  TBezierMonitor = class(TRPropertyMonitor)
  private
    FButtons: TBezierButtonSet;

    procedure EnableButtons(ASegmentType: TSegmentType;
      ANodeType: TNodeType; AImaginary: Boolean = False);
    procedure DisableButtons;
    procedure InitButtons;
    procedure NodeBtnClickHandler(Sender: TObject);
    procedure SegmBtnClickHandler(Sender: TObject);

    procedure PushUndoPoint(sel: TRFigure); 
  public
    constructor Create(LineBtn, BezierBtn, CuspBtn, SmoothBtn, SymmetBtn: TBezierButton);
    procedure Process(Sheet: TRSheet); override; 
  end;

implementation

uses
  RBzrCtl, RSelFrm, RFigHlp, RUtils, RBzrHlp, SysUtils, RCrvCtl;

function IsDown(Btn: TBezierButton): Boolean;
begin
  Result := Assigned(Btn)and(Btn.Down);
end;

procedure SetDown(Btn: TBezierButton; Value: Boolean);
begin
  if Assigned(Btn) then Btn.Down := Value;
end;

procedure SetEnabled(Btn: TBezierButton; Value: Boolean);
begin
  if Assigned(Btn) then Btn.Enabled := Value;
end;

type
  TBezierSelectionInfo = record
    NodeType: TNodeType;
    SegmentType: TSegmentType;
    Imaginary: Boolean;
  end;

function BezierSelectionInfo(sel: TRFigure): TBezierSelectionInfo;
begin
  Result.NodeType := ntNone;
  Result.SegmentType := stNone;
  Result.Imaginary := False;

  if sel = nil then
    Exit
  else if sel is TRSelBezierPoint then
  begin
    Result.NodeType := TRSelBezierPoint(sel).NodeType;
    Result.SegmentType := TRSelBezierPoint(sel).SegmentType;
    Result.Imaginary := TRSelBezierPoint(sel).Imaginary;
  end
  else if(sel is TRBezierSelection) then
  begin
    Result.NodeType := TRBezierSelection(sel).NodeType;
    Result.SegmentType := TRBezierSelection(sel).SegmentType;
  end
  else if (sel is TRBezier) then
  begin
    Result.NodeType := TRBezierHelper(sel).AllNodesType;
    Result.SegmentType := TRBezierHelper(sel).AllSegmentsType;
  end;
end;

{------------------------------ TBezierMonitor --------------------------------}

constructor TBezierMonitor.Create(LineBtn, BezierBtn, CuspBtn, SmoothBtn,
  SymmetBtn: TBezierButton);
begin
  inherited Create;
  FButtons.SegmentTypeBtn[stLine  ] := LineBtn;
  FButtons.SegmentTypeBtn[stBezier] := BezierBtn;

  FButtons.NodeTypeBtn[ntCusp  ] := CuspBtn;
  FButtons.NodeTypeBtn[ntSmooth] := SmoothBtn;
  FButtons.NodeTypeBtn[ntSymmet] := SymmetBtn;

  InitButtons;
  DisableButtons;
end;

procedure TBezierMonitor.DisableButtons;
var nt: TNodeType;
    st: TSegmentType;
begin
  with FButtons do
  begin
    for nt := Low(TNodeType) to High(TNodeType) do
    begin
      SetDown(NodeTypeBtn[nt], False);
      SetEnabled(NodeTypeBtn[nt], False);
    end;
    for st := Low(TSegmentType) to High(TSegmentType) do
    begin
      SetDown(SegmentTypeBtn[st], False);
      SetEnabled(SegmentTypeBtn[st], False);
    end;
  end;
end;

procedure TBezierMonitor.EnableButtons(ASegmentType: TSegmentType;
  ANodeType: TNodeType; AImaginary: Boolean);
var nt: TNodeType;
    st: TSegmentType;
begin
  with FButtons do
  begin
    for nt := Low(TNodeType) to High(TNodeType) do SetEnabled(NodeTypeBtn[nt], not AImaginary);
    for st := Low(TSegmentType) to High(TSegmentType) do SetEnabled(SegmentTypeBtn[st], True);

    if not IsDown(NodeTypeBtn[ANodeType]) then
      for nt := Low(TNodeType) to High(TNodeType) do
        SetDown(NodeTypeBtn[nt], nt = ANodeType);

    if not IsDown(SegmentTypeBtn[ASegmentType]) then
      for st := Low(TSegmentType) to High(TSegmentType) do
        SetDown(SegmentTypeBtn[st], st = ASegmentType);
  end;
end;

procedure TBezierMonitor.InitButtons;
var nt: TNodeType;
    st: TSegmentType;
begin
  with FButtons do
  begin
    for nt := Low(TNodeType) to High(TNodeType) do
      if Assigned(NodeTypeBtn[nt]) then
      begin
        NodeTypeBtn[nt].Tag := Integer(nt);
        NodeTypeBtn[nt].OnClick := NodeBtnClickHandler;
      end;

    for st := Low(TSegmentType) to High(TSegmentType) do
      if Assigned(SegmentTypeBtn[st]) then
      begin
        SegmentTypeBtn[st].Tag := Integer(st);
        SegmentTypeBtn[st].OnClick := SegmBtnClickHandler;
      end;
  end;
end;

procedure TBezierMonitor.Process(Sheet: TRSheet);
var sel: TRFigure;
    info: TBezierSelectionInfo;
begin
  sel := FindSelectionObject(Sheet, [TRSelBezierPoint, TRBezierSelection{, TRBezier}]);

  if sel = nil then
    DisableButtons
  else
  begin
    info := BezierSelectionInfo(sel);
    EnableButtons(info.SegmentType, info.NodeType, info.Imaginary);
  end;
end;

procedure TBezierMonitor.PushUndoPoint(sel: TRFigure);
var crv: TRCurve;
begin
  crv := nil;
  if sel = nil then
    Exit
  else if sel is TRSelBezierPoint then
    crv := TRSelBezierPoint(sel).Curve
  else if sel is TRBezierSelection then
    crv := TRBezierSelection(sel).SourceCurve
  else if sel is TRBezier then
    crv := TRBezier(sel);

  UndoStack(InputSheet).Push(
    GetUndoPoint(crv, InputSheet, InputSheet.WorkingLayer, [daGeometry])
  );
end;

procedure TBezierMonitor.NodeBtnClickHandler(Sender: TObject);
var sel: TRFigure;
    nt: TNodeType;
    info: TBezierSelectionInfo;
begin
  if InputSheet = nil then Exit;
  nt := TNodeType((Sender as TComponent).Tag);
  sel := FindSelectionObject(InputSheet,
    [TRSelBezierPoint, TRBezierSelection, TRBezier]);

  PushUndoPoint(sel);

  if sel = nil then
    Exit
  else if sel is TRSelBezierPoint then
    TRSelBezierPoint(sel).NodeType := nt
  else if sel is TRBezierSelection then
    TRBezierSelection(sel).NodeType := nt
  else if sel is TRBezier then
    TRBezierHelper(sel).AllNodesType := nt;

  info := BezierSelectionInfo(sel);
  EnableButtons(info.SegmentType, info.NodeType, info.Imaginary);

  InputSheet.Dest.Refresh;
end;

procedure TBezierMonitor.SegmBtnClickHandler(Sender: TObject);
var sel: TRFigure;
    st: TSegmentType;
    info: TBezierSelectionInfo;
begin
  if InputSheet = nil then Exit;
  st := TSegmentType((Sender as TComponent).Tag);
  sel := FindSelectionObject(InputSheet,
    [TRSelBezierPoint, TRBezierSelection, TRBezier]);

  PushUndoPoint(sel);

  if sel = nil then
    Exit
  else if sel is TRSelBezierPoint then
    TRSelBezierPoint(sel).SegmentType := st
  else if sel is TRBezierSelection then
    TRBezierSelection(sel).SegmentType := st
  else if sel is TRBezier then
    TRBezierHelper(sel).AllSegmentsType := st;

  info := BezierSelectionInfo(sel);
  EnableButtons(info.SegmentType, info.NodeType, info.Imaginary);

  InputSheet.Dest.Refresh;
end;

end.
