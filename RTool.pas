{*******************************************************************************
*                                                                              *
*                       Author: Reonid                                         *
*                       Categoty: vector graphic                               *
*                       mailto: reonid@yahoo.com                               *
*                                                                              *
*******************************************************************************}

unit RTool;

interface

uses               
  RCore, RTypes, RGeom,  RIntf, RGroup, RUndo,
  Controls, Classes;

type

  // There are 3 main categories of Tools:
  // Edit, Zoom and Creation

  TRCreateEvent = function(Layer: TRLayer; const Rect: TRectF): TRFigure of object;

  TRCreationTool = class(TRTool)
  private
    FFigure: TRFigure;
    FOnCreate: TRCreateEvent;

    FPrevPt: TPointF;
    FHitDisplacement: TPointF;

    function GetEdgePoint(Layer: TRLayer; const R: TRectF): TPointF;
  protected
    function CreateFigure(Sheet: TRSheet): TRFigure;

    procedure BeginHandleMouse(Sheet: TRSheet; var Handled: Boolean); override;
    procedure EndHandleMouse(Sheet: TRSheet); override;
    procedure HandleKbd(Sheet: TRSheet); override;
    procedure ProcessLayer(Layer: TRLayer); override;
    function KeepActiveFigure(Sheet: TRSheet): Boolean; override;
  public
    property Figure: TRFigure read FFigure write FFigure;
    property OnCreate: TRCreateEvent read FOnCreate write FOnCreate;
  end;

  TRCreationUndoPoint = class(TRUndoPoint)
  private
    FFigure: TRFigure;
    FFigures: TList;
  public
    constructor Create(AFigure: TRFigure; ASheet: TRSheet; ALayer: TRLayer); overload;
    constructor Create(AGroup: TRSelectionGroup; ASheet: TRSheet; ALayer: TRLayer); overload;
    destructor Destroy; override;
    procedure Restore; override;
  end;

function CreationTool: TRCreationTool;
function EditTool: TREditTool;

implementation

uses
  RFigHlp;

var
  theCreationTool: TRCreationTool;
  theEditTool: TREditTool;

function CreationTool: TRCreationTool;
begin
  if theCreationTool= nil then
    theCreationTool := TRCreationTool.Create('LineCreation');
  Result := theCreationTool;
end;

function EditTool: TREditTool;
begin
  if theEditTool= nil then
    theEditTool := TREditTool.Create('Edit');
  Result := theEditTool;
end;

{---------------------------- TRCreationTool ----------------------------------}

function TRCreationTool.CreateFigure(Sheet: TRSheet): TRFigure;
var R: TRectF;
begin
  Result := nil;
  if not Assigned(Sheet.WorkingLayer) then Exit;

  R := RectF(Sheet.WorkingLayer.DownPt, Sheet.WorkingLayer.CurrPt);
  OrientRectF(R);

  if Assigned(FOnCreate) then
    Result := FOnCreate(Sheet.WorkingLayer, R);

  if Assigned(Result) then
    UndoStack(Sheet.WorkingLayer.Sheet).Push(
      TRCreationUndoPoint.Create(Result, Sheet.WorkingLayer.Sheet, Sheet.WorkingLayer)
    );
end;

function TRCreationTool.GetEdgePoint(Layer: TRLayer; const R: TRectF): TPointF;
begin
  with Layer.Sheet do
  begin
    if CurrPt.X > DownPt.X then Result.X := R.XMax else Result.X := R.XMin;
    if CurrPt.Y > DownPt.Y then Result.Y := R.YMin else Result.Y := R.YMax;
  end;
end;

procedure TRCreationTool.BeginHandleMouse(Sheet: TRSheet; var Handled: Boolean);
var Data: TTransformData;
    edgePt: TPointF;
    figRect: TRectF;
begin
  Sheet.ProcessActiveFigure;
  if Sheet.EventHandled then  Exit;

  Handled := True;
  if not Assigned(Sheet.WorkingLayer) then Exit;

  Sheet.WorkingLayer.Prepare(prHandleMouse);

  case Sheet.Event of
    {...............................}
    evMouseDown: FFigure := nil;
    {...............................}
    evMouseUp:
    begin
      //WorkLayer.Deselect;
      if Assigned(FFigure) then FFigure.SelectProgramly(Sheet.WorkingLayer);
    end;
    {...............................}
    evMouseMove:
    begin
      if (ssLeft in Sheet.WorkingLayer.Sheet.ShiftState) then
      begin

        if (FFigure = nil) then {---------- Creation of the figure ----------}
        begin
          with Sheet.WorkingLayer.Sheet do
            if (Abs(CurrPt.X - DownPt.X) < 6)or
               (Abs(CurrPt.Y - DownPt.Y) < 6)then Exit;

          FFigure := CreateFigure(Sheet);

          figRect := TRFigureHelper(FFigure).ContainingRect;
          OrientRectF(figRect);
          edgePt := GetEdgePoint(Sheet.WorkingLayer, figRect);

          FHitDisplacement := PointF(Sheet.WorkingLayer.CurrPt.X - edgePt.X,
            Sheet.WorkingLayer.CurrPt.Y - edgePt.Y);

          FPrevPt := Sheet.WorkingLayer.CurrPt;

        end
        else                    {---------- Scaling of the figure -----------}
        begin
          with Sheet.WorkingLayer do
          begin
            if (CurrPt.X - DownPt.X - FHitDisplacement.X = 0)or
               (CurrPt.Y - DownPt.Y - FHitDisplacement.Y = 0) then Exit;
            if (FPrevPt.X - DownPt.X - FHitDisplacement.X = 0)or
               (FPrevPt.Y - DownPt.Y - FHitDisplacement.Y = 0) then Exit;
          end;

          with Sheet.WorkingLayer do
            InitScaleData(Data,
              DownPt.X,
              DownPt.Y,
              (CurrPt.X - DownPt.X - FHitDisplacement.X)/(FPrevPt.X - DownPt.X - FHitDisplacement.X),
              (CurrPt.Y - DownPt.Y - FHitDisplacement.Y)/(FPrevPt.Y - DownPt.Y - FHitDisplacement.Y));

          TRFigureHelper(FFigure).Transform(Data);
          FPrevPt := Sheet.WorkingLayer.CurrPt;
        end;
        Sheet.WorkingLayer.Sheet.Redraw := true;
      end;                      {--------------------------------------------}
    end;
    {...............................}
  end;
end;

function TRCreationTool.KeepActiveFigure(Sheet: TRSheet): Boolean;
begin
  Result := False;
end;

procedure TRCreationTool.EndHandleMouse(Sheet: TRSheet);
begin
  Sheet.ProcessContextPopup;
end;

procedure TRCreationTool.HandleKbd(Sheet: TRSheet);
begin
  Sheet.ProcessActiveFigure;
  if Sheet.EventHandled then Exit;
end;

procedure TRCreationTool.ProcessLayer(Layer: TRLayer);
begin
end;

{-------------------------- TRCreationUndoPoint -------------------------------}

constructor TRCreationUndoPoint.Create(AFigure: TRFigure; ASheet: TRSheet; ALayer: TRLayer);
begin
  inherited Create(ASheet, ALayer);
  if AFigure is TRSelectionGroup
    then Create(TRSelectionGroup(AFigure), ASheet, ALayer)
    else FFigure := AFigure;
end;

constructor TRCreationUndoPoint.Create(AGroup: TRSelectionGroup; ASheet: TRSheet; ALayer: TRLayer);
var i: Integer;
begin
  inherited Create(ASheet, ALayer);
  FFigures := TList.Create;
  for i := 0 to AGroup.Count-1 do
    FFigures.Add(AGroup[i]);
end;

destructor TRCreationUndoPoint.Destroy;
begin
  FFigures.Free; 
  inherited;
end;

procedure TRCreationUndoPoint.Restore;
var i: Integer;
begin
  Sheet.BeginDeal;

  if Assigned(FFigure)
    then FFigure.Free
    else for i := 0 to FFigures.Count-1 do TObject(FFigures[i]).Free;

  Layer.Deselect;
  Sheet.EndDeal;
end;

initialization
finalization
  theCreationTool.Free;
  theEditTool.Free;
end.
